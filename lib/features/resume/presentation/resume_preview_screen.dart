import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/error_message.dart';
import 'resume_providers.dart';

class ResumePreviewScreen extends ConsumerStatefulWidget {
  const ResumePreviewScreen({super.key});
  @override
  ConsumerState<ResumePreviewScreen> createState() => _ResumePreviewState();
}

class _ResumePreviewState extends ConsumerState<ResumePreviewScreen> {
  Uri? _saved;
  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(resumePreviewProvider),
        action = ref.watch(resumeActionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        bottom: preview.asData == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.requireValue.document.profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        preview.requireValue.document.config.position,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          IconButton(
            tooltip: 'Обновить данные',
            onPressed: action.isLoading
                ? null
                : () => ref.invalidate(resumePreviewProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: preview.when(
        loading: () => const LoadingState(),
        error: (error, stack) => Center(
          child: ErrorMessage(
            error: error,
            onRetry: () => ref.invalidate(resumePreviewProvider),
          ),
        ),
        data: (data) => TweenAnimationBuilder<double>(
          tween: Tween(begin: .96, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) => Opacity(
            opacity: ((value - .96) / .04).clamp(0, 1),
            child: Transform.scale(scale: value, child: child),
          ),
          child: PdfPreview(
            build: (format) async => data.bytes,
            initialPageFormat: PdfPageFormat.a4,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
            pdfFileName: data.document.fileName,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (action.hasError) ErrorMessage(error: action.error!),
              if (_saved != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Резюме сохранено\n$_saved',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              PrimaryButton(
                label: 'Скачать PDF',
                icon: Icons.download_outlined,
                busy: action.isLoading,
                onPressed: preview.asData == null
                    ? null
                    : () async {
                        final uri = await ref
                            .read(resumeActionsProvider.notifier)
                            .export(preview.requireValue);
                        if (uri != null && context.mounted) {
                          setState(() => _saved = uri);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Резюме сохранено')),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
