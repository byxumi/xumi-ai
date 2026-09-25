import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/app_state.dart';
import '../models/chat_conversation.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/message_bubble.dart';
import 'settings_screen.dart';

/// 主聊天页面
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  bool _showScrollBtn = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    animate
        ? _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
        : _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final messages = app.activeMessages;

    return Scaffold(
      drawer: const ConversationDrawer(),
      appBar: _buildAppBar(context, app, scheme),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(
                    model: app.activeModel,
                    hasApi: app.hasApi,
                    generating: app.isGenerating,
                    onSubmit: (t) => app.sendMessage(t),
                    onOpenSettings: () =>
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  )
                : _MessageList(
                    messages: messages,
                    controller: _scrollController,
                    onScrollChange: (show) =>
                        setState(() => _showScrollBtn = show),
                  ),
          ),
          if (_showScrollBtn)
            _ScrollToBottomButton(
              onTap: () => _scrollToBottom(),
            ),
          const ChatInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppState app, ColorScheme scheme) {
    final model = app.activeModel;
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '须弥AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (model.isNotEmpty)
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    model,
                    style: TextStyle(fontSize: 11, color: scheme.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        // 模型快速切换（下拉）
        IconButton(
          icon: const Icon(Icons.auto_awesome, size: 20),
          tooltip: '切换模型',
          onPressed: () => _showModelPicker(context, app),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: '设置',
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }

  void _showModelPicker(BuildContext context, AppState app) {
    final profile = app.activeProfile;
    final models = profile?.models ?? [];
    if (profile == null || models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profile == null ? '请先在设置中添加接口' : '该接口暂无可切换模型'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '选择模型',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: models.length,
                itemBuilder: (context, i) {
                  final m = models[i];
                  final selected = m == app.activeModel;
                  return ListTile(
                    leading: Icon(
                      selected ? Icons.auto_awesome : Icons.view_in_ar,
                      size: 20,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(m, style: const TextStyle(fontSize: 15)),
                    trailing: selected
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      app.selectModel(m);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 消息列表
class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController controller;
  final ValueChanged<bool> onScrollChange;
  const _MessageList({
    required this.messages,
    required this.controller,
    required this.onScrollChange,
  });

  @override
  Widget build(BuildContext context) {
    // 在列表变化后滚到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        final max = controller.position.maxScrollExtent;
        // 若用户接近底部或正在生成，则自动跟随
        if (controller.position.pixels >= max - 120) {
          controller.animateTo(
            max,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical) {
          final nearBottom = n.metrics.pixels >= n.metrics.maxScrollExtent - 80;
          onScrollChange(!nearBottom);
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        itemCount: messages.length,
        itemBuilder: (context, i) {
          return MessageBubble(message: messages[i]);
        },
      ),
    );
  }
}

/// 滚到底部按钮
class _ScrollToBottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
        ),
      ),
    );
  }
}

/// 空态聊天页（欢迎 + 快捷建议）
class _EmptyChat extends StatelessWidget {
  final String model;
  final bool hasApi;
  final bool generating;
  final ValueChanged<String> onSubmit;
  final VoidCallback onOpenSettings;
  const _EmptyChat({
    required this.model,
    required this.hasApi,
    required this.generating,
    required this.onSubmit,
    required this.onOpenSettings,
  });

  static const _suggestions = [
    '用简单的语言解释什么是量子纠缠',
    '帮我写一首关于夏天的短诗',
    '给出一周健身计划',
    'Explain how photosynthesis works in one paragraph',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          // Logo
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            '须弥AI',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasApi ? '你好，我是须弥AI，有什么可以帮你？' : '请先配置 API 接口开始对话',
            style: TextStyle(fontSize: 15, color: scheme.outline),
            textAlign: TextAlign.center,
          ),
          if (model.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '当前模型：$model',
                style: TextStyle(fontSize: 12, color: scheme.primary),
              ),
            ),
          const SizedBox(height: 32),
          if (!hasApi)
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('去配置接口'),
            )
          else
            ..._suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SuggestionChip(
                    text: s,
                    onSubmit: onSubmit,
                    disabled: generating,
                  ),
                )),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final ValueChanged<String> onSubmit;
  final bool disabled;
  const _SuggestionChip({
    required this.text,
    required this.onSubmit,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disabled ? null : () => onSubmit(text),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.north_east,
                  size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}