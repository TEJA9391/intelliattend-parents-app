import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intelli_attend_faculty/Services/app_update_service.dart';
import 'package:intelli_attend_faculty/Services/permission_service.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import 'parent_dashboard_tab.dart';
import 'parent_attendance_tab.dart';
import 'parent_chat_tab.dart';
import 'parent_notices_faculty_tab.dart';
import 'parent_profile_tab.dart';

class ParentMainNavigationScreen extends StatefulWidget {
  final String? initialParentName;
  const ParentMainNavigationScreen({super.key, this.initialParentName});

  @override
  State<ParentMainNavigationScreen> createState() =>
      _ParentMainNavigationScreenState();
}

class _ParentMainNavigationScreenState
    extends State<ParentMainNavigationScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  void _onTabChange(int index, [int subTab = 0]) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleBackPress() {
    // 1. If not on Home tab, switch to Home tab first
    if (_currentIndex != 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = 0);
      return;
    }

    // 2. On Home tab: Require double tap to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      HapticFeedback.lightImpact();
      AppSnackBar.showExitNotice(context);
      return;
    }

    // 3. Double press confirmed within 2 seconds -> exit application
    HapticFeedback.mediumImpact();
    SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _applySystemNavOverlay();
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        await PermissionService().requestFirstLoginPermissions();
      }
      if (mounted) {
        AppUpdateService.checkAndPromptUpdate(context);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applySystemNavOverlay();
  }

  void _applySystemNavOverlay() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navColor = isDark ? const Color(0xFF101012) : Colors.white;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    // Apply imperatively on each build
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: ChangeNotifierProvider(
          create: (_) {
            final c = ParentController();
            if (widget.initialParentName != null &&
                widget.initialParentName!.trim().isNotEmpty) {
              c.setParentName(widget.initialParentName!);
            }
            return c;
          },
          child: Scaffold(
            backgroundColor: AppTheme.bg(context),
            body: IndexedStack(
              index: _currentIndex,
              children: [
                ParentDashboardTab(onTabChange: _onTabChange),
                const ParentAttendanceTab(),
                const ParentChatTab(),
                const ParentNoticesFacultyTab(),
                const ParentProfileTab(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(context, isDark, navColor),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark, Color navColor) {
    const navItems = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Home'),
      _NavItem(icon: Icons.school_rounded, label: 'Academics'),
      _NavItem(icon: Icons.chat_bubble_rounded, label: 'Chat'),
      _NavItem(icon: Icons.campaign_rounded, label: 'Notices'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    const activeColor = Color(0xFF2DD4BF);
    final activeBg = const Color(0xFF2DD4BF).withValues(alpha: 0.16);
    final inactiveColor =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF71717A);

    return Container(
      decoration: BoxDecoration(
        color: navColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = _currentIndex == index;
              final item = navItems[index];

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _onTabChange(index, 0);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
