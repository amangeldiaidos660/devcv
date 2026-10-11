import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/config/app_features.dart';
import '../../../core/errors/app_failure.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/domain/profile_entries.dart';
import '../../profile/domain/developer_profile.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../profile/presentation/entry_providers.dart';
import '../../profile/presentation/details_providers.dart';
import '../domain/resume_config.dart';
import '../domain/resume_document.dart';

final resumeConfigRepositoryProvider = Provider<ResumeConfigRepository>(
  (ref) => getIt<ResumeConfigRepository>(),
);
final resumePdfGeneratorProvider = Provider<ResumePdfGenerator>(
  (ref) => getIt<ResumePdfGenerator>(),
);
final resumeExporterProvider = Provider<ResumeExporter>(
  (ref) => getIt<ResumeExporter>(),
);
final lastResumeConfigProvider = FutureProvider.autoDispose<ResumeConfig?>((
  ref,
) {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null) return null;
  return ref.watch(resumeConfigRepositoryProvider).load(user.uid);
});

class ResumeProfileData {
  const ResumeProfileData(this.profile, this.entries);
  final DeveloperProfile profile;
  final Map<EntryKind, List<ProfileEntry>> entries;
}

final resumeProfileDataProvider = FutureProvider.autoDispose<ResumeProfileData>(
  (ref) async {
    final profileFuture = ref.watch(currentProfileProvider.future);
    final entryFutures = {
      for (final kind in EntryKind.values)
        kind: ref.watch(entriesProvider(kind).future),
    };
    final profile = await profileFuture;
    if (profile == null) {
      throw const AppFailure('Сначала заполните основную информацию профиля');
    }
    final lists = await Future.wait(entryFutures.values);
    return ResumeProfileData(profile, {
      for (var i = 0; i < EntryKind.values.length; i++)
        EntryKind.values[i]: lists[i],
    });
  },
);
final resumeDraftProvider = NotifierProvider<ResumeDraft, ResumeConfig>(
  ResumeDraft.new,
);

class ResumeDraft extends Notifier<ResumeConfig> {
  @override
  ResumeConfig build() {
    ref.watch(authSessionProvider.select((s) => s.asData?.value?.uid));
    return const ResumeConfig();
  }

  void setConfig(ResumeConfig value) => state = value;
}

class ResumePreview {
  const ResumePreview(this.document, this.bytes);
  final ResumeDocument document;
  final Uint8List bytes;
}

final resumePreviewProvider = FutureProvider.autoDispose<ResumePreview>((
  ref,
) async {
  final dataFuture = ref.watch(resumeProfileDataProvider.future);
  final draft = ref.watch(resumeDraftProvider);
  final photosEnabled = ref.watch(profilePhotosEnabledProvider);
  final config = photosEnabled
      ? draft
      : draft.copyWith(
          showPhoto: false,
          includedSections: {...draft.includedSections}
            ..remove(ResumeSection.photo),
        );
  final generator = ref.watch(resumePdfGeneratorProvider);
  final data = await dataFuture;
  Uint8List? photo;
  final path = data.profile.avatarPath;
  if (photosEnabled &&
      config.showPhoto &&
      config.includedSections.contains(ResumeSection.photo) &&
      path != null) {
    try {
      photo = await ref
          .watch(avatarRepositoryProvider)
          .loadBytes(data.profile.uid, path);
    } on Exception {
      photo = null;
    }
  }
  final document = ResumeDocument(
    profile: data.profile,
    config: config,
    entries: data.entries,
    photo: photo,
  );
  return ResumePreview(document, await generator.generate(document));
});
final resumeActionsProvider =
    NotifierProvider.autoDispose<ResumeActions, AsyncValue<void>>(
      ResumeActions.new,
    );

class ResumeActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<bool> saveConfig(ResumeConfig config) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      final uid = ref.read(authSessionProvider).asData?.value?.uid;
      if (uid == null) throw const AppFailure('Войдите в свой аккаунт');
      final error = config.validate();
      if (error != null) throw AppFailure(error);
      await ref.read(resumeConfigRepositoryProvider).save(uid, config);
      ref.invalidate(lastResumeConfigProvider);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<Uri?> export(ResumePreview preview) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final uri = await ref
          .read(resumeExporterProvider)
          .save(preview.bytes, preview.document.fileName);
      if (ref.mounted) state = const AsyncData(null);
      return uri;
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return null;
    }
  }
}
