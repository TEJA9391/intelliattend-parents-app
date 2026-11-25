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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: notice.isUrgent
              ? const Color(0xFFEF4444).withValues(alpha: 0.4)
              : AppTheme.border(context),
          width: notice.isUrgent ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openNoticeDetail(context, notice),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Category tag, Urgent badge, Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: notice.categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notice.category.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: notice.categoryColor,
                        ),
                      ),
                    ),
                    if (notice.isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 11,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'IMPORTANT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: AppTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(notice.publishedDate),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  notice.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: AppTheme.text(context),
                  ),
                ),

                const SizedBox(height: 8),

                // Summary / Content
                Text(
                  notice.fullContent,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),

                const SizedBox(height: 14),

                // Footer: Published by authority & open full screen arrow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 15,
                        color: Color(0xFF2DD4BF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notice.publishedBy,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2DD4BF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Read More',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2DD4BF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: Color(0xFF2DD4BF),
                      ),
                    ],
                  ),
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
