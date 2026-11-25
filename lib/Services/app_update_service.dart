import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Core/Network/api_client.dart';
import '../Presentation/Widgets/app_snack_bar.dart';
import '../Theme/app_theme.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final int currentBuild;
  final int latestBuild;
  final bool isMandatory;
  final String releaseTitle;
  final List<String> releaseNotes;
  final String downloadUrl;
  final String? apkDownloadUrl;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.currentBuild,
    required this.latestBuild,
    required this.isMandatory,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    this.apkDownloadUrl,
  });

  bool get hasUpdate => AppUpdateService.isVersionNewer(
        latestVersion: latestVersion,
        latestBuild: latestBuild,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
}

enum UpdateDownloadStatus { idle, downloading, readyToInstall, failed }

class AppUpdateDownloadState {
  final UpdateDownloadStatus status;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String? filePath;
  final String? error;

  const AppUpdateDownloadState({
    this.status = UpdateDownloadStatus.idle,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.filePath,
    this.error,
  });

  AppUpdateDownloadState copyWith({
    UpdateDownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? filePath,
    String? error,
  }) {
    return AppUpdateDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }
}

class AppUpdateService {
  static const String _githubRepo = 'TEJA9391/intelliattend-parents-app';
  static const String _githubLatestReleaseApi =
      'https://api.github.com/repos/$_githubRepo/releases/latest';
  static const String _fallbackReleasesUrl =
      'https://github.com/$_githubRepo/releases/latest';

  static final ValueNotifier<AppUpdateDownloadState> downloadState =
      ValueNotifier<AppUpdateDownloadState>(const AppUpdateDownloadState());

  static bool _dialogShowing = false;
  static bool _isDownloading = false;
  static bool _autoInstallTriggeredForVersion = false;
  static String? _lastAutoTriggeredVersion;

