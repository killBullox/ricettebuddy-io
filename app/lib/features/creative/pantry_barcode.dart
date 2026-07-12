import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pagina scanner: inquadra il codice a barre e ritorna l'EAN letto.
class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final code = capture.barcodes
              .map((b) => b.rawValue ?? '')
              .firstWhere((v) => v.length >= 8, orElse: () => '');
          if (code.isEmpty) return;
          _done = true;
          Navigator.of(context).pop(code);
        },
      ),
    );
  }
}

/// Prodotto trovato su Open Food Facts.
class OffProduct {
  final String name;
  final double? quantity;
  final String? unit;
  const OffProduct({required this.name, this.quantity, this.unit});
}

/// Cerca l'EAN su Open Food Facts (database libero, nessuna chiave).
/// Ritorna null se il prodotto non esiste.
Future<OffProduct?> lookupBarcode(String ean) async {
  final r = await http
      .get(Uri.parse(
          'https://world.openfoodfacts.org/api/v2/product/$ean.json'
          '?fields=product_name,product_name_it,brands,quantity'))
      .timeout(const Duration(seconds: 15));
  if (r.statusCode != 200) return null;
  final j = jsonDecode(r.body) as Map<String, dynamic>;
  if (j['status'] != 1) return null;
  final p = Map<String, dynamic>.from(j['product'] as Map);
  final name = ((p['product_name_it'] ?? p['product_name']) ?? '')
      .toString()
      .trim();
  if (name.isEmpty) return null;

  // "quantity" è testo libero, es. "400 g", "1 l", "3 x 125 g".
  double? qty;
  String? unit;
  final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*(kg|g|gr|l|cl|ml)\b',
          caseSensitive: false)
      .firstMatch((p['quantity'] ?? '').toString());
  if (m != null) {
    qty = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    unit = m.group(2)!.toLowerCase();
    if (unit == 'kg') {
      qty = (qty ?? 0) * 1000;
      unit = 'g';
    } else if (unit == 'l') {
      qty = (qty ?? 0) * 1000;
      unit = 'ml';
    } else if (unit == 'cl') {
      qty = (qty ?? 0) * 10;
      unit = 'ml';
    } else if (unit == 'gr') {
      unit = 'g';
    }
  }
  return OffProduct(name: name, quantity: qty, unit: unit);
}
