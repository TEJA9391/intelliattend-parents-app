import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';
import '../Widgets/student_photo_viewer_dialog.dart';

class StudentCampusIdFullScreen extends StatefulWidget {
  final ChildProfile child;

  const StudentCampusIdFullScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    ChildProfile child, {
    ParentController? controller,
  }) {
    HapticFeedback.mediumImpact();
    ParentController? effectiveController = controller;
    if (effectiveController == null) {
      try {
        effectiveController = context.read<ParentController>();
      } catch (_) {}
    }

    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          final screen = StudentCampusIdFullScreen(child: child);
          if (effectiveController != null) {
            return ChangeNotifierProvider<ParentController>.value(
              value: effectiveController,
              child: screen,
            );
          }
          return screen;
        },
      ),
    );
  }

  @override
  State<StudentCampusIdFullScreen> createState() =>
      _StudentCampusIdFullScreenState();
}

class _StudentCampusIdFullScreenState extends State<StudentCampusIdFullScreen> {
  bool _showBack = false;

  Future<void> _callMentor(String phone) async {
    HapticFeedback.lightImpact();
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not open phone dialer');
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not open phone dialer');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ParentController? controller;
    try {
      controller = context.watch<ParentController>();
    } catch (_) {}
    final child = controller != null
        ? controller.children.firstWhere(
            (c) => c.id == widget.child.id,
            orElse: () => widget.child,
          )
        : widget.child;

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
          'Digital Campus ID Card',
          style: TextStyle(
            color: AppTheme.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _showBack
                ? _buildCardBack(context, isDark, child)
                : _buildCardFront(context, isDark, child),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _showBack = !_showBack);
              },
              icon: Icon(
                Icons.flip_camera_android_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFF2DD4BF)
                    : const Color(0xFF2DD4BF),
              ),
              label: Text(
                _showBack ? 'Flip to Front View' : 'Flip to Gate QR Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFF2DD4BF)
                      : const Color(0xFF2DD4BF),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.5)
                      : const Color(0xFF2DD4BF).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(BuildContext context, bool isDark, ChildProfile child) {
    return Container(
      key: const ValueKey('card_front'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400, minHeight: 480),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INTELLIATTEND VERIFIED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'STUDENT IDENTIFICATION CARD',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                // 2. Large Student Avatar
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ParentController? parentCtrl;
                    try {
                      parentCtrl = context.read<ParentController>();
                    } catch (_) {}
                    StudentPhotoViewerDialog.show(
                      context,
                      child,
                      controller: parentCtrl,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2DD4BF),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: buildSmartAvatarImage(child.avatarUrl,
                              width: 105, height: 105),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2DD4BF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Student Name
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text(context),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Active Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2DD4BF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Enrolled Student • ${child.academicYear}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF2DD4BF)
                              : const Color(0xFF2DD4BF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Data Table
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Roll Number', child.rollNumber, context),
                      const Divider(height: 14),
                      _buildDetailRow('Class', child.program, context),
                      const Divider(height: 14),
                      _buildDetailRow('Section', child.semester, context),
                      const Divider(height: 14),
                      _buildDetailRow('Class Teacher', child.mentorName, context,
                          trailingIcon: Icons.verified_rounded),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Direct Call Class Teacher Button
                if (child.mentorPhone.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _callMentor(child.mentorPhone),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: Text(
                        'Contact Class Teacher (${child.mentorPhone})',
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
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

  Widget _buildCardBack(BuildContext context, bool isDark, ChildProfile child) {
    return Container(
      key: const ValueKey('card_back'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400, minHeight: 480),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.border(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  color: Color(0xFF2DD4BF), size: 22),
              const SizedBox(width: 8),
              Text(
                'CAMPUS ENTRY GATE PASS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.text(context),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Real High-Contrast Turnstile QR Code
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: QrImageView(
              data:
                  'INTELLIATTEND:ID=${child.id};ROLL=${child.rollNumber};NAME=${child.name};EXP=2027',
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Scan at Campus RFID Turnstiles & Library',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(context),
            ),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Terms & Safety
          _buildBackInfoRow(Icons.security_rounded, 'RFID Verified',
              'Valid for Smart Attendance and Bus Transit', context),
          const SizedBox(height: 8),
          _buildBackInfoRow(Icons.emergency_rounded, 'Emergency Contact',
              'Campus Security Desk: +91 80 2345 6700', context),
          const SizedBox(height: 8),
          _buildBackInfoRow(Icons.policy_rounded, 'Property Of School',
              'Must be surrendered upon completion of academic session', context),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context,
      {IconData? trailingIcon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trailingIcon, size: 14, color: const Color(0xFF2DD4BF)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackInfoRow(
      IconData icon, String title, String subtitle, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2DD4BF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text(context),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
