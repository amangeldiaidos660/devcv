import 'package:devcv/core/config/app_features.dart';
import 'package:devcv/core/errors/app_failure.dart';
import 'package:devcv/features/profile/data/disabled_avatar_repository.dart';
import 'package:devcv/features/profile/presentation/details_providers.dart';
import 'package:devcv/features/resume/domain/resume_config.dart';
import 'package:devcv/features/resume/presentation/resume_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Disabled avatar repository needs no Firebase initialization', () async {
    const repository = DisabledAvatarRepository();
    expect(await repository.selectAndUpload('user-1', null), isFalse);
    expect(await repository.loadBytes('user-1', 'old.jpg'), isNull);
  });

  test('Disabled photo action never resolves the Storage repository', () async {
    var resolved = false;
    final container = ProviderContainer(
      overrides: [
        profilePhotosEnabledProvider.overrideWithValue(false),
        avatarRepositoryProvider.overrideWith((ref) {
          resolved = true;
          throw StateError('Storage must not be resolved');
        }),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(detailsActionsProvider, (_, _) {});
    addTearDown(subscription.close);
    expect(
      await container.read(detailsActionsProvider.notifier).avatar('old.jpg'),
      isFalse,
    );
    expect(resolved, isFalse);
    expect(container.read(detailsActionsProvider).hasError, isFalse);
  });

  for (final enabled in [false, true]) {
    test(
      'Preview survives unavailable Storage with photos enabled=$enabled',
      () async {
        var resolved = false;
        final avatars = FakeAvatarRepository()
          ..failure = const AppFailure('Storage unavailable');
        final pdf = FakePdfGenerator();
        final config = const ResumeConfig(
          position: 'Backend Developer',
          includedSections: {
            ResumeSection.basic,
            ResumeSection.contacts,
            ResumeSection.photo,
          },
          showPhoto: true,
        );
        final container = ProviderContainer(
          overrides: [
            profilePhotosEnabledProvider.overrideWithValue(enabled),
            resumeDraftProvider.overrideWith(() => FixedResumeDraft(config)),
            resumeProfileDataProvider.overrideWith(
              (ref) async => ResumeProfileData(
                sampleProfile().copyWith(
                  avatarPath: 'users/user-1/profile/avatar_1.jpg',
                ),
                const {},
              ),
            ),
            avatarRepositoryProvider.overrideWith((ref) {
              resolved = true;
              return avatars;
            }),
            resumePdfGeneratorProvider.overrideWithValue(pdf),
            resumeExporterProvider.overrideWithValue(FakeResumeExporter()),
          ],
        );
        addTearDown(container.dispose);
        final previewSubscription = container.listen(
          resumePreviewProvider,
          (_, _) {},
        );
        addTearDown(previewSubscription.close);
        final actionSubscription = container.listen(
          resumeActionsProvider,
          (_, _) {},
        );
        addTearDown(actionSubscription.close);
        final preview = await container.read(resumePreviewProvider.future);
        expect(preview.document.photo, isNull);
        expect(String.fromCharCodes(preview.bytes.take(5)), '%PDF-');
        expect(resolved, enabled);
        expect(avatars.loadCalls, enabled ? 1 : 0);
        expect(
          await container.read(resumeActionsProvider.notifier).export(preview),
          isNotNull,
        );
      },
    );
  }
}

class FixedResumeDraft extends ResumeDraft {
  FixedResumeDraft(this.config);
  final ResumeConfig config;
  @override
  ResumeConfig build() => config;
}
