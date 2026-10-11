import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_page.dart';
import 'auth_fields.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeated = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeated.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authActionsProvider).isLoading;
    return FormPage(
      title: 'Создать аккаунт',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmailField(controller: _email, enabled: !busy),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              validator: Validators.password,
              enabled: !busy,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _repeated,
              label: 'Повторите пароль',
              validator: (value) =>
                  Validators.repeatPassword(value, _password.text),
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
                            .register(
                              _email.text,
                              _password.text,
                              _repeated.text,
                            );
                      }
                    },
              child: const Text('Зарегистрироваться'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      ref.read(authActionsProvider.notifier).clearError();
                      context.goNamed(RouteNames.login);
                    },
              child: const Text('Уже есть аккаунт? Войти'),
            ),
          ],
        ),
      ),
    );
  }
}
