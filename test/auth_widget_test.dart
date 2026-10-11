import 'package:devcv/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/fakes.dart';

void main() {
  testWidgets(
    'Login form validates email and required password before calling repository',
    (tester) async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository();
      addTearDown(auth.dispose);
      addTearDown(profiles.dispose);
      await pumpDevCv(tester, auth, profiles);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();
      expect(find.text('Введите email'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);
      expect(auth.signInCalls, 0);
      await tester.enterText(field('Email'), 'invalid');
      await tester.enterText(field('Пароль'), 'password123');
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();
      expect(find.text('Введите корректный email'), findsOneWidget);
      expect(auth.signInCalls, 0);
    },
  );
  testWidgets(
    'Register catches password mismatch and routes unverified accounts outside the shell',
    (tester) async {
      final auth = FakeAuthRepository();
      final profiles = FakeProfileRepository();
      addTearDown(auth.dispose);
      addTearDown(profiles.dispose);
      await pumpDevCv(tester, auth, profiles);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Создать аккаунт'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Email'), 'dev@example.com');
      await tester.enterText(field('Пароль'), 'password123');
      await tester.enterText(field('Повторите пароль'), 'different');
      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pumpAndSettle();
      expect(find.text('Пароли не совпадают'), findsOneWidget);
      expect(auth.registerCalls, 0);
      await tester.enterText(field('Повторите пароль'), 'password123');
      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pumpAndSettle();
      expect(find.text('Подтверждение email'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(auth.verificationCalls, 1);
      auth.verificationConfirmed = true;
      await tester.tap(find.text('Я подтвердил email / Проверить'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await openTab(tester, 'Настройки');
      await tester.tap(find.text('Выйти из аккаунта'));
      await tester.pumpAndSettle();
      expect(find.text('Войти в DevCV'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );
  testWidgets(
    'Login displays mapped failure and password reset shows a success message',
    (tester) async {
      final auth = FakeAuthRepository()
        ..failure = const AppFailure('Неверный email или пароль');
      final profiles = FakeProfileRepository();
      addTearDown(auth.dispose);
      addTearDown(profiles.dispose);
      await pumpDevCv(tester, auth, profiles);
      await tester.pumpAndSettle();
      await logIn(tester);
      expect(find.text('Неверный email или пароль'), findsOneWidget);
      auth.failure = null;
      await tester.tap(find.text('Забыли пароль?'));
      await tester.pumpAndSettle();
      expect(find.text('Неверный email или пароль'), findsNothing);
      await tester.enterText(field('Email'), 'dev@example.com');
      await tester.tap(find.text('Отправить письмо'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('письмо для сброса пароля отправлено'),
        findsOneWidget,
      );
      expect(auth.resetCalls, 1);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );
}
