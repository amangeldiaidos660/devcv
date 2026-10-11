import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as ui;

import '../features/settings/domain/settings_repository.dart';
import '../features/settings/presentation/theme_controller.dart';
import 'di/dependencies.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class DevCvApp extends ConsumerWidget {
  const DevCvApp({super.key, this.settingsRepository});

  final SettingsRepository? settingsRepository;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return ui.ChangeNotifierProvider(
      create: (_) =>
          ThemeController(settingsRepository ?? getIt<SettingsRepository>()),
      child: ui.Consumer<ThemeController>(
        builder: (context, controller, child) => MaterialApp.router(
          title: 'DevCV',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.themeMode,
          routerConfig: router,
        ),
      ),
    );
  }
}
