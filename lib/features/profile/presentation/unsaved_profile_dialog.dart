import 'package:flutter/material.dart';

Future<bool> confirmLeaveProfile(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Профиль не сохранён'),
        content: const Text(
          'Вернуться без сохранения? Изменения в этой форме будут потеряны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Перейти'),
          ),
        ],
      ),
    ) ??
    false;
