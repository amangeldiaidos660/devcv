import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_message.dart';
import 'auth_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(authSessionProvider).asError?.error;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DevCV', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 24),
                if (error == null)
                  const CircularProgressIndicator()
                else
                  ErrorMessage(
                    error: error,
                    onRetry: () => ref.invalidate(authSessionProvider),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
