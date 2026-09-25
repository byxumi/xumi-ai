import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/app_state.dart';

/// 底部输入栏（含发送 / 停止按钮）
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<AppState>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surface.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 输入框
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: TextStyle(fontSize: 15.5, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: app.hasApi ? '输入消息…' : '请先在「设置」配置 API',
                  hintStyle: TextStyle(color: scheme.outline),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            // 发送 / 停止
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: app.isGenerating
                  ? _RoundButton(
                      key: const ValueKey('stop'),
                      icon: Icons.stop_rounded,
                      color: scheme.error,
                      onTap: () => app.stopGenerating(),
                    )
                  : _RoundButton(
                      key: const ValueKey('send'),
                      icon: Icons.send_rounded,
                      color: scheme.primary,
                      onTap: _send,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}