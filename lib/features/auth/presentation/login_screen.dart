import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Login')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code, size: 64),
            const SizedBox(height: 24),
            Text('DevCV', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            const Text('Authentication will be added in a future stage.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.goNamed(RouteNames.home),
              child: const Text('Explore DevCV'),
            ),
          ],
        ),
      ),
    ),
  );
}