  /// Checks installed version against CI/CD published releases (GitHub Releases
  /// first, with backend release endpoint fallback).
  static Future<AppUpdateInfo> getUpdateInfo() async {
    String currentVersion = '2.4.0';
    int currentBuild = 140;

    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) currentVersion = info.version;
      currentBuild = int.tryParse(info.buildNumber) ?? currentBuild;
    } catch (_) {}

    // 1. Query GitHub CI/CD latest release
    final remoteFromGithub = await _fetchFromGithubReleases(
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );
    if (remoteFromGithub != null) {
      return remoteFromGithub;
    }

    // 2. Fallback: query backend release metadata endpoint if deployed
    final remoteFromBackend = await _fetchFromBackend(
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );
    if (remoteFromBackend != null) {
      return remoteFromBackend;
    }

    // 3. Offline / no remote release newer than installed -> up to date
    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      currentBuild: currentBuild,
      latestBuild: currentBuild,
      isMandatory: false,
      releaseTitle: 'IntelliAttend v$currentVersion',
      releaseNotes: const [],
      downloadUrl: _fallbackReleasesUrl,
      apkDownloadUrl: null,
    );
  }

  static Future<AppUpdateInfo?> _fetchFromGithubReleases({
    required String currentVersion,
    required int currentBuild,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Accept': 'application/vnd.github+json'},
      ));
      final res = await dio.get(_githubLatestReleaseApi);
      if (res.statusCode == 200 && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        if (data['draft'] == true || data['prerelease'] == true) {
          return null;
        }
        final tag = (data['tag_name'] ?? '').toString().trim();
        final parsed = _parseVersionTag(tag);
        if (parsed.version.isEmpty) return null;

        String? apkUrl;
        if (data['assets'] is List) {
          for (final asset in (data['assets'] as List)) {
            if (asset is Map) {
              final name = (asset['name'] ?? '').toString().toLowerCase();
              final url = (asset['browser_download_url'] ?? '').toString();
              if (name.endsWith('.apk') && url.isNotEmpty) {
                apkUrl = url;
                break;
              }
            }
          }
        }

        final htmlUrl =
            (data['html_url'] ?? _fallbackReleasesUrl).toString().trim();
        final body = (data['body'] ?? '').toString();
        final notes = _parseReleaseNotes(body);
        final isMandatory = body.toLowerCase().contains('[mandatory]') ||
            body.toLowerCase().contains('force_update: true');

        final latestBuild = parsed.build ??
            (_compareSemver(parsed.version, currentVersion) > 0
                ? currentBuild + 1
                : currentBuild);

        return AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: parsed.version,
          currentBuild: currentBuild,
          latestBuild: latestBuild,
          isMandatory: isMandatory,
          releaseTitle:
              (data['name'] ?? 'IntelliAttend v${parsed.version}').toString(),
          releaseNotes: notes.isNotEmpty
              ? notes
              : const ['Latest CI/CD release improvements and stability fixes'],
          downloadUrl: htmlUrl,
          apkDownloadUrl: apkUrl,
        );
      }
    } catch (e) {
      debugPrint('[AppUpdate] GitHub release check skipped: $e');
    }
    return null;
  }

  static Future<AppUpdateInfo?> _fetchFromBackend({
    required String currentVersion,
    required int currentBuild,
  }) async {
    try {
      final res = await ApiClient().dio.get(
        '/api/v1/app/version',
        queryParameters: {'app': 'parent', 'platform': 'android'},
      );
      if (res.statusCode == 200 && res.data is Map) {
        final raw = res.data['data'] is Map ? res.data['data'] : res.data;
        final data = Map<String, dynamic>.from(raw as Map);
        final ver =
            (data['latest_version'] ?? data['version'] ?? '').toString().trim();
        if (ver.isEmpty) return null;

        final parsed = _parseVersionTag(ver);
        final build = int.tryParse(
                (data['latest_build'] ?? data['build_number'] ?? '')
                    .toString()) ??
            parsed.build ??
            (_compareSemver(parsed.version, currentVersion) > 0
                ? currentBuild + 1
                : currentBuild);

        final rawNotes = data['release_notes'];
        final notes = rawNotes is List
            ? rawNotes.map((e) => e.toString()).toList()
            : _parseReleaseNotes(rawNotes?.toString() ?? '');

        return AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: parsed.version,
          currentBuild: currentBuild,
          latestBuild: build,
          isMandatory:
              data['mandatory'] == true || data['is_mandatory'] == true,
          releaseTitle: 'IntelliAttend v${parsed.version}',
          releaseNotes: notes.isNotEmpty
              ? notes
              : const ['Performance improvements and bug fixes'],
          downloadUrl:
              (data['download_url'] ?? _fallbackReleasesUrl).toString(),
          apkDownloadUrl: data['apk_url']?.toString(),
        );
      }
    } catch (e) {
      debugPrint('[AppUpdate] Backend release check skipped: $e');
    }
    return null;
  }

  /// Checks for a new CI/CD published version. When a newer release exists:
  /// 1. Starts downloading the APK automatically in the background (if APK asset exists),
  /// 2. Prompts the user to install the new version.
  static Future<void> checkAndPromptUpdate(
    BuildContext context, {
    bool manual = false,
  }) async {
    final info = await getUpdateInfo();

    if (!context.mounted) return;

    if (info.hasUpdate) {
      // Automatically download CI/CD APK immediately upon detection
      if (info.apkDownloadUrl != null && info.apkDownloadUrl!.isNotEmpty) {
        startAutoDownload(info);
      }

      if (_dialogShowing) return;
      _dialogShowing = true;

      await AppUpdateDialog.show(
        context,
        updateInfo: info,
      );

      _dialogShowing = false;
    } else if (manual) {
      AppSnackBar.showSuccess(
        context,
        'You are on the latest version (v${info.currentVersion})',
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }

  /// Automatically downloads the CI/CD APK asset into local cache and triggers
  /// installation prompt once ready.
  static Future<void> startAutoDownload(AppUpdateInfo info) async {
    final apkUrl = info.apkDownloadUrl;
    if (apkUrl == null || apkUrl.isEmpty || _isDownloading) return;

    try {
      final dir = await getTemporaryDirectory();
      final safeVer =
          info.latestVersion.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final savePath = '${dir.path}/intelliattend_parent_v$safeVer.apk';
      final file = File(savePath);

      if (await file.exists() && await file.length() > 1024 * 1024) {
        downloadState.value = AppUpdateDownloadState(
          status: UpdateDownloadStatus.readyToInstall,
          progress: 1.0,
          filePath: savePath,
        );
        return;
      }

      _isDownloading = true;
      _autoInstallTriggeredForVersion =
          _lastAutoTriggeredVersion == info.latestVersion;
      downloadState.value = const AppUpdateDownloadState(
        status: UpdateDownloadStatus.downloading,
        progress: 0.0,
      );

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 5),
      ));

      await dio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          final pct = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          downloadState.value = AppUpdateDownloadState(
            status: UpdateDownloadStatus.downloading,
            progress: pct,
            receivedBytes: received,
            totalBytes: total,
          );
        },
      );

      _isDownloading = false;
      downloadState.value = AppUpdateDownloadState(
        status: UpdateDownloadStatus.readyToInstall,
        progress: 1.0,
        filePath: savePath,
      );

      if (!_autoInstallTriggeredForVersion) {
        _autoInstallTriggeredForVersion = true;
        _lastAutoTriggeredVersion = info.latestVersion;
        await installDownloadedApk(savePath);
      }
    } catch (e) {
      _isDownloading = false;
      downloadState.value = AppUpdateDownloadState(
        status: UpdateDownloadStatus.failed,
        error: e.toString(),
      );
      debugPrint('[AppUpdate] Auto download failed: $e');
    }
  }

  /// Launches Android's system package installer for the downloaded APK.
  static Future<bool> installDownloadedApk([String? filePath]) async {
    final path = filePath ?? downloadState.value.filePath;
    if (path == null || path.isEmpty) return false;
    try {
      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('[AppUpdate] Error opening APK installer: $e');
      return false;
    }
  }

  static Future<bool> launchUpdateUrl(String url) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
    return false;
  }

  static ({String version, int? build}) _parseVersionTag(String tag) {
    final cleaned =
        tag.replaceFirst(RegExp(r'^v', caseSensitive: false), '').trim();
    if (cleaned.isEmpty) return (version: '', build: null);
    final plusSplit = cleaned.split('+');
    final ver = plusSplit.first.split('-').first.trim();
    final build =
        plusSplit.length > 1 ? int.tryParse(plusSplit[1].trim()) : null;
    return (version: ver, build: build);
  }

  static int _compareSemver(String remote, String current) {
    final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = rParts.length > cParts.length ? rParts.length : cParts.length;
    for (int i = 0; i < len; i++) {
      final rv = i < rParts.length ? rParts[i] : 0;
      final cv = i < cParts.length ? cParts[i] : 0;
      if (rv != cv) return rv.compareTo(cv);
    }
    return 0;
  }

  static bool isVersionNewer({
    required String latestVersion,
    required int latestBuild,
    required String currentVersion,
    required int currentBuild,
  }) {
    final cmp = _compareSemver(latestVersion, currentVersion);
    if (cmp != 0) return cmp > 0;
    return latestBuild > currentBuild;
  }

  static List<String> _parseReleaseNotes(String body) {
    return body
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^[-*•#\s]+'), '').trim())
        .where((line) =>
            line.isNotEmpty &&
            !line.toLowerCase().startsWith('full changelog') &&
            !line.toLowerCase().contains('force_update:'))
        .take(4)
        .toList();
  }
}

