import 'package:flutter/material.dart';

import '../models/chat_conversation.dart';
import '../theme/app_theme.dart';

/// 聊天气泡（用户 / AI 两套样式）
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    if (isUser) {
      return _UserBubble(message: message);
    }
    return _AiBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: SelectionArea(
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final ChatMessage message;
  const _AiBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 错误样式
    if (message.isError) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(right: 48, top: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.content,
                  style: TextStyle(fontSize: 14, color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // AI 头像 + 内容
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(isDark: isDark),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(right: 24, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainerHigh
                    : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.content.isEmpty && message.isStreaming)
                    const _TypingIndicator()
                  else
                    SelectionArea(
                      child: Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.5,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  if (message.isStreaming && message.content.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: _TypingIndicatorLine(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 圆形 AI 头像
class _Avatar extends StatelessWidget {
  final bool isDark;
  const _Avatar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome, size: 15, color: Colors.white),
    );
  }
}

/// 三点闪烁打字指示器（无文字时）
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value * 3 + i) % 3;
            final scale = 0.6 + phase * 0.4;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: 0.5 + phase * 0.5,
                child: Container(
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 尾部光标（文字已出现时的闪烁下划线）
class _TypingIndicatorLine extends StatelessWidget {
  const _TypingIndicatorLine();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 5,
      height: 14,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}