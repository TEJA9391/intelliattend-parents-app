import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:intelli_attend_faculty/Data/Models/Messaging/messaging_models.dart';
import 'package:intelli_attend_faculty/Theme/app_theme.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/attachment_bubble.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/chat_theme.dart';
import 'package:intelli_attend_faculty/Presentation/Features/Messaging/Widgets/peer_avatar.dart';

/// Renders one message bubble (Instagram-DM pill style — message text/content only,
/// no timestamps or pointed tails). Handles tap (selection mode) and long-press.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOutgoing;
  final bool showTail;
  final bool showAvatar;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onCancelUpload;
  final VoidCallback? onRetry;
  final void Function(String emoji)? onReact;
  final VoidCallback? onReactMore;
  final VoidCallback? onReplyTap;
  final VoidCallback? onThreadTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.showTail = true,
    this.showAvatar = false,
    this.onLongPress,
    this.onTap,
    this.onDoubleTap,
    this.onCancelUpload,
    this.onRetry,
    this.onReact,
    this.onReactMore,
    this.onReplyTap,
    this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _SystemMessage(message: message);
    }
    if (message.isDeletedForEveryone) {
      return _DeletedMessage(message: message, isOutgoing: isOutgoing);
    }
    if (message.isDeletedForMe && !isOutgoing) {
      return _DeletedMessage(message: message, isOutgoing: isOutgoing);
    }

    final accent = ChatThemeScope.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = ChatThemeScope.glassOf(context);
    final incomingBubble =
        isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF);
    final bubbleColor = isOutgoing
        ? accent
        : glass
            ? (isDark
                ? const Color(0xFF262626).withValues(alpha: 0.78)
                : const Color(0xFFEFEFEF).withValues(alpha: 0.85))
            : incomingBubble;
    final textColor =
        isOutgoing ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A));
    final secondaryText = isOutgoing
        ? Colors.white70
        : (isDark ? Colors.white70 : const Color(0xFF64748B));
    final selectionColor = isOutgoing ? Colors.white : accent;
    final selected = message.isSelected;
    final isPinnedMessage = message.isPinned;

    // Smooth pill corners: tighter inner corner when grouped (not last in run)
    final groupedCorner = showTail ? 20.0 : 6.0;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOutgoing) ...[
                const SizedBox(width: 8),
                if (showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: PeerAvatar(
                      name: message.senderName,
                      radius: 13,
                    ),
                  )
                else
                  const SizedBox(width: 26),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  onDoubleTap: onDoubleTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                      left: isOutgoing ? 54 : 6,
                      right: isOutgoing ? 10 : 16,
                      top: 2,
                      bottom: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                  decoration: BoxDecoration(
                    color: selected
                        ? selectionColor.withValues(alpha: 0.22)
                        : bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          Radius.circular(isOutgoing ? 20 : groupedCorner),
                      bottomRight:
                          Radius.circular(isOutgoing ? groupedCorner : 20),
                    ),
                    border: selected
                        ? Border.all(color: selectionColor, width: 2)
                        : glass
                            ? Border.all(
                                color: Colors.white
                                    .withValues(alpha: isDark ? 0.10 : 0.55),
                                width: 0.6,
                              )
                            : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.replyTo != null)
                        _ReplyPreview(
                          message.replyTo!,
                          isOutgoing: isOutgoing,
                          textColor: textColor,
                          onTap: onReplyTap,
                        ),
                      if (onThreadTap != null && message.threadCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: GestureDetector(
                            onTap: onThreadTap,
                            child: Text(
                                '${message.threadCount} reply${message.threadCount == 1 ? '' : 's'}',
                                style: GoogleFonts.inter(
                                    color: isOutgoing ? Colors.white70 : accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      if (message.isForwarded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Forwarded',
                              style: GoogleFonts.inter(
                                  color: isOutgoing ? Colors.white70 : accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                      if (isPinnedMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin_rounded,
                                  size: 12,
                                  color: isOutgoing ? Colors.white70 : accent),
                              const SizedBox(width: 3),
                              Text('Pinned',
                                  style: GoogleFonts.inter(
                                      color:
                                          isOutgoing ? Colors.white70 : accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      if (message.attachments.isNotEmpty)
                        for (final att in message.attachments)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: AttachmentBubble(
                              attachment: att,
                              bubbleColor: bubbleColor,
                              textColor: textColor,
                              isOutgoing: isOutgoing,
                            ),
                          ),
                      if (message.text.isNotEmpty)
                        _MessageText(message: message, color: textColor),
                      if (message.isUploading && onCancelUpload != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 78,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    value: message.uploadProgress > 0
                                        ? message.uploadProgress
                                        : null,
                                    backgroundColor: isOutgoing
                                        ? Colors.white24
                                        : AppTheme.border(context)
                                            .withValues(alpha: 0.5),
                                    color: isOutgoing ? Colors.white : accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(message.uploadProgress * 100).clamp(0, 100).round()}%',
                                style: GoogleFonts.inter(
                                    color: secondaryText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: onCancelUpload,
                                child: Icon(Icons.close_rounded,
                                    size: 15, color: secondaryText),
                              ),
                            ],
                          ),
                        )
                      else if (isOutgoing &&
                          message.status == MessageStatus.failed &&
                          onRetry != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: onRetry,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded,
                                    size: 14, color: secondaryText),
                                const SizedBox(width: 4),
                                Text('Tap to retry',
                                    style: GoogleFonts.inter(
                                        color: secondaryText, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: isOutgoing ? 0 : 44,
                right: isOutgoing ? 18 : 0,
                top: 2,
              ),
              child: _ReactionChips(
                reactions: message.reactions,
                onTap: onReact,
                onMore: onReactMore,
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageText extends StatelessWidget {
  final ChatMessage message;
  final Color color;

  const _MessageText({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = message.text;
    final uriPattern = RegExp(r'(https?://[^\s]+)');
    final segments = text.split(uriPattern);
    final hasLinks = uriPattern.hasMatch(text);

    Widget child;
    if (hasLinks) {
      child = Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        children: segments.map((s) {
          if (uriPattern.hasMatch(s)) {
            return GestureDetector(
              onTap: () => _openLink(s),
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: const Icon(Icons.language_rounded, size: 12),
                    ),
                    TextSpan(
                      text: s,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.92),
                        decoration: TextDecoration.underline,
                        decorationColor: color.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                style: _style,
              ),
            );
          }
          return Text(s, style: _style);
        }).toList(),
      );
    } else {
      child = Text(text, style: _style);
    }

    return child;
  }

  TextStyle get _style => GoogleFonts.inter(
        color: color,
        fontSize: 14.5,
        height: 1.35,
      );

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _ReplyPreview extends StatelessWidget {
  final ReplyPreview reply;
  final bool isOutgoing;
  final Color textColor;
  final VoidCallback? onTap;

  const _ReplyPreview(this.reply,
      {required this.isOutgoing, required this.textColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = ChatThemeScope.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewBg = isOutgoing
        ? Colors.white12
        : (isDark ? Colors.white10 : AppTheme.surface(context));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: previewBg,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: isOutgoing ? Colors.white : accent,
              width: 3,
            ),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 230),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reply.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: isOutgoing ? Colors.white : accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    reply.type.isFile || reply.type == MessageContentType.image
                        ? reply.type.isFile
                            ? '📎 ${reply.text}'
                            : '📷 ${reply.text}'
                        : reply.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: isOutgoing
                            ? Colors.white70
                            : (isDark ? Colors.white70 : AppTheme.textSecondary(context)),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.subdirectory_arrow_left_rounded,
                  size: 16, color: isOutgoing ? Colors.white54 : accent),
            ],
          ],
        ),
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final ChatMessage message;

  const _SystemMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DeletedMessage extends StatelessWidget {
  final ChatMessage message;
  final bool isOutgoing;

  const _DeletedMessage({required this.message, required this.isOutgoing});

  @override
  Widget build(BuildContext context) {
    final color = isOutgoing ? Colors.white70 : AppTheme.textSecondary(context);
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: isOutgoing ? 48 : 8, right: isOutgoing ? 8 : 48, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutgoing
              ? AppTheme.primary(context).withValues(alpha: 0.85)
              : AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_forever_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              message.isDeletedForEveryone ? 'This message was deleted' : 'You deleted this message',
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// WhatsApp-style reaction chips rendered below the bubble. Tapping a chip
/// toggles it; the trailing "+" opens the full emoji picker.
class _ReactionChips extends StatelessWidget {
  final List<String> reactions;
  final void Function(String emoji)? onTap;
  final VoidCallback? onMore;

  const _ReactionChips({
    required this.reactions,
    this.onTap,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ChatThemeScope.accentOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in reactions)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: GestureDetector(
                onTap: () => onTap?.call(e),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 3),
                      Text(
                        '${reactions.where((x) => x == e).length}',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.border(context).withValues(alpha: 0.6)),
              ),
              child: Icon(Icons.add_rounded,
                  size: 14, color: AppTheme.textSecondary(context)),
            ),
          ),
      ],
    );
  }
}
