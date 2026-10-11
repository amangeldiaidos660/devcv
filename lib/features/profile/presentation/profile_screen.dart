import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Profile',
    description: 'Your developer profile will be available here.',
    icon: Icons.person_outline,
  );
}
