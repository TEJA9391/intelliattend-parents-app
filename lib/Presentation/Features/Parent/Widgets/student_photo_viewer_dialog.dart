import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Services/permission_service.dart';
import '../../../../Theme/app_theme.dart';
import '../../../Widgets/app_snack_bar.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

/// Preset avatar identifiers that render 100% offline with zero network needed
const List<String> kPresetStudentAvatars = [
  'preset:aarav',
  'preset:ananya',
  'preset:scholar_m',
  'preset:scholar_f',
  'preset:tech_boy',
  'preset:creative_girl',
];

/// Robust Smart Avatar Image Widget:
/// Supports vector preset student avatars, local Camera/Gallery files, assets, and network URLs
Widget buildSmartAvatarImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  double? iconSize = 32,
  String? fallbackPreset,
}) {
  final effectiveUrl = url.trim().isEmpty ? (fallbackPreset ?? 'preset:aarav') : url.trim();

  // 1. Vector Preset Student Avatar (Renders 100% offline with zero network)
  if (effectiveUrl.startsWith('preset:')) {
    return SizedBox(
      key: ValueKey('vector_box_${effectiveUrl}_${width}_$height'),
      width: width,
      height: height,
      child: CustomPaint(
        key: ValueKey('custom_paint_$effectiveUrl'),
        size: Size(width ?? 48, height ?? 48),
        painter: StudentAvatarPainter(presetId: effectiveUrl),
      ),
    );
  }

  // 2. Local file path from camera / gallery
  if (effectiveUrl.startsWith('/') ||
      effectiveUrl.startsWith('file:') ||
      (effectiveUrl.length > 3 && effectiveUrl[1] == ':')) {
    final cleanPath = effectiveUrl.replaceFirst('file://', '');
    final file = File(cleanPath);
    if (file.existsSync()) {
      int modifiedMs = 0;
      try {
        modifiedMs = file.lastModifiedSync().millisecondsSinceEpoch;
      } catch (_) {}
      return Image.file(
        file,
        key: ValueKey('file_avatar_${cleanPath}_$modifiedMs'),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildVectorFallback(width, height, fallbackPreset),
      );
    }
  }

  // 3. Asset image
  if (effectiveUrl.startsWith('assets/')) {
    return Image.asset(
      effectiveUrl,
      key: ValueKey('asset_$effectiveUrl'),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildVectorFallback(width, height, fallbackPreset),
    );
  }

  // 4. Network URL with caching & offline vector fallback
  return CachedNetworkImage(
    key: ValueKey('cached_net_$effectiveUrl'),
    imageUrl: effectiveUrl,
    width: width,
    height: height,
    fit: fit,
    placeholder: (_, __) => Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    ),
    errorWidget: (_, __, ___) => _buildVectorFallback(width, height, fallbackPreset),
  );
}

Widget _buildVectorFallback(double? width, double? height, String? fallbackPreset) {
  return SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      size: Size(width ?? 48, height ?? 48),
      painter: StudentAvatarPainter(presetId: fallbackPreset ?? 'preset:aarav'),
    ),
  );
}

/// Student Photo Viewer & Avatar Selection Dialog
class StudentPhotoViewerDialog extends StatefulWidget {
  final ChildProfile child;
  final ParentController? controller;

  const StudentPhotoViewerDialog({
    super.key,
    required this.child,
    this.controller,
  });

  /// Full-screen, view-only image viewer (no edit controls) used on Home's Enrolled Student card.
  static Future<void> showFullScreenImageOnly(
    BuildContext context,
    ChildProfile child,
  ) {
    HapticFeedback.lightImpact();
    final avatarUrl = child.avatarUrl.trim().isNotEmpty
        ? child.avatarUrl
        : (child.id == 'child_2' ? 'preset:ananya' : 'preset:aarav');

    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              child.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: SizedBox(
                  width: MediaQuery.sizeOf(ctx).width,
                  height: MediaQuery.sizeOf(ctx).width,
                  child: buildSmartAvatarImage(
                    avatarUrl,
                    width: MediaQuery.sizeOf(ctx).width,
                    height: MediaQuery.sizeOf(ctx).width,
                    fit: BoxFit.contain,
                    iconSize: 80,
                    fallbackPreset:
                        child.id == 'child_2' ? 'preset:ananya' : 'preset:aarav',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) {
        final dialog = StudentPhotoViewerDialog(child: child, controller: effectiveController);
        if (effectiveController != null) {
          return ChangeNotifierProvider<ParentController>.value(
            value: effectiveController,
            child: dialog,
          );
        }
        return dialog;
      },
    );
  }

