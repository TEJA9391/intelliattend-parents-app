import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intelli_attend_faculty/Services/haptic_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/chat_theme.dart';
import 'package:intelli_attend_faculty/Theme/app_theme.dart';

/// State machine for a WhatsApp-style voice note:
///
///   hold to record · slide left to cancel · lock · pause/resume ·
///   live amplitude wave · timer · preview playback · delete · send.
///
/// Recording uses the `record` plugin (AAC-LC, mono, noise suppression +
/// auto-gain). Preview playback uses `audioplayers`. No logic is faked —
/// the wave is real captured amplitude and the timer is the live duration.
class VoiceRecorderController extends ChangeNotifier {
  VoiceRecorderController({
    required void Function(String path, {int? durationMs}) onSend,
  }) : _onSend = onSend;

  final void Function(String path, {int? durationMs}) _onSend;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  static const int _maxWaveBars = 30;
  static const Duration _maxDuration = Duration(seconds: 60);
  static const Duration _minDuration = Duration(milliseconds: 700);

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLocked = false;
  bool _slideCancel = false;
  bool _isPreviewing = false;
  bool _isPlayingPreview = false;
  bool _disposed = false;

  String? _path;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Duration _previewPosition = Duration.zero;
  Duration _previewDuration = Duration.zero;
  double _slideDx = 0;
  final List<double> _wave = [];

  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  bool get isLocked => _isLocked;
  bool get slideCancel => _slideCancel;
  bool get isPreviewing => _isPreviewing;
  bool get isPlayingPreview => _isPlayingPreview;
  String? get path => _path;
  Duration get elapsed => _elapsed;
  Duration get previewPosition => _previewPosition;
  Duration get previewDuration => _previewDuration;

  double get previewProgress {
    final total = _previewDuration.inMilliseconds;
    if (total <= 0) return 0;
    return (_previewPosition.inMilliseconds / total).clamp(0.0, 1.0);
  }

  List<double> get wave => _wave.isEmpty
      ? List<double>.filled(_maxWaveBars, 0.04)
      : List.unmodifiable(_wave);

  String get timerText => _format(_elapsed);
  String get previewPositionText => _format(_previewPosition);
  String get previewDurationText => _format(_previewDuration);

