import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/error_message.dart';
import 'profile_providers.dart';
import 'profile_form.dart';

class BasicProfileScreen extends ConsumerWidget {
  const BasicProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(currentProfileProvider)
      .when(
        loading: () => const Scaffold(body: LoadingState()),
        error: (error, stack) => Scaffold(
          body: ErrorMessage(
            error: error,
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
        ),
        data: (data) =>
            ProfileForm(profile: data, email: ref.watch(authEmailProvider)),
      );
}
