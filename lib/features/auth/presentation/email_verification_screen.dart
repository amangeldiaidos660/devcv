import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/form_page.dart';
import 'auth_fields.dart';
import 'auth_providers.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).asData?.value;
    final busy = ref.watch(authActionsProvider).isLoading;
    return FormPage(
      title: 'Подтверждение email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 64),
          const SizedBox(height: 24),
          Text(
            'Подтвердите адрес ${user?.email ?? ''}. Откройте ссылку в письме, затем нажмите «Проверить». Если письма нет, отправьте его повторно.',
          ),
          const AuthFeedback(),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    final checked = await ref
                        .read(authActionsProvider.notifier)
                        .reloadUser();
                    if (checked &&
                        context.mounted &&
                        !(ref
                                .read(authSessionProvider)
                                .asData
                                ?.value
                                ?.emailVerified ??
                            false)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email пока не подтверждён'),
                        ),
                      );
                    }
                  },
            child: const Text('Я подтвердил email / Проверить'),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final sent = await ref
                        .read(authActionsProvider.notifier)
                        .sendVerificationEmail();
                    if (sent && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Письмо отправлено на ${user?.email ?? ''}',
                          ),
                        ),
                      );
                    }
                  },
            child: const Text('Отправить письмо повторно'),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () => ref.read(authActionsProvider.notifier).signOut(),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
