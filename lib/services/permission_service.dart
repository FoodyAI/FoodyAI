import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/app_colors.dart';

class PermissionService {
  /// Check and request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      // Check current permission status
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // Request permission
        final result = await Permission.camera.request();
        if (result.isGranted) {
          // Don't show success message - camera will open immediately
          return true;
        } else if (result.isPermanentlyDenied) {
          _showSnackBarWithSettings(
              context,
              'Camera permission is permanently denied. Please enable it in settings.',
              AppColors.error);
          return false;
        } else {
          _showSnackBar(context, 'Camera permission denied', AppColors.error);
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        // Even if status shows permanently denied, try to request permission
        // This handles the case where user changed setting from "Don't Allow" to "Ask Every Time"
        final result = await Permission.camera.request();
        if (result.isGranted) {
          // Don't show success message - camera will open immediately
          return true;
        } else if (result.isPermanentlyDenied) {
          _showSnackBarWithSettings(
              context,
              'Camera permission is denied. Please enable it in settings.',
              AppColors.error);
          return false;
        } else {
          // If result is denied (not permanently denied), user can try again
          _showSnackBar(context, 'Camera permission denied', AppColors.error);
          return false;
        }
      }

      if (status.isRestricted) {
        _showSnackBar(context, 'Camera access is restricted on this device',
            AppColors.error);
        return false;
      }

      return false;
    } catch (e) {
      _showSnackBar(
          context, 'Error checking camera permission', AppColors.error);
      return false;
    }
  }

  /// Check camera permission status (useful after returning from settings)
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  /// Show snackbar with message (same style as sign out success)
  static void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show snackbar with settings button for permanently denied permissions
  static void _showSnackBarWithSettings(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          onPressed: () async {
            try {
              await openAppSettings();
            } catch (e) {
              print('Error opening app settings: $e');
            }
          },
        ),
      ),
    );
  }
}
