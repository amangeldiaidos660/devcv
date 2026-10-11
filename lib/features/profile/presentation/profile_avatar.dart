import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_features.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 38,
  });
  final String name;
  final String? url;
  final double radius;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e.characters.first.toUpperCase())
        .join();
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary
          .withValues(alpha: .15),
      child: initials.isEmpty
          ? const Icon(Icons.person_outline)
          : Text(initials, style: Theme.of(context).textTheme.titleLarge),
    );
    if (!ref.watch(profilePhotosEnabledProvider) ||
        url == null ||
        url!.isEmpty) {
      return fallback;
    }
    return ClipOval(
      child: Image.network(
        url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}
