import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/widgets/form_page.dart';
import 'auth_fields.dart';
import 'auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authActionsProvider).isLoading;
    return FormPage(
      title: 'Восстановить пароль',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmailField(controller: _email, enabled: !busy),
            if (_sent)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Если аккаунт с таким email существует, письмо для сброса пароля отправлено. Проверьте почту и папку «Спам».',
                ),
              ),
            const AuthFeedback(),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!(_form.currentState?.validate() ?? false)) return;
                      final sent = await ref
                          .read(authActionsProvider.notifier)
                          .resetPassword(_email.text);
                      if (mounted && sent) setState(() => _sent = true);
                    },
              child: const Text('Отправить письмо'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      ref.read(authActionsProvider.notifier).clearError();
                      context.goNamed(RouteNames.login);
                    },
              child: const Text('Вернуться ко входу'),
            ),
          ],
        ),
      ),
    );
  }
}
