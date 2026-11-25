import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Theme/app_theme.dart';
import '../../Widgets/app_snack_bar.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({Key? key}) : super(key: key);

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = "Technical Bug";
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _categories = [
    "Technical Bug",
    "Attendance Record Discrepancy",
    "Bus / RFID Tracking Issue",
    "Leave Application Issue",
    "Notification Delay",
    "Other Feedback",
  ];

  // Attachment state
  PlatformFile? _pickedFile;

  // Diagnostics state
  bool _includeDiagnostics = true;
  bool _showDiagnosticsPreview = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    HapticFeedback.lightImpact();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            AppSnackBar.showError(
              context,
              'File exceeds maximum limit of 10MB',
            );
          }
          return;
        }

        setState(() {
          _pickedFile = file;
        });

        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            'Attached ${file.name}',
            icon: Icons.attach_file_rounded,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not access file picker');
      }
    }
  }

  void _removeAttachment() {
    HapticFeedback.selectionClick();
    setState(() {
      _pickedFile = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openSupportEmail() async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(
      'mailto:support@intelliattend.com?subject=Issue%20Report%20from%20Parent%20Portal',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not open email client');
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not open email client');
      }
    }
  }

  void _submitIssue() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API submission
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppTheme.card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2DD4BF),
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Report Submitted",
                  style: TextStyle(
                    color: AppTheme.text(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Thank you for reporting this issue. A support ticket #IA-${DateTime.now().millisecondsSinceEpoch % 100000} has been created and our team will get back to you shortly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.text(context),
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Report an Issue",
          style: TextStyle(
            color: AppTheme.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Email Support",
            icon: Icon(
              Icons.mail_outline_rounded,
              color: AppTheme.text(context),
              size: 22,
            ),
            onPressed: _openSupportEmail,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Issue Category Dropdown Card (exact mockup)
              _buildCategoryDropdown(context, isDark),

              const SizedBox(height: 22),

              // 2. Subject Section
              _buildSectionLabel("Subject"),
              const SizedBox(height: 8),
              _buildTextInputCard(
                context,
                isDark,
                controller: _subjectController,
                hintText: "Brief summary of the issue",
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a subject";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // 3. Detailed Description Section
              _buildSectionLabel("Detailed Description"),
              const SizedBox(height: 8),
              _buildTextInputCard(
                context,
                isDark,
                controller: _descriptionController,
                hintText:
                    "Describe what happened, error message, or steps to reproduce...",
                minLines: 4,
                maxLines: 8,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please provide a detailed description";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // 4. Attachments (Optional) Section
              Row(
                children: [
                  _buildSectionLabel("Attachments"),
                  const SizedBox(width: 6),
                  Text(
                    "(Optional)",
                    style: TextStyle(
                      color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildAttachmentBox(context, isDark),

              const SizedBox(height: 22),

              // 5. Include Diagnostic Info Card
              _buildDiagnosticInfoCard(context, isDark),

              const SizedBox(height: 28),

              // 6. Submit Report Primary Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DD4BF),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Text(
                          "Submit Report",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 36 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.text(context),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.text(context),
            size: 24,
          ),
          dropdownColor: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          style: TextStyle(
            color: AppTheme.text(context),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(cat),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTextInputCard(
    BuildContext context,
    bool isDark, {
    required TextEditingController controller,
    required String hintText,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: AppTheme.text(context),
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentBox(BuildContext context, bool isDark) {
    if (_pickedFile != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Color(0xFF2DD4BF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickedFile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatFileSize(_pickedFile!.size),
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppTheme.textSecondary(context),
              onPressed: _removeAttachment,
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _pickAttachment,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DottedBorderPainter(
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          strokeWidth: 1.4,
          gap: 6.0,
          radius: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    size: 24,
                    color: AppTheme.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Click to upload or drag and drop",
                style: TextStyle(
                  color: AppTheme.text(context),
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "PNG, JPG, PDF, or TXT only (strict max. 10MB per file)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary(context).withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticInfoCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Include Diagnostic Info",
                      style: TextStyle(
                        color: AppTheme.text(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Auto-attaches device model & OS to help resolve the issue faster",
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: _includeDiagnostics,
                activeThumbColor: const Color(0xFF2DD4BF),
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  setState(() => _includeDiagnostics = val);
                },
              ),
            ],
          ),
          if (_includeDiagnostics) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(
                    () => _showDiagnosticsPreview = !_showDiagnosticsPreview);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showDiagnosticsPreview
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF2DD4BF),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Preview attached diagnostics",
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showDiagnosticsPreview) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  "• Device: Android Device (SDK 34)\n• App: IntelliAttend Parent v2.4.0 (Build 140)\n• Portal: Guardian Portal • Network: Connected\n• Session ID: #IA-SEC-${DateTime.now().millisecondsSinceEpoch % 10000}",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Custom dashed border painter for the attachment drop zone
class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = _dashPath(path, width: 6.0, space: gap);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = width.clamp(0.0, metric.length - distance);
        dest.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + space;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DottedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gap != oldDelegate.gap ||
      radius != oldDelegate.radius;
}
