import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

class ParentNotificationDetailScreen extends StatefulWidget {
  final ParentNotificationMessage notification;
  final ParentController? controller;

  const ParentNotificationDetailScreen({
    Key? key,
    required this.notification,
    this.controller,
  }) : super(key: key);

  @override
  State<ParentNotificationDetailScreen> createState() =>
      _ParentNotificationDetailScreenState();
}

class _ParentNotificationDetailScreenState
    extends State<ParentNotificationDetailScreen> {
  late ParentNotificationMessage _notif;

  ParentController? _resolveController(BuildContext context, {bool listen = false}) {
    if (widget.controller != null) return widget.controller;
    try {
      return listen
          ? Provider.of<ParentController>(context, listen: true)
          : Provider.of<ParentController>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _notif = widget.notification;
    // Mark as read immediately on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_notif.isRead) {
        final ctrl = _resolveController(context, listen: false);
        ctrl?.markNotificationAsRead(_notif.id);
        if (mounted) {
          setState(() {
            _notif = _notif.copyWith(isRead: true);
          });
        }
      }
    });
  }

  Future<void> _makePhoneCall(String phone, String name) async {
    HapticFeedback.lightImpact();
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not open phone dialer for $name');
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not open phone dialer for $name');
      }
    }
  }

  Future<void> _sendEmail(String email, String name) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(
        'mailto:$email?subject=${Uri.encodeComponent('Regarding: ${_notif.title}')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not open email client for $name');
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not open email client for $name');
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Notification',
                  style: TextStyle(
                    color: AppTheme.text(ctx),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this notification? This action cannot be undone.',
            style: TextStyle(
              color: AppTheme.textSecondary(ctx),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary(ctx),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final ctrl = _resolveController(context, listen: false);
      ctrl?.deleteNotification(_notif.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = _resolveController(context, listen: true);
    final isFaculty = _notif.senderType == NotificationSenderType.faculty;

    // Sender Emblem styling
    final Color badgeBg;
    final Color badgeFg;
    final IconData badgeIcon;

    if (isFaculty) {
      badgeBg = const Color(0xFF2DD4BF).withValues(alpha: 0.15);
      badgeFg = const Color(0xFF2DD4BF);
      badgeIcon = Icons.school_rounded;
    } else {
      if (_notif.title.contains('Bus') || _notif.title.contains('RFID')) {
        badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        badgeFg = const Color(0xFFD97706);
        badgeIcon = Icons.directions_bus_rounded;
      } else if (_notif.title.contains('Exam') ||
          _notif.title.contains('Hall Ticket')) {
        badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        badgeFg = const Color(0xFFEF4444);
        badgeIcon = Icons.assignment_late_rounded;
      } else {
        badgeBg = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        badgeFg = const Color(0xFF2563EB);
        badgeIcon = Icons.account_balance_rounded;
      }
    }

    final dateFormatted =
        DateFormat('EEEE, MMM d, yyyy • h:mm a').format(_notif.timestamp);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.text(context),
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Notification Details',
          style: TextStyle(
            color: AppTheme.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Delete Notification',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Sender Information Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2DD4BF).withValues(alpha: 0.25)
                    : AppTheme.border(context),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(badgeIcon, color: badgeFg, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _notif.senderName,
                            style: TextStyle(
                              color: AppTheme.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _notif.senderRole,
                            style: TextStyle(
                              color: isFaculty
                                  ? const Color(0xFF2DD4BF)
                                  : AppTheme.textSecondary(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_notif.senderDepartment != null &&
                              _notif.senderDepartment!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              _notif.senderDepartment!,
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _notif.priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _notif.priority == NotificationPriority.urgent
                                ? Icons.warning_rounded
                                : _notif.priority ==
                                        NotificationPriority.important
                                    ? Icons.error_outline_rounded
                                    : Icons.info_outline_rounded,
                            size: 13,
                            color: _notif.priorityColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _notif.priorityLabel,
                            style: TextStyle(
                              color: _notif.priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ward Badge (if applicable)
                    if (_notif.childName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF)
                              .withValues(alpha: isDark ? 0.16 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2DD4BF)
                                .withValues(alpha: isDark ? 0.4 : 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_pin_rounded,
                              size: 13,
                              color: Color(0xFF2DD4BF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ward: ${_notif.childName}',
                              style: const TextStyle(
                                color: Color(0xFF2DD4BF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Full Message Body Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2DD4BF).withValues(alpha: 0.25)
                    : AppTheme.border(context),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormatted,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title / Subject
                Text(
                  _notif.title,
                  style: TextStyle(
                    color: AppTheme.text(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Full Message Text
                SelectableText(
                  _notif.message,
                  style: TextStyle(
                    color: AppTheme.text(context),
                    fontSize: 14.5,
                    height: 1.65,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Action Buttons
          if (_notif.senderPhone != null || _notif.senderEmail != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Actions',
                    style: TextStyle(
                      color: AppTheme.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_notif.senderPhone != null) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(
                                _notif.senderPhone!, _notif.senderName),
                            icon: const Icon(Icons.phone_rounded,
                                size: 16, color: Colors.white),
                            label: Text(
                              isFaculty ? 'Call Faculty' : 'Call Office',
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DD4BF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                      if (_notif.senderPhone != null &&
                          _notif.senderEmail != null)
                        const SizedBox(width: 10),
                      if (_notif.senderEmail != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendEmail(
                                _notif.senderEmail!, _notif.senderName),
                            icon: const Icon(Icons.mail_outline_rounded,
                                size: 16),
                            label: const Text(
                              'Send Email',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.text(context),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFCBD5E1),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
