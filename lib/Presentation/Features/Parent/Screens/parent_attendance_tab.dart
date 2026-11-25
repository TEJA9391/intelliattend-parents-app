import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../Services/fee_payment_service.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import '../Widgets/child_switcher_bar.dart';
import '../Widgets/school_report_card_sheet.dart';
import 'parent_detailed_attendance_screen.dart';

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
    final double overallPercentage =
        totalClasses > 0 ? (totalAttended / totalClasses) * 100 : 0.0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text(context),
              ),
            ),
            Text(
              '${child.name} • ${child.program} (${child.semester})',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        physics: const BouncingScrollPhysics(),
        children: [
          const ChildSwitcherBar(),

          // 1. Attendance Overview Card with button to open full Subject Attendance
          _buildAttendanceOverviewCard(
            context,
            controller: controller,
            totalAttended: totalAttended,
            totalClasses: totalClasses,
            percentage: overallPercentage,
            isDark: isDark,
          ),

          // 2. Academic Performance (Compact 3-Metric Summary, opens Report Card)
          _buildAcademicGradesCard(context, controller, child, isDark),

          // 3. Study Activities & Homeworks (Clean & Concise List)
          _buildStudyActivitiesCard(context, child, isDark),

          // 4. School Fees & Dues (intelliattend.com payment + clickable PDF receipts)
          _SchoolFeesCard(
            child: child,
            parentName: controller.parentName,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. ATTENDANCE OVERVIEW CARD WITH BUTTON
  // ==========================================
  Widget _buildAttendanceOverviewCard(
    BuildContext context, {
    required ParentController controller,
    required int totalAttended,
    required int totalClasses,
    required double percentage,
    required bool isDark,
  }) {
    final bool isEligible = percentage >= 75.0;
    final int safeBuffer = totalClasses > 0 && isEligible
        ? ((totalAttended - 0.75 * totalClasses) / 0.75).floor().clamp(0, 999)
        : 0;
    final int classesNeeded = totalClasses > 0 && !isEligible
        ? ((0.75 * totalClasses - totalAttended) / 0.25).ceil().clamp(1, 999)
        : 0;

    final String marginText = isEligible
        ? (safeBuffer > 0
            ? 'Safe margin: Can miss up to $safeBuffer classes above 75%.'
            : 'On 75% boundary. Regular attendance advised.')
        : 'Needs next $classesNeeded classes to reach 75% target.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: isDark ? 0.4 : 0.25),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: Color(0xFF2DD4BF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(context),
                        ),
                      ),
                      Text(
                        'Minimum Required: 75%',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isEligible
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isEligible
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isEligible ? 'Eligible' : 'Low Attendance',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isEligible
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.12)
                      : const Color(0xFFF0FDFA),
                  border: Border.all(
                    color: const Color(0xFF2DD4BF),
                    width: 3.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attended: $totalAttended / $totalClasses classes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      marginText,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider<ParentController>.value(
                      value: controller,
                      child: const ParentDetailedAttendanceScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_rounded, size: 18),
              label: const Text(
                'View Subject-Wise Attendance & Logs',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. ACADEMIC PERFORMANCE SUMMARY
  // ==========================================
  Widget _buildAcademicGradesCard(BuildContext context,
      ParentController controller, ChildProfile child, bool isDark) {
    final bool isJunior = child.id == 'child_2' || child.program.contains('7');
    final String avgScore = isJunior ? '93.4%' : '92.5%';
    final String classRank = isJunior ? '2nd / 42' : '3rd / 45';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border(context)),
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
          onTap: () => SchoolReportCardSheet.show(context, child, controller),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.military_tech_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Academic Performance',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Term-1 Assessment • Tap for Report Card',
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
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Grade A1',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        'Average Score',
                        avgScore,
                        const Color(0xFF2DD4BF),
                        context,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        'Class Rank',
                        classRank,
                        const Color(0xFF3B82F6),
                        context,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        'Next Exam',
                        '10 Dec',
                        const Color(0xFFF59E0B),
                        context,
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

  Widget _buildMetricTile(
      String label, String value, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. STUDY ACTIVITIES & HOMEWORKS (SIMPLE)
  // ==========================================
  Widget _buildStudyActivitiesCard(
      BuildContext context, ChildProfile child, bool isDark) {
    final bool isJunior = child.id == 'child_2' || child.program.contains('7');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study & Homeworks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text(context),
                    ),
                  ),
                  Text(
                    '2 Completed • 1 Due Tomorrow',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSimpleHomeworkRow(
            subject: 'Mathematics',
            title: isJunior ? 'Fractions Practice Set #3' : 'Quadratic Equations #4',
            status: 'Graded (A+)',
            statusColor: const Color(0xFF10B981),
            context: context,
          ),
          const Divider(height: 18),
          _buildSimpleHomeworkRow(
            subject: 'Science',
            title: isJunior ? 'Plant Nutrition Diagram' : 'Light Reflection Lab',
            status: 'Verified',
            statusColor: const Color(0xFF2DD4BF),
            context: context,
          ),
          const Divider(height: 18),
          _buildSimpleHomeworkRow(
            subject: isJunior ? 'English' : 'Computer Science',
            title: isJunior ? 'Creative Writing Task' : 'Python Loops Task',
            status: 'Due Tomorrow',
            statusColor: const Color(0xFFF59E0B),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHomeworkRow({
    required String subject,
    required String title,
    required String status,
    required Color statusColor,
    required BuildContext context,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

}

// ==========================================
// 4. SCHOOL FEES & DUES CARD (PAYMENT REDIRECT & DOWNLOADABLE RECEIPTS)
// ==========================================
class _SchoolFeesCard extends StatefulWidget {
  final ChildProfile child;
  final String parentName;

  const _SchoolFeesCard({
    required this.child,
    required this.parentName,
  });

  @override
  State<_SchoolFeesCard> createState() => _SchoolFeesCardState();
}

class _SchoolFeesCardState extends State<_SchoolFeesCard>
    with WidgetsBindingObserver {
  late List<FeeItemRecord> _fees;
  String? _downloadingFeeId;
  FeeItemRecord? _pendingPaymentFee;
  FeeItemRecord? _latestDownloadedFee;
  bool _verifyingReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fees = FeePaymentService.defaultFeesForChild(
      childId: widget.child.id,
      program: widget.child.program,
    );
    FeePaymentService.registerDeepLinkListener(_handlePaymentCallbackUri);
    _loadChildFees();
  }

  @override
  void didUpdateWidget(covariant _SchoolFeesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.id != widget.child.id) {
      _fees = FeePaymentService.defaultFeesForChild(
        childId: widget.child.id,
        program: widget.child.program,
      );
      _latestDownloadedFee = null;
      _loadChildFees();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadChildFees() async {
    final loaded = await FeePaymentService.loadFees(
      childId: widget.child.id,
      program: widget.child.program,
    );
    if (!mounted) return;
    setState(() {
      _fees = loaded;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _pendingPaymentFee != null &&
        !_verifyingReturn) {
      _checkReturnedFromGateway();
    }
  }

  void _handlePaymentCallbackUri(Uri uri) {
    final bool isPaymentReturn =
        (uri.scheme == 'intelliattend' && uri.host == 'payment-callback') ||
            (uri.host.contains('intelliattend.com') &&
                uri.path.contains('payment'));
    if (!isPaymentReturn) return;

    final status = (uri.queryParameters['status'] ?? '').toLowerCase();
    final targetId = uri.queryParameters['fee_id'];
    final receiptNo = uri.queryParameters['receipt'] ??
        uri.queryParameters['receipt_no'];
    final txnId = uri.queryParameters['transaction_id'] ??
        uri.queryParameters['txn_id'];
    final receiptUrl = uri.queryParameters['receipt_url'];

    final FeeItemRecord? targetFee = _fees.cast<FeeItemRecord?>().firstWhere(
          (f) => f != null && !f.isPaid && (targetId == null || f.id == targetId),
          orElse: () => _pendingPaymentFee,
        );

    _pendingPaymentFee = null;

    if (targetFee != null &&
        (status == 'success' || status == 'paid' || receiptNo != null)) {
      _completeAndDownloadReceipt(
        targetFee,
        receiptNo: receiptNo,
        transactionId: txnId,
        receiptUrl: receiptUrl,
      );
    } else if (mounted && status == 'failed') {
      AppSnackBar.showError(
        context,
        'Payment was not completed on intelliattend.com',
      );
    }
  }

  Future<void> _checkReturnedFromGateway() async {
    final pending = _pendingPaymentFee;
    if (pending == null) return;
    _verifyingReturn = true;

    final serverResult = await FeePaymentService.verifyPaymentOnServer(
      childId: widget.child.id,
      feeId: pending.id,
    );

    if (!mounted) {
      _verifyingReturn = false;
      return;
    }

    if (serverResult != null) {
      _pendingPaymentFee = null;
      _verifyingReturn = false;
      await _completeAndDownloadReceipt(
        pending,
        receiptNo: serverResult['receipt_no']?.toString(),
        transactionId: serverResult['transaction_id']?.toString(),
        receiptUrl: serverResult['receipt_url']?.toString(),
      );
      return;
    }

    // Gateway page returned via app switch before callback URI triggered:
    // prompt user to confirm & download receipt or retry/cancel.
    _pendingPaymentFee = null;
    _verifyingReturn = false;
    _showPaymentReturnDialog(pending);
  }

  Future<void> _startOnlinePayment(FeeItemRecord unpaidFee) async {
    HapticFeedback.lightImpact();
    setState(() => _pendingPaymentFee = unpaidFee);

    try {
      final launched = await FeePaymentService.launchPaymentRedirect(
        childId: widget.child.id,
        childName: widget.child.name,
        rollNumber: widget.child.rollNumber,
        className: '${widget.child.program} (${widget.child.semester})',
        fee: unpaidFee,
      );
      if (!launched && mounted) {
        setState(() => _pendingPaymentFee = null);
        AppSnackBar.showError(
          context,
          'Could not open intelliattend.com payment page',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingPaymentFee = null);
      AppSnackBar.showError(
        context,
        'Could not open intelliattend.com payment page',
      );
    }
  }

  void _showPaymentReturnDialog(FeeItemRecord pendingFee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.language_rounded, color: Color(0xFF2DD4BF), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'intelliattend.com Payment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Returned from intelliattend.com for ${pendingFee.title} (${pendingFee.amountLabel}).\n\nIf payment is complete, confirm to download and display the official fee receipt here.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary(ctx),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Yet'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _completeAndDownloadReceipt(pendingFee);
            },
            icon: const Icon(Icons.download_rounded, size: 17),
            label: const Text('Download Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeAndDownloadReceipt(
    FeeItemRecord fee, {
    String? receiptNo,
    String? transactionId,
    String? receiptUrl,
  }) async {
    final completed = await FeePaymentService.completeFeePayment(
      childId: widget.child.id,
      fee: fee,
      receiptNo: receiptNo,
      transactionId: transactionId,
      receiptUrl: receiptUrl,
    );

    if (!mounted) return;
    setState(() {
      _fees = _fees.map((f) => f.id == fee.id ? completed : f).toList();
    });
    await FeePaymentService.saveFees(widget.child.id, _fees);
    await _downloadAndDisplayReceipt(completed, openImmediately: true);
  }

  Future<void> _downloadAndDisplayReceipt(
    FeeItemRecord fee, {
    bool openImmediately = false,
  }) async {
    HapticFeedback.lightImpact();
    setState(() => _downloadingFeeId = fee.id);

    try {
      final path = await FeePaymentService.downloadReceiptPdf(
        childName: widget.child.name,
        rollNumber: widget.child.rollNumber,
        className: '${widget.child.program} (${widget.child.semester})',
        fee: fee,
        parentName: widget.parentName,
      );
      final updatedFee = fee.copyWith(localReceiptPath: path);

      if (!mounted) return;
      setState(() {
        _downloadingFeeId = null;
        _latestDownloadedFee = updatedFee;
        _fees = _fees.map((f) => f.id == fee.id ? updatedFee : f).toList();
      });
      await FeePaymentService.saveFees(widget.child.id, _fees);

      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'Receipt #${updatedFee.receiptNo ?? 'PDF'} downloaded',
        icon: Icons.download_done_rounded,
      );

      if (openImmediately) {
        await FeePaymentService.openOrShareReceiptFile(
          filePath: path,
          childName: widget.child.name,
          rollNumber: widget.child.rollNumber,
          className: '${widget.child.program} (${widget.child.semester})',
          fee: updatedFee,
          parentName: widget.parentName,
        );
      } else {
        _showDownloadedReceiptSheet(updatedFee, path);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloadingFeeId = null);
      AppSnackBar.showError(context, 'Failed to download receipt PDF');
    }
  }

  void _showDownloadedReceiptSheet(FeeItemRecord fee, String filePath) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark
              ? Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official Fee Receipt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(ctx),
                        ),
                      ),
                      Text(
                        'Receipt #${fee.receiptNo ?? 'REC'} • Downloaded PDF',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface(ctx),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border(ctx)),
              ),
              child: Column(
                children: [
                  _receiptPreviewLine(ctx, 'Student', widget.child.name),
                  const SizedBox(height: 6),
                  _receiptPreviewLine(ctx, 'Fee Head', fee.title),
                  const SizedBox(height: 6),
                  _receiptPreviewLine(ctx, 'Amount Paid', fee.amountLabel),
                  if (fee.paidDate != null) ...[
                    const SizedBox(height: 6),
                    _receiptPreviewLine(ctx, 'Paid Date', fee.paidDate!),
                  ],
                  if (fee.transactionId != null) ...[
                    const SizedBox(height: 6),
                    _receiptPreviewLine(ctx, 'Txn Ref', fee.transactionId!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  FeePaymentService.openOrShareReceiptFile(
                    filePath: filePath,
                    childName: widget.child.name,
                    rollNumber: widget.child.rollNumber,
                    className: '${widget.child.program} (${widget.child.semester})',
                    fee: fee,
                    parentName: widget.parentName,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text(
                  'Open / Save Receipt PDF',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptPreviewLine(BuildContext ctx, String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(ctx)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            v,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.text(ctx),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatInr(int amount) {
    final s = amount.toString();
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+$)'),
      (m) => '${m[1]},',
    );
    return '₹$formattedRest,$last3';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<FeeItemRecord> unpaidItems =
        _fees.where((f) => !f.isPaid).toList();
    final int totalDue =
        unpaidItems.fold<int>(0, (sum, item) => sum + item.numericAmount);
    final bool hasDue = unpaidItems.isNotEmpty && totalDue > 0;
    final FeeItemRecord? firstUnpaid = hasDue ? unpaidItems.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'School Fees & Dues',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.text(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Session 2026 - 2027 • Tap receipt for PDF',
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
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (hasDue
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasDue ? 'Term-2 Due' : 'All Paid',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: hasDue
                        ? const Color(0xFFD97706)
                        : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _fees.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            _buildFeeRow(_fees[i], context),
          ],
          if (_latestDownloadedFee != null &&
              _latestDownloadedFee!.localReceiptPath != null) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => FeePaymentService.openOrShareReceiptFile(
                  filePath: _latestDownloadedFee!.localReceiptPath!,
                  childName: widget.child.name,
                  rollNumber: widget.child.rollNumber,
                  className: '${widget.child.program} (${widget.child.semester})',
                  fee: _latestDownloadedFee!,
                  parentName: widget.parentName,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.download_done_rounded,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Downloaded Receipt #${_latestDownloadedFee!.receiptNo ?? 'PDF'} • Tap to open PDF',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: (hasDue ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
                  .withValues(alpha: isDark ? 0.10 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    (hasDue ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
                        .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDue ? 'Outstanding Amount' : 'Fee Status',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasDue
                              ? (isDark
                                  ? Colors.white70
                                  : const Color(0xFF92400E))
                              : const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        hasDue ? _formatInr(totalDue) : 'All Dues Cleared',
                        style: TextStyle(
                          fontSize: hasDue ? 18 : 15,
                          fontWeight: FontWeight.w900,
                          color: hasDue
                              ? const Color(0xFFD97706)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                if (firstUnpaid != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _startOnlinePayment(firstUnpaid),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text(
                      'Pay Online',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ] else if (_fees.any((f) => f.isPaid)) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _downloadAndDisplayReceipt(
                      _fees.lastWhere((f) => f.isPaid),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text(
                      'Latest Receipt',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(FeeItemRecord item, BuildContext context) {
    final bool isDownloading = _downloadingFeeId == item.id;
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.isPaid && item.receiptNo != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDownloading)
                        const SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: Color(0xFF2DD4BF),
                          ),
                        )
                      else
                        const Icon(
                          Icons.download_for_offline_rounded,
                          size: 13,
                          color: Color(0xFF2DD4BF),
                        ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          isDownloading
                              ? 'Downloading receipt...'
                              : 'Receipt: #${item.receiptNo} • Download PDF',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2DD4BF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.amountLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: item.isPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: item.isPaid
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!item.isPaid) return rowContent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDownloading ? null : () => _downloadAndDisplayReceipt(item),
        borderRadius: BorderRadius.circular(10),
        child: rowContent,
      ),
    );
  }
}
