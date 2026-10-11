import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Resume',
    description: 'Your resume workspace will be available here.',
    icon: Icons.description_outlined,
  );
}
