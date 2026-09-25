import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_profile.dart';
import '../provider/app_state.dart';
import '../theme/app_theme.dart';

/// 设置页：AI 接口档案管理与主题切换
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前模型概览
          _ModelOverviewCard(app: app),
          const SizedBox(height: 20),
          // API 档案
          Row(
            children: [
              Text('API 接口', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: '新增接口',
                onPressed: () => _openProfileEditor(context, app),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (app.profiles.isEmpty)
            _EmptyProfiles(isDark: isDark, onAdd: () => _openProfileEditor(context, app))
          else
            ...app.profiles.map((p) => _ProfileCard(
                  profile: p,
                  active: p.id == app.settings.activeProfileId,
                  onSelect: () => app.selectProfile(p.id),
                  onEdit: () => _openProfileEditor(context, app, profile: p),
                  onDelete: () => _confirmDelete(context, app, p),
                )),
          const SizedBox(height: 24),
          // 主题设置
          Text('外观', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface)),
          const SizedBox(height: 8),
          _ThemeSelector(app: app),
          const SizedBox(height: 24),
          // 关于
          _AboutCard(isDark: isDark),
        ],
      ),
    );
  }

  Future<void> _openProfileEditor(BuildContext context, AppState app,
      {AiProfile? profile}) async {
    await Navigator.push<AiProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(profile: profile),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState app, AiProfile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除接口'),
        content: Text('确定删除接口「${profile.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.removeProfile(profile.id);
    }
  }
}

/// 当前模型概览卡片
class _ModelOverviewCard extends StatelessWidget {
  final AppState app;
  const _ModelOverviewCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final profile = app.activeProfile;
    final model = app.activeModel;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                '当前模型',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            model.isNotEmpty ? model : '未配置',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile != null ? profile.name : '请添加一个 API 接口',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 单个 API 档案卡片
class _ProfileCard extends StatelessWidget {
  final AiProfile profile;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProfileCard({
    required this.profile,
    required this.active,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // 选中指示
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? scheme.primary : scheme.outlineVariant,
                    width: 2,
                  ),
                  color: active ? scheme.primary : Colors.transparent,
                ),
                child: active
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.normalizedBaseUrl,
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.models.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${profile.models.length} 个模型',
                          style: TextStyle(
                              fontSize: 11, color: scheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: scheme.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;
  const _EmptyProfiles({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi, size: 38, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            '还没有配置 API 接口',
            style: TextStyle(fontSize: 15, color: scheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '添加一个 OpenAI 兼容接口即可开始对话',
            style: TextStyle(fontSize: 12, color: scheme.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加接口'),
          ),
        ],
      ),
    );
  }
}

/// 主题切换
class _ThemeSelector extends StatelessWidget {
  final AppState app;
  const _ThemeSelector({required this.app});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mode = app.settings.themeMode;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ThemeOption(
            icon: Icons.desktop_windows,
            label: '跟随系统',
            selected: mode == 'system',
            onTap: () => app.settings.saveThemeMode('system'),
          ),
          _ThemeOption(
            icon: Icons.light_mode,
            label: '浅色',
            selected: mode == 'light',
            onTap: () => app.settings.saveThemeMode('light'),
          ),
          _ThemeOption(
            icon: Icons.dark_mode,
            label: '深色',
            selected: mode == 'dark',
            onTap: () => app.settings.saveThemeMode('dark'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 关于卡片
class _AboutCard extends StatelessWidget {
  final bool isDark;
  const _AboutCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 18),
              SizedBox(width: 8),
              Text('须弥AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '版本 1.0.0 · 基于 OpenAI 兼容 API',
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
          const SizedBox(height: 4),
          Text(
            '本期为测试版本，请自行配置接口后使用。生成内容由模型提供，仅供参考。',
            style: TextStyle(fontSize: 12, color: scheme.outline, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 档案编辑页
class ProfileEditorScreen extends StatefulWidget {
  final AiProfile? profile; // null 表示新增
  const ProfileEditorScreen({super.key, this.profile});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  final _modelsCtrl = TextEditingController();
  List<String> _models = [];
  bool _busy = false;

  bool get _isEdit => widget.profile != null;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.baseUrl ?? '');
    _keyCtrl = TextEditingController(text: p?.apiKey ?? '');
    _models = p?.models ?? [];
    _modelsCtrl.text = _models.join(', ');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _modelsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchModels(AppState app) async {
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (url.isEmpty) {
      _toast('请先填写 Base URL');
      return;
    }
    setState(() => _busy = true);
    final probe = AiProfile(
      id: 'probe',
      name: 'probe',
      baseUrl: url,
      apiKey: key,
    );
    final models = await app.api.fetchModels(probe);
    setState(() {
      _busy = false;
      if (models.isNotEmpty) {
        _models = models;
        _modelsCtrl.text = models.join(', ');
        _toast('已获取 ${models.length} 个模型');
      } else {
        _toast('未能获取模型列表，请手动填写');
      }
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) {
      _toast('请填写名称和 Base URL');
      return;
    }

    // 解析逗号分隔的模型
    final parsed = _modelsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (_models.isNotEmpty) {
      final combined = _models.toSet().toList();
      for (final m in parsed) {
        if (!combined.contains(m)) combined.add(m);
      }
      _models = combined;
    } else {
      _models = parsed;
    }

    final app = context.read<AppState>();
    final profile = AiProfile(
      id: _isEdit ? widget.profile!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      baseUrl: url,
      apiKey: key,
      models: _models,
      defaultModel: _models.isNotEmpty ? _models.first : null,
      enabled: true,
    );

    if (_isEdit) {
      app.updateProfile(profile);
    } else {
      app.addProfile(profile);
    }
    Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑接口' : '添加接口'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _fieldLabel(scheme, '名称'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: '如：豆包 / DeepSeek / 自定义',
              prefixIcon: const Icon(Icons.label, size: 19),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel(scheme, 'Base URL'),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://api.example.com/v1',
              prefixIcon: Icon(Icons.link, size: 19),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '需以 /v1 结尾，系统会自动拼接 /chat/completions',
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
          const SizedBox(height: 20),
          _fieldLabel(scheme, 'API Key'),
          const SizedBox(height: 8),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'sk-...',
              prefixIcon: const Icon(Icons.vpn_key, size: 19),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _fieldLabel(scheme, '模型列表'),
              const Spacer(),
              TextButton.icon(
                onPressed: _busy ? null : () => _fetchModels(app),
                icon: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 16),
                label: Text(_busy ? '获取中…' : '自动获取'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelsCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'gpt-4o, deepseek-chat, ...（逗号分隔）',
              prefixIcon: Icon(Icons.list, size: 19),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? '保存修改' : '保存并启用'),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(ColorScheme scheme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}