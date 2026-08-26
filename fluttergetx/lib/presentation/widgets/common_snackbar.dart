import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import '../../core/constants/colors.dart';

/// Unified Snackbar Widget
/// Position: Top, Background: White, Text: Primary Blue
/// Usage: AppSnackbar.show(message, type: SnackType.success/error/info)
enum SnackType { success, error, info, warning }

class AppSnackbar {
  static const Duration _defaultDuration = Duration(seconds: 3);

  static void show(
    String message, {
    SnackType type = SnackType.info,
    Duration duration = _defaultDuration,
    String? title,
    void Function(GetSnackBar)? onTap,
  }) {
    final Color textColor;
    final Color borderColor;
    final IconData icon;

    switch (type) {
      case SnackType.success:
        textColor = AppColors.success;
        borderColor = AppColors.success.withOpacity(0.3);
        icon = Icons.check_circle_rounded;
        break;
      case SnackType.error:
        textColor = AppColors.error;
        borderColor = AppColors.error.withOpacity(0.3);
        icon = Icons.error_rounded;
        break;
      case SnackType.warning:
        textColor = Colors.orange;
        borderColor = Colors.orange.withOpacity(0.3);
        icon = Icons.warning_amber_rounded;
        break;
      case SnackType.info:
      default:
        textColor = AppColors.primary;
        borderColor = AppColors.primary.withOpacity(0.3);
        icon = Icons.info_rounded;
        break;
    }

    Get.showSnackbar(
      GetSnackBar(
        messageText: _buildContent(message, title, icon, textColor),
        backgroundColor: Colors.white,
        borderRadius: 16,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: duration,
        snackPosition: SnackPosition.TOP,
        borderWidth: 1.5,
        borderColor: borderColor,
        boxShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        animationDuration: const Duration(milliseconds: 300),
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        onTap: onTap,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static Widget _buildContent(String message, String? title, IconData icon, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: textColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Convenience methods
  static void success(String message, {String? title, Duration? duration}) =>
      show(message, type: SnackType.success, title: title, duration: duration ?? _defaultDuration);

  static void error(String message, {String? title, Duration? duration}) =>
      show(message, type: SnackType.error, title: title, duration: duration ?? _defaultDuration);

  static void info(String message, {String? title, Duration? duration}) =>
      show(message, type: SnackType.info, title: title, duration: duration ?? _defaultDuration);

  static void warning(String message, {String? title, Duration? duration}) =>
      show(message, type: SnackType.warning, title: title, duration: duration ?? _defaultDuration);
}