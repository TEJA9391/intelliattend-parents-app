import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Theme/app_theme.dart';
import 'notification_service.dart';

/// Core runtime permissions used by IntelliAttend Parent features.
enum AppPermissionType {
  notifications,
  location,
  camera,
  microphone,
  photos,
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static const String firstLoginAskedPrefKey =
      'parent_first_login_permissions_asked_v1';

  static const List<AppPermissionType> _firstLoginOrder = [
    AppPermissionType.notifications,
    AppPermissionType.location,
    AppPermissionType.camera,
    AppPermissionType.microphone,
    AppPermissionType.photos,
  ];

  bool _isRequesting = false;
  int? _cachedAndroidSdkInt;

  /// Backward-compatible check used by SecurityController.
  Future<bool> hasAllPermissions() async {
    return await Permission.notification.isGranted;
  }

  /// Backward-compatible single notification request used by auth/security flows.
  Future<Map<Permission, PermissionStatus>> requestAll() async {
    if (_isRequesting) return {};
    _isRequesting = true;
    try {
      final status = await requestNotificationPermission();
      return {Permission.notification: status};
    } finally {
      _isRequesting = false;
    }
  }

  Future<bool> isNotificationGranted() async =>
      await Permission.notification.isGranted;

  Future<int> _getAndroidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    if (_cachedAndroidSdkInt != null) return _cachedAndroidSdkInt!;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      _cachedAndroidSdkInt = info.version.sdkInt;
      return _cachedAndroidSdkInt!;
    } catch (_) {
      return 33;
    }
  }

  Future<Permission> resolvePlatformPermission(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.notifications:
        return Permission.notification;
      case AppPermissionType.location:
        return Permission.locationWhenInUse;
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.microphone:
        return Permission.microphone;
      case AppPermissionType.photos:
        if (Platform.isAndroid) {
          final sdk = await _getAndroidSdkInt();
          return sdk >= 33 ? Permission.photos : Permission.storage;
        }
        return Permission.photos;
    }
  }

  String labelFor(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.notifications:
        return 'Notifications';
      case AppPermissionType.location:
        return 'Location';
      case AppPermissionType.camera:
        return 'Camera';
      case AppPermissionType.microphone:
        return 'Microphone';
      case AppPermissionType.photos:
        return 'Photos & Media';
    }
  }

  /// Requests Device Notification permission across permission_handler,
  /// flutter_local_notifications, and FirebaseMessaging so FCM & alerts work.
  Future<PermissionStatus> requestNotificationPermission() async {
    PermissionStatus status = PermissionStatus.denied;
    try {
      status = await Permission.notification.request();
    } catch (e) {
      debugPrint('[PermissionService] Permission.notification.request error: $e');
    }

    try {
      await NotificationService().requestPlatformPermissions();
    } catch (e) {
      debugPrint('[PermissionService] Local notification request error: $e');
    }

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[PermissionService] FirebaseMessaging permission error: $e');
    }

    return status;
  }

  Future<PermissionStatus> requestSinglePermission(AppPermissionType type) async {
    if (type == AppPermissionType.notifications) {
      final current = await Permission.notification.status;
      if (current.isGranted || current.isLimited) return current;
      return requestNotificationPermission();
    }
    final permission = await resolvePlatformPermission(type);
    final current = await permission.status;
    if (current.isGranted || current.isLimited) {
      return current;
    }
    return permission.request();
  }

  /// Called once automatically right after first login: triggers the native OS
  /// permission prompts directly (Notifications first, then Location, Camera,
  /// Microphone, Photos/Storage) without showing any custom onboarding card UI.
  Future<void> requestFirstLoginPermissions() async {
    if (_isRequesting) return;
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(firstLoginAskedPrefKey) ?? false;
    if (alreadyAsked) return;

    await prefs.setBool(firstLoginAskedPrefKey, true);
    _isRequesting = true;
    try {
      for (final type in _firstLoginOrder) {
        try {
          await requestSinglePermission(type);
        } catch (e) {
          debugPrint('[PermissionService] First-login ask failed for $type: $e');
        }
      }
    } finally {
      _isRequesting = false;
    }
  }

  /// Just-in-time feature permission guard:
  /// If a user tries to use a feature whose permission was not allowed earlier,
  /// ask the native OS permission dialog right then (or offer Settings if
  /// permanently denied).
  Future<bool> ensureFeaturePermission(
    BuildContext context,
    AppPermissionType type, {
    String? featureName,
  }) async {
    final permission = await resolvePlatformPermission(type);
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showOpenSettingsDialog(
          context,
          labelFor(type),
          featureName: featureName,
        );
      }
      status = await permission.status;
      return status.isGranted || status.isLimited;
    }

    status = await requestSinglePermission(type);
    if (status.isGranted || status.isLimited) return true;

    if (!context.mounted) return false;

    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog(
        context,
        labelFor(type),
        featureName: featureName,
      );
      final updated = await permission.status;
      return updated.isGranted || updated.isLimited;
    }

    final label = labelFor(type);
    final suffix = (featureName != null && featureName.isNotEmpty)
        ? ' for $featureName'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label permission is required$suffix.'),
      ),
    );
    return false;
  }

  Future<void> _showOpenSettingsDialog(
    BuildContext context,
    String label, {
    String? featureName,
  }) {
    final actionText = (featureName != null && featureName.isNotEmpty)
        ? 'use $featureName'
        : 'use this feature';

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card(ctx),
        title: Text(
          '$label permission required',
          style: GoogleFonts.inter(
            color: AppTheme.text(ctx),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Please allow $label access in system settings to $actionText.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary(ctx),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Not now',
              style: TextStyle(color: AppTheme.textSecondary(ctx)),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
