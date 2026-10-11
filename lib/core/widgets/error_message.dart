import 'package:flutter/material.dart';

import '../errors/app_failure.dart';

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          failureMessage(error),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}
