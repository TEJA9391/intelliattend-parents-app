import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intelli_attend_faculty/Services/app_update_service.dart';
import 'package:intelli_attend_faculty/Services/permission_service.dart';
import '../../Faculty/change_password_screen.dart';
import '../../Faculty/login_devices_screen.dart';
import '../../Support/about_app_page.dart';
import '../../Support/help_center_page.dart';
import '../../Support/report_issue_page.dart';
import '../../../../Theme/app_theme.dart';
import '../../../../Theme/theme_controller.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import '../Widgets/child_switcher_bar.dart';
import '../Widgets/student_photo_viewer_dialog.dart';
import 'parent_guardian_info_screen.dart';
import 'student_health_info_screen.dart';
import 'student_campus_id_full_screen.dart';
import '../Models/parent_models.dart';

class ParentProfileTab extends StatelessWidget {
  const ParentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentController>();
    final child = controller.activeChild;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Student & Guardian Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.text(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        physics: const BouncingScrollPhysics(),
        children: [
          const ChildSwitcherBar(),

          // Digital Student ID Card (Clean, Sleek Surface with Ring Teal Accents)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.border(context),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  HapticFeedback.lightImpact();
                  StudentCampusIdFullScreen.show(context, child,
                      controller: controller);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: isDark
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFF2DD4BF),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'INTELLIATTEND VERIFIED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? const Color(0xFF2DD4BF)
                                  : const Color(0xFF2DD4BF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              StudentPhotoViewerDialog.show(context, child,
                                  controller: controller);
                            },
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF2DD4BF),
                                      width: 2.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2DD4BF)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: buildSmartAvatarImage(
                                        child.avatarUrl,
                                        width: 64,
                                        height: 64),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2DD4BF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 10, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text(context),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Roll No: ${child.rollNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF2DD4BF)
                                        : const Color(0xFF2DD4BF),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  child.program,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.border(context),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Class Advisor: ${child.mentorName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tap card for ID',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF2DD4BF)
                                        : const Color(0xFF2DD4BF),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: isDark
                                      ? const Color(0xFF2DD4BF)
                                      : const Color(0xFF2DD4BF),
                                ),
                              ],
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

          // Content with clean padding - NO BOXES, NO DIVIDER LINES
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Guardian & Medical Records
                _buildSectionHeader(context, 'Guardian & Medical Records'),
                _buildInteractiveTile(
                  context,
                  icon: Icons.family_restroom_rounded,
                  title: 'Guardian Information',
                  subtitle: _buildGuardianSubtitle(controller),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: controller,
                          child: const ParentGuardianInfoScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildInteractiveTile(
                  context,
                  icon: Icons.health_and_safety_rounded,
                  title: 'Student Health & Medical ID',
                  subtitle: _buildMedicalSubtitle(
                      controller.healthRecordForChild(child.id)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: controller,
                          child: StudentHealthInfoScreen(child: child),
                        ),
                      ),
                    );
                  },
                ),

                // 2. App Preferences
                _buildSectionHeader(context, 'App Preferences'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            size: 24,
                            color: const Color(0xFF2DD4BF),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Theme Mode',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.text(context),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isDark ? 'Dark Theme' : 'Light Theme',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2DD4BF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: isDark,
                        activeThumbColor: const Color(0xFF2DD4BF),
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          ThemeController.toggle();
                        },
                      ),
                    ],
                  ),
                ),
                const _DailyAttendanceAlertsTile(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AppUpdateService.checkAndPromptUpdate(context,
                          manual: true);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: FutureBuilder<AppUpdateInfo>(
                      future: AppUpdateService.getUpdateInfo(),
                      builder: (context, snapshot) {
                        final info = snapshot.data;
                        final String versionLabel = info != null
                            ? (info.hasUpdate
                                ? 'v${info.latestVersion} available • Tap to download'
                                : 'v${info.currentVersion} (Build ${info.currentBuild}) • Up to date')
                            : 'Check for latest release';

                        return Row(
                          children: [
                            const Icon(
                              Icons.system_update_rounded,
                              size: 24,
                              color: Color(0xFF2DD4BF),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'App Updates',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    versionLabel,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2DD4BF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // 3. Security & Access
                _buildSectionHeader(context, 'Security & Access'),
                _buildInteractiveTile(
                  context,
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  subtitle: 'Update credentials',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                _buildInteractiveTile(
                  context,
                  icon: Icons.devices_other_rounded,
                  title: 'Login Devices',
                  subtitle: 'Manage sessions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginDevicesScreen()),
                  ),
                ),

                // 4. Campus Support Contacts
                _buildSectionHeader(context, 'Campus Support Contacts'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEmergencyItem(
                    context,
                    title: 'Academic Office Helpdesk',
                    phone: '+91 80 2345 6789',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEmergencyItem(
                    context,
                    title: 'Student Health Centre',
                    phone: '+91 80 2345 6700',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEmergencyItem(
                    context,
                    title: 'Dean of Student Affairs',
                    phone: '+91 80 2345 6750',
                  ),
                ),

                // 5. Help & Support (Last Section)
                _buildSectionHeader(context, 'Help & Support'),
                _buildInteractiveTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About IntelliAttend',
                  subtitle: 'App version & information',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutAppPage()),
                  ),
                ),
                _buildInteractiveTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  subtitle: 'FAQs & Tutorials',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                  ),
                ),
                _buildInteractiveTile(
                  context,
                  icon: Icons.mail_outline_rounded,
                  title: 'Report an Issue',
                  subtitle: 'Submit feedback',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportIssuePage()),
                  ),
                ),

                const SizedBox(height: 36),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'INTELLIATTEND PARENT PORTAL',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context)
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '© 2026 IntelliAttend Technologies.\nAll Rights Reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary(context)
                              .withValues(alpha: 0.35),
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildGuardianSubtitle(ParentController controller) {
    final parts = [
      controller.parentName.trim(),
      controller.parentPhone.trim(),
    ].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Not synced yet • Tap to add or sync';
    }
    return parts.join(' • ');
  }

  String _buildMedicalSubtitle(StudentHealthRecord record) {
    final parts = [
      record.bloodGroup.trim(),
      record.allergies.trim(),
      record.chronicConditions.trim(),
    ].where((p) => p.isNotEmpty).take(2).toList();
    if (parts.isEmpty) {
      return 'No medical records yet • Tap to add';
    }
    return parts.join(' • ');
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInteractiveTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor =
        isDark ? const Color(0xFF2DD4BF) : const Color(0xFF2DD4BF);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(icon, color: tealColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.text(context),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tealColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textSecondary(context).withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyItem(
    BuildContext context, {
    required String title,
    required String phone,
  }) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> launchDialer() async {
      HapticFeedback.lightImpact();
      final uri = Uri.parse('tel:$clean');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            AppSnackBar.showError(context, 'Could not open phone dialer');
          }
        }
      } catch (_) {
        if (context.mounted) {
          AppSnackBar.showError(context, 'Could not open phone dialer');
        }
      }
    }

    void copyNumber() {
      HapticFeedback.mediumImpact();
      Clipboard.setData(ClipboardData(text: phone));
      AppSnackBar.showSuccess(
        context,
        'Copied $phone to clipboard',
        icon: Icons.copy_rounded,
      );
    }

    return InkWell(
      onTap: launchDialer,
      onLongPress: copyNumber,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text(context),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_in_talk_rounded,
                  size: 15,
                  color: isDark
                      ? const Color(0xFF2DD4BF)
                      : const Color(0xFF2DD4BF),
                ),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF2DD4BF)
                        : const Color(0xFF2DD4BF),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyAttendanceAlertsTile extends StatefulWidget {
  const _DailyAttendanceAlertsTile();

  @override
  State<_DailyAttendanceAlertsTile> createState() =>
      _DailyAttendanceAlertsTileState();
}

