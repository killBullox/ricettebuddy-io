/// Voce di dispensa: ciò che l'utente ha in casa. Base per lo "Chef creativo"
/// e per gli avvisi "usa prima che scada".
class PantryItem {
  final String? id;
  final String rawText;
  final String normalizedName; // chiave di match con gli ingredienti
  final double? quantity;
  final String? unit;
  final String? aisleCategory;
  final DateTime? expiryDate;

  const PantryItem({
    this.id,
    required this.rawText,
    required this.normalizedName,
    this.quantity,
    this.unit,
    this.aisleCategory,
    this.expiryDate,
  });

  factory PantryItem.fromMap(Map<String, dynamic> m) => PantryItem(
        id: m['id'] as String?,
        rawText: m['raw_text'] as String? ?? '',
        normalizedName: m['normalized_name'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble(),
        unit: m['unit'] as String?,
        aisleCategory: m['aisle_category'] as String?,
        expiryDate: m['expiry_date'] == null
            ? null
            : DateTime.tryParse(m['expiry_date'].toString()),
      );

  PantryItem copyWith({
    String? rawText,
    String? normalizedName,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
  }) =>
      PantryItem(
        id: id,
        rawText: rawText ?? this.rawText,
        normalizedName: normalizedName ?? this.normalizedName,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        aisleCategory: aisleCategory,
        expiryDate: expiryDate ?? this.expiryDate,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'raw_text': rawText,
        'normalized_name': normalizedName,
        'quantity': quantity,
        'unit': unit,
        'aisle_category': aisleCategory,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
      };
}
