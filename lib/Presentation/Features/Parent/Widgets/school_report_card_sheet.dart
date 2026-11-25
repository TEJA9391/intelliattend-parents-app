import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

/// Data model describing one subject's Term-1 report card evaluation.
class SubjectReportData {
  final String name;
  final String code;
  final String grade;
  final int totalMarks;
  final int maxMarks;
  final String summaryDetails;
  final Color accentColor;
  final String componentLabel;
  final int componentScored;
  final int componentMax;
  final String examLabel;
  final int examScored;
  final int examMax;
  final int classAverage;
  final int classHighest;
  final List<({String topic, String score, String grade})> unitBreakdown;

  const SubjectReportData({
    required this.name,
    required this.code,
    required this.grade,
    required this.totalMarks,
    this.maxMarks = 100,
    required this.summaryDetails,
    required this.accentColor,
    required this.componentLabel,
    required this.componentScored,
    required this.componentMax,
    required this.examLabel,
    required this.examScored,
    required this.examMax,
    required this.classAverage,
    required this.classHighest,
    required this.unitBreakdown,
  });
}

/// Modal bottom sheet displaying the term report card and opening
/// individual subject report cards on tap.
class SchoolReportCardSheet {
  static void show(
    BuildContext context,
    ChildProfile child,
    ParentController controller,
  ) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isJunior =
        child.id == 'child_2' || child.program.contains('7');
    final subjects = _buildSubjectsForChild(isJunior);

    final int sumMarks = subjects.fold(0, (acc, s) => acc + s.totalMarks);
    final double overallPct =
        subjects.isNotEmpty ? (sumMarks / (subjects.length * 100)) * 100 : 0.0;
    final String overallGrade = overallPct >= 90 ? 'A1' : 'A2';
    final String classRank = isJunior ? '2nd / 42' : '3rd / 45';

