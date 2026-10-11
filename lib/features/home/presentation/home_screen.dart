import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DevCV')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Developer Profile & Resume Builder',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        for (final entry in [
          (RouteNames.profile, 'Profile', Icons.person_outline),
          (RouteNames.resume, 'Resume', Icons.description_outlined),
          (RouteNames.settings, 'Settings', Icons.settings_outlined),
        ])
          Card(
            child: ListTile(
              leading: Icon(entry.$3),
              title: Text(entry.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushNamed(entry.$1),
            ),
          ),
      ],
    ),
  );
}
