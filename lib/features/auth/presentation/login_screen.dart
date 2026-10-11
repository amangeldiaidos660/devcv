import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_page.dart';
import 'auth_fields.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authActionsProvider).isLoading;
    return FormPage(
      title: 'Войти в DevCV',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('DevCV', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text('Developer Profile & Resume Builder'),
            const SizedBox(height: 24),
            EmailField(controller: _email, enabled: !busy),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              validator: Validators.loginPassword,
              enabled: !busy,
            ),
            const AuthFeedback(),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      if (_form.currentState?.validate() ?? false) {
                        ref
                            .read(authActionsProvider.notifier)
                            .signIn(_email.text, _password.text);
                      }
                    },
              child: const Text('Войти'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => ref
                        .read(authActionsProvider.notifier)
                        .signInWithGoogle(),
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Войти через Google'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      ref.read(authActionsProvider.notifier).clearError();
                      context.goNamed(RouteNames.forgotPassword);
                    },
              child: const Text('Забыли пароль?'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      ref.read(authActionsProvider.notifier).clearError();
                      context.goNamed(RouteNames.register);
                    },
              child: const Text('Создать аккаунт'),
            ),
          ],
        ),
      ),
    );
  }
}
