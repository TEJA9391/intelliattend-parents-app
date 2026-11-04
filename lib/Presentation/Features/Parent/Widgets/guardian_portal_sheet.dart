import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../Theme/app_theme.dart';
import '../Controllers/parent_controller.dart';
import '../Models/parent_models.dart';

class GuardianPortalSheet extends StatelessWidget {
  final VoidCallback? onNavigateToProfile;

  const GuardianPortalSheet({
    super.key,
    this.onNavigateToProfile,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onNavigateToProfile,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: Provider.of<ParentController>(context, listen: false),
        child: GuardianPortalSheet(onNavigateToProfile: onNavigateToProfile),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 18),
            const SizedBox(width: 10),
            Text(
              '$label copied to clipboard',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<ParentController>();
    final activeChild = controller.activeChild;
    final children = controller.children;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131923) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.16),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset > 0 ? bottomInset + 16 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Centered drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          const SizedBox(height: 22),

          // 2. Profile Hero Header (Avatar + Name + Email)
          Row(
            children: [
              // Circular avatar with double ring
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF5EEAD4),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(controller.parentName),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Guardian Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.parentName,
                      style: GoogleFonts.inter(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(context),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.parentName.toLowerCase().replaceAll(RegExp(r'\s+'), '.')}.parent@intelliattend.app',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 3. Clean Info Rows (Matching exact faculty style layout)
          _buildInfoRow(
            context: context,
            isDark: isDark,
            icon: Icons.badge_outlined,
            label: 'Guardian ID',
            value: 'PRNT-2024-8841',
            onTap: () => _copyToClipboard(context, 'PRNT-2024-8841', 'Guardian ID'),
          ),

          _buildInfoRow(
            context: context,
            isDark: isDark,
            icon: Icons.apartment_rounded,
            label: 'Institution',
            value: 'Institute of Technology & Management',
          ),

          _buildInfoRow(
            context: context,
            isDark: isDark,
            icon: Icons.work_outline_rounded,
            label: 'Designation',
            value: 'Primary Guardian (Parent)',
          ),

          _buildInfoRow(
            context: context,
            isDark: isDark,
            icon: Icons.phone_iphone_rounded,
            label: 'Registered Mobile',
            value: '+91 98765 43210',
            onTap: () => _copyToClipboard(context, '+919876543210', 'Phone Number'),
          ),

          _buildInfoRow(
            context: context,
            isDark: isDark,
            icon: Icons.school_outlined,
            label: 'Active Ward',
            value: '${activeChild.name} (${activeChild.rollNumber})',
            isLast: true,
            onTap: () {
              // Quick ward switch between children
              HapticFeedback.selectionClick();
              final nextChild = children.firstWhere(
                (c) => c.id != activeChild.id,
                orElse: () => activeChild,
              );
              controller.switchChild(nextChild.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.only(top: 10, bottom: isLast ? 6 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Mint Teal Icon
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF2DD4BF),
            ),
            const SizedBox(width: 14),

            // Field Label
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 16),

            // Field Value (Right-aligned)
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}
