import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../Widgets/school_report_card_sheet.dart';
import 'parent_notifications_screen.dart';

class ParentDashboardTab extends StatefulWidget {
  final void Function(int index, [int subTab]) onTabChange;

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
    final subjects = controller.subjects;

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
                  key: ValueKey('academic_card_${child.id}_${child.avatarUrl}'),
                  child: child,
                  transit: controller.activeChildTransit,
                  onRfidBusTap: () => controller.tapRfidBoardBus(child.id),
                ),
                secondChild: controller.activeChildTransit != null
                    ? ZomatoBusTrackingCard(
                        child: child,
                        transit: controller.activeChildTransit!,
                        onDeboardTap: () {
                          controller.tapRfidDeboardBus(child.id);
                        },
                      )
                    : const SizedBox.shrink(),
              ),

              // 3. Quick Action Buttons (Academic Essentials)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildQuickAction(
                      context,
                      icon: Icons.note_add_rounded,
                      label: 'Apply Leave',
                      color: const Color(0xFF2DD4BF),
                      onTap: () => ApplyLeaveBottomSheet.show(context),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.calendar_today_rounded,
                      label: 'Timetable',
                      color: const Color(0xFF2DD4BF),
                      onTap: () => _showTimetableSheet(context, child, controller),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.workspace_premium_rounded,
                      label: 'Report Card',
                      color: const Color(0xFF2DD4BF),
                      onTap: () => SchoolReportCardSheet.show(
                        context,
                        child,
                        controller,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.menu_book_rounded,
                      label: 'Homeworks',
                      color: const Color(0xFF2DD4BF),
                      onTap: () => _showHomeworksSheet(context, child, controller),
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

              const SizedBox(height: 16),
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
                                      color: const Color(0xFFA3E635).withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Greeting on top, Name of parent below
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getTimeGreeting(),
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? const Color(0xFF71717A)
                                      : const Color(0xFF64748B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                controller.parentName.trim().isNotEmpty
                                    ? controller.parentName
                                    : 'Parent Portal',
                                style: GoogleFonts.inter(
                                  color: AppTheme.text(context),
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
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

                // Right notifications button - Opens dedicated Campus Notifications from Faculty & Authorities
                GestureDetector(
                  onTap: () {
                    final parentCtrl = Provider.of<ParentController>(context, listen: false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: parentCtrl,
                          child: const ParentNotificationsScreen(),
                        ),
                      ),
                    );
                  },
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
                        Consumer<ParentController>(
                          builder: (context, ctrl, _) {
                            final unread = ctrl.unreadNotificationsCount;
                            if (unread == 0) return const SizedBox.shrink();
                            return Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    unread > 9 ? '9+' : '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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

  void _showTimetableSheet(
    BuildContext context,
    ChildProfile child,
    ParentController controller,
  ) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayClasses = controller.todayClasses;

    // Weekly routine schedule per day
    final weeklySchedule = <String, List<PeriodAttendance>>{
      'Mon (Today)': todayClasses,
      'Tuesday': [
        const PeriodAttendance(
          periodNumber: 'Period 1',
          subjectName: 'Social Science (History)',
          subjectCode: 'SST-10',
          startTime: '09:00 AM',
          endTime: '09:45 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Kavita Reddy',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 2',
          subjectName: 'Mathematics (Geometry)',
          subjectCode: 'MTH-10',
          startTime: '09:50 AM',
          endTime: '10:35 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Sunita Sharma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 3',
          subjectName: 'English Language',
          subjectCode: 'ENG-10',
          startTime: '10:50 AM',
          endTime: '11:35 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Ananya Gupta',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 4',
          subjectName: 'Science (Biology Lab)',
          subjectCode: 'SCI-10',
          startTime: '11:40 AM',
          endTime: '12:25 PM',
          room: 'Biology Lab',
          facultyName: 'Mr. R. K. Verma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 5',
          subjectName: 'Hindi Literature',
          subjectCode: 'HIN-10',
          startTime: '01:10 PM',
          endTime: '01:50 PM',
          room: 'Class 10-A',
          facultyName: 'Mr. Arvind Joshi',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 6',
          subjectName: 'Art & Craft Studio',
          subjectCode: 'ART-10',
          startTime: '01:55 PM',
          endTime: '02:40 PM',
          room: 'Art Studio',
          facultyName: 'Mrs. Meera Roy',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 7',
          subjectName: 'Library & Reading Period',
          subjectCode: 'LIB-10',
          startTime: '02:45 PM',
          endTime: '03:30 PM',
          room: 'School Library',
          facultyName: 'Librarian Mr. Sharma',
          status: PeriodStatus.upcoming,
        ),
      ],
      'Wednesday': [
        const PeriodAttendance(
          periodNumber: 'Period 1',
          subjectName: 'Science (Physics Practical)',
          subjectCode: 'SCI-10',
          startTime: '09:00 AM',
          endTime: '09:45 AM',
          room: 'Physics Lab',
          facultyName: 'Mr. R. K. Verma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 2',
          subjectName: 'Mathematics',
          subjectCode: 'MTH-10',
          startTime: '09:50 AM',
          endTime: '10:35 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Sunita Sharma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 3',
          subjectName: 'Social Science (Geography)',
          subjectCode: 'SST-10',
          startTime: '10:50 AM',
          endTime: '11:35 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Kavita Reddy',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 4',
          subjectName: 'English Grammar & Speech',
          subjectCode: 'ENG-10',
          startTime: '11:40 AM',
          endTime: '12:25 PM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Ananya Gupta',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 5',
          subjectName: 'Computer Science Coding Lab',
          subjectCode: 'CS-10',
          startTime: '01:10 PM',
          endTime: '01:50 PM',
          room: 'Computer Lab 1',
          facultyName: 'Ms. Priya Nair',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 6',
          subjectName: 'Hindi Grammar & Writing',
          subjectCode: 'HIN-10',
          startTime: '01:55 PM',
          endTime: '02:40 PM',
          room: 'Class 10-A',
          facultyName: 'Mr. Arvind Joshi',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 7',
          subjectName: 'Yoga & Physical Fitness',
          subjectCode: 'PET-10',
          startTime: '02:45 PM',
          endTime: '03:30 PM',
          room: 'Indoor Activity Hall',
          facultyName: 'Coach Vikram Singh',
          status: PeriodStatus.upcoming,
        ),
      ],
      'Thursday': [
        const PeriodAttendance(
          periodNumber: 'Period 1',
          subjectName: 'Mathematics (Algebra)',
          subjectCode: 'MTH-10',
          startTime: '09:00 AM',
          endTime: '09:45 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Sunita Sharma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 2',
          subjectName: 'Science (Chemistry Practical)',
          subjectCode: 'SCI-10',
          startTime: '09:50 AM',
          endTime: '10:35 AM',
          room: 'Chemistry Lab',
          facultyName: 'Mr. R. K. Verma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 3',
          subjectName: 'Social Science (Economics)',
          subjectCode: 'SST-10',
          startTime: '10:50 AM',
          endTime: '11:35 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Kavita Reddy',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 4',
          subjectName: 'English Literature',
          subjectCode: 'ENG-10',
          startTime: '11:40 AM',
          endTime: '12:25 PM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Ananya Gupta',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 5',
          subjectName: 'General Knowledge & Values',
          subjectCode: 'GK-10',
          startTime: '01:10 PM',
          endTime: '01:50 PM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Sunita Sharma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 6',
          subjectName: 'Coding & AI Practical',
          subjectCode: 'CS-10',
          startTime: '01:55 PM',
          endTime: '02:40 PM',
          room: 'Computer Lab 1',
          facultyName: 'Ms. Priya Nair',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 7',
          subjectName: 'House Activities & Debate',
          subjectCode: 'ACT-10',
          startTime: '02:45 PM',
          endTime: '03:30 PM',
          room: 'Auditorium',
          facultyName: 'Activity Incharge',
          status: PeriodStatus.upcoming,
        ),
      ],
      'Friday': [
        const PeriodAttendance(
          periodNumber: 'Period 1',
          subjectName: 'Science (Combined Lab)',
          subjectCode: 'SCI-10',
          startTime: '09:00 AM',
          endTime: '09:45 AM',
          room: 'Science Lab 2',
          facultyName: 'Mr. R. K. Verma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 2',
          subjectName: 'Mathematics Problem Solving',
          subjectCode: 'MTH-10',
          startTime: '09:50 AM',
          endTime: '10:35 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Sunita Sharma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 3',
          subjectName: 'Social Science (Civics)',
          subjectCode: 'SST-10',
          startTime: '10:50 AM',
          endTime: '11:35 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Kavita Reddy',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 4',
          subjectName: 'English Creative Writing & ASL',
          subjectCode: 'ENG-10',
          startTime: '11:40 AM',
          endTime: '12:25 PM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Ananya Gupta',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 5',
          subjectName: 'Hindi Comprehension',
          subjectCode: 'HIN-10',
          startTime: '01:10 PM',
          endTime: '01:50 PM',
          room: 'Class 10-A',
          facultyName: 'Mr. Arvind Joshi',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 6',
          subjectName: 'Environmental Studies & Eco Club',
          subjectCode: 'EVS-10',
          startTime: '01:55 PM',
          endTime: '02:40 PM',
          room: 'School Eco Garden',
          facultyName: 'Dr. Rajeshwari Raman',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 7',
          subjectName: 'School Athletics & Outdoor Games',
          subjectCode: 'PET-10',
          startTime: '02:45 PM',
          endTime: '03:30 PM',
          room: 'Sports Ground',
          facultyName: 'Coach Vikram Singh',
          status: PeriodStatus.upcoming,
        ),
      ],
      'Saturday': [
        const PeriodAttendance(
          periodNumber: 'Period 1',
          subjectName: 'Weekly Revision & Doubt Session',
          subjectCode: 'REV-10',
          startTime: '09:00 AM',
          endTime: '10:15 AM',
          room: 'Class 10-A',
          facultyName: 'Mrs. Sunita Sharma',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 2',
          subjectName: 'Co-Curricular Clubs (Robotics/Music)',
          subjectCode: 'CLB-10',
          startTime: '10:30 AM',
          endTime: '11:45 AM',
          room: 'Activity Block',
          facultyName: 'Club Mentors',
          status: PeriodStatus.upcoming,
        ),
        const PeriodAttendance(
          periodNumber: 'Period 3',
          subjectName: 'PTM / Teacher-Parent Open House',
          subjectCode: 'PTM-10',
          startTime: '12:00 PM',
          endTime: '01:00 PM',
          room: 'Class 10-A',
          facultyName: 'School Faculty',
          status: PeriodStatus.upcoming,
        ),
      ],
    };

    final dayKeys = weeklySchedule.keys.toList();
    int selectedDayIdx = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final activeDayKey = dayKeys[selectedDayIdx];
            final currentClasses = weeklySchedule[activeDayKey] ?? [];

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface(ctx),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Row with Title, Ward Info and Live/Routine Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class Timetable',
                              style: TextStyle(
                                color: AppTheme.text(ctx),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${child.name} • ${child.program} • ${child.semester}",
                              style: TextStyle(
                                color: AppTheme.textSecondary(ctx),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Weekday Selector (Mon - Sat)
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: dayKeys.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final isSel = selectedDayIdx == i;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => selectedDayIdx = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF2DD4BF)
                                  : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF2DD4BF)
                                    : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              dayKeys[i],
                              style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Timetable Periods List
                  Expanded(
                    child: currentClasses.isEmpty
                        ? Center(
                            child: Text(
                              'No scheduled classes for $activeDayKey',
                              style: TextStyle(color: AppTheme.textSecondary(ctx)),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: currentClasses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final cls = currentClasses[index];

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.card(ctx),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Dedicated Period Box (Zero awkward text wrapping)
                                    Container(
                                      width: 58,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : const Color(0xFFF0FDFA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white10
                                              : const Color(0xFFCCFBF1),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'PERIOD',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0D9488),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${index + 1}'.padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 2. Class Subject Details & Timing
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Top row: Subject Code Pill + Time
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  cls.subjectCode,
                                                  style: const TextStyle(
                                                    color: Color(0xFF2DD4BF),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textSecondary(ctx)),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  '${cls.startTime} - ${cls.endTime}',
                                                  style: TextStyle(
                                                    color: AppTheme.textSecondary(ctx),
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Subject Title
                                          Text(
                                            cls.subjectName,
                                            style: TextStyle(
                                              color: AppTheme.text(ctx),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),

                                          // Location & Faculty Info
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.meeting_room_outlined,
                                                size: 12.5,
                                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                cls.room,
                                                style: TextStyle(
                                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 12.5,
                                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  cls.facultyName,
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHomeworksSheet(
    BuildContext context,
    ChildProfile child,
    ParentController controller,
  ) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // School daily homework tasks
    final homeworks = [
      {
        'title': 'Chapter 4: Quadratic Equations - Exercise 4.2 (Q1 to Q8)',
        'subject': 'Mathematics • Class 10',
        'due': 'Due Tomorrow, 8:30 AM',
        'status': 'Pending Submission',
        'statusColor': const Color(0xFFF59E0B),
        'icon': Icons.assignment_late_rounded,
      },
      {
        'title': 'Life Processes: Draw & Label Human Digestive System in Science Record',
        'subject': 'Science (Biology) • Class 10',
        'due': 'Due Friday, Nov 27',
        'status': 'In Progress',
        'statusColor': const Color(0xFF3B82F6),
        'icon': Icons.pending_actions_rounded,
      },
      {
        'title': 'Essay: "Impact of Digital Learning on Modern Schools" (250 Words)',
        'subject': 'English Language & Literature',
        'due': 'Submitted on Nov 22',
        'status': 'Checked: Grade A+ (Excellent)',
        'statusColor': const Color(0xFF10B981),
        'icon': Icons.task_alt_rounded,
      },
      {
        'title': 'India Map Pointing: 5 Key Centers of 1857 Revolt in India Map',
        'subject': 'Social Science (History)',
        'due': 'Submitted on Nov 20',
        'status': 'Checked: 10/10 ⭐⭐⭐',
        'statusColor': const Color(0xFF10B981),
        'icon': Icons.task_alt_rounded,
      },
      {
        'title': 'Python Script: Write program to calculate Simple & Compound Interest',
        'subject': 'Computer Science & AI',
        'due': 'Submitted on Nov 18',
        'status': 'Checked: Grade A1',
        'statusColor': const Color(0xFF10B981),
        'icon': Icons.task_alt_rounded,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Homework & Diary',
                          style: TextStyle(
                            color: AppTheme.text(ctx),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${child.name} • 2 Pending, 3 Completed',
                          style: TextStyle(
                            color: AppTheme.textSecondary(ctx),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Term 1 Diary',
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: homeworks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final h = homeworks[idx];
                    final color = h['statusColor'] as Color;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.card(ctx),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(h['icon'] as IconData, size: 18, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h['title'] as String,
                                      style: TextStyle(
                                        color: AppTheme.text(ctx),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      h['subject'] as String,
                                      style: TextStyle(
                                        color: AppTheme.textSecondary(ctx),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                h['due'] as String,
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  h['status'] as String,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