  /// Starts a new recording. Permission must already be granted by the caller.
  Future<void> startRecording() async {
    if (_isRecording || _isPreviewing || _disposed) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
          noiseSuppress: true,
          autoGain: true,
        ),
        path: path,
      );
      _path = path;
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
      _slideDx = 0;
      _slideCancel = false;
      _isPaused = false;
      _isLocked = false;
      _isPreviewing = false;
      _wave.clear();
      _wave.addAll(List<double>.filled(_maxWaveBars, 0.04));
      _isRecording = true;

      _ampSub?.cancel();
      _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 60))
          .listen(_onAmplitude);

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!_isRecording || _isPaused) return;
        _elapsed = DateTime.now().difference(_startedAt!);
        if (_elapsed >= _maxDuration) {
          _finishRecording();
        } else {
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (_) {
      _reset();
    }
  }

  void _onAmplitude(Amplitude amp) {
    if (!_isRecording || _isPaused || _disposed) return;
    final db = amp.current.isFinite ? amp.current : -160.0;
    final level = ((db + 55) / 55).clamp(0.03, 1.0);
    _wave.removeAt(0);
    _wave.add(level);
    notifyListeners();
  }

  // ── Recording controls ────────────────────────────────────────────────

  Future<void> togglePause() async {
    if (!_isRecording) return;
    try {
      if (_isPaused) {
        await _recorder.resume();
        _isPaused = false;
      } else {
        await _recorder.pause();
        _isPaused = true;
      }
      notifyListeners();
    } catch (_) {}
  }

  void toggleLock() {
    if (!_isRecording) return;
    _isLocked = !_isLocked;
    if (_isLocked) _slideCancel = false;
    HapticService.selection();
    notifyListeners();
  }

  /// Feeds horizontal drag deltas while holding the mic. Sliding left past
  /// a threshold arms the cancel state; releasing then deletes the take.
  void updateSlide(double dx) {
    if (!_isRecording || _isLocked) return;
    _slideDx += dx;
    final cancel = _slideDx < -80;
    if (cancel != _slideCancel) {
      _slideCancel = cancel;
      if (cancel) HapticService.light();
      notifyListeners();
    }
  }

  /// Called when the user releases the mic (or the long-press is cancelled
  /// because the drag recognizer took over). Locked recordings keep going.
  void endHold() {
    if (!_isRecording) return;
    if (_isLocked) return;
    _finishRecording();
  }

  /// Cancels a locked recording and deletes the file.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    HapticService.medium();
    try {
      await _recorder.cancel();
    } catch (_) {}
    _deleteFile();
    _reset();
  }

  /// Sends a locked recording directly without preview.
  Future<void> sendRecording() async {
    if (!_isRecording) return;
    HapticService.medium();
    await _stopRecorder();
    final path = _path;
    final durationMs = _elapsed.inMilliseconds;
    _reset();
    if (path != null) _onSend(path, durationMs: durationMs);
  }

  /// Stops recording and opens the preview capsule (used by the stop square).
  Future<void> stopToPreview() => _finishRecording(minDuration: const Duration(milliseconds: 250));

  Future<void> _finishRecording({Duration? minDuration}) async {
    if (!_isRecording) return;
    await _stopRecorder();
    final path = _path;
    final elapsed = _elapsed;
    if (path == null) {
      _reset();
      return;
    }
    if (elapsed < (minDuration ?? _minDuration)) {
      // Too short to be useful: silently discard.
      _deleteFile();
      _reset();
      return;
    }
    _isRecording = false;
    _isPaused = false;
    _isLocked = false;
    _slideCancel = false;
    _isPreviewing = true;
    _previewPosition = Duration.zero;
    _previewDuration = elapsed;
    notifyListeners();
  }

  Future<void> _stopRecorder() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  // ── Preview controls ──────────────────────────────────────────────────

  Future<void> togglePreviewPlayback() async {
    if (!_isPreviewing) return;
    final path = _path;
    if (path == null) return;
    try {
      if (_isPlayingPreview) {
        await _player.pause();
        _isPlayingPreview = false;
        notifyListeners();
        return;
      }
      if (_previewPosition >= _previewDuration &&
          _previewDuration > Duration.zero) {
        await _player.seek(Duration.zero);
        _previewPosition = Duration.zero;
      }
      _posSub ??= _player.onPositionChanged.listen((p) {
        if (!_isPreviewing || _disposed) return;
        _previewPosition = p;
        notifyListeners();
      });
      _durationSub ??= _player.onDurationChanged.listen((d) {
        if (d.inMilliseconds > 0) _previewDuration = d;
      });
      _completeSub ??= _player.onPlayerComplete.listen((_) {
        if (!_isPreviewing || _disposed) return;
        _isPlayingPreview = false;
        _previewPosition = _previewDuration;
        notifyListeners();
      });
      await _player.play(DeviceFileSource(path));
      _isPlayingPreview = true;
      notifyListeners();
    } catch (_) {}
  }

  void seekPreview(double fraction) {
    if (!_isPreviewing || _previewDuration.inMilliseconds <= 0) return;
    final target = Duration(
        milliseconds: (_previewDuration.inMilliseconds * fraction).round());
    _previewPosition = target;
    _player.seek(target);
    notifyListeners();
  }

  /// Discards the preview and deletes the file.
  Future<void> deletePreview() async {
    if (!_isPreviewing) return;
    HapticService.medium();
    await _player.stop();
    _previewPosition = Duration.zero;
    _previewDuration = Duration.zero;
    _deleteFile();
    _reset();
  }

  /// Sends the previewed voice note.
  Future<void> sendPreview() async {
    if (!_isPreviewing) return;
    HapticService.medium();
    await _player.stop();
    final path = _path;
    final durationMs = _previewDuration.inMilliseconds;
    _reset();
    if (path != null) _onSend(path, durationMs: durationMs);
  }

  void _deleteFile() {
    final p = _path;
    _path = null;
    if (p != null) {
      try {
        File(p).deleteSync();
      } catch (_) {}
    }
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    _ampSub?.cancel();
    _ampSub = null;
    _isRecording = false;
    _isPaused = false;
    _isLocked = false;
    _slideCancel = false;
    _slideDx = 0;
    _isPreviewing = false;
    _isPlayingPreview = false;
    _path = null;
    _startedAt = null;
    _elapsed = Duration.zero;
    _previewPosition = Duration.zero;
    _previewDuration = Duration.zero;
    _wave.clear();
    notifyListeners();
  }

  static String _format(Duration d) {
    final s = d.inSeconds;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _ampSub?.cancel();
    _posSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }
}

