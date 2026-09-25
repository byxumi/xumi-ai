import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/app_state.dart';
import '../theme/app_theme.dart';

/// 侧边会话历史抽屉
class ConversationDrawer extends StatelessWidget {
  const ConversationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.brandGradientStart,
                          AppColors.brandGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '须弥AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 新建对话按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  app.createConversation();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建对话'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.3)),
            // 会话列表
            Expanded(
              child: app.conversations.isEmpty
                  ? const _EmptyList()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: app.conversations.length,
                      itemBuilder: (context, i) {
                        final conv = app.conversations[i];
                        final active = conv.id == app.activeConvId;
                        return ListTile(
                          dense: true,
                          selected: active,
                          selectedTileColor:
                              scheme.primaryContainer.withValues(alpha: 0.5),
                          leading: Icon(
                            active ? Icons.chat_bubble : Icons.chat_bubble_outline,
                            size: 19,
                            color: active ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                          title: Text(
                            conv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              color: active
                                  ? scheme.primary
                                  : scheme.onSurface,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            app.switchConversation(conv.id);
                          },
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                size: 18, color: scheme.onSurfaceVariant),
                            onSelected: (v) async {
                              switch (v) {
                                case 'rename':
                                  await _renameDialog(context, app, conv.id,
                                      app.conversations[i].title);
                                  break;
                                case 'clear':
                                  await app.clearMessages(conv.id);
                                  break;
                                case 'delete':
                                  await app.deleteConversation(conv.id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: ListTile(
                                  leading: Icon(Icons.edit, size: 18),
                                  title: Text('重命名'),
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'clear',
                                child: ListTile(
                                  leading: Icon(Icons.backspace, size: 18),
                                  title: Text('清空消息'),
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline, size: 18,
                                      color: Colors.redAccent),
                                  title: Text('删除会话',
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDialog(
      BuildContext context, AppState app, String id, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新标题'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await app.renameConversation(id, result.trim());
    }
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum, size: 44, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            '还没有聊天记录，点「新建对话」开聊吧',
            style: TextStyle(color: scheme.outline, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}