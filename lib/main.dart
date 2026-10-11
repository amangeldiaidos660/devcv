import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di/dependencies.dart';
import 'core/storage/local_cache_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  final cacheBox = await Hive.openBox<dynamic>(LocalCacheService.boxName);
  final preferences = await SharedPreferences.getInstance();
  registerDependencies(preferences: preferences, cacheBox: cacheBox);
  runApp(const ProviderScope(child: DevCvApp()));
}
