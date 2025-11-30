// lib/auri/memory/memory_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_models.dart';

class AuriMemoryManager {
  AuriMemoryManager._();
  static final AuriMemoryManager instance = AuriMemoryManager._();

  final List<AuriMemoryEntry> _memories = [];

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("auri_memories");

    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          _memories.add(AuriMemoryEntry.fromJson(item));
        }
      } catch (_) {}
    }

    _cleanup();
    _initialized = true;
  }

  // -----------------------------------------------------
  // SAVE TO STORAGE
  // -----------------------------------------------------
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_memories.map((e) => e.toJson()).toList());
    await prefs.setString("auri_memories", raw);
  }

  // -----------------------------------------------------
  // REMEMBER ANYTHING
  // -----------------------------------------------------
  Future<void> remember({
    required String type,
    required String value,
    int importance = 1,
    bool ephemeral = false,
  }) async {
    _memories.add(
      AuriMemoryEntry(
        type: type,
        value: value,
        importance: importance,
        created: DateTime.now(),
        ephemeral: ephemeral,
      ),
    );

    _cleanup();
    await _persist();
  }

  // -----------------------------------------------------
  // SEARCH
  // -----------------------------------------------------
  List<AuriMemoryEntry> search(String type) {
    return _memories.where((m) => m.type == type).toList();
  }

  AuriMemoryEntry? getLastOfType(String type) {
    final list = search(type);
    if (list.isEmpty) return null;

    list.sort((a, b) => b.created.compareTo(a.created));
    return list.first;
  }

  // -----------------------------------------------------
  // CLEAN OLD MEMORIES
  // -----------------------------------------------------
  void _cleanup() {
    final now = DateTime.now();

    _memories.removeWhere((m) {
      if (!m.ephemeral) return false;
      return now.difference(m.created).inHours > 12;
    });

    if (_memories.length > 250) {
      _memories.sort((a, b) => a.importance.compareTo(b.importance));
      _memories.removeRange(0, _memories.length - 200);
    }
  }
}
