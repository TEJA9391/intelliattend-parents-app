import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import '../Widgets/child_switcher_bar.dart';
import 'parent_subject_detail_screen.dart';

class ParentDetailedAttendanceScreen extends StatelessWidget {
  const ParentDetailedAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ParentController>();
    final child = controller.activeChild;
    final subjects = controller.subjects;

    int totalAttended = 0;
    int totalClasses = 0;
    for (var s in subjects) {
      totalAttended += s.attendedClasses;
      totalClasses += s.totalClasses;
    }
    final double overallPercentage =
        totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 0.0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.text(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subject-Wise Attendance',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.text(context),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        physics: const BouncingScrollPhysics(),
        children: [
          const ChildSwitcherBar(),

          // Summary header card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2DD4BF).withValues(alpha: 0.3)
                    : AppTheme.border(context),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                    const SizedBox(height: 2),
                    Text(
                      'Roll: ${child.rollNumber} • ${child.program} (${child.semester})',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total Classes Attended: $totalAttended / $totalClasses',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text(context),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF)
                        .withValues(alpha: isDark ? 0.16 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2DD4BF)
                          .withValues(alpha: isDark ? 0.4 : 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${overallPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                      const Text(
                        'Target 75%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 75% Exam Eligibility Card
          _buildExamEligibilityCard(
            context,
            child: child,
            totalAttended: totalAttended,
            totalClasses: totalClasses,
            overallPercentage: overallPercentage,
            isDark: isDark,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrolled Subjects (${subjects.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text(context),
                  ),
                ),
                Text(
                  'Board Cutoff: 75%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),

          ...subjects
              .map((subject) => _buildSubjectCard(context, subject, child)),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
      BuildContext context, SubjectAttendance subject, ChildProfile child) {
    final double pct = subject.percentage;
    final Color color = subject.statusColor;
    final bool isEligible = pct >= 75.0;
    final int margin = subject.safeMarginOrNeededClasses;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ParentSubjectDetailScreen(
                  subject: subject,
                  child: child,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subject.subjectName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppTheme.textSecondary(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${subject.code} • Teacher: ${subject.facultyName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 7,
                    backgroundColor: AppTheme.surface(context),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attended: ${subject.attendedClasses} of ${subject.totalClasses} classes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.text(context),
                      ),
                    ),
                    Text(
                      isEligible
                          ? 'Can miss $margin classes'
                          : 'Need next $margin classes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isEligible
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFFEF4444),
                      ),
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

  Widget _buildExamEligibilityCard(
    BuildContext context, {
    required ChildProfile child,
    required int totalAttended,
    required int totalClasses,
    required double overallPercentage,
    required bool isDark,
  }) {
    final bool isSafe = overallPercentage >= 75.0;
    final bool isCondonation =
        overallPercentage >= 65.0 && overallPercentage < 75.0;

    // Buffer calculations
    final int safeBuffer = totalClasses > 0 && isSafe
        ? ((totalAttended - 0.75 * totalClasses) / 0.75).floor().clamp(0, 999)
        : 0;

    final int classesNeeded = totalClasses > 0 && !isSafe
        ? ((0.75 * totalClasses - totalAttended) / 0.25).ceil().clamp(1, 999)
        : 0;

    final Color statusColor = isSafe
        ? const Color(0xFF10B981) // Emerald / Mint
        : isCondonation
            ? const Color(0xFFF59E0B) // Amber
            : const Color(0xFFEF4444); // Crimson Red

    final IconData statusIcon = isSafe
        ? Icons.verified_rounded
        : isCondonation
            ? Icons.warning_amber_rounded
            : Icons.error_outline_rounded;

    final String statusTitle = isSafe
        ? 'Term Exam Eligibility: Safe'
        : isCondonation
            ? 'Term Exam: Low Attendance Notice'
            : 'Term Exam: Shortage Warning';

    final String badgeLabel = isSafe
        ? 'SAFE (75%+)'
        : isCondonation
            ? 'NEAR CUTOFF'
            : 'CRITICAL SHORTAGE';

    final String adviceText = isSafe
        ? (safeBuffer > 0
            ? '${child.name} has a safe buffer of $safeBuffer class${safeBuffer == 1 ? '' : 'es'} above the mandatory 75% school board cutoff.'
            : '${child.name} is right on the 75% boundary. Regular attendance is advised to maintain exam eligibility.')
        : isCondonation
            ? '${child.name} is currently below 75%. Must attend the next $classesNeeded consecutive class${classesNeeded == 1 ? '' : 'es'} to regain full eligibility.'
            : 'Immediate action needed! Attendance is below 65%. Needs next $classesNeeded consecutive classes. Please consult Class Teacher (${child.mentorName}) immediately.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon + Title + Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'School Board 75% Mandatory Policy',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Advice Text
          Text(
            adviceText,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppTheme.text(context),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Metric Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSafe
                          ? Icons.shield_rounded
                          : Icons.notification_important_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSafe ? 'Safe Margin:' : 'Deficit Action:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  isSafe
                      ? (safeBuffer > 0
                          ? '+$safeBuffer classes safe'
                          : '0 buffer (At risk)')
                      : 'Need next $classesNeeded classes',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
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
