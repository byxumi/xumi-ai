import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'provider/app_state.dart';
import 'screens/chat_screen.dart';
import 'services/chat_store.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  final store = ChatStore();
  final appState = AppState(settings: settings, store: store);
  unawaited(appState.init());

  runApp(XumiAiApp(state: appState));
}

/// 根组件：负责主题切换
class XumiAiApp extends StatelessWidget {
  final AppState state;
  const XumiAiApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: Consumer<AppState>(
        builder: (context, s, _) {
          final mode = s.settings.themeMode;
          final themeMode = switch (mode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          return MaterialApp(
            title: '须弥AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            home: const ChatScreen(),
          );
        },
      ),
    );
  }
}