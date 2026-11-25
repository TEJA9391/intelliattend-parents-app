import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intelli_attend_faculty/Services/haptic_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:intelli_attend_faculty/Data/Models/Messaging/messaging_models.dart';
import 'package:intelli_attend_faculty/Data/Repositories/Messaging/messaging_repository.dart';
import 'package:intelli_attend_faculty/Data/Services/message_cache_service.dart';
import 'package:intelli_attend_faculty/Theme/app_theme.dart';
import 'package:intelli_attend_faculty/Services/chat_realtime_service.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/chat_appearance_sheet.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/chat_time_format.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/peer_avatar.dart';

/// "View contact" profile for a chat peer with contact details, call buttons,
/// presence, mute/block/report and wallpaper settings.
class ViewProfileScreen extends StatefulWidget {
  final StudentContact peer;
  final String conversationId;

  const ViewProfileScreen({super.key, required this.peer, required this.conversationId});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final MessageCacheService _cache = MessageCacheService.instance;
  final MessagingRepository _repository = MessagingRepository();

  StudentContact get _peer => widget.peer;

  bool get _isOnline {
    final snap = ChatRealtimeService.instance.presenceFor(_peer.id);
    return snap?.isOnline ?? _peer.isOnline;
  }

  String get _presenceText {
    final snap = ChatRealtimeService.instance.presenceFor(_peer.id);
    if (_isOnline) return 'Online';
    return ChatTimeFormat.lastSeen(snap?.lastSeen ?? _peer.lastSeen);
  }