/// Shared Instagram-style voice note capsule UI:
/// Top capsule pill: [Stop / Play-Pause] [Waveform Bars] [00:01]
/// Bottom row: [Trash Delete]       (clean empty middle)       [Send Pill]
class _VoiceCapsuleBar extends StatelessWidget {
  final Color accent;
  final Widget leadingControl;
  final List<double> waveLevels;
  final double progress;
  final String timerText;
  final VoidCallback onDelete;
  final VoidCallback onSend;
  final void Function(double fraction)? onSeek;

  const _VoiceCapsuleBar({
    required this.accent,
    required this.leadingControl,
    required this.waveLevels,
    required this.progress,
    required this.timerText,
    required this.onDelete,
    required this.onSend,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trashColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top rounded capsule pill
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                leadingControl,
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      Widget wave = WaveformBars(
                        levels: waveLevels,
                        progress: progress,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white.withValues(alpha: 0.35),
                        height: 24,
                      );
                      if (onSeek != null && constraints.maxWidth > 0) {
                        wave = GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) => onSeek!(
                              (d.localPosition.dx / constraints.maxWidth)
                                  .clamp(0.0, 1.0)),
                          onHorizontalDragUpdate: (d) => onSeek!(
                              (d.localPosition.dx / constraints.maxWidth)
                                  .clamp(0.0, 1.0)),
                          child: wave,
                        );
                      }
                      return wave;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  timerText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Bottom controls: Trash (left) ... Empty middle ... Send pill (right)
          Row(
            children: [
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: trashColor,
                  size: 25,
                ),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 64,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live recording bar matching the reference capsule pill + trash/send row.
class VoiceRecordingBar extends StatelessWidget {
  final VoiceRecorderController controller;

  const VoiceRecordingBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final accent = ChatThemeScope.accentOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return _VoiceCapsuleBar(
          accent: controller.slideCancel ? AppTheme.errorRed : accent,
          leadingControl: GestureDetector(
            onTap: controller.stopToPreview,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          waveLevels: controller.wave,
          progress: 1.0,
          timerText: controller.timerText,
          onDelete: controller.cancelRecording,
          onSend: controller.sendRecording,
        );
      },
    );
  }
}

/// Pre-send preview: playback with real position, seekable wave, delete and send.
class VoicePreviewBar extends StatelessWidget {
  final VoiceRecorderController controller;

  const VoicePreviewBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final accent = ChatThemeScope.accentOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return _VoiceCapsuleBar(
          accent: accent,
          leadingControl: GestureDetector(
            onTap: controller.togglePreviewPlayback,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                controller.isPlayingPreview
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          waveLevels: controller.wave,
          progress: controller.previewProgress,
          timerText: controller.isPlayingPreview
              ? controller.previewPositionText
              : controller.previewDurationText,
          onDelete: controller.deletePreview,
          onSend: controller.sendPreview,
          onSeek: controller.seekPreview,
        );
      },
    );
  }
}

/// Animated waveform bars driven by real amplitude levels (recording) or by
/// playback progress (preview).
class WaveformBars extends StatelessWidget {
  final List<double> levels;
  final double progress;
  final Color activeColor;
  final Color? inactiveColor;
  final double height;

  const WaveformBars({
    super.key,
    required this.levels,
    required this.progress,
    required this.activeColor,
    this.inactiveColor,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    final dimColor =
        inactiveColor ?? AppTheme.textSecondary(context).withValues(alpha: 0.25);
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < levels.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              width: 3,
              height: 4 + (levels[i] * (height - 6)).clamp(0.0, height - 6),
              decoration: BoxDecoration(
                color: (i / levels.length) <= progress
                    ? activeColor
                    : dimColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
