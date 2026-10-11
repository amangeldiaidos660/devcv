import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/developer_profile.dart';

abstract final class ProfileMapper {
  static DeveloperProfile fromFirestore(String uid, Map<String, Object?> data) {
    if (data['uid'] != uid) {
      throw const AppFailure('Некорректные данные профиля');
    }
    return DeveloperProfile(
      uid: uid,
      email: _text(data['email']),
      fullName: _text(data['fullName']),
      birthDate: _timestamp(data['birthDate']),
      city: _text(data['city']),
      createdAt: _timestamp(data['createdAt']),
      updatedAt: _timestamp(data['updatedAt']),
    );
  }

  static Map<String, Object?> toFirestore(
    DeveloperProfile profile, {
    required bool isNew,
  }) {
    final birthDate = profile.birthDate;
    return {
      'uid': profile.uid,
      'email': profile.email,
      'fullName': profile.fullName.trim(),
      'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate),
      'city': profile.city.trim(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, Object?> toCache(DeveloperProfile profile) => {
    'uid': profile.uid,
    'email': profile.email,
    'fullName': profile.fullName,
    'birthDate': profile.birthDate?.millisecondsSinceEpoch,
    'city': profile.city,
    'createdAt': profile.createdAt?.millisecondsSinceEpoch,
    'updatedAt': profile.updatedAt?.millisecondsSinceEpoch,
  };

  static DeveloperProfile fromCache(String uid, Map<Object?, Object?> data) {
    if (data['uid'] != uid) throw const AppFailure('Некорректные данные кэша');
    return DeveloperProfile(
      uid: uid,
      email: _text(data['email']),
      fullName: _text(data['fullName']),
      birthDate: _milliseconds(data['birthDate']),
      city: _text(data['city']),
      createdAt: _milliseconds(data['createdAt']),
      updatedAt: _milliseconds(data['updatedAt']),
    );
  }

  static String _text(Object? value) {
    if (value is String) return value;
    if (value == null) return '';
    throw const AppFailure('Некорректные данные профиля');
  }

  static DateTime? _timestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value == null) return null;
    throw const AppFailure('Некорректная дата в профиле');
  }

  static DateTime? _milliseconds(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value == null) return null;
    throw const AppFailure('Некорректная дата в кэше');
  }
}
