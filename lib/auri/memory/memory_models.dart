// lib/auri/memory/memory_models.dart

/// Cada memoria que guarda Auri
class AuriMemoryEntry {
  final String type; // ej: "conversation", "preference", "emotion"
  final String value; // contenido
  final int importance; // 1–5
  final DateTime created; // timestamp
  final bool ephemeral; // si debe expirar

  AuriMemoryEntry({
    required this.type,
    required this.value,
    required this.importance,
    required this.created,
    required this.ephemeral,
  });

  Map<String, dynamic> toJson() => {
    "type": type,
    "value": value,
    "importance": importance,
    "created": created.toIso8601String(),
    "ephemeral": ephemeral,
  };

  factory AuriMemoryEntry.fromJson(Map<String, dynamic> json) {
    return AuriMemoryEntry(
      type: json["type"] ?? "",
      value: json["value"] ?? "",
      importance: json["importance"] ?? 1,
      created:
          DateTime.tryParse(json["created"] ?? "") ??
          DateTime.now().subtract(const Duration(days: 365)),
      ephemeral: json["ephemeral"] ?? false,
    );
  }
}
