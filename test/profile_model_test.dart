import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devcv/core/errors/app_failure.dart';
import 'package:devcv/features/profile/data/profile_mapper.dart';
import 'package:devcv/features/profile/domain/developer_profile.dart';
import 'package:devcv/features/profile/domain/profile_completion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('Firestore serialization uses server timestamps and preserves creation on update', () {
    final source = sampleProfile();
    final creation = ProfileMapper.toFirestore(source, isNew: true);
    expect(creation['createdAt'], isA<FieldValue>());
    expect(creation['updatedAt'], isA<FieldValue>());
    final update = ProfileMapper.toFirestore(source, isNew: false);
    expect(update.containsKey('createdAt'), isFalse);
    final stored = {
      ...creation,
      'createdAt': Timestamp.fromDate(source.createdAt!),
      'updatedAt': Timestamp.fromDate(source.updatedAt!),
    };
    final restored = ProfileMapper.fromFirestore(source.uid, stored);
    expect(restored.fullName, source.fullName);
    expect(restored.birthDate, source.birthDate);
    expect(restored.city, source.city);
    expect(restored.email, source.email);
    expect(restored.createdAt, source.createdAt);
    expect(restored.updatedAt, source.updatedAt);
  });
  test('Hive representation round-trips and cannot cross account IDs', () {
    final source = sampleProfile();
    final cached = ProfileMapper.toCache(source);
    final restored = ProfileMapper.fromCache(source.uid, cached);
    expect(restored.birthDate, source.birthDate);
    expect(restored.fullName, source.fullName);
    expect(restored.createdAt, source.createdAt);
    expect(
      () => ProfileMapper.fromCache('another-user', cached),
      throwsA(isA<AppFailure>()),
    );
  });
  test('Completion counts real fields and verified auth email', () {
    expect(
      ProfileCompletion.calculate(
        profile: null,
        email: null,
        emailVerified: false,
      ),
      0,
    );
    expect(
      ProfileCompletion.calculate(
        profile: null,
        email: 'dev@example.com',
        emailVerified: true,
      ),
      25,
    );
    expect(
      ProfileCompletion.calculate(
        profile: sampleProfile(),
        email: 'dev@example.com',
        emailVerified: true,
      ),
      100,
    );
    expect(
      ProfileCompletion.calculate(
        profile: sampleProfile(),
        email: 'dev@example.com',
        emailVerified: false,
      ),
      75,
    );
    final incomplete = DeveloperProfile(
      uid: 'u',
      email: 'dev@example.com',
      fullName: '  ',
      birthDate: DateTime(2030),
      city: ' ',
    );
    expect(
      ProfileCompletion.calculate(
        profile: incomplete,
        email: 'dev@example.com',
        emailVerified: true,
        now: DateTime(2024),
      ),
      25,
    );
  });
}
