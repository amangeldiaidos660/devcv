import 'dart:io';

import 'package:devcv/core/storage/local_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('Cache survives reopening and supports remove and clear', () async {
    final directory = await Directory.systemTemp.createTemp(
      'devcv_cache_test_',
    );
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    var box = await Hive.openBox<dynamic>(LocalCacheService.boxName);
    var cache = LocalCacheService(box);
    await cache.write('profile', {'name': 'Developer'});
    await box.close();

    box = await Hive.openBox<dynamic>(LocalCacheService.boxName);
    cache = LocalCacheService(box);
    expect(cache.read<Map>('profile'), {'name': 'Developer'});
    await cache.remove('profile');
    expect(cache.read<Map>('profile'), isNull);
    await cache.write('reference', ['Dart', 'Flutter']);
    await cache.clear();
    expect(cache.read<List>('reference'), isNull);
  });
}
