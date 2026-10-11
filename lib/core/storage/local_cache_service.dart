import 'package:hive/hive.dart';

class LocalCacheService {
  LocalCacheService(this._box);

  static const boxName = 'general_cache';
  final Box<dynamic> _box;

  T? read<T>(String key) => _box.get(key) as T?;

  Future<void> write(String key, Object value) => _box.put(key, value);

  Future<void> remove(String key) => _box.delete(key);

  Future<void> clear() async {
    await _box.clear();
  }
}
