import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/app_state.dart';
import '../models/chat_conversation.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_avatar.dart';
import '../widgets/model_picker.dart';
import 'settings_screen.dart';

/// 主聊天页面（v2 消费级风格：首页欢迎 + 灵感话题 + 模型大厅）
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
                ? _HomeView(
                    app: app,
                    onSubmit: (t) => app.sendMessage(t),
                    onOpenSettings: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
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
      title: GestureDetector(
        onTap: () => showModelPicker(context, app),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.brandGradientStart,
                    AppColors.brandGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '须弥AI',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                if (model.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          model,
                          style:
                              TextStyle(fontSize: 11, color: scheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.expand_more,
                          size: 13, color: scheme.outline),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: '设置',
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
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

/// 灵感话题数据
class _InspirationTopic {
  final String emoji;
  final String title;
  final String prompt;
  const _InspirationTopic(this.emoji, this.title, this.prompt);
}

/// 首页欢迎视图（无消息时的空态，消费级风格）
class _HomeView extends StatefulWidget {
  final AppState app;
  final ValueChanged<String> onSubmit;
  final VoidCallback onOpenSettings;
  const _HomeView({
    required this.app,
    required this.onSubmit,
    required this.onOpenSettings,
  });

  static const _topics = [
    _InspirationTopic('✍️', '帮我写文案', '帮我写一条更有吸引力的产品宣传文案，产品是：'),
    _InspirationTopic('🌍', '翻译小助手', '请把下面这句话翻译成英文，并简短说明语气：'),
    _InspirationTopic('💻', '编程助手', '帮我写一段简洁的代码，实现：'),
    _InspirationTopic('📖', '科普达人', '用最通俗的话给我解释：'),
    _InspirationTopic('🧠', '头脑风暴', '围绕这个主题给我 10 个有趣的创意：'),
    _InspirationTopic('📝', '文章总结', '把下面这段内容总结成 3 个要点：'),
  ];

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  /// 换一批的 seed（0 表示原始顺序）
  int _topicSeed = 0;

  /// 每次打开随机一句轻松的问候语
  late final String _subtitle = const [
    '今天想聊点什么？写写、翻译、查资料，都可以问我～',
    '随便聊聊也行，写作、翻译、编程、科普我都行～',
    '想聊什么都可以，我超会接话的～',
  ][Random().nextInt(3)];

  AppState get app => widget.app;
  ValueChanged<String> get onSubmit => widget.onSubmit;
  VoidCallback get onOpenSettings => widget.onOpenSettings;

  /// 按当前 seed 重新洗牌灵感话题
  List<_InspirationTopic> get _topics {
    if (_topicSeed == 0) return _HomeView._topics;
    final copy = List<_InspirationTopic>.from(_HomeView._topics);
    copy.shuffle(Random(_topicSeed));
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasApi = app.hasApi;
    final model = app.activeModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 欢迎渐变 Hero =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.brandGradientStart,
                  AppColors.brandGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hi，我是须弥AI 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                // 当前模型 pill（点击切换）
                GestureDetector(
                  onTap: () => showModelPicker(context, app),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 7),
                        Text(
                          model.isNotEmpty ? model : '选择模型',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more,
                            color: Colors.white70, size: 17),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!hasApi) ...[
            // ===== 未配置接口引导 =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? scheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.wifi_tethering,
                      size: 40, color: scheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  const Text(
                    '还没接上 AI 呢',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '在设置里接一个 OpenAI 兼容接口（DeepSeek / 豆包 / 自定义）就能开聊啦',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.outline,
                        height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('去接一个'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ===== 灵感话题 =====
            Row(
              children: [
                Text(
                  '灵感话题',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _topicSeed++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shuffle, size: 13, color: scheme.primary),
                        const SizedBox(width: 3),
                        Text(
                          '换一批',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.35,
              children: [
                for (final t in _topics)
                  _TopicCard(topic: t, onSubmit: onSubmit),
              ],
            ),
            const SizedBox(height: 24),
            // ===== 模型大厅 =====
            Row(
              children: [
                Text(
                  '模型大厅',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => showModelPicker(context, app),
                  child: Text(
                    '全部 ›',
                    style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ModelHall(app: app),
          ],
        ],
      ),
    );
  }
}

/// 灵感话题卡片
class _TopicCard extends StatelessWidget {
  final _InspirationTopic topic;
  final ValueChanged<String> onSubmit;
  const _TopicCard({required this.topic, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? scheme.surfaceContainer : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSubmit(topic.prompt),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(topic.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  topic.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 模型大厅：横向模型卡片（跨接口）
class _ModelHall extends StatelessWidget {
  final AppState app;
  const _ModelHall({required this.app});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeProfileId = app.settings.activeProfileId;
    final activeModel = app.activeModel;

    // 收集所有接口下的所有模型
    final entries = <({String profileId, String profileName, String model})>[];
    for (final p in app.profiles) {
      for (final m in p.models) {
        entries.add((profileId: p.id, profileName: p.name, model: m));
      }
    }

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainer : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.extension, color: scheme.outlineVariant),
            const SizedBox(width: 10),
            Text(
              '还没添加模型，去设置里加几个吧',
              style: TextStyle(fontSize: 13, color: scheme.outline),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final e = entries[i];
          final selected =
              e.profileId == activeProfileId && e.model == activeModel;
          return GestureDetector(
            onTap: () async {
              await app.selectProfile(e.profileId);
              await app.selectModel(e.model);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('已切换：${e.model}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
              }
            },
            child: Container(
              width: 138,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? scheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : scheme.outlineVariant.withValues(alpha: 0.35),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ModelAvatar(model: e.model, size: 30),
                      const Spacer(),
                      if (selected)
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 17),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    e.model,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    e.profileName,
                    style: TextStyle(fontSize: 10.5, color: scheme.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
