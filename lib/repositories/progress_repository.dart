import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog_models.dart';

/// A seam for future cloud sync. v1 persists only the first collection event.
abstract class ProgressRepository {
  Future<Map<String, CollectionRecord>> load();
  Future<void> save(CollectionRecord record);
  Future<void> remove(String brandId);
}

class LocalProgressRepository implements ProgressRepository {
  static const _key = 'cardex.collection.v1';

  @override
  Future<Map<String, CollectionRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return decoded.map((id, value) => MapEntry(
          id,
          CollectionRecord(brandId: id, firstCollectedAt: DateTime.parse(value as String)),
        ));
  }

  @override
  Future<void> save(CollectionRecord record) async {
    final records = await load();
    records.putIfAbsent(record.brandId, () => record);
    await _write(records);
  }

  @override
  Future<void> remove(String brandId) async {
    final records = await load();
    records.remove(brandId);
    await _write(records);
  }

  Future<void> _write(Map<String, CollectionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = records.map((id, record) => MapEntry(id, record.firstCollectedAt.toIso8601String()));
    await prefs.setString(_key, jsonEncode(payload));
  }
}
