import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/app_state.dart';
import '../theme/app_theme.dart';
import 'model_picker.dart';

/// 底部输入栏（模型快捷切换 + 发送 / 停止）
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

  void _showVoicePlaceholder(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎙️ 语音输入'),
        content: const Text('语音输入马上就来啦，先用打字聊天吧～'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 12),
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
            // 模型快捷切换
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ModelShortcutChip(
                hasApi: app.hasApi,
                model: app.activeModel,
                onTap: () => showModelPicker(context, app),
              ),
            ),
            const SizedBox(width: 8),
            // 输入框
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: TextStyle(fontSize: 15.5, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: app.hasApi ? '随便说点什么…' : '先在设置里接个接口吧',
                  hintStyle: TextStyle(color: scheme.outline),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            // 语音输入入口（麦克风，占位）
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _MicButton(
                onTap: () => _showVoicePlaceholder(context),
              ),
            ),
            const SizedBox(width: 6),
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
                      gradient: const [
                        AppColors.brandGradientStart,
                        AppColors.brandGradientEnd,
                      ],
                      onTap: _send,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 输入框左侧的模型快捷按钮（✨ + 模型名）
class _ModelShortcutChip extends StatelessWidget {
  final bool hasApi;
  final String model;
  final VoidCallback onTap;
  const _ModelShortcutChip({
    required this.hasApi,
    required this.model,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainerHigh
              : scheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasApi
                ? AppColors.primary.withValues(alpha: 0.25)
                : scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 15,
              color: hasApi ? AppColors.primary : scheme.outlineVariant,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 74),
              child: Text(
                model.isNotEmpty ? model : '模型',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasApi ? scheme.onSurface : scheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more,
                size: 14,
                color: hasApi ? scheme.onSurfaceVariant : scheme.outline),
          ],
        ),
      ),
    );
  }
}

/// 麦克风按钮（语音输入入口占位）
class _MicButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MicButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(Icons.mic_none, size: 20, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final List<Color>? gradient;
  final VoidCallback onTap;
  const _RoundButton({
    super.key,
    required this.icon,
    this.color,
    this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (gradient != null) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: gradient!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      );
    } else {
      decoration = BoxDecoration(color: color!, shape: BoxShape.circle);
    }
    return Material(
      shape: const CircleBorder(),
      child: Ink(
        decoration: decoration,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
