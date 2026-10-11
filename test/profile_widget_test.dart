import 'dart:async';

import 'package:devcv/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/fakes.dart';

void main() {
  testWidgets('New profile displays an empty form and required validation', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: verifiedUser);
    final profiles = FakeProfileRepository();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    await pumpDevCv(tester, auth, profiles);
    await tester.pumpAndSettle();
    expect(find.text('Заполнение базового профиля: 25%'), findsOneWidget);
    await openTab(tester, 'Профиль');
    expect(find.textContaining('Профиль ещё не создан'), findsOneWidget);
    expect(find.text('dev@example.com'), findsOneWidget);
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Укажите ФИО'), findsOneWidget);
    expect(find.text('Укажите дату рождения'), findsOneWidget);
    expect(find.text('Укажите город'), findsOneWidget);
    expect(profiles.saveCalls, 0);
  });
  testWidgets('Profile renders loading then data and prevents future dates', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: verifiedUser);
    final profiles = FakeProfileRepository()..loadGate = Completer<void>();
    profiles.profiles['user-1'] = sampleProfile();
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    await pumpDevCv(tester, auth, profiles);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    profiles.loadGate?.complete();
    await tester.pumpAndSettle();
    expect(find.text('Заполнение базового профиля: 100%'), findsOneWidget);
    await openTab(tester, 'Профиль');
    expect(find.text('Айдос Разработчик'), findsOneWidget);
    expect(find.text('Алматы'), findsOneWidget);
    await tester.tap(field('Дата рождения'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(
      dialog.lastDate.isAfter(DateUtils.dateOnly(DateTime.now())),
      isFalse,
    );
  });
  testWidgets('Profile error offers retry and recovers to data', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: verifiedUser);
    final profiles = FakeProfileRepository()
      ..failure = const AppFailure('Нет доступа к профилю');
    addTearDown(auth.dispose);
    addTearDown(profiles.dispose);
    await pumpDevCv(tester, auth, profiles);
    await tester.pumpAndSettle();
    await openTab(tester, 'Профиль');
    expect(find.text('Нет доступа к профилю'), findsOneWidget);
    profiles.failure = null;
    profiles.profiles['user-1'] = sampleProfile();
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Айдос Разработчик'), findsOneWidget);
  });
  testWidgets(
    'Profile keeps a draft between tabs and disables Save while saving',
    (tester) async {
      final auth = FakeAuthRepository(user: verifiedUser);
      final profiles = FakeProfileRepository()..saveGate = Completer<void>();
      profiles.profiles['user-1'] = sampleProfile();
      addTearDown(auth.dispose);
      addTearDown(profiles.dispose);
      await pumpDevCv(tester, auth, profiles);
      await tester.pumpAndSettle();
      await openTab(tester, 'Профиль');
      await tester.enterText(field('ФИО'), 'Новое Имя');
      await tester.tap(find.widgetWithText(NavigationDestination, 'Главная'));
      await tester.pumpAndSettle();
      expect(find.text('Профиль не сохранён'), findsOneWidget);
      await tester.tap(find.text('Перейти'));
      await tester.pumpAndSettle();
      await openTab(tester, 'Профиль');
      expect(find.text('Новое Имя'), findsOneWidget);
      await tester.ensureVisible(find.text('Сохранить'));
      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Сохранить'),
      );
      expect(button.onPressed, isNull);
      expect(profiles.saveCalls, 1);
      profiles.saveGate?.complete();
      await tester.pumpAndSettle();
      expect(find.text('Профиль сохранён'), findsOneWidget);
      expect(profiles.lastSaved?.fullName, 'Новое Имя');
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(900, 1000),
  ]) {
    testWidgets('Forms and navigation do not overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository();
      addTearDown(auth.dispose);
      addTearDown(profiles.dispose);
      await pumpDevCv(tester, auth, profiles);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Создать аккаунт'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      auth.emit(verifiedUser);
      await tester.pumpAndSettle();
      await openTab(tester, 'Профиль');
      expect(tester.takeException(), isNull);
      await openTab(tester, 'Настройки');
      expect(tester.takeException(), isNull);
    });
  }
}