    int totalAttended = 0;
    int totalClasses = 0;
    for (final s in controller.subjects) {
      totalAttended += s.attendedClasses;
      totalClasses += s.totalClasses;
    }
    final double attPct =
        totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 94.5;

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
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'School Report Card',
                          style: TextStyle(
                            color: AppTheme.text(ctx),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${child.name} • ${child.program} (${child.semester}) • Term 1 Assessment',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Grade $overallGrade • ${overallPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Metrics Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF162529)
                      : const Color(0xFFF0FDF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryMetric(
                      'Percentage',
                      '${overallPct.toStringAsFixed(1)}%',
                      const Color(0xFF2DD4BF),
                    ),
                    _summaryMetric(
                      'Overall Grade',
                      overallGrade,
                      const Color(0xFF10B981),
                    ),
                    _summaryMetric(
                      'Class Rank',
                      classRank,
                      const Color(0xFF3B82F6),
                    ),
                    _summaryMetric(
                      'Attendance',
                      '${attPct.toStringAsFixed(1)}%',
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Subject-wise Evaluation (Max: 100)',
                      style: TextStyle(
                        color: AppTheme.text(ctx),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 0,
                    child: Text(
                      'Tap subject for details',
                      style: TextStyle(
                        color: AppTheme.textSecondary(ctx),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tappable Subject List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final s = subjects[idx];
                    final SubjectAttendance? matchedAtt =
                        _matchSubjectAttendance(controller.subjects, s);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(ctx).push(
                            MaterialPageRoute(
                              builder: (_) => SubjectReportCardScreen(
                                child: child,
                                report: s,
                                attendance: matchedAtt,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.card(ctx),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: s.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s.grade,
                                  style: TextStyle(
                                    color: s.accentColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: TextStyle(
                                        color: AppTheme.text(ctx),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Score: ${s.totalMarks} / ${s.maxMarks} • ${s.summaryDetails}',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary(ctx),
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppTheme.textSecondary(ctx),
                              ),
                            ],
                          ),
                        ),
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

  static Widget _summaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static SubjectAttendance? _matchSubjectAttendance(
    List<SubjectAttendance> list,
    SubjectReportData report,
  ) {
    for (final item in list) {
      if (item.code == report.code ||
          item.subjectName.toLowerCase().contains(
                report.name.split(' ').first.toLowerCase(),
              )) {
        return item;
      }
    }
    return null;
  }

  static List<SubjectReportData> _buildSubjectsForChild(bool isJunior) {
    final suffix = isJunior ? '07' : '10';
    final List<SubjectReportData> list = [
      SubjectReportData(
        name: 'Mathematics',
        code: 'MTH-$suffix',
        grade: 'A1',
        totalMarks: isJunior ? 97 : 96,
        summaryDetails: isJunior
            ? 'Internal: 20/20 • Theory: 77/80'
            : 'Internal: 19/20 • Theory: 77/80',
        accentColor: const Color(0xFF2DD4BF),
        componentLabel: 'Internal & Notebook',
        componentScored: isJunior ? 20 : 19,
        componentMax: 20,
        examLabel: 'Term-1 Theory Exam',
        examScored: 77,
        examMax: 80,
        classAverage: 82,
        classHighest: 99,
        unitBreakdown: isJunior
            ? const [
                (topic: 'Integers & Fractions', score: '24 / 25', grade: 'A1'),
                (topic: 'Linear Equations', score: '25 / 25', grade: 'A1'),
                (topic: 'Lines, Angles & Triangles', score: '28 / 30', grade: 'A1'),
              ]
            : const [
                (topic: 'Quadratic Equations', score: '25 / 25', grade: 'A1'),
                (topic: 'Coordinate Geometry & Triangles', score: '24 / 25', grade: 'A1'),
                (topic: 'Trigonometry Applications', score: '28 / 30', grade: 'A1'),
              ],
      ),
      SubjectReportData(
        name: isJunior ? 'General Science' : 'Science (Physics, Chem, Bio)',
        code: 'SCI-$suffix',
        grade: 'A1',
        totalMarks: isJunior ? 94 : 92,
        summaryDetails: isJunior
            ? 'Practicals: 19/20 • Theory: 75/80'
            : 'Practicals: 20/20 • Theory: 72/80',
        accentColor: const Color(0xFF3B82F6),
        componentLabel: 'Lab Practicals & Activity',
        componentScored: isJunior ? 19 : 20,
        componentMax: 20,
        examLabel: 'Term-1 Theory Exam',
        examScored: isJunior ? 75 : 72,
        examMax: 80,
        classAverage: 80,
        classHighest: 98,
        unitBreakdown: isJunior
            ? const [
                (topic: 'Nutrition & Respiration', score: '24 / 25', grade: 'A1'),
                (topic: 'Acids, Bases & Salts', score: '25 / 25', grade: 'A1'),
                (topic: 'Heat, Motion & Light', score: '26 / 30', grade: 'A1'),
              ]
            : const [
                (topic: 'Physics: Optics & Electricity', score: '24 / 27', grade: 'A1'),
                (topic: 'Chemistry: Chemical Reactions', score: '24 / 26', grade: 'A1'),
                (topic: 'Biology: Life Processes', score: '24 / 27', grade: 'A1'),
              ],
      ),
      SubjectReportData(
        name: isJunior ? 'English Grammar & Literature' : 'English Language & Literature',
        code: 'ENG-$suffix',
        grade: 'A1',
        totalMarks: isJunior ? 95 : 94,
        summaryDetails: isJunior
            ? 'ASL: 20/20 • Written: 75/80'
            : 'ASL: 20/20 • Written: 74/80',
        accentColor: const Color(0xFF10B981),
        componentLabel: 'ASL Speaking & Listening',
        componentScored: 20,
        componentMax: 20,
        examLabel: 'Written Examination',
        examScored: isJunior ? 75 : 74,
        examMax: 80,
        classAverage: 84,
        classHighest: 97,
        unitBreakdown: const [
          (topic: 'Reading Comprehension', score: '19 / 20', grade: 'A1'),
          (topic: 'Writing & Grammar Skills', score: '27 / 30', grade: 'A1'),
          (topic: 'Literature Prose & Poetry', score: '28 / 30', grade: 'A1'),
        ],
      ),
      SubjectReportData(
        name: isJunior ? 'Social Studies' : 'Social Science (History, Civics, Geo)',
        code: 'SST-$suffix',
        grade: isJunior ? 'A1' : 'A2',
        totalMarks: isJunior ? 91 : 88,
        summaryDetails: isJunior
            ? 'Project: 19/20 • Theory: 72/80'
            : 'Project: 18/20 • Theory: 70/80',
        accentColor: const Color(0xFF8B5CF6),
        componentLabel: 'Term Project & Map Work',
        componentScored: isJunior ? 19 : 18,
        componentMax: 20,
        examLabel: 'Term-1 Theory Exam',
        examScored: isJunior ? 72 : 70,
        examMax: 80,
        classAverage: 79,
        classHighest: 96,
        unitBreakdown: const [
          (topic: 'History & Heritage', score: '23 / 27', grade: 'A2'),
          (topic: 'Geography & Maps', score: '24 / 27', grade: 'A1'),
          (topic: 'Civics & Economics', score: '23 / 26', grade: 'A1'),
        ],
      ),
      SubjectReportData(
        name: isJunior ? 'Hindi Language' : 'Hindi / Regional Language',
        code: 'HIN-$suffix',
        grade: isJunior ? 'A1' : 'A2',
        totalMarks: isJunior ? 90 : 87,
        summaryDetails: isJunior
            ? 'Internal: 19/20 • Written: 71/80'
            : 'Internal: 19/20 • Written: 68/80',
        accentColor: const Color(0xFFF59E0B),
        componentLabel: 'Oral & Internal Assessment',
        componentScored: 19,
        componentMax: 20,
        examLabel: 'Written Examination',
        examScored: isJunior ? 71 : 68,
        examMax: 80,
        classAverage: 78,
        classHighest: 95,
        unitBreakdown: const [
          (topic: 'Vyakaran (Grammar)', score: '22 / 25', grade: 'A1'),
          (topic: 'Patra & Essay Writing', score: '22 / 25', grade: 'A1'),
          (topic: 'Sahitya & Prose', score: '24 / 30', grade: 'A2'),
        ],
      ),
    ];

    if (!isJunior) {
      list.add(
        const SubjectReportData(
          name: 'Computer Science & AI Basics',
          code: 'CS-10',
          grade: 'A1',
          totalMarks: 98,
          summaryDetails: 'Lab Practical: 30/30 • Written: 68/70',
          accentColor: Color(0xFF06B6D4),
          componentLabel: 'Coding Lab Practical',
          componentScored: 30,
          componentMax: 30,
          examLabel: 'Theory Examination',
          examScored: 68,
          examMax: 70,
          classAverage: 86,
          classHighest: 99,
          unitBreakdown: [
            (topic: 'Python Loops & Functions', score: '24 / 25', grade: 'A1'),
            (topic: 'Data Handling & SQL', score: '22 / 22', grade: 'A1'),
            (topic: 'AI Ethics & Foundations', score: '22 / 23', grade: 'A1'),
          ],
        ),
      );
    }

    return list;
  }
}

/// Detailed Subject Report Card screen opened when a parent taps
/// any subject inside [SchoolReportCardSheet].
class SubjectReportCardScreen extends StatelessWidget {
  final ChildProfile child;
  final SubjectReportData report;
  final SubjectAttendance? attendance;

  const SubjectReportCardScreen({
    super.key,
    required this.child,
    required this.report,
    this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double ratio = (report.totalMarks / report.maxMarks).clamp(0.0, 1.0);

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Report Card',
              style: TextStyle(
                color: AppTheme.text(context),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              '${child.name} • ${child.program} (${child.semester})',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Subject Hero Score Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: report.accentColor.withValues(alpha: isDark ? 0.4 : 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: report.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: report.accentColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Grade ${report.grade} • Term 1',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text(context),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${report.totalMarks}',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: report.accentColor,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        '/ ${report.maxMarks} Marks',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: AppTheme.surface(context),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(report.accentColor),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        context,
                        'Class Average',
                        '${report.classAverage}%',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        context,
                        'Class Highest',
                        '${report.classHighest}%',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        context,
                        'Status',
                        report.totalMarks >= 35 ? 'Distinction' : 'Pass',
                        valueColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Marks Component Breakdown
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Assessment Breakdown',
            icon: Icons.assessment_rounded,
            iconColor: const Color(0xFF3B82F6),
            child: Column(
              children: [
                _buildComponentBar(
                  context,
                  label: report.componentLabel,
                  scored: report.componentScored,
                  max: report.componentMax,
                  color: report.accentColor,
                ),
                const SizedBox(height: 14),
                _buildComponentBar(
                  context,
                  label: report.examLabel,
                  scored: report.examScored,
                  max: report.examMax,
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Unit / Topic Evaluation
          _buildSectionCard(
            context,
            isDark: isDark,
            title: 'Topic-Wise Evaluation',
            icon: Icons.topic_rounded,
            iconColor: const Color(0xFF8B5CF6),
            child: Column(
              children: List.generate(report.unitBreakdown.length, (i) {
                final u = report.unitBreakdown[i];
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            u.topic,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          u.score,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: report.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            u.grade,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: report.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),

          // 4. Subject Teacher & Attendance (when available)
          if (attendance != null) ...[
            const SizedBox(height: 14),
            _buildSectionCard(
              context,
              isDark: isDark,
              title: 'Subject Teacher & Attendance',
              icon: Icons.person_outline_rounded,
              iconColor: const Color(0xFF10B981),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance!.facultyName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Attended: ${attendance!.attendedClasses} / ${attendance!.totalClasses} classes',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${attendance!.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.text(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildComponentBar(
    BuildContext context, {
    required String label,
    required int scored,
    required int max,
    required Color color,
  }) {
    final double ratio = max > 0 ? (scored / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.text(context),
              ),
            ),
            Text(
              '$scored / $max',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: AppTheme.surface(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