  @override
  Widget build(BuildContext context) {
    final peer = _peer;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: ChatRealtimeService.instance,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: AppTheme.text(context), size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [const Color(0xFF0D1117), const Color(0xFF161B22)]
                          : [const Color(0xFFF0FDF4), const Color(0xFFF8FAFC)],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Hero(
                          tag: 'avatar_${peer.id}',
                          child: PeerAvatar(
                            name: peer.name,
                            imageUrl: peer.avatarUrl,
                            radius: 52,
                            isOnline: _isOnline,
                            showOnlineDot: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          peer.displayTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppTheme.text(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            key: ValueKey(_presenceText),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? AppTheme.greenOnline.withValues(alpha: 0.12)
                                  : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isOnline)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.greenOnline,
                                    ),
                                  ),
                                Text(
                                  _presenceText,
                                  style: GoogleFonts.inter(
                                    color: _isOnline ? AppTheme.greenOnline : AppTheme.textSecondary(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(isDark),
                    const SizedBox(height: 16),
                    _buildContactActions(isDark),
                    const SizedBox(height: 16),
                    _buildSettingsSection(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          if (_peer.rollNumber != null)
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Roll Number',
              value: _peer.rollNumber!,
              copyable: true,
              onCopy: () => _copy(_peer.rollNumber!),
              isFirst: true,
              isDark: isDark,
            ),
          if (_peer.section != null)
            _InfoTile(
              icon: Icons.class_outlined,
              label: 'Section',
              value: _peer.section!,
              isDark: isDark,
            ),
          if (_peer.department != null)
            _InfoTile(
              icon: Icons.school_outlined,
              label: 'Department',
              value: _peer.department!,
              isDark: isDark,
            ),
          if (_peer.courseCode != null || _peer.courseName != null)
            _InfoTile(
              icon: Icons.menu_book_outlined,
              label: 'Course',
              value: [_peer.courseName, _peer.courseCode]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(' '),
              isDark: isDark,
            ),
          if (_peer.email != null)
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _peer.email!,
              copyable: true,
              onCopy: () => _copy(_peer.email!),
              isDark: isDark,
            ),
          if (_peer.phone != null)
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _peer.phone!,
              copyable: true,
              onCopy: () => _copy(_peer.phone!),
              isLast: true,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildContactActions(bool isDark) {
    if (_peer.phone == null) return const SizedBox.shrink();
    return _ContactButton(
      icon: Icons.call_outlined,
      label: 'Call Faculty',
      color: const Color(0xFF2DD4BF),
      onTap: () => launchUrl(
        Uri.parse('tel:${_peer.phone}'),
        mode: LaunchMode.externalApplication,
      ),
      isDark: isDark,
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.wallpaper_outlined,
            label: 'Wallpaper & Theme',
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary(context), size: 20),
            onTap: () => showChatAppearanceSheet(
              context,
              conversationId: widget.conversationId,
            ),
            isFirst: true,
            isDark: isDark,
          ),
          _SettingsRow(
            icon: Icons.report_problem_outlined,
            label: 'Report Faculty / Grievance',
            labelColor: const Color(0xFFEF4444),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444), size: 20),
            onTap: () => _showReportFacultySheet(context),
            isLast: true,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  void _showReportFacultySheet(BuildContext context) {
    HapticService.medium();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = [
      'Unprofessional Conduct or Harsh Behavior',
      'Unfair Academic Evaluation / Grading Concern',
      'Frequent Absence or Class Lateness',
      'Unresponsive to Academic Inquiries',
      'Lack of Homework / Syllabus Guidance',
      'Other Grievance / Concern',
    ];
    String selectedReason = reasons.first;
    final detailsController = TextEditingController();
    bool forwardToPrincipal = true;
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Faculty / File Grievance',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text(context),
                              ),
                            ),
                            Text(
                              'Official Parent Confidential Grievance Cell',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Scrollable Form
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Faculty Info pill
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                child: Text(
                                  _peer.name[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _peer.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.text(context),
                                      ),
                                    ),
                                    Text(
                                      _peer.department ?? 'Faculty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CONFIDENTIAL',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Section 1: Requirement / Reason
                        Text(
                          '1. Reason for Reporting *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 8),

                        ...reasons.map((r) {
                          final isSelected = selectedReason == r;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setModalState(() => selectedReason = r),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                        : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAFAFA)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFEF4444)
                                          : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                      width: isSelected ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        size: 16,
                                        color: isSelected ? const Color(0xFFEF4444) : AppTheme.textSecondary(context),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          r,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected ? AppTheme.text(context) : AppTheme.textSecondary(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 14),

                        // Section 2: Incident Details Requirement
                        Text(
                          '2. Detailed Incident / Grievance Description *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: validationError != null
                                  ? const Color(0xFFEF4444)
                                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              width: validationError != null ? 1.4 : 1.0,
                            ),
                          ),
                          child: TextField(
                            controller: detailsController,
                            maxLines: 4,
                            maxLength: 500,
                            onChanged: (_) {
                              if (validationError != null) {
                                setModalState(() => validationError = null);
                              }
                            },
                            style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                            decoration: InputDecoration(
                              hintText: 'Please describe the incident, dates, and specific concerns clearly for the Principal\'s review...',
                              hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Section 3: Escalation Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: forwardToPrincipal,
                              activeColor: const Color(0xFFEF4444),
                              onChanged: (v) => setModalState(() => forwardToPrincipal = v ?? true),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => forwardToPrincipal = !forwardToPrincipal),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Forward directly to Principal\'s Office (Dr. Meera Nambiar)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.text(context),
                                        ),
                                      ),
                                      Text(
                                        'Your report will remain strictly confidential and will not be shared with the teacher.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (validationError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    validationError!,
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary(context),
                                  side: BorderSide(color: AppTheme.border(context)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final details = detailsController.text.trim();
                                  if (details.length < 5) {
                                    HapticService.light();
                                    setModalState(() {
                                      validationError =
                                          'Please enter at least a brief description of the incident.';
                                    });
                                    return;
                                  }

                                  Navigator.of(ctx).pop();
                                  _repository.reportConversation(
                                    widget.conversationId,
                                    '[$selectedReason] $details',
                                  );

                                  final refId = 'GRV-${DateTime.now().millisecondsSinceEpoch % 100000}';
                                  showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: AppTheme.card(context),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 24),
                                          SizedBox(width: 10),
                                          Text('Report Submitted', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your grievance regarding ${_peer.name} has been filed successfully with the School Principal.',
                                            style: const TextStyle(fontSize: 13, height: 1.4),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.confirmation_number_outlined, size: 16, color: Color(0xFF2DD4BF)),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Grievance ID: $refId',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2DD4BF),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'The Principal\'s Office will review this discreetly within 24-48 working hours.',
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(c).pop(),
                                          child: const Text('OK', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final VoidCallback? onCopy;
  final bool isFirst;
  final bool isLast;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.onCopy,
    this.isFirst = false,
    this.isLast = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: !isLast
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary(context), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.text(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: onCopy,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.copy_rounded, size: 14, color: AppTheme.textSecondary(context)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;
  final bool isDark;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.labelColor,
    this.trailing,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = labelColor ?? AppTheme.text(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: !isLast
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                    width: 1,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, color: labelColor ?? AppTheme.textSecondary(context), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: c,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
