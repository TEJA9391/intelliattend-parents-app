import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import '../Widgets/child_switcher_bar.dart';
import '../Widgets/student_academic_card.dart';
import '../Widgets/zomato_bus_tracking_card.dart';
import '../Widgets/attendance_gauge_card.dart';
import '../Widgets/apply_leave_dialog.dart';
import '../Widgets/guardian_portal_sheet.dart';

class ParentDashboardTab extends StatefulWidget {
  final Function(int) onTabChange;

  const ParentDashboardTab({
    super.key,
    required this.onTabChange,
  });

  @override
  State<ParentDashboardTab> createState() => _ParentDashboardTabState();
}

class _ParentDashboardTabState extends State<ParentDashboardTab> {
  static const double _kRefreshThreshold = 80.0;
  double _dragProgress = 0.0;
  bool _isRefreshing = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isRefreshing || notification.depth != 0) return false;

    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels < 0) {
        final p = (pixels.abs() / _kRefreshThreshold).clamp(0.0, 1.0);
        if ((p - _dragProgress).abs() > 0.005) {
          setState(() => _dragProgress = p);
        }
      } else if (_dragProgress > 0) {
        setState(() => _dragProgress = 0.0);
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragProgress >= 1.0) {
        _triggerRefresh();
      } else if (_dragProgress > 0) {
        setState(() => _dragProgress = 0.0);
      }
    }
    return false;
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _isRefreshing = true;
      _dragProgress = 0.0;
    });
    await context.read<ParentController>().refreshData();
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _isRefreshing = false);
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<ParentController>();
    final child = controller.activeChild;
    final todayClasses = controller.todayClasses;
    final subjects = controller.subjects;
    final notices = controller.notices;

    const paleGreenBar = Color(0xFFA3E635); // Pale green / Lime
    final bool showBar = _dragProgress > 0 || _isRefreshing;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 68.0;

    return Stack(
      children: [
        // Scrollable Body with Scroll Notification Listener
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: ListView(
            padding: EdgeInsets.only(top: headerHeight + 8, bottom: 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 1. Child Switcher (Multi-child toggle)
              const ChildSwitcherBar(),

              // 2. Enrolled Student Card (Normal Time) OR Zomato-style Live Map (When on Bus via RFID Tap)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 400),
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeInCubic,
                crossFadeState: (controller.isChildOnBus && controller.activeChildTransit != null)
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: StudentAcademicCard(
                  child: child,
                  transit: controller.activeChildTransit,
                  onRfidBusTap: () => controller.tapRfidBoardBus(child.id),
                ),
                secondChild: controller.activeChildTransit != null
                    ? ZomatoBusTrackingCard(
                        child: child,
                        transit: controller.activeChildTransit!,
                        onDeboardTap: () {
                          final transit = controller.activeChildTransit!;
                          final destName = transit.destinationType == TransitDestinationType.school ? 'School' : 'Home';
                          controller.tapRfidDeboardBus(child.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '🎉 ${child.name} safely reached $destName! Map tracking stopped.',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0F766E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),

              // 3. Quick Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildQuickAction(
                      context,
                      icon: Icons.note_add_rounded,
                      label: 'Apply Leave',
                      color: const Color(0xFF0F766E),
                      onTap: () => ApplyLeaveBottomSheet.show(context),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.event_note_rounded,
                      label: 'My Leaves',
                      color: const Color(0xFFF97316),
                      onTap: () => widget.onTabChange(2),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.support_agent_rounded,
                      label: 'Call Mentor',
                      color: const Color(0xFF0D9488),
                      onTap: () => widget.onTabChange(3),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.analytics_outlined,
                      label: 'Detailed %',
                      color: const Color(0xFF3B82F6),
                      onTap: () => widget.onTabChange(1),
                    ),
                  ],
                ),
              ),

              // 4. Cumulative Attendance Gauge
              AttendanceGaugeCard(
                child: child,
                subjects: subjects,
                onDetailsTap: () => widget.onTabChange(1),
              ),

              // 5. Today's Period Schedule
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Lectures",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text(context),
                      ),
                    ),
                    Text(
                      '${todayClasses.where((c) => c.status == PeriodStatus.present).length} of ${todayClasses.length} Attended',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ],
                ),
              ),

              ...todayClasses.map((lecture) => _buildLectureItem(context, lecture)),

              // 6. Recent Campus Circulars preview
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Important Circulars',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text(context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onTabChange(3),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ...notices.take(2).map((notice) => _buildNoticePreview(context, notice)),
            ],
          ),
        ),

        // Fixed Top Header (Old header layout: left logo ring, name on top, good morning below, right notifications)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: headerHeight,
            padding: EdgeInsets.only(
              top: topPadding + 6,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.bg(context),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.border(context),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                // Left IntelliAttend logo & parent name (tappable to open Guardian Portal Sheet)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => GuardianPortalSheet.show(
                      context,
                      onNavigateToProfile: () => widget.onTabChange(4),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/logo_square.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 12,
                                width: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA3E635), // Pale green online dot
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.bg(context),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFA3E635).withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Name of parent on top, Good Morning text below
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                controller.parentName,
                                style: GoogleFonts.inter(
                                  color: AppTheme.text(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getTimeGreeting(),
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? const Color(0xFF71717A)
                                      : const Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right notifications button with unread dot
                GestureDetector(
                  onTap: () => widget.onTabChange(3),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          size: 22,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
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

        // Pale green refresh progress sweep right under the header
        Positioned(
          top: headerHeight - 1,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: showBar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              height: showBar ? 3.0 : 0.0,
              child: LinearProgressIndicator(
                value: _isRefreshing ? null : _dragProgress,
                backgroundColor: paleGreenBar.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(paleGreenBar),
                minHeight: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLectureItem(BuildContext context, PeriodAttendance lecture) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lecture.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(lecture.statusIcon, size: 20, color: lecture.statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lecture.subjectName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: lecture.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lecture.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: lecture.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${lecture.startTime} - ${lecture.endTime} • ${lecture.room} • ${lecture.facultyName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (lecture.timeMarked != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '✓ ${lecture.timeMarked}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2DD4BF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticePreview(BuildContext context, CampusNotice notice) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: notice.categoryColor,
                  ),
                ),
              ),
              if (notice.isUrgent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ACTION REQUIRED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notice.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notice.summary,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
