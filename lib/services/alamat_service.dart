import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alamat_kirim.dart';

/// Persistensi daftar alamat kirim di perangkat (belum ada API alamat).
class AlamatService {
  AlamatService._();

  static const _keyList = 'alamat_kirim_list';
  static const _keyAktif = 'alamat_kirim_aktif';

  static Future<List<AlamatKirim>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyList);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw) as List;
      return data
          .map((e) => AlamatKirim.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(AlamatKirim a) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await list();
    final idx = items.indexWhere((e) => e.id == a.id);
    if (idx >= 0) {
      items[idx] = a;
    } else {
      items.add(a);
    }
    await prefs.setString(_keyList, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await list()..removeWhere((e) => e.id == id);
    await prefs.setString(_keyList, jsonEncode(items.map((e) => e.toJson()).toList()));
    if (prefs.getInt(_keyAktif) == id) {
      await prefs.remove(_keyAktif);
    }
  }

  static Future<int?> aktifId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAktif);
  }

  static Future<void> setAktifId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAktif, id);
  }
}
