import 'package:flutter/material.dart';

import 'dart:typed_data';
import 'dart:convert';

import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devcv/features/profile/domain/profile_entries.dart';
import 'package:devcv/features/resume/domain/resume_config.dart';
import 'package:devcv/features/resume/domain/resume_document.dart';
import 'package:devcv/core/config/app_features.dart';
import 'package:devcv/core/errors/app_failure.dart';

import 'support/app_harness.dart';
import 'support/fakes.dart';

void main() {
  testWidgets('Profile sections, empty experience and add validation work', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: verifiedUser),
        profiles = FakeProfileRepository();
    profiles.profiles['user-1'] = sampleProfile();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    await pumpDevCv(tester, auth, profiles);
    await tester.pumpAndSettle();
    await openTab(tester, 'Профиль');
    await tester.scrollUntilVisible(
      find.text('Основная информация'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Основная информация'), findsOneWidget);
    expect(find.text('Контакты'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Опыт работы'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Опыт работы'));
    await tester.pumpAndSettle();
    expect(find.text('Опыт пока не добавлен'), findsOneWidget);
    await tester.tap(find.text('Добавить опыт'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Укажите Компания'), findsOneWidget);
    expect(find.text('Укажите Должность'), findsOneWidget);
    expect(find.text('Укажите дата начала'), findsNothing);
    expect(find.text('Укажите дату начала'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Resume wizard validates position and saves selected entries', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: verifiedUser),
        profiles = FakeProfileRepository();
    profiles.profiles['user-1'] = sampleProfile();
    final entries = FakeEntryRepository(), resumes = FakeResumeRepository();
    entries.values[EntryKind.experience] = [
      WorkExperience(
        id: 'e1',
        company: 'Forpay',
        position: 'Backend Developer',
        startDate: DateTime(2024),
        isCurrent: true,
      ),
      WorkExperience(
        id: 'e2',
        company: 'Company B',
        position: 'QA',
        startDate: DateTime(2023),
        isCurrent: true,
      ),
    ];
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    await pumpDevCv(tester, auth, profiles, entries: entries, resumes: resumes);
    await tester.pumpAndSettle();
    await openTab(tester, 'Резюме');
    await tester.tap(find.text('Создать резюме'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Укажите позицию'), findsOneWidget);
    await tester.enterText(field('Позиция'), 'Backend Developer');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Что включить?'), findsOneWidget);
    await tester.ensureVisible(find.text('Продолжить'));
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.text('QA'), findsOneWidget);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'QA'));
    await tester.pumpAndSettle();
    final box = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'QA'),
    );
    expect(box.value, isFalse);
    final original = PrintingPlatform.instance;
    PrintingPlatform.instance = FakePrinting();
    addTearDown(() => PrintingPlatform.instance = original);
    await tester.ensureVisible(find.text('Открыть Preview'));
    await tester.tap(find.text('Открыть Preview'));
    await tester.pumpAndSettle();
    expect(resumes.config?.selectedIds[EntryKind.experience], {'e1'});
    expect(find.text('Айдос Разработчик'), findsOneWidget);
    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.byType(PdfPreview), findsOneWidget);
    expect(find.text('Скачать PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Spark profile and saved resume export without Storage calls', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: verifiedUser);
    final profiles = FakeProfileRepository();
    profiles.profiles['user-1'] = sampleProfile().copyWith(
      avatarUrl: 'https://firebasestorage.googleapis.com/old-avatar.jpg',
      avatarPath: 'users/user-1/profile/avatar_1.jpg',
    );
    final avatars = FakeAvatarRepository()
      ..failure = const AppFailure('Storage unavailable');
    final pdf = FakePdfGenerator(), exporter = FakeResumeExporter();
    final resumes = FakeResumeRepository()
      ..config = const ResumeConfig(
        position: 'Backend Developer',
        includedSections: {
          ResumeSection.basic,
          ResumeSection.contacts,
          ResumeSection.photo,
        },
        showPhoto: true,
      );
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    final original = PrintingPlatform.instance;
    PrintingPlatform.instance = FakePrinting();
    addTearDown(() => PrintingPlatform.instance = original);
    await pumpDevCv(
      tester,
      auth,
      profiles,
      resumes: resumes,
      avatars: avatars,
      pdf: pdf,
      exporter: exporter,
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    await openTab(tester, 'Профиль');
    expect(find.text('АР'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text(AppFeatures.photoUnavailableMessage), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Фото недоступно'),
    );
    expect(button.onPressed, isNull);
    expect(avatars.uploadCalls, 0);
    expect(avatars.loadCalls, 0);
    await openTab(tester, 'Резюме');
    await tester.ensureVisible(
      find.text('Продолжить с последними настройками'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продолжить с последними настройками'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    final photo = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Фото'),
    );
    expect(photo.value, isFalse);
    expect(photo.onChanged, isNull);
    expect(find.text(AppFeatures.photoUnavailableMessage), findsOneWidget);
    await tester.ensureVisible(find.text('Продолжить'));
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть Preview'));
    await tester.pumpAndSettle();
    expect(find.byType(PdfPreview), findsOneWidget);
    expect(pdf.lastDocument?.photo, isNull);
    expect(pdf.lastDocument?.config.showPhoto, isFalse);
    expect(resumes.config?.showPhoto, isFalse);
    expect(
      resumes.config?.includedSections.contains(ResumeSection.photo),
      isFalse,
    );
    await tester.tap(find.text('Скачать PDF'));
    await tester.pumpAndSettle();
    expect(exporter.calls, 1);
    expect(find.textContaining('Резюме сохранено'), findsWidgets);
    expect(avatars.loadCalls, 0);
    expect(avatars.uploadCalls, 0);
    expect(tester.takeException(), isNull);
  });
  test('Export cancellation returns no success URI', () async {
    final exporter = FakeResumeExporter()..cancel = true;
    final document = ResumeDocument(
      profile: sampleProfile(),
      config: const ResumeConfig(position: 'Backend'),
      entries: const {},
    );
    expect(
      await exporter.save(
        await FakePdfGenerator().generate(document),
        document.fileName,
      ),
      isNull,
    );
  });
}

class FakePrinting extends PrintingPlatform {
  @override
  Future<PrintingInfo> info() async => const PrintingInfo(canRaster: true);
  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {
    yield FakeRaster();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRaster extends PdfRaster {
  FakeRaster() : super(2, 2, Uint8List.fromList(List.filled(16, 255)));
  @override
  Future<Uint8List> toPng() async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGP8////fwYGBgYmEAHCAD34BABm6tHAAAAAAElFTkSuQmCC',
  );
}