  @override
  State<StudentPhotoViewerDialog> createState() => _StudentPhotoViewerDialogState();
}

class _StudentPhotoViewerDialogState extends State<StudentPhotoViewerDialog> {
  late String _activeAvatarUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _activeAvatarUrl = widget.child.avatarUrl;
    if (_activeAvatarUrl.isEmpty) {
      _activeAvatarUrl = widget.child.id == 'child_2' ? 'preset:ananya' : 'preset:aarav';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    final permType = source == ImageSource.camera
        ? AppPermissionType.camera
        : AppPermissionType.photos;
    final featureLabel = source == ImageSource.camera
        ? 'Camera photo update'
        : 'Gallery photo selection';
    final allowed = await PermissionService().ensureFeaturePermission(
      context,
      permType,
      featureName: featureLabel,
    );
    if (!allowed || !mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 88,
      );

      if (picked != null && mounted) {
        setState(() => _isSaving = true);

        // Read bytes directly - robust across all Android versions
        final bytes = await picked.readAsBytes();
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${widget.child.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = File('${appDir.path}/$fileName');
        await savedFile.writeAsBytes(bytes, flush: true);

        // Invalidate image cache
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        if (!mounted) return;
        setState(() {
          _activeAvatarUrl = savedFile.path;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, 'Failed to pick image: $e');
      }
      debugPrint('Error picking image: $e');
    }
  }

  void _selectPresetAvatar(String presetId) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeAvatarUrl = presetId;
    });
  }

  Future<void> _saveAndApplyAvatar() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final parentCtrl = widget.controller ?? context.read<ParentController>();
      await parentCtrl.updateChildAvatar(widget.child.id, _activeAvatarUrl);

      // Invalidate image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Double-ensure SharedPreferences has it in cache memory
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('child_avatar_${widget.child.id}', _activeAvatarUrl);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(
          context,
          'Profile photo saved permanently!',
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      debugPrint('Error saving avatar: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, 'Failed to save photo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final child = widget.child;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF2DD4BF).withValues(alpha: isDark ? 0.35 : 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar with Title and Close Icon
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.badge_rounded,
                          size: 16,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Student Profile Photo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text(context),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppTheme.textSecondary(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Large Full-View Interactive Photo (210x210)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF2DD4BF),
                        width: 3.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: _isSaving
                          ? Container(
                              color: const Color(0xFF2DD4BF),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(color: Colors.white),
                            )
                          : InteractiveViewer(
                              panEnabled: true,
                              minScale: 1.0,
                              maxScale: 3.0,
                              child: buildSmartAvatarImage(
                                _activeAvatarUrl,
                                width: 210,
                                height: 210,
                                fit: BoxFit.cover,
                                iconSize: 56,
                                fallbackPreset: child.id == 'child_2' ? 'preset:ananya' : 'preset:aarav',
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Student Name & Roll Number
                  Text(
                    child.name,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Roll No: ${child.rollNumber} • ${child.program}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Change Photo Action Buttons (Camera / Gallery)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 17),
                      label: const Text('Camera', style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.text(context),
                        side: BorderSide(color: AppTheme.border(context)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 17, color: Colors.black),
                      label: const Text('Gallery', style: TextStyle(fontSize: 12.5, color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Or Pick From Preset Student Avatars
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Or select a preset student avatar:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: kPresetStudentAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final presetId = kPresetStudentAvatars[index];
                  final isSelected = _activeAvatarUrl == presetId;

                  return Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _selectPresetAvatar(presetId),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.transparent,
                            width: 2.6,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipOval(
                          child: buildSmartAvatarImage(presetId, width: 48, height: 48),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Save Photo Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndApplyAvatar,
                  icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Save Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DD4BF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

/// Stylized Vector Student Avatar Painter
/// Draws handsome, crisp student portraits completely offline with zero network latency
class StudentAvatarPainter extends CustomPainter {
  final String presetId;

  const StudentAvatarPainter({required this.presetId});

  @override
  bool shouldRepaint(covariant StudentAvatarPainter oldDelegate) =>
      oldDelegate.presetId != presetId;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Clip to circle bounds
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // Style Configuration based on presetId
    final _AvatarConfig config = _getConfig(presetId);

    // 1. Vibrant Gradient Background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: config.bgColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Student Body & Clothes
    final bodyPaint = Paint()..color = config.clothesColor;
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 1.15),
      width: w * 0.96,
      height: h * 0.75,
    );
    canvas.drawOval(bodyRect, bodyPaint);

    // 3. Shirt Collar / Tie / Inner Accent
    if (config.hasTie) {
      final tiePaint = Paint()..color = const Color(0xFFDC2626);
      final tiePath = Path()
        ..moveTo(w * 0.46, h * 0.74)
        ..lineTo(w * 0.54, h * 0.74)
        ..lineTo(w * 0.52, h * 0.95)
        ..lineTo(w * 0.50, h * 0.98)
        ..lineTo(w * 0.48, h * 0.95)
        ..close();
      canvas.drawPath(tiePath, tiePaint);
    } else {
      // White / light inner collar
      final collarPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      final collarPath = Path()
        ..moveTo(w * 0.38, h * 0.72)
        ..lineTo(w * 0.5, h * 0.86)
        ..lineTo(w * 0.62, h * 0.72)
        ..close();
      canvas.drawPath(collarPath, collarPaint);
    }

    // 4. Neck
    final skinPaint = Paint()..color = config.skinColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.66), width: w * 0.22, height: h * 0.22),
        Radius.circular(w * 0.08),
      ),
      skinPaint,
    );

    // 5. Head / Face Oval
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.44),
      width: w * 0.44,
      height: h * 0.52,
    );
    canvas.drawOval(faceRect, skinPaint);

    // 6. Hair
    final hairPaint = Paint()..color = config.hairColor;
    if (config.isFemale) {
      // Long / shoulder hair
      final hairPath = Path()
        ..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.38), width: w * 0.54, height: h * 0.50))
        ..addOval(Rect.fromCenter(center: Offset(w * 0.30, h * 0.56), width: w * 0.20, height: h * 0.38))
        ..addOval(Rect.fromCenter(center: Offset(w * 0.70, h * 0.56), width: w * 0.20, height: h * 0.38));
      canvas.drawPath(hairPath, hairPaint);
      // Redraw face center so hair frames the face
      canvas.drawOval(faceRect, skinPaint);
      // Bangs / Forehead hair
      final bangs = Path()
        ..moveTo(w * 0.28, h * 0.34)
        ..quadraticBezierTo(w * 0.5, h * 0.24, w * 0.72, h * 0.34)
        ..quadraticBezierTo(w * 0.5, h * 0.36, w * 0.28, h * 0.34)
        ..close();
      canvas.drawPath(bangs, hairPaint);
    } else {
      // Male styled side-part / wavy hair
      final hairPath = Path()
        ..moveTo(w * 0.24, h * 0.42)
        ..quadraticBezierTo(w * 0.24, h * 0.16, w * 0.50, h * 0.16)
        ..quadraticBezierTo(w * 0.76, h * 0.16, w * 0.76, h * 0.42)
        ..quadraticBezierTo(w * 0.68, h * 0.28, w * 0.50, h * 0.28)
        ..quadraticBezierTo(w * 0.32, h * 0.30, w * 0.24, h * 0.42)
        ..close();
      canvas.drawPath(hairPath, hairPaint);
    }

    // 7. Facial Features: Eyes & Eyebrows
    final featurePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    // Left eye & Right eye
    canvas.drawCircle(Offset(w * 0.41, h * 0.45), w * 0.030, featurePaint);
    canvas.drawCircle(Offset(w * 0.59, h * 0.45), w * 0.030, featurePaint);
    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.42, h * 0.44), w * 0.010, shinePaint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.44), w * 0.010, shinePaint);

    // 8. Eyeglasses (if present)
    if (config.hasGlasses) {
      final glassesPaint = Paint()
        ..color = config.glassesColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.026;
      canvas.drawCircle(Offset(w * 0.40, h * 0.45), w * 0.082, glassesPaint);
      canvas.drawCircle(Offset(w * 0.60, h * 0.45), w * 0.082, glassesPaint);
      canvas.drawLine(Offset(w * 0.482, h * 0.45), Offset(w * 0.518, h * 0.45), glassesPaint);
    }

    // 9. Friendly Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF991B1B).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.024;
    final smilePath = Path()
      ..moveTo(w * 0.43, h * 0.56)
      ..quadraticBezierTo(w * 0.50, h * 0.62, w * 0.57, h * 0.56);
    canvas.drawPath(smilePath, smilePaint);

    // 10. Over-Ear Tech Headphones (for tech_boy)
    if (config.hasHeadphones) {
      final hpPaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.fill;
      // Left ear cup
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.22, h * 0.44), width: w * 0.08, height: h * 0.18),
          Radius.circular(w * 0.04),
        ),
        hpPaint,
      );
      // Right ear cup
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.78, h * 0.44), width: w * 0.08, height: h * 0.18),
          Radius.circular(w * 0.04),
        ),
        hpPaint,
      );
      // Headband
      final bandPaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.038;
      final bandPath = Path()
        ..moveTo(w * 0.24, h * 0.38)
        ..quadraticBezierTo(w * 0.50, h * 0.12, w * 0.76, h * 0.38);
      canvas.drawPath(bandPath, bandPaint);
    }
  }

  _AvatarConfig _getConfig(String id) {
    switch (id) {
      case 'preset:ananya':
        return const _AvatarConfig(
          bgColors: [Color(0xFFBE185D), Color(0xFFF472B6)], // Rose / Pink
          clothesColor: Color(0xFF9D174D),
          skinColor: Color(0xFFFFDFBA),
          hairColor: Color(0xFF451A03), // Brown
          isFemale: true,
          hasGlasses: false,
        );
      case 'preset:scholar_m':
        return const _AvatarConfig(
          bgColors: [Color(0xFF1E3A8A), Color(0xFF60A5FA)], // Navy
          clothesColor: Color(0xFF1E293B),
          skinColor: Color(0xFFF5D0A9),
          hairColor: Color(0xFF1C1917),
          isFemale: false,
          hasTie: true,
          hasGlasses: false,
        );
      case 'preset:scholar_f':
        return const _AvatarConfig(
          bgColors: [Color(0xFF5B21B6), Color(0xFFA78BFA)], // Violet
          clothesColor: Color(0xFF4C1D95),
          skinColor: Color(0xFFFFE0BD),
          hairColor: Color(0xFF2E1065),
          isFemale: true,
          hasGlasses: true,
          glassesColor: Color(0xFF7C3AED),
        );
      case 'preset:tech_boy':
        return const _AvatarConfig(
          bgColors: [Color(0xFF047857), Color(0xFF34D399)], // Emerald
          clothesColor: Color(0xFF064E3B),
          skinColor: Color(0xFFECC29C),
          hairColor: Color(0xFF171717),
          isFemale: false,
          hasHeadphones: true,
        );
      case 'preset:creative_girl':
        return const _AvatarConfig(
          bgColors: [Color(0xFFC2410C), Color(0xFFFBBF24)], // Amber / Gold
          clothesColor: Color(0xFF9A3412),
          skinColor: Color(0xFFFFDFBA),
          hairColor: Color(0xFF7C2D12),
          isFemale: true,
          hasGlasses: false,
        );
      case 'preset:aarav':
      default:
        return const _AvatarConfig(
          bgColors: [Color(0xFF0F766E), Color(0xFF2DD4BF)], // Deep Teal / Mint
          clothesColor: Color(0xFF115E59),
          skinColor: Color(0xFFFDDEC0),
          hairColor: Color(0xFF262626), // Dark wavy hair
          isFemale: false,
          hasGlasses: true,
          glassesColor: Color(0xFF1E293B),
        );
    }
  }
}

class _AvatarConfig {
  final List<Color> bgColors;
  final Color clothesColor;
  final Color skinColor;
  final Color hairColor;
  final bool isFemale;
  final bool hasGlasses;
  final Color glassesColor;
  final bool hasTie;
  final bool hasHeadphones;

  const _AvatarConfig({
    required this.bgColors,
    required this.clothesColor,
    required this.skinColor,
    required this.hairColor,
    required this.isFemale,
    this.hasGlasses = false,
    this.glassesColor = const Color(0xFF1E293B),
    this.hasTie = false,
    this.hasHeadphones = false,
  });
}
