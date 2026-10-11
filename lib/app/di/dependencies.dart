import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/local_cache_service.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/profile/data/firestore_profile_repository.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/settings/data/preferences_settings_repository.dart';
import '../../features/settings/domain/settings_repository.dart';

final getIt = GetIt.instance;

void registerDependencies({
  required SharedPreferences preferences,
  required Box<dynamic> cacheBox,
}) {
  getIt.registerSingleton<SharedPreferences>(preferences);
  getIt.registerSingleton<LocalCacheService>(LocalCacheService(cacheBox));
  getIt.registerLazySingleton<DioClient>(DioClient.new);
  getIt.registerLazySingleton<Dio>(() => getIt<DioClient>().dio);
  getIt.registerLazySingleton<SettingsRepository>(
    () => PreferencesSettingsRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(getIt<FirebaseAuth>(), GoogleSignIn.instance),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => FirestoreProfileRepository(
      getIt<FirebaseFirestore>(),
      getIt<FirebaseAuth>(),
      getIt<LocalCacheService>(),
    ),
  );
}
