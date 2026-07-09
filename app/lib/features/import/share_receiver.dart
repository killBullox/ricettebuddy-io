import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../data/repositories/recipe_repository.dart';
import '../../l10n/app_localizations.dart';
import '../recipes/recipe_detail_page.dart';
import 'import_flow.dart';

/// Riceve i contenuti condivisi da altre app (Share Extension iOS / Intent
/// Android): quando arriva un link (reel IG/FB/TikTok, video YouTube, ...) lo
/// importa automaticamente e apre la ricetta.
///
/// - **Android**: plugin `receive_sharing_intent` (intent `ACTION_SEND`).
/// - **iOS**: la Share Extension scrive il link nell'App Group; qui lo leggiamo
///   via un MethodChannel nativo all'avvio e ad ogni resume dell'app. Questo
///   bypassa la consegna dell'URL (inaffidabile col ciclo di vita a "scene").
///
/// È una feature NATIVA: no-op su web.
class ShareReceiver extends ConsumerStatefulWidget {
  final Widget child;
  const ShareReceiver({super.key, required this.child});

  @override
  ConsumerState<ShareReceiver> createState() => _ShareReceiverState();
}

class _ShareReceiverState extends ConsumerState<ShareReceiver>
    with WidgetsBindingObserver {
  static const _iosChannel = MethodChannel('beetit/share');
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return; // la condivisione è nativa (iOS/Android)

    // Android (e fallback): link condiviso via intent, app aperta o a freddo.
    try {
      _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handleFiles,
        onError: (_) {},
      );
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _handleFiles(files);
        ReceiveSharingIntent.instance.reset();
      });
    } catch (_) {/* piattaforma non supportata */}

    // iOS: leggiamo l'App Group direttamente (robusto col SceneDelegate).
    if (Platform.isIOS) {
      WidgetsBinding.instance.addObserver(this);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIosShare());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (!kIsWeb && Platform.isIOS) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Torna in primo piano (es. dopo "Condividi" da Instagram) → controlla.
    if (state == AppLifecycleState.resumed) _checkIosShare();
  }

  Future<void> _checkIosShare() async {
    try {
      // Ritorna {url, caption}: la didascalia arriva dall'app social loggata.
      final res = await _iosChannel.invokeMethod('getSharedUrl');
      if (res is Map) {
        _importShared(
          (res['url'] ?? '').toString(),
          (res['caption'] ?? '').toString(),
        );
      }
    } catch (_) {/* canale non disponibile */}
  }

  void _handleFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final text = files.map((f) => f.path).join(' ').trim();
    final url = RegExp(r'https?://[^\s]+').firstMatch(text)?.group(0) ?? '';
    // Se la condivisione porta un testo ricco (didascalia), passalo.
    _importShared(url, text.length >= 40 ? text : '');
  }

  Future<void> _importShared(String url, String caption) async {
    if (_importing) return; // evita import doppi (resume multipli)
    if (url.isEmpty && caption.trim().length < 40) return;
    _importing = true;
    final ctx = context;
    final l = AppLocalizations.of(ctx);
    try {
      final res = await runImportShared(ctx, ref, url: url, caption: caption);
      if (res == null) return; // annullato
      ref.invalidate(recipeListProvider);
      if (!ctx.mounted) return;
      Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => RecipeDetailPage(recipeId: res.id),
      ));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(l.importFailed('$e'))),
      );
    } finally {
      _importing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
