import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/local_cache_service.dart';
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
}
