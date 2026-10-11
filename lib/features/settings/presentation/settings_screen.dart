import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as ui;

import '../../auth/presentation/auth_fields.dart';
import '../../auth/presentation/auth_providers.dart';
import 'theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ui.Provider.of<ThemeController>(context);
    final busy = ref.watch(authActionsProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Тёмная тема'),
                value: controller.isDarkMode,
                onChanged: controller.isSaving
                    ? null
                    : (value) async {
                        try {
                          await controller.setDarkMode(value);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Не удалось сохранить тему'),
                              ),
                            );
                          }
                        }
                      },
              ),
              const Divider(),
              const AuthFeedback(),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => ref.read(authActionsProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Выйти из аккаунта'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
