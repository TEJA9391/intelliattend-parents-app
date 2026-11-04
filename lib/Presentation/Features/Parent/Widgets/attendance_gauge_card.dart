import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../Theme/app_theme.dart';
import '../Models/parent_models.dart';

class AttendanceGaugeCard extends StatelessWidget {
  final ChildProfile child;
  final List<SubjectAttendance> subjects;
  final VoidCallback? onDetailsTap;

  const AttendanceGaugeCard({
    super.key,
    required this.child,
    required this.subjects,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    int totalAttended = 0;
    int totalClasses = 0;

    for (var s in subjects) {
      totalAttended += s.attendedClasses;
      totalClasses += s.totalClasses;
    }

    final double percentage = child.overallAttendance;
    final Color statusColor = child.attendanceColor;
    final bool isSafe = percentage >= 75.0;

    // Calculate needed or safe margin
    String helperText = '';
    if (isSafe) {
      final safeToBunk = totalClasses > 0
          ? ((4 * totalAttended - 3 * totalClasses) / 3).floor()
          : 0;
      helperText = safeToBunk > 0
          ? 'Safe margin: Can miss $safeToBunk classes & maintain 75%'
          : 'Attendance is right at the 75% cutoff threshold';
    } else {
      final needed = totalClasses > 0 ? (3 * totalClasses - 4 * totalAttended) : 0;
      helperText = '⚠️ Must attend next $needed classes to cross 75% requirement';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Cumulative Attendance',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  child.attendanceStatusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Visual Row (Ring Gauge + Metrics)
          Row(
            children: [
              // Premium Target Ring Gauge
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: TargetGaugePainter(
                        percentage: percentage,
                        targetPercentage: 75.0,
                        progressColor: statusColor,
                        trackColor: AppTheme.surface(context),
                        targetTickColor: isSafe
                            ? const Color(0xFF14B8A6)
                            : const Color(0xFFFBBF24),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSafe
                                ? const Color(0xFF2DD4BF).withValues(alpha: 0.15)
                                : const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSafe ? '≥ 75% Goal' : 'Goal: 75%',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: isSafe
                                  ? const Color(0xFF2DD4BF)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Metrics Column (Guaranteed no overflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      context,
                      label: 'Attended',
                      value: '$totalAttended / $totalClasses classes',
                      color: const Color(0xFF2DD4BF),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      context,
                      label: 'Missed',
                      value: '${totalClasses - totalAttended} classes',
                      color: const Color(0xFFEF4444),
                      icon: Icons.highlight_off_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      context,
                      label: 'Status',
                      value: isSafe ? 'Eligible for Exams' : 'Defaulter Risk',
                      color: isSafe ? const Color(0xFF2DD4BF) : const Color(0xFFEF4444),
                      icon: Icons.verified_user_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Helper tip box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    helperText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.text(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary(context),
              ),
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text(context),
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Custom Target Ring Painter with dedicated 75% cutoff benchmark indicator
class TargetGaugePainter extends CustomPainter {
  final double percentage;
  final double targetPercentage;
  final Color progressColor;
  final Color trackColor;
  final Color targetTickColor;

  TargetGaugePainter({
    required this.percentage,
    required this.targetPercentage,
    required this.progressColor,
    required this.trackColor,
    required this.targetTickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const strokeWidth = 8.0;

    // 1. Background Circular Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage.clamp(0.0, 100.0) / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // 3. 75% Target Marker Notch
    final targetAngle = -math.pi / 2 + (targetPercentage / 100.0) * 2 * math.pi;
    final tickInner = Offset(
      center.dx + (radius - strokeWidth / 2 - 2) * math.cos(targetAngle),
      center.dy + (radius - strokeWidth / 2 - 2) * math.sin(targetAngle),
    );
    final tickOuter = Offset(
      center.dx + (radius + strokeWidth / 2 + 2) * math.cos(targetAngle),
      center.dy + (radius + strokeWidth / 2 + 2) * math.sin(targetAngle),
    );

    final tickPaint = Paint()
      ..color = targetTickColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tickInner, tickOuter, tickPaint);
  }

  @override
  bool shouldRepaint(covariant TargetGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}