class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
  }) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.isMandatory,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => AppUpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !updateInfo.isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.border(context),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Version Available',
                  style: TextStyle(
                    fontSize: 19.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text(context),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${updateInfo.latestVersion} (Build ${updateInfo.latestBuild})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFF0F766E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A new CI/CD release of IntelliAttend Parent is ready. Would you like to install this update?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                if (updateInfo.releaseNotes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFF2DD4BF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "What's New in v${updateInfo.latestVersion}:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final note in updateInfo.releaseNotes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: Color(0xFF2DD4BF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.textSecondary(context),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ValueListenableBuilder<AppUpdateDownloadState>(
                  valueListenable: AppUpdateService.downloadState,
                  builder: (context, dl, _) {
                    final bool isDownloading =
                        dl.status == UpdateDownloadStatus.downloading;
                    final bool isReady =
                        dl.status == UpdateDownloadStatus.readyToInstall;

                    return Column(
                      children: [
                        if (isDownloading) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: dl.progress > 0 ? dl.progress : null,
                              minHeight: 7,
                              backgroundColor: AppTheme.surface(context),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2DD4BF)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dl.totalBytes > 0
                                ? 'Downloading automatically... ${(dl.progress * 100).toStringAsFixed(0)}%'
                                : 'Downloading update package...',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    HapticFeedback.heavyImpact();
                                    if (isReady && dl.filePath != null) {
                                      await AppUpdateService
                                          .installDownloadedApk(dl.filePath);
                                    } else if (updateInfo.apkDownloadUrl !=
                                            null &&
                                        updateInfo.apkDownloadUrl!.isNotEmpty) {
                                      await AppUpdateService.startAutoDownload(
                                          updateInfo);
                                    } else {
                                      await AppUpdateService.launchUpdateUrl(
                                          updateInfo.downloadUrl);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DD4BF),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: Icon(
                              isReady
                                  ? Icons.install_mobile_rounded
                                  : Icons.download_rounded,
                              size: 19,
                            ),
                            label: Text(
                              isDownloading
                                  ? 'Downloading...'
                                  : isReady
                                      ? 'Install New Version'
                                      : 'Download & Install',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (!updateInfo.isMandatory) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Later',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Installed: v${updateInfo.currentVersion} (Build ${updateInfo.currentBuild})',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
