import 'package:flutter/material.dart';

/// Centralized SnackBar Utility matching system theme:
/// - Black Mode (Dark): True pitch black background (#141414), white text, neutral dark border (no violet/blue)
/// - White Mode (Light): Pure white background (#FFFFFF), dark slate text, subtle light border
/// - Only shown for critical actions (Exit prompt, Errors like 404/network, and permanent saves)
class AppSnackBar {
  /// Error SnackBar (404, network failure, server errors, validation failures)
  static void showError(
    BuildContext context,
    String message, {
    IconData icon = Icons.error_outline_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      iconColor: const Color(0xFFEF4444),
      duration: duration,
      action: action,
    );
  }

  /// Double-Back Exit Prompt Notice
  static void showExitNotice(BuildContext context) {
    _show(
      context,
      message: 'Press back again to exit IntelliAttend',
      icon: Icons.exit_to_app_rounded,
      iconColor: const Color(0xFF94A3B8),
      duration: const Duration(seconds: 2),
    );
  }

  /// Critical Action Success (e.g. Save Photo permanently, Submit Leave)
  static void showSuccess(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      iconColor: const Color(0xFF10B981),
      duration: duration,
      action: action,
    );
  }

  /// Informational SnackBar (Important alerts only)
  static void showInfo(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      iconColor: const Color(0xFF94A3B8),
      duration: duration,
      action: action,
    );
  }

  /// Warning SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_amber_rounded,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      iconColor: const Color(0xFFF59E0B),
      duration: duration,
      action: action,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pure black in dark mode (no violet / blue hue), pure white in light mode
    final backgroundColor = isDark ? const Color(0xFF141414) : Colors.white;
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0);
    final iconBgColor = isDark ? const Color(0xFF222222) : const Color(0xFFF1F5F9);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: isDark ? 4 : 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: borderColor,
            width: 1.2,
          ),
        ),
        duration: duration,
        action: action,
      ),
    );
  }
}
