import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Theme/app_theme.dart';

class ParentPermissionOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ParentPermissionOnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<ParentPermissionOnboardingScreen> createState() =>
      _ParentPermissionOnboardingScreenState();
}

class _ParentPermissionOnboardingScreenState
    extends State<ParentPermissionOnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _isRequesting = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAllowPermissions() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      // 1. Request Push Notifications (Android 13+)
      await Permission.notification.request();

      // 2. Request Location for Map Proximity
      await Permission.locationWhenInUse.request();
    } catch (e) {
      debugPrint('[PermissionOnboarding] Error requesting permissions: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('parent_permissions_onboarding_completed', true);

      if (mounted) {
        setState(() => _isRequesting = false);
        widget.onComplete();
      }
    }
  }

  Future<void> _handleSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('parent_permissions_onboarding_completed', true);
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Glowing Shield & Radar Hero Illustration
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final pulse = _pulseController.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ambient halo
                            Container(
                              width: 110 + (pulse * 14),
                              height: 110 + (pulse * 14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF14B8A6)
                                    .withValues(alpha: (1.0 - pulse) * 0.25),
                              ),
                            ),
                            // Inner radiant circle
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F766E)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.security_rounded,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Main Title
                    Text(
                      'Permissions for Peace of Mind',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text(context),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'To keep you instantly informed about your child\'s transit and campus safety, IntelliAttend needs a few device permissions.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(context),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Permission Item 1: Push Notifications
                    _buildPermissionCard(
                      context,
                      isDark: isDark,
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
                      title: 'Live Bus & Safety Alerts',
                      description:
                          'Get notified the moment the bus departs, approaches your stop, or if your child is marked absent.',
                      badgeText: 'Essential',
                      badgeColor: const Color(0xFF10B981),
                    ),

                    const SizedBox(height: 14),

                    // Permission Item 2: Live Location
                    _buildPermissionCard(
                      context,
                      isDark: isDark,
                      icon: Icons.my_location_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      title: 'Map Proximity & Stops',
                      description:
                          'Displays your live distance to the bus and pinpoints your exact home pickup stop on Google Maps.',
                      badgeText: 'Recommended',
                      badgeColor: const Color(0xFF0284C7),
                    ),

                    const SizedBox(height: 14),

                    // Permission Item 3: Quick Mentor Calls
                    _buildPermissionCard(
                      context,
                      isDark: isDark,
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      title: 'Direct Faculty & Mentor Calling',
                      description:
                          'Instantly connect to your student\'s academic mentor and bus coordinator with one-tap dialing.',
                      badgeText: 'System Dialer',
                      badgeColor: const Color(0xFF8B5CF6),
                    ),

                    const SizedBox(height: 24),

                    // Privacy Assurance Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.border(context),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: Color(0xFF14B8A6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your privacy is fully protected. Location is strictly used locally on your phone and never sold.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary(context),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Allow & Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _handleAllowPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Allow & Continue',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Maybe Later Skip Button
                  TextButton(
                    onPressed: _isRequesting ? null : _handleSkip,
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary(context),
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

