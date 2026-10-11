import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark theme'),
            subtitle: const Text(
              'Save your preferred appearance on this device',
            ),
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
                            content: Text('Could not save theme.'),
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}
