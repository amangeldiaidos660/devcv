import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/presentation/profile_providers.dart';
import '../../features/profile/presentation/unsaved_profile_dialog.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) async {
        if (index == shell.currentIndex) return;
        if (shell.currentIndex == 1) {
          if (ref.read(profileActionsProvider).isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Дождитесь сохранения профиля')),
            );
            return;
          }
          if (ref.read(profileDirtyProvider) &&
              !await confirmLeaveProfile(context)) {
            return;
          }
        }
        if (context.mounted) shell.goBranch(index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Главная',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Профиль',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Резюме',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Настройки',
        ),
      ],
    ),
  );
}
