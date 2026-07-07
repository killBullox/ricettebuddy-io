import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../common/cooking_loader.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/recipe_repository.dart';
import '../recipes/recipe_detail_page.dart';

/// Riceve i contenuti condivisi da altre app (Share Extension iOS / Intent
/// Android): quando arriva un link (reel IG/FB/TikTok, video YouTube, ...) lo
/// importa automaticamente e apre la ricetta.
///
/// È una feature NATIVA: attiva solo su mobile, no-op su web.
class ShareReceiver extends ConsumerStatefulWidget {
  final Widget child;
  const ShareReceiver({super.key, required this.child});

  @override
  ConsumerState<ShareReceiver> createState() => _ShareReceiverState();
}

class _ShareReceiverState extends ConsumerState<ShareReceiver> {
  StreamSubscription<List<SharedMediaFile>>? _sub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return; // la condivisione è nativa (iOS/Android)
    try {
      // App già aperta: link condiviso mentre gira.
      _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handle,
        onError: (_) {},
      );
      // App aperta DA una condivisione (avvio a freddo).
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _handle(files);
        ReceiveSharingIntent.instance.reset();
      });
    } catch (_) {/* piattaforma non supportata */}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handle(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final text = files.map((f) => f.path).join(' ');
    final m = RegExp(r'https?://[^\s]+').firstMatch(text);
    if (m != null) _import(m.group(0)!);
  }

  Future<void> _import(String url) async {
    final ctx = context;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierColor: const Color(0xFFFBFAF7),
      useSafeArea: false,
      builder: (_) => const Center(
        child: CookingLoader(size: 230, message: 'Sto preparando la tua ricetta…'),
      ),
    );
    try {
      final res = await ref.read(importRepositoryProvider).importFromUrl(url);
      ref.invalidate(recipeListProvider);
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop(); // chiude il loader
      Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => RecipeDetailPage(recipeId: res.id),
      ));
    } catch (e) {
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Import non riuscito: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