class _DailyAttendanceAlertsTileState
    extends State<_DailyAttendanceAlertsTile> with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  bool _alertsEnabled = true;
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final notifGranted = await Permission.notification.isGranted;
    final prefEnabled = prefs.getBool('daily_attendance_alerts_enabled') ?? true;

    if (mounted) {
      setState(() {
        _notifGranted = notifGranted;
        _alertsEnabled = prefEnabled && notifGranted;
      });
    }
  }

  Future<void> _toggleAttendanceAlerts(bool val) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (val) {
      final granted = await _permissionService.ensureFeaturePermission(
        context,
        AppPermissionType.notifications,
        featureName: 'Daily Attendance Alerts',
      );
      await prefs.setBool('daily_attendance_alerts_enabled', granted);
      if (mounted) {
        setState(() {
          _notifGranted = granted;
          _alertsEnabled = granted;
        });
      }
      return;
    }

    await prefs.setBool('daily_attendance_alerts_enabled', false);
    if (mounted) {
      setState(() => _alertsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 24,
                  color: Color(0xFF2DD4BF),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Attendance Alerts',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.text(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _notifGranted
                            ? 'Real-time period & bus push alerts'
                            : 'Tap to allow device notifications',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _alertsEnabled,
            activeThumbColor: const Color(0xFF2DD4BF),
            onChanged: _toggleAttendanceAlerts,
          ),
        ],
      ),
    );
  }
}
