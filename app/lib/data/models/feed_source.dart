/// Tipo di sorgente da cui importare ricette automaticamente.
enum SourceType {
  web, // pagina/blog/sito
  instagram,
  tiktok,
  youtube,
  pinterest;

  String get label => switch (this) {
        SourceType.web => 'Sito / blog',
        SourceType.instagram => 'Instagram',
        SourceType.tiktok => 'TikTok',
        SourceType.youtube => 'YouTube',
        SourceType.pinterest => 'Pinterest',
      };

  /// Nome icona Material (per la UI).
  String get icon => switch (this) {
        SourceType.web => 'language',
        SourceType.instagram => 'photo_camera',
        SourceType.tiktok => 'music_note',
        SourceType.youtube => 'smart_display',
        SourceType.pinterest => 'push_pin',
      };

  static SourceType fromName(String? name) {
    for (final t in SourceType.values) {
      if (t.name == name) return t;
    }
    return SourceType.web;
  }
}

/// Una sorgente/feed salvata: una pagina web o un account social da cui l'app
/// analizza e importa automaticamente le ricette (filtrate per regime).
class FeedSource {
  final String? id;
  final SourceType type;

  /// URL della pagina, oppure handle social (es. "@giallozafferano").
  final String reference;
  final String name; // etichetta mostrata
  final bool autoImport; // import automatico periodico (server) attivo?
  final DateTime? lastCheckedAt;

  const FeedSource({
    this.id,
    required this.type,
    required this.reference,
    required this.name,
    this.autoImport = true,
    this.lastCheckedAt,
  });

  factory FeedSource.fromMap(Map<String, dynamic> m) => FeedSource(
        id: m['id'] as String?,
        type: SourceType.fromName(m['type'] as String?),
        reference: m['reference'] as String? ?? '',
        name: m['name'] as String? ?? '',
        autoImport: (m['auto_import'] as bool?) ?? true,
        lastCheckedAt: m['last_checked_at'] == null
            ? null
            : DateTime.tryParse(m['last_checked_at'].toString()),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type.name,
        'reference': reference,
        'name': name,
        'auto_import': autoImport,
      };

  FeedSource copyWith({bool? autoImport, DateTime? lastCheckedAt}) => FeedSource(
        id: id,
        type: type,
        reference: reference,
        name: name,
        autoImport: autoImport ?? this.autoImport,
        lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      );
}
