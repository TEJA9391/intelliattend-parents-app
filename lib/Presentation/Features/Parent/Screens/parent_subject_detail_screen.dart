import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Models/parent_models.dart';

class ParentSubjectDetailScreen extends StatefulWidget {
  final SubjectAttendance subject;
  final ChildProfile child;

  const ParentSubjectDetailScreen({
    super.key,
    required this.subject,
    required this.child,
  });

  @override
  State<ParentSubjectDetailScreen> createState() => _ParentSubjectDetailScreenState();
}

class _ParentSubjectDetailScreenState extends State<ParentSubjectDetailScreen> {
  String _selectedFilter = 'All'; // 'All', 'Present', 'Absent'

  Future<void> _callFaculty(String phone) async {
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
            'Could not launch dialer for ${widget.subject.facultyName}',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Could not launch dialer for ${widget.subject.facultyName}',
        );
      }
    }
  }

  List<SubjectClassSession> _generateSessions(SubjectAttendance subject) {
    final List<SubjectClassSession> list = [];
    final total = subject.totalClasses;
    final attended = subject.attendedClasses;
    final missed = total - attended;

    final topics = [
      'Dynamic Programming: 0/1 Knapsack & Memoization',
      'Greedy Algorithms: Huffman Coding & Fractional Knapsack',
      'Graph Traversal: Breadth-First & Depth-First Search',
      'Minimum Spanning Trees: Kruskal & Prim Algorithm',
      'Divide and Conquer: Strassen Matrix Multiplication',
      'Asymptotic Analysis: Big-O, Omega & Theta Notations',
      'Recurrence Relations & The Master Theorem',
      'Sorting Lower Bounds & Linear Time Sorting (Radix Sort)',
      'Shortest Paths: Dijkstra & Bellman-Ford Algorithms',
      'Complexity Classes: P, NP and NP-Completeness',
    ];

    // Build recent sessions
    final now = DateTime.now();
    int missedRemaining = missed;

    for (int i = 0; i < total && i < 15; i++) {
      final sessionNum = total - i;
      final date = now.subtract(Duration(days: (i * 2) + 1));
      final bool isAbsent = (i == 2 || i == 7 || i == 11) && missedRemaining > 0;
      if (isAbsent) missedRemaining--;

      list.add(
        SubjectClassSession(
          sessionNumber: sessionNum,
          date: date,
          time: i % 2 == 0 ? '09:30 AM - 10:30 AM' : '11:15 AM - 12:15 PM',
          room: 'Room 402 (Tech Block)',
          topic: topics[i % topics.length],
          isPresent: !isAbsent,
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = widget.subject;
    final child = widget.child;
    final double pct = subject.percentage;
    final Color statusColor = subject.statusColor;
    final bool isEligible = pct >= 75.0;
    final int safeMargin = subject.safeMarginOrNeededClasses;

    final sessions = _generateSessions(subject);
    final filteredSessions = sessions.where((s) {
      if (_selectedFilter == 'Present') return s.isPresent;
      if (_selectedFilter == 'Absent') return !s.isPresent;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.text(context), size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject.subjectName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.text(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${subject.code} • ${child.name}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Hero Circle Graph & Circular Progress Card
          _buildCircleGraphCard(
            context,
            pct: pct,
            statusColor: statusColor,
            isEligible: isEligible,
            attended: subject.attendedClasses,
            total: subject.totalClasses,
            safeMargin: safeMargin,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // 2. Metrics 3-Pill Quick Stats Row (Compact sizes, Conducted in Gray)
          Row(
            children: [
              _buildStatPill(
                context,
                label: 'Attended',
                value: '${subject.attendedClasses}',
                subtext: 'Classes',
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                context,
                label: 'Missed',
                value: '${subject.totalClasses - subject.attendedClasses}',
                subtext: 'Classes',
                color: const Color(0xFFEF4444),
                icon: Icons.cancel_rounded,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                context,
                label: 'Conducted',
                value: '${subject.totalClasses}',
                subtext: 'Total Held',
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                icon: Icons.school_rounded,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Safe Margin & Projection Card
          _buildProjectionCard(
            context,
            pct: pct,
            attended: subject.attendedClasses,
            total: subject.totalClasses,
            isEligible: isEligible,
            margin: safeMargin,
            statusColor: statusColor,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          // 4. Faculty & Course Details Card
          _buildFacultyCard(context, subject: subject, child: child, isDark: isDark),

          const SizedBox(height: 18),

          // 5. Lecture-by-Lecture Attendance Log Header & Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sessions Log',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip('All', sessions.length),
                  const SizedBox(width: 5),
                  _buildFilterChip('Present', sessions.where((s) => s.isPresent).length),
                  const SizedBox(width: 5),
                  _buildFilterChip('Absent', sessions.where((s) => !s.isPresent).length),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 6. Session History Cards
          if (filteredSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No sessions found for selected filter.',
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ),
            )
          else
            ...filteredSessions.map((s) => _buildSessionItem(context, s, isDark)),
        ],
      ),
    );
  }

  Widget _buildCircleGraphCard(
    BuildContext context, {
    required double pct,
    required Color statusColor,
    required bool isEligible,
    required int attended,
    required int total,
    required int safeMargin,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Radial Circle Graph
          SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(124, 124),
                  painter: _SubjectRadialGaugePainter(
                    percentage: pct,
                    targetPercentage: 75.0,
                    progressColor: statusColor,
                    trackColor: AppTheme.surface(context),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.text(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$attended / $total Held',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEligible ? Icons.verified_rounded : Icons.warning_amber_rounded,
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 5),
                Text(
                  isEligible
                      ? 'Exam Hall Ticket: Eligible (Safe)'
                      : 'Exam Hall Ticket: Shortage Warning',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

  Widget _buildStatPill(
    BuildContext context, {
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.text(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard(
    BuildContext context, {
    required double pct,
    required int attended,
    required int total,
    required bool isEligible,
    required int margin,
    required Color statusColor,
    required bool isDark,
  }) {
    // Simulator calculations:
    final ifMissOnePct = total > 0 ? (attended / (total + 1)) * 100 : pct;
    final ifAttendNextThreePct = total > 0 ? ((attended + 3) / (total + 3)) * 100 : pct;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 16, color: statusColor),
              const SizedBox(width: 7),
              Text(
                '75% Cutoff Buffer Analysis',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEligible
                ? 'Your ward can safely miss up to $margin class${margin == 1 ? '' : 'es'} without dropping below the mandatory 75% cutoff.'
                : 'Your ward must attend the next $margin consecutive class${margin == 1 ? '' : 'es'} to cross the mandatory 75% cutoff.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'If misses next class:',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${ifMissOnePct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ifMissOnePct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 22, color: AppTheme.border(context)),
                Column(
                  children: [
                    Text(
                      'If attends next 3:',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${ifAttendNextThreePct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
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
  }

  Widget _buildFacultyCard(
    BuildContext context, {
    required SubjectAttendance subject,
    required ChildProfile child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
            child: const Icon(Icons.person_rounded, color: Color(0xFF2DD4BF), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.facultyName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  'Course Instructor • Room 402',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _callFaculty(child.mentorPhone),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_rounded, color: Colors.black, size: 12.5),
                    SizedBox(width: 4),
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedFilter = label);
        AppSnackBar.showInfo(
          context,
          'Filtered to $label sessions ($count)',
          icon: Icons.filter_list_rounded,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2DD4BF)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2DD4BF)
                : AppTheme.border(context),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : AppTheme.text(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, SubjectClassSession session, bool isDark) {
    final statusColor = session.isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: session.isPresent
              ? AppTheme.border(context)
              : const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              session.isPresent ? Icons.check_rounded : Icons.close_rounded,
              size: 14,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session #${session.sessionNumber}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text(context),
                      ),
                    ),
                    Text(
                      session.isPresent ? 'Present' : 'Absent',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  session.topic,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${_formatDate(session.date)} • ${session.time}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class SubjectClassSession {
  final int sessionNumber;
  final DateTime date;
  final String time;
  final String room;
  final String topic;
  final bool isPresent;

  const SubjectClassSession({
    required this.sessionNumber,
    required this.date,
    required this.time,
    required this.room,
    required this.topic,
    required this.isPresent,
  });
}

class _SubjectRadialGaugePainter extends CustomPainter {
  final double percentage;
  final double targetPercentage;
  final Color progressColor;
  final Color trackColor;

  _SubjectRadialGaugePainter({
    required this.percentage,
    required this.targetPercentage,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 11.0;

    // 1. Background Track
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
      center.dx + (radius - strokeWidth / 2 - 3) * math.cos(targetAngle),
      center.dy + (radius - strokeWidth / 2 - 3) * math.sin(targetAngle),
    );
    final tickOuter = Offset(
      center.dx + (radius + strokeWidth / 2 + 3) * math.cos(targetAngle),
      center.dy + (radius + strokeWidth / 2 + 3) * math.sin(targetAngle),
    );

    final tickPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tickInner, tickOuter, tickPaint);
  }

  @override
  bool shouldRepaint(covariant _SubjectRadialGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}
