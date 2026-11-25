import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Models/parent_models.dart';
import 'student_photo_viewer_dialog.dart';

class StudentAcademicCard extends StatefulWidget {
  final ChildProfile child;
  final StudentBusTransit? transit;
  final VoidCallback? onRfidBusTap;

  const StudentAcademicCard({
    super.key,
    required this.child,
    this.transit,
    this.onRfidBusTap,
  });

  @override
  State<StudentAcademicCard> createState() => _StudentAcademicCardState();
}

class _StudentAcademicCardState extends State<StudentAcademicCard> {
  bool _isBackFlipped = false;

  void _toggleFlip() {
    HapticFeedback.lightImpact();
    setState(() {
      _isBackFlipped = !_isBackFlipped;
    });
  }

  Future<void> _callPhone(String phone) async {
    HapticFeedback.lightImpact();
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppSnackBar.showError(
            context,
            'Could not launch phone dialer for ${widget.child.mentorName}',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Could not launch phone dialer for ${widget.child.mentorName}',
        );
      }
    }
  }

  String _cleanProgram(String program) {
    if (program.toLowerCase().contains('class') || program.toLowerCase().contains('grade')) {
      return program;
    }
    if (program.contains('-')) {
      final parts = program.split('-');
      final degree = parts[0].trim();
      var branch = parts[1].replaceAll('& Engineering', '').trim();
      if (branch.contains('Computer Science')) {
        branch = 'CSE-AIML';
      }
      return '$degree • $branch';
    }
    return program;
  }

  String _cleanSemester(String semester) {
    if (semester.toLowerCase().contains('sec')) {
      return semester;
    }
    if (semester.contains('(')) {
      semester = semester.split('(').first.trim();
    }
    return semester.replaceAll('Semester', 'Sem').trim();
  }

  String _shortGate(String? dest) {
    if (dest == null || dest.isEmpty) return 'North Gate';
    if (dest.contains('Gate')) {
      final parts = dest.split(' ');
      final gateIdx = parts.indexWhere((p) => p.toLowerCase().contains('gate'));
      if (gateIdx > 0) {
        return '${parts[gateIdx - 1]} Gate';
      }
      return 'Campus Gate';
    }
    return 'North Gate';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final child = widget.child;
    final transit = widget.transit;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
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
        child: InkWell(
          onTap:
              _toggleFlip, // Tapping anywhere on the card flips between Front & Back!
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header Row: Left Badge + Right Live Location Symbol
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge (Enrolled Student or Emergency & Safety ID)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5.5),
                      decoration: BoxDecoration(
                        color: _isBackFlipped
                            ? AppTheme.surface(context)
                            : const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: _isBackFlipped
                            ? Border.all(
                                color: AppTheme.border(context), width: 0.9)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isBackFlipped
                                ? Icons.medical_services_rounded
                                : Icons.school_rounded,
                            size: 13.5,
                            color: _isBackFlipped
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF2DD4BF),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isBackFlipped
                                ? 'Emergency & Safety ID'
                                : 'Enrolled Student',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _isBackFlipped
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF2DD4BF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Side: Live Location Symbol Button
                    // Active & Pulsing ONLY when student has entered bus via RFID (isOnBus == true)
                    // Otherwise Gray & Non-Clickable
                    _buildLiveLocationBadge(context, isDark),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Animated Card Body (Both sides engineered to equal, balanced height)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 240),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeInCubic,
                  crossFadeState: _isBackFlipped
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: _buildAcademicFront(context, child, isDark),
                  secondChild:
                      _buildEmergencyBack(context, child, transit, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clean, Spacious, Uncluttered Academic Front View
  Widget _buildAcademicFront(
      BuildContext context, ChildProfile child, bool isDark) {
    return SizedBox(
      height: 172,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Student Avatar (Tappable to view full-screen image only)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              StudentPhotoViewerDialog.showFullScreenImageOnly(context, child);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2DD4BF),
                      width: 2.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DD4BF).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: buildSmartAvatarImage(child.avatarUrl,
                        width: 76, height: 76),
                  ),
                ),
                // Online active campus dot
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.card(context),
                        width: 2.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Clean Details: Name, Branch, Semester/Roll, Advisor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 19.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text(context),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_cleanProgram(child.program)} • ${_cleanSemester(child.semester)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  'Roll: ${child.rollNumber}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  child.mentorName.contains('Teacher')
                      ? child.mentorName
                      : 'Class Teacher: ${child.mentorName}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Clean monochrome Emergency & Safety ID view (no colored boxes)
  Widget _buildEmergencyBack(
    BuildContext context,
    ChildProfile child,
    StudentBusTransit? transit,
    bool isDark,
  ) {
    final cleanBus =
        (transit?.busNumber ?? '#14').replaceAll('Bus ', '').trim();
    final busDisplay = cleanBus.startsWith('#') ? cleanBus : '#$cleanBus';
    final bloodGroupDisplay =
        child.bloodGroup.isNotEmpty ? child.bloodGroup : 'O+ve';

    return SizedBox(
      height: 172,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info rows — no lines, no border container
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmergencyLine(
                context,
                label: 'Blood Group',
                value: bloodGroupDisplay,
              ),
              _buildEmergencyLine(
                context,
                label: 'Bus No',
                value: busDisplay,
                onTap: () => widget.onRfidBusTap?.call(),
              ),
              _buildEmergencyLine(
                context,
                label: 'Emergency No',
                value: '080-2345 6700',
                onTap: () => _callPhone('+918023456700'),
              ),
              _buildEmergencyLine(
                context,
                label: 'Medical',
                value: 'No Allergies',
              ),
            ],
          ),

          // Call Class Teacher button (neutral monochrome)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _callPhone(child.mentorPhone),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_in_talk_rounded,
                      size: 16,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Call Class Teacher',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Plain key : value row for Emergency & Safety ID
  /// Only the action icon on the right (Bus / Phone) is tappable, not the text.
  Widget _buildEmergencyLine(
    BuildContext context, {
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final isButton = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            SizedBox(
              width: 112,
              child: Text(
                '$label :',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isButton)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      label.contains('Bus')
                          ? Icons.directions_bus_rounded
                          : Icons.phone_rounded,
                      size: 16,
                      color: const Color(0xFF2DD4BF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Live GPS badge: Active & pulsing ONLY when student has boarded bus via RFID
  /// Otherwise muted gray & non-clickable
  Widget _buildLiveLocationBadge(BuildContext context, bool isDark) {
    final bool isLive = widget.transit?.isOnBus == true;

    if (!isLive) {
      // Gray color, non-clickable
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.near_me_outlined,
              size: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              'Live',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }

    // Active Live state: Student entered bus & tapped RFID on bus device!
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onRfidBusTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF2DD4BF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2DD4BF)
                    .withValues(alpha: isDark ? 0.45 : 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 13,
                color: Colors.black,
              ),
              SizedBox(width: 4),
              Text(
                'Live',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 5),
              _PulsingLiveDot(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated pulsing green dot indicating real-time active GPS broadcast from bus device
class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.75, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              color: const Color(0xFFA3E635), // Pale green / Lime
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA3E635).withValues(alpha: 0.8),
                  blurRadius: 4.5 * _pulseAnimation.value,
                  spreadRadius: 1.0 * _pulseAnimation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
