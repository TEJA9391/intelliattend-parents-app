import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import '../Widgets/child_switcher_bar.dart';

class ParentAttendanceTab extends StatelessWidget {
  const ParentAttendanceTab({super.key});

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
    final double overallPercentage = totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Subject-Wise Attendance',
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

          // Summary header card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.rollNumber} • ${child.semester}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total Classes Attended: $totalAttended / $totalClasses',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${overallPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Target 75%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrolled Courses (${subjects.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text(context),
                  ),
                ),
                Text(
                  'Cutoff: 75%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),

          ...subjects.map((subject) => _buildSubjectCard(context, subject)),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectAttendance subject) {
    final double pct = subject.percentage;
    final Color color = subject.statusColor;
    final bool isEligible = pct >= 75.0;
    final int margin = subject.safeMarginOrNeededClasses;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${subject.code} • Faculty: ${subject.facultyName}',
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
                  color: isEligible ? const Color(0xFF2DD4BF) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
