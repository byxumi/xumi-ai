import 'package:flutter/material.dart';

import '../provider/app_state.dart';
import '../theme/app_theme.dart';
import 'model_avatar.dart';
import '../screens/settings_screen.dart';

/// 打开 Operit 式分组模型选择器（支持搜索 / 多接口分组 / 快速切换）
Future<void> showModelPicker(BuildContext context, AppState app) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => ModelPickerSheet(app: app),
  );
}

/// 模型切换底部面板：按接口分组展示所有模型，支持搜索
class ModelPickerSheet extends StatefulWidget {
  final AppState app;
  const ModelPickerSheet({super.key, required this.app});

  @override
  State<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<ModelPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(AiProfileShim profile, String model) async {
    await widget.app.selectProfile(profile.id);
    await widget.app.selectModel(model);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profiles = app.profiles;
    final activeProfileId = app.settings.activeProfileId;
    final activeModel = app.activeModel;
    final kw = _keyword.trim().toLowerCase();

    // 过滤：只保留匹配关键字的模型；命中模型所属的接口也保留
    final visibleProfiles = <AiProfileShim>[];
    for (final p in profiles) {
      final models = p.models
          .where((m) => kw.isEmpty || m.toLowerCase().contains(kw))
          .toList();
      if (models.isNotEmpty) {
        visibleProfiles.add(AiProfileShim(
            id: p.id, name: p.name, baseUrl: p.baseUrl, models: models));
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部把手 + 标题
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Text(
                    '换个模型聊聊',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${app.profiles.length} 个接口',
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                ],
              ),
            ),
            // 搜索框
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _keyword = v),
                style: TextStyle(fontSize: 14.5, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: '搜一搜模型…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _keyword.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _keyword = '');
                          },
                        ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: visibleProfiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 40, color: scheme.outlineVariant),
                          const SizedBox(height: 10),
                          Text('没搜到，换个词试试～',
                              style:
                                  TextStyle(color: scheme.outline, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: visibleProfiles.length,
                      itemBuilder: (context, i) {
                        final p = visibleProfiles[i];
                        final isActiveProfile = p.id == activeProfileId;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 接口分组头
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 4),
                              child: Row(
                                children: [
                                  Icon(Icons.dns_rounded,
                                      size: 15,
                                      color: isActiveProfile
                                          ? AppColors.primary
                                          : scheme.outlineVariant),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isActiveProfile
                                            ? AppColors.primary
                                            : scheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActiveProfile)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '当前',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // 该接口下的模型
                            for (final m in p.models)
                              _ModelTile(
                                model: m,
                                profile: p,
                                selected: isActiveProfile && m == activeModel,
                                onTap: () => _pick(p, m),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            // 底部：管理接口
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('去设置里管理'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(
                        color: scheme.primary.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 模型行（含头像 / 名称 / 选中态）
class _ModelTile extends StatelessWidget {
  final String model;
  final AiProfileShim profile;
  final bool selected;
  final VoidCallback onTap;
  const _ModelTile({
    required this.model,
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? SchemeContainerLike.primarySoft(scheme)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          child: Row(
            children: [
              ModelAvatar(model: model, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      profile.name,
                      style: TextStyle(fontSize: 11.5, color: scheme.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 轻量接口档案投影（避免 model_picker 直接依赖 AiProfile 的不必要字段）
class AiProfileShim {
  final String id;
  final String name;
  final String baseUrl;
  final List<String> models;
  const AiProfileShim({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.models,
  });
}

/// 简单的颜色工具（分离出来避免 name 冲突）
class SchemeContainerLike {
  static Color primarySoft(ColorScheme scheme) {
    return scheme.primary.withValues(alpha: 0.08);
  }
}
