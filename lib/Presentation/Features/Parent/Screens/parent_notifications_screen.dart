import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import 'parent_notification_detail_screen.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  // Filters
  NotificationSenderType? _filterSenderType; // null = All
  bool _filterUnreadOnly = false;
  String? _filterChildId; // null = All Wards
  bool _showArchivedOnly = false;
  final Set<String> _expandedIds = {};

  Future<void> _makePhoneCall(String phone, String name) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        AppSnackBar.showError(context, 'Could not open phone dialer for $name');
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Could not open phone dialer for $name');
    }
  }

  Future<void> _sendEmail(String email, String name) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('mailto:$email?subject=Query regarding ward');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        AppSnackBar.showError(context, 'Could not open email client for $name');
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Could not open email client for $name');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
      return '$mins m ago';
    } else if (now.year == timestamp.year && now.month == timestamp.month && now.day == timestamp.day) {
      return DateFormat('h:mm a').format(timestamp).toLowerCase();
    } else if (difference.inDays < 7) {
      return DateFormat('EEE, h:mm a').format(timestamp).toLowerCase();
    } else {
      return DateFormat('d MMM').format(timestamp);
    }
  }

  Future<void> _confirmDeleteNotification(
    BuildContext context,
    ParentNotificationMessage notif,
    ParentController controller,
  ) async {
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
      controller.deleteNotification(notif.id);
    }
  }

  void _showNotificationOptions(
    BuildContext context,
    bool isDark,
    ParentNotificationMessage notif,
    ParentController controller,
  ) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
                      child: Text(
                        notif.senderName.isNotEmpty ? notif.senderName[0].toUpperCase() : 'N',
                        style: const TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.text(ctx),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notif.senderName,
                            style: TextStyle(
                              color: AppTheme.textSecondary(ctx),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Option 1: Open Full Screen
              ListTile(
                leading: const Icon(Icons.open_in_full_rounded, color: Color(0xFF2DD4BF)),
                title: const Text('Open Full Screen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (!notif.isRead) {
                    controller.markNotificationAsRead(notif.id);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: ParentNotificationDetailScreen(
                          notification: notif,
                          controller: controller,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Option 2: Toggle Read / Unread
              ListTile(
                leading: Icon(
                  notif.isRead ? Icons.mark_email_unread_rounded : Icons.mark_email_read_rounded,
                  color: notif.isRead ? const Color(0xFF2DD4BF) : AppTheme.textSecondary(ctx),
                ),
                title: Text(
                  notif.isRead ? 'Mark as Unread' : 'Mark as Read',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.toggleNotificationRead(notif.id);
                },
              ),

              // Option 3: Call (if senderPhone exists)
              if (notif.senderPhone != null)
                ListTile(
                  leading: const Icon(Icons.phone_rounded, color: Color(0xFF2DD4BF)),
                  title: Text('Call ${notif.senderName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _makePhoneCall(notif.senderPhone!, notif.senderName);
                  },
                ),

              // Option 4: Email (if senderEmail exists)
              if (notif.senderEmail != null)
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: Color(0xFF2DD4BF)),
                  title: Text('Email ${notif.senderName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendEmail(notif.senderEmail!, notif.senderName);
                  },
                ),

              // Option 5: Delete Notification (Red - triggers confirmation dialog)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text(
                  'Delete Notification',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteNotification(context, notif, controller);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClearAllRead(BuildContext context, ParentController controller) async {
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
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Clear Read Alerts',
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
            'Are you sure you want to remove all read notifications? Unread and archived items will be kept safe.',
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
              child: const Text('Clear Read', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      controller.clearReadNotifications();
      AppSnackBar.showSuccess(context, 'All read notifications cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<ParentController>();
    final allNotifications = controller.notifications;

    // Apply filters
    final filtered = allNotifications.where((n) {
      if (_showArchivedOnly) {
        return n.isArchived;
      }
      if (n.isArchived) {
        return false;
      }
      if (_filterSenderType != null && n.senderType != _filterSenderType) {
        return false;
      }
      if (_filterUnreadOnly && n.isRead) {
        return false;
      }
      if (_filterChildId != null && n.childId != null && n.childId != _filterChildId) {
        return false;
      }
      return true;
    }).toList();

    final unreadCount = controller.unreadNotificationsCount;
    final archivedCount = controller.archivedNotificationsCount;

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
            if (_showArchivedOnly) {
              setState(() => _showArchivedOnly = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _showArchivedOnly ? 'Archived Notifications' : 'Campus Notifications',
          style: TextStyle(
            color: AppTheme.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppTheme.text(context)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: AppTheme.card(context),
            elevation: 6,
            onSelected: (val) {
              HapticFeedback.selectionClick();
              if (val == 'mark_all_read') {
                controller.markAllNotificationsAsRead();
              } else if (val == 'toggle_archived') {
                setState(() => _showArchivedOnly = !_showArchivedOnly);
              } else if (val == 'clear_read') {
                _confirmClearAllRead(context, controller);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF2DD4BF)),
                    const SizedBox(width: 12),
                    Text('Mark all as read', style: TextStyle(color: AppTheme.text(ctx), fontSize: 13.5)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_archived',
                child: Row(
                  children: [
                    Icon(
                      _showArchivedOnly ? Icons.inbox_rounded : Icons.archive_outlined,
                      size: 18,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _showArchivedOnly
                          ? 'Back to Inbox'
                          : 'Archived ${archivedCount > 0 ? "($archivedCount)" : ""}',
                      style: TextStyle(color: AppTheme.text(ctx), fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_outlined, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Text('Clear all read', style: TextStyle(color: AppTheme.text(ctx), fontSize: 13.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Child Filter Pills (Aarav / Ananya / All Wards)
          _buildChildFilterBar(context, isDark, controller.children),

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return _buildNotificationCard(context, isDark, notif, controller);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildFilterBar(BuildContext context, bool isDark, List<ChildProfile> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            Text(
              'Filter Ward: ',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('All Wards'),
              selected: _filterChildId == null,
              onSelected: (sel) {
                HapticFeedback.selectionClick();
                setState(() => _filterChildId = null);
              },
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _filterChildId == null
                    ? const Color(0xFF2DD4BF)
                    : AppTheme.textSecondary(context),
              ),
              selectedColor: const Color(0xFF2DD4BF).withValues(alpha: 0.18),
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: _filterChildId == null
                    ? const Color(0xFF2DD4BF)
                    : isDark
                        ? Colors.white24
                        : const Color(0xFFCBD5E1),
              ),
              visualDensity: VisualDensity.compact,
            ),
            for (final child in children) ...[
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(child.name.split(' ').first),
                selected: _filterChildId == child.id,
                onSelected: (sel) {
                  HapticFeedback.selectionClick();
                  setState(() => _filterChildId = sel ? child.id : null);
                },
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _filterChildId == child.id
                      ? const Color(0xFF2DD4BF)
                      : AppTheme.textSecondary(context),
                ),
                selectedColor: const Color(0xFF2DD4BF).withValues(alpha: 0.18),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: _filterChildId == child.id
                      ? const Color(0xFF2DD4BF)
                      : isDark
                          ? Colors.white24
                          : const Color(0xFFCBD5E1),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    bool isDark,
    ParentNotificationMessage notif,
    ParentController controller,
  ) {
    final isFaculty = notif.senderType == NotificationSenderType.faculty;

    // Extract sender initial letter (matching reference image)
    final String initial;
    final String cleanName = notif.senderName
        .replaceAll('Dr. ', '')
        .replaceAll('Prof. ', '')
        .replaceAll('Office of the ', '')
        .replaceAll('Department of ', '')
        .trim();
    initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'N';

    final Color badgeBg;
    final Color badgeFg;

    if (isFaculty) {
      badgeBg = const Color(0xFF2DD4BF).withValues(alpha: isDark ? 0.22 : 0.16);
      badgeFg = const Color(0xFF2DD4BF);
    } else if (notif.title.contains('Bus') || notif.title.contains('RFID') || notif.title.contains('Transit')) {
      badgeBg = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.22 : 0.16);
      badgeFg = const Color(0xFFD97706);
    } else if (notif.title.contains('Exam') || notif.title.contains('Alert') || notif.priority == NotificationPriority.urgent) {
      badgeBg = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.22 : 0.16);
      badgeFg = const Color(0xFFEF4444);
    } else {
      badgeBg = const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.22 : 0.16);
      badgeFg = const Color(0xFF2563EB);
    }

    final String snippet = (notif.childName != null && notif.childName!.isNotEmpty)
        ? '[${notif.childName}] ${notif.message}'
        : notif.message;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: _showArchivedOnly ? const Color(0xFF3B82F6) : const Color(0xFF2DD4BF),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showArchivedOnly ? Icons.unarchive_rounded : Icons.archive_rounded,
              color: _showArchivedOnly ? Colors.white : Colors.black,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              _showArchivedOnly ? 'Unarchive' : 'Archive',
              style: TextStyle(
                color: _showArchivedOnly ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        if (_showArchivedOnly) {
          controller.unarchiveNotification(notif.id);
          AppSnackBar.showSuccess(
            context,
            'Notification restored to inbox',
            icon: Icons.unarchive_rounded,
          );
        } else {
          controller.archiveNotification(notif.id);
          AppSnackBar.showSuccess(
            context,
            'Notification moved to archive',
            icon: Icons.archive_rounded,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF2DD4BF),
              onPressed: () => controller.unarchiveNotification(notif.id),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.border(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () {
              _showNotificationOptions(context, isDark, notif, controller);
            },
            onTap: () {
              HapticFeedback.selectionClick();
              if (!notif.isRead) {
                controller.markNotificationAsRead(notif.id);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: controller,
                    child: ParentNotificationDetailScreen(
                      notification: notif,
                      controller: controller,
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular initial avatar (matching reference image)
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: badgeBg,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: badgeFg,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Content Column: Sender + Time/Dot, Title + Star, Snippet
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Sender Name & Timestamp + Unread Dot
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: notif.isRead
                                      ? AppTheme.textSecondary(context)
                                      : AppTheme.text(context),
                                  fontWeight: notif.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTimestamp(notif.timestamp),
                                  style: TextStyle(
                                    color: notif.isRead
                                        ? (isDark
                                            ? Colors.white54
                                            : const Color(0xFF64748B))
                                        : const Color(0xFF2DD4BF),
                                    fontSize: 11.5,
                                    fontWeight: notif.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                if (!notif.isRead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2DD4BF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Row 2: Subject / Title & Star icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: notif.isRead
                                      ? AppTheme.textSecondary(context)
                                      : AppTheme.text(context),
                                  fontWeight: notif.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star_border_rounded,
                              size: 19,
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFCBD5E1),
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Row 3: Snippet / Message preview (1 line)
                        Text(
                          snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: notif.isRead
                                ? (isDark
                                    ? Colors.white54
                                    : const Color(0xFF94A3B8))
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_chat_read_rounded,
                size: 64,
                color: Color(0xFF2DD4BF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications Found',
              style: TextStyle(
                color: AppTheme.text(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All official alerts, faculty messages, and authority announcements will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (_filterSenderType != null || _filterUnreadOnly || _filterChildId != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filterSenderType = null;
                    _filterUnreadOnly = false;
                    _filterChildId = null;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset All Filters'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2DD4BF)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
