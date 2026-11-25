import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import 'parent_notice_detail_screen.dart';

class ParentNoticesFacultyTab extends StatefulWidget {
  const ParentNoticesFacultyTab({super.key});

  @override
  State<ParentNoticesFacultyTab> createState() =>
      _ParentNoticesFacultyTabState();
}

class _ParentNoticesFacultyTabState extends State<ParentNoticesFacultyTab> {
  NoticeCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentController>();
    final allNotices = controller.notices;

    // Filter by category and search query
    final filteredNotices = allNotices.where((notice) {
      if (_selectedCategory != null && notice.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = notice.title.toLowerCase().contains(q);
        final matchesBody = notice.fullContent.toLowerCase().contains(q);
        final matchesAuthor = notice.publishedBy.toLowerCase().contains(q);
        return matchesTitle || matchesBody || matchesAuthor;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notices & Circulars',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text(context),
              ),
            ),
            Text(
              'Official School Announcements',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(fontSize: 13, color: AppTheme.text(context)),
                decoration: InputDecoration(
                  hintText: 'Search circulars, exams, events...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Color(0xFF2DD4BF),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All (${allNotices.length})',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Exams',
                  isSelected: _selectedCategory == NoticeCategory.exam,
                  icon: Icons.assignment_outlined,
                  onTap: () => setState(
                      () => _selectedCategory = NoticeCategory.exam),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Events & PTM',
                  isSelected: _selectedCategory == NoticeCategory.event,
                  icon: Icons.event_rounded,
                  onTap: () => setState(
                      () => _selectedCategory = NoticeCategory.event),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Holidays',
                  isSelected: _selectedCategory == NoticeCategory.holiday,
                  icon: Icons.beach_access_rounded,
                  onTap: () => setState(
                      () => _selectedCategory = NoticeCategory.holiday),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Academic',
                  isSelected: _selectedCategory == NoticeCategory.academic,
                  icon: Icons.school_outlined,
                  onTap: () => setState(
                      () => _selectedCategory = NoticeCategory.academic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Notices List
          Expanded(
            child: filteredNotices.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredNotices.length,
                    itemBuilder: (ctx, index) => _buildNoticeCard(
                      context,
                      filteredNotices[index],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final activeBg = const Color(0xFF2DD4BF);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? activeBg
                : (isDark ? const Color(0xFF161616) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? activeBg
                  : AppTheme.border(context).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? Colors.black
                      : AppTheme.textSecondary(context),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black : AppTheme.text(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNoticeDetail(BuildContext context, CampusNotice notice) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentNoticeDetailScreen(notice: notice),
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, CampusNotice notice) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notice.isUrgent
              ? const Color(0xFFEF4444).withValues(alpha: 0.45)
              : AppTheme.border(context),
          width: notice.isUrgent ? 1.2 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNoticeDetail(context, notice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact metadata row: Category, Urgent tag, Date
                Row(
                  children: [
                    Text(
                      notice.category.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: notice.categoryColor,
                      ),
                    ),
                    if (notice.isUrgent) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '• IMPORTANT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      dateFormat.format(notice.publishedDate),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Main Subject Headline + open arrow
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppTheme.text(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppTheme.textSecondary(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No notices found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try selecting another category or clear search',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
