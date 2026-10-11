import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/error_message.dart';
import '../domain/profile_entries.dart';
import 'entry_providers.dart';

class EntryListScreen extends ConsumerWidget {
  const EntryListScreen({super.key, required this.kind});
  final EntryKind kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider(kind));
    final action = ref.watch(entryActionsProvider);
    void add() =>
        context.pushNamed('entryAdd', pathParameters: {'kind': kind.name});
    return Scaffold(
      appBar: AppBar(
        title: Text(kind.label),
        actions: [
          IconButton(
            onPressed: action.isLoading ? null : add,
            icon: const Icon(Icons.add),
            tooltip: 'Добавить ${kind.singular.toLowerCase()}',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              if (action.hasError)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorMessage(error: action.error!),
                ),
              Expanded(
                child: entries.when(
                  loading: () => const LoadingState(),
                  error: (error, stack) => Center(
                    child: ErrorMessage(
                      error: error,
                      onRetry: () => ref.invalidate(entriesProvider(kind)),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            EmptyState(
                              title: kind.emptyLabel,
                              message: 'Добавьте первую запись, чтобы использовать её в резюме.',
                              action: 'Добавить ${kind.singular.toLowerCase()}',
                              onPressed: add,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final entry = items[index];
                            return AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry is Skill)
                                    AppChip(label: entry.name)
                                  else
                                    Text(
                                      entry.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(entry.subtitle),
                                  if (entry is WorkExperience)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${entry.periodLabel} · ${entry.durationLabel()}',
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 10,
                                    children: [
                                      TextButton.icon(
                                        onPressed: action.isLoading
                                            ? null
                                            : () => context.pushNamed(
                                                'entryEdit',
                                                pathParameters: {
                                                  'kind': kind.name,
                                                  'id': entry.id,
                                                },
                                                extra: entry,
                                              ),
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Изменить'),
                                      ),
                                      TextButton.icon(
                                        onPressed: action.isLoading
                                            ? null
                                            : () async {
                                                final confirmed =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                            title: const Text(
                                                              'Удалить запись?',
                                                            ),
                                                            content: Text(
                                                              entry.title,
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Отмена',
                                                                    ),
                                                              ),
                                                              FilledButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Удалить',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                if (confirmed == true) {
                                                  await ref
                                                      .read(
                                                        entryActionsProvider
                                                            .notifier,
                                                      )
                                                      .delete(kind, entry.id);
                                                }
                                              },
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Удалить'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
