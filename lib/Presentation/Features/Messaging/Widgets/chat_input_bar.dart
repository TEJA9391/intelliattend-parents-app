import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intelli_attend_faculty/Services/haptic_service.dart';
import 'package:intelli_attend_faculty/Services/permission_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intelli_attend_faculty/Data/Models/Messaging/messaging_models.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/attachment_preview_sheet.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/attachment_sheet.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/chat_theme.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/voice_recorder.dart';
import 'package:intelli_attend_faculty/Theme/app_theme.dart';

/// Premium bottom composer:
///
///   [Emoji] [Attach] [expandable field] [Camera] [Mic ⇄ Send]
///
/// - No text  → camera shortcut + hold-to-record mic.
/// - Typing   → mic becomes a send button, a toolbar (undo/redo/paste/
///   mention) + character counter appears, and a typing indicator is
///   broadcast to the backend via [onTextChanged].
/// - Field grows to six lines, supports paste, `@`-mentions with an inline
///   picker, reply preview chips and auto-focus when replying.
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final ValueChanged<ChatAttachment> onSendAttachment;
  final void Function(String path, {int? durationMs}) onSendVoice;
  final ValueChanged<String> onTextChanged;
  final ChatMessage? replyTarget;
  final VoidCallback onClearReply;
  final bool blocked;
  final List<String> mentionSuggestions;

  /// Broadcast when the local voice-note recording starts / stops, so the
  /// peer sees the realtime "Recording audio…" presence state.
  final ValueChanged<bool>? onVoiceRecording;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendAttachment,
    required this.onSendVoice,
    required this.onTextChanged,
    this.replyTarget,
    required this.onClearReply,
    this.blocked = false,
    this.mentionSuggestions = const [],
    this.onVoiceRecording,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final FocusNode _focusNode = FocusNode();
  late final UndoHistoryController _undoHistory;

  late final VoiceRecorderController _voice;
  bool _voiceRecordingWasOn = false;

  @override
  void initState() {
    super.initState();
    _voice = VoiceRecorderController(
      onSend: (path, {durationMs}) =>
          widget.onSendVoice(path, durationMs: durationMs),
    )..addListener(_onVoiceChanged);
    _undoHistory = UndoHistoryController();
  }

  void _onVoiceChanged() {
    final recording = _voice.isRecording;
    if (recording != _voiceRecordingWasOn) {
      _voiceRecordingWasOn = recording;
      widget.onVoiceRecording?.call(recording);
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-focus the composer the moment a reply is queued.
    if (oldWidget.replyTarget == null && widget.replyTarget != null) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoiceChanged);
    _voice.dispose();
    _undoHistory.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  // ── Sending ───────────────────────────────────────────────────────────

  void _send() {
    final text = widget.controller.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    widget.controller.clear();
    widget.onTextChanged('');
    setState(() {});
    // Keep keyboard open continuously for fast multi-message replies
    _focusNode.requestFocus();
  }

  void _notifyChanged(String value) {
    widget.onTextChanged(value);
    setState(() {});
  }

  // ── Voice recording ───────────────────────────────────────────────────

  Future<void> _beginVoice() async {
    if (_voice.isRecording || _voice.isPreviewing) return;
    final allowed = await PermissionService().ensureFeaturePermission(
      context,
      AppPermissionType.microphone,
      featureName: 'voice messages',
    );
    if (!allowed || !mounted) return;
    HapticService.medium();
    await _voice.startRecording();
  }

  Widget _micControl(BuildContext context) {
    final accent = ChatThemeScope.accentOf(context);
    return GestureDetector(
      onTap: _beginVoice,
      onLongPressStart: (_) => _beginVoice(),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
    );
  }

  // ── Camera shortcut ───────────────────────────────────────────────────

  Future<void> _openCamera() async {
    HapticService.light();
    final allowed = await PermissionService().ensureFeaturePermission(
      context,
      AppPermissionType.camera,
      featureName: 'camera attachments',
    );
    if (!allowed || !mounted) return;
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (result == null || !mounted) return;
    final file = File(result.path);
    widget.onSendAttachment(ChatAttachment(
      id: 'att_${DateTime.now().microsecondsSinceEpoch}',
      name: result.name,
      type: MessageContentType.image,
      mimeType: result.mimeType ?? 'image/jpeg',
      localPath: result.path,
      sizeBytes: file.lengthSync(),
    ));
  }

  /// Returns the start index + query of the active `@mention` (the last
  /// `@` token before the caret), or null when none is being typed.
  (int, String)? _activeMention() {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (!sel.isValid) return null;
    final caret = sel.extentOffset.clamp(0, text.length);
    for (int i = caret - 1; i >= 0; i--) {
      final ch = text[i];
      if (ch == '@') {
        final prev = i == 0 ? ' ' : text[i - 1];
        if (prev != ' ' && prev != '\n') return null;
        final query = text.substring(i + 1, caret);
        if (query.contains(' ')) return null;
        return (i, query);
      }
      if (ch == ' ' || ch == '\n') return null;
    }
    return null;
  }

  void _selectMention(String name) {
    final m = _activeMention();
    if (m == null) return;
    final controller = widget.controller;
    final caret = controller.selection.isValid
        ? controller.selection.extentOffset
        : controller.text.length;
    final newText = controller.text.replaceRange(m.$1, caret, '@$name ');
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: m.$1 + name.length + 2),
    );
    _notifyChanged(newText);
    _focusNode.requestFocus();
  }

  Future<void> _openAttachmentSheet() async {
    HapticService.medium();
    final attachments = await showModalBottomSheet<List<ChatAttachment>>(
      context: context,
      backgroundColor: AppTheme.card(context),
      showDragHandle: true,
      builder: (_) => const AttachmentSheet(),
    );
    if (attachments == null || attachments.isEmpty || !mounted) return;

    final confirmed = await showModalBottomSheet<List<ChatAttachment>>(
      context: context,
      backgroundColor: AppTheme.card(context),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => AttachmentPreviewSheet(attachments: attachments),
    );
    if (confirmed == null || !mounted) return;

    for (final attachment in confirmed) {
      widget.onSendAttachment(attachment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ChatThemeScope.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = ChatThemeScope.glassOf(context);
    final mention = _activeMention();
    final mentionQuery = (mention?.$2 ?? '').trim().toLowerCase();
    final mentionList = mention == null
        ? const <String>[]
        : widget.mentionSuggestions
            .where((s) => s.toLowerCase().contains(mentionQuery))
            .toList();

    if (widget.blocked) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Container(
          width: double.infinity,
          color: AppTheme.card(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.block_rounded, color: AppTheme.errorRed, size: 20),
              const SizedBox(width: 10),
              Text('You can\'t send messages to this chat',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary(context), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final pillBg = isDark
        ? const Color(0xFF1F2C34).withValues(alpha: glass ? 0.92 : 1.0)
        : Colors.white.withValues(alpha: glass ? 0.95 : 1.0);
    final pillTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final pillSecondaryColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final pillBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    final bar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyTarget != null)
          _ReplyChip(reply: widget.replyTarget!, onCancel: widget.onClearReply),
        if (_voice.isRecording)
          VoiceRecordingBar(controller: _voice)
        else if (_voice.isPreviewing)
          VoicePreviewBar(controller: _voice)
        else ...[
          if (mention != null && mentionList.isNotEmpty)
            _MentionPanel(
              suggestions: mentionList,
              onSelect: _selectMention,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // WhatsApp-style floating rounded pill: [Message ...  📎  📷]
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: pillBorderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            undoController: _undoHistory,
                            onChanged: _notifyChanged,
                            onTapOutside: (_) => _focusNode.unfocus(),
                            maxLines: 6,
                            minLines: 1,
                            cursorColor: accent,
                            textCapitalization: TextCapitalization.sentences,
                            style: GoogleFonts.inter(
                              color: pillTextColor,
                              fontSize: 15,
                              height: 1.3,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Message',
                              hintStyle: GoogleFonts.inter(
                                color: pillSecondaryColor,
                                fontSize: 15,
                              ),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.fromLTRB(18, 12, 4, 12),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Attach',
                          icon: Icon(
                            Icons.attach_file_rounded,
                            color: pillSecondaryColor,
                            size: 22,
                          ),
                          onPressed: _openAttachmentSheet,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(
                              minWidth: 38, minHeight: 46),
                        ),
                        if (!_hasText)
                          IconButton(
                            tooltip: 'Camera',
                            icon: Icon(
                              Icons.camera_alt_rounded,
                              color: pillSecondaryColor,
                              size: 22,
                            ),
                            onPressed: _openCamera,
                            padding: const EdgeInsets.only(
                                left: 2, right: 10, top: 6, bottom: 6),
                            constraints: const BoxConstraints(
                                minWidth: 40, minHeight: 46),
                          )
                        else
                          const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Separate round circular button: Send when typing, Mic when empty
                if (_hasText)
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                else
                  _micControl(context),
              ],
            ),
          ),
        ],
      ],
    );

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return TextFieldTapRegion(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: bar,
      ),
    );
  }
}

class _MentionPanel extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  const _MentionPanel({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      constraints: const BoxConstraints(maxHeight: 176),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.border(context)),
        itemBuilder: (context, index) {
          final name = suggestions[index];
          return InkWell(
            onTap: () => onSelect(name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primary(context).withValues(alpha: 0.15),
                    child: Icon(Icons.person_rounded, size: 16, color: AppTheme.primary(context)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('@$name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: AppTheme.text(context), fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReplyChip extends StatelessWidget {
  final ChatMessage reply;
  final VoidCallback onCancel;

  const _ReplyChip({required this.reply, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final accent = ChatThemeScope.accentOf(context);
    return Container(
      color: AppTheme.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Replying to ${reply.senderName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: accent, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text(reply.contentSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary(context), size: 20),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
