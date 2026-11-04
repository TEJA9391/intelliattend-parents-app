import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intelli_attend_faculty/Services/faculty_service.dart';
import 'package:intelli_attend_faculty/Theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intelli_attend_faculty/Services/time_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Parent/Screens/parent_main_navigation_screen.dart';
import '../Parent/Screens/parent_permission_onboarding_screen.dart';
import '../Parent/Screens/parent_name_verification_screen.dart';

/// Boot phase state machine.
enum _BootPhase {
  initial,
  cacheHit,
  permissionsOnboarding,
  parentNameVerification,
  dashboard,
}

/// Lightning-fast auth gate — state-based routing like Student App.
class UnifiedAuthGate extends StatefulWidget {
  final Future<void> persistenceFuture;
  final Future<void> firebaseReady;

  const UnifiedAuthGate({
    Key? key,
    required this.persistenceFuture,
    required this.firebaseReady,
  }) : super(key: key);

  @override
  State<UnifiedAuthGate> createState() => _UnifiedAuthGateState();
}

class _UnifiedAuthGateState extends State<UnifiedAuthGate> {
  _BootPhase _phase = _BootPhase.initial;
  String? _verifiedParentName;

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    try {
      await widget.persistenceFuture;
    } catch (_) {}
    FacultyService.ensureDefaultProfile();
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final bool permissionsDone =
        prefs.getBool('parent_permissions_onboarding_completed') ?? false;
    final bool identityVerified =
        prefs.getBool('parent_identity_verified') ?? false;
    _verifiedParentName = prefs.getString('parent_full_name');

    if (!mounted) return;
    if (!permissionsDone) {
      setState(() => _phase = _BootPhase.permissionsOnboarding);
    } else if (!identityVerified ||
        _verifiedParentName == null ||
        _verifiedParentName!.trim().isEmpty) {
      setState(() => _phase = _BootPhase.parentNameVerification);
    } else {
      setState(() => _phase = _BootPhase.dashboard);
    }
    try {
      TimeSyncService.bootstrap();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _BootPhase.permissionsOnboarding) {
      return ParentPermissionOnboardingScreen(
        onComplete: () {
          if (mounted) {
            setState(() => _phase = _BootPhase.parentNameVerification);
          }
        },
      );
    }
    if (_phase == _BootPhase.parentNameVerification) {
      return ParentNameVerificationScreen(
        initialName: _verifiedParentName,
        onVerified: (parentName) {
          if (mounted) {
            setState(() {
              _verifiedParentName = parentName;
              _phase = _BootPhase.dashboard;
            });
          }
        },
      );
    }
    if (_phase == _BootPhase.dashboard || _phase == _BootPhase.cacheHit) {
      return ParentMainNavigationScreen(initialParentName: _verifiedParentName);
    }
    return _buildSplash(statusText: "Starting IntelliAttend Parent...");
  }

  Widget _buildSplash({required String statusText}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 240,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            Text(
              "IntelliAttend Parent",
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (statusText.isNotEmpty)
              Text(
                statusText,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 48),
            Container(
              width: 120,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF84CC16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
