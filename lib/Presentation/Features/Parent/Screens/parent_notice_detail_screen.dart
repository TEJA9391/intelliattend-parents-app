import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Models/parent_models.dart';

/// Simplified, elegant full-screen view for an official school circular.
class ParentNoticeDetailScreen extends StatefulWidget {
  final CampusNotice notice;

  const ParentNoticeDetailScreen({
    super.key,
    required this.notice,
  });

  @override
  State<ParentNoticeDetailScreen> createState() =>
      _ParentNoticeDetailScreenState();
}

class _ParentNoticeDetailScreenState extends State<ParentNoticeDetailScreen> {
  // Static set to persist bookmarks across screens in-session
  static final Set<String> _savedNoticeIds = {};

  bool get _isSaved => _savedNoticeIds.contains(widget.notice.id);

  void _toggleSave() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_isSaved) {
        _savedNoticeIds.remove(widget.notice.id);
        AppSnackBar.showSuccess(
          context,
          'Notice removed from saved items',
          icon: Icons.bookmark_remove_rounded,
        );
      } else {
        _savedNoticeIds.add(widget.notice.id);
        AppSnackBar.showSuccess(
          context,
          'Notice saved to your bookmarks',
          icon: Icons.bookmark_added_rounded,
        );
      }
    });
  }

  Future<void> _shareNotice() async {
    HapticFeedback.lightImpact();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final shareText = '''📢 *${widget.notice.title}*

${widget.notice.fullContent}

🗓 Published: ${dateFormat.format(widget.notice.publishedDate)}
🏛 Issued by: ${widget.notice.publishedBy}
🏫 IntelliAttend School
''';

    try {
      await Share.share(
        shareText,
        subject: widget.notice.title,
      );
    } catch (_) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: shareText));
        AppSnackBar.showSuccess(
          context,
          'Circular text copied to clipboard',
          icon: Icons.copy_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppTheme.text(context),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'School Circular',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.text(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            tooltip: 'Share',
            color: AppTheme.text(context),
            onPressed: _shareNotice,
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: 24,
              color: _isSaved ? const Color(0xFF2DD4BF) : AppTheme.text(context),
            ),
            tooltip: _isSaved ? 'Saved' : 'Save Notice',
            onPressed: _toggleSave,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag & Urgent chip
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: notice.categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notice.category.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: notice.categoryColor,
                    ),
                  ),
                ),
                if (notice.isUrgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 13, color: Color(0xFFEF4444)),
                        SizedBox(width: 4),
                        Text(
                          'IMPORTANT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Notice Title
            Text(
              notice.title,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                height: 1.35,
                color: AppTheme.text(context),
              ),
            ),

            const SizedBox(height: 8),

            // Date & Time line
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppTheme.textSecondary(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateFormat.format(notice.publishedDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Summary quote (if present and distinct)
            if (notice.summary.isNotEmpty && notice.summary != notice.title) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Color(0xFF2DD4BF),
                      width: 3.5,
                    ),
                  ),
                ),
                child: Text(
                  notice.summary,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                ),
              ),
            ],

            // Full Content Text (clean prose without nested card box)
            Text(
              notice.fullContent,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.7,
                color: AppTheme.text(context),
              ),
            ),

            const SizedBox(height: 24),

            // PDF Attachment Download Pill
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.lightImpact();
                  AppSnackBar.showSuccess(
                    context,
                    'Circular PDF downloaded to device storage',
                    icon: Icons.download_done_rounded,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161616)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Official_Circular_${notice.id}.pdf',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '284 KB • Official Stamp Signed Copy',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.file_download_outlined,
                        color: Color(0xFF2DD4BF),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Formal Authority Sign-Off Footer
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      color: Color(0xFF2DD4BF),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issued by: ${notice.publishedBy}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Office of Administration & Academic Affairs',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2DD4BF),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
