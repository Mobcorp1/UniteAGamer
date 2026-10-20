import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/arc_smart_trade_terms.dart';
import '../data/arc_trade_share_copy.dart';
import '../models/arc_blueprint_demand.dart';
import '../models/trading_listing.dart';
import '../repositories/arc_blueprint_demand_repository.dart';
import '../repositories/trading_repository.dart';
import '../services/uag_trade_invite_service.dart';

class ArcCollectionShareItem {
  const ArcCollectionShareItem({
    required this.label,
    this.id,
    this.rarity = 'unknown',
    this.assetPath,
    this.spares = 0,
  });
  final String label;
  final String? id;
  final String rarity;
  final String? assetPath;
  final int spares;
}

/// Shares existing Blueprint art, never the entire owned collection.
/// Smart terms are advisory until published to the canonical TradingRepository.
class ArcCollectionVisualShare {
  const ArcCollectionVisualShare._();

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<ArcCollectionShareItem> owned,
    required List<ArcCollectionShareItem> needed,
    required List<ArcCollectionShareItem> duplicates,
    Map<String, int> wantedPriorityRanks = const <String, int>{},
  }) async {
    String? link;
    var raider = 'UAG Raider';
    try {
      final invite = await UagTradeInviteService.instance.create();
      link = invite['url']?.toString();
      raider = invite['alias']?.toString() ?? raider;
    } catch (_) {
      // PNG sharing stays available offline. No invented or UID-based URL.
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ArcTradeShareDialog(
        title: title, raider: raider, link: link,
        needed: needed, duplicates: duplicates,
        priorityRanks: wantedPriorityRanks,
      ),
    );
  }

  static Widget _previewSection(
    String title,
    List<ArcCollectionShareItem> items,
    Map<String, int> minimums, {
    String? selectedId,
    ValueChanged<ArcCollectionShareItem>? onSelected,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(3, 12, 3, 7),
      child: Text(title, style: const TextStyle(
        color: Color(0xFF57E7F2), fontFamily: 'SpaceGrotesk', fontSize: 22)),
    ),
    if (items.isEmpty)
      const Padding(padding: EdgeInsets.all(12),
        child: Text('None', style: TextStyle(color: Colors.white54))),
    LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final columns = maxWidth >= 630 ? 6 : maxWidth >= 490 ? 5
          : maxWidth >= 350 ? 4 : maxWidth >= 225 ? 3 : 2;
      const gap = 7.0;
      final width = (maxWidth - gap * (columns - 1)) / columns;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final item in items)
          SizedBox(width: width,
            child: InkWell(
              key: Key('smart-trade-card-${item.id ?? item.label}'),
              borderRadius: BorderRadius.circular(9),
              onTap: onSelected == null ? null : () => onSelected(item),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF092130).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selectedId != null && selectedId == item.id
                      ? const Color(0xFFFF69B5) : const Color(0xFF276176),
                    width: selectedId != null && selectedId == item.id ? 2 : 1,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AspectRatio(aspectRatio: 1, child: item.assetPath == null
                    ? const Icon(Icons.image_not_supported_outlined, color: Colors.white30)
                    : Image.asset(item.assetPath!, fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_not_supported_outlined, color: Colors.white30))),
                  const SizedBox(height: 4),
                  Text(item.label, textAlign: TextAlign.center, maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white,
                      fontSize: 10.5, height: 1.05)),
                  if (item.spares > 0)
                    Text('x${item.spares}  •  ${minimums[item.id] ?? 1}:1',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFFF8EC8),
                        fontWeight: FontWeight.bold, fontSize: 10)),
                ]),
              ),
            ),
          ),
      ]);
    }),
  ]);

  // Export every item directly onto a canvas, including off-screen rows.
  static Future<Uint8List> _exportPng(
    String title, List<ArcCollectionShareItem> needed,
    List<ArcCollectionShareItem> duplicates, {
    bool portrait = false,
    String raider = 'UAG Raider', String? link,
    Map<String, int> minimums = const <String, int>{},
  }) async {
    const width = 1080.0;
    final columns = portrait ? 5 : 6;
    final trade = portrait ? duplicates.take(16).toList() : duplicates;
    final wanted = portrait ? needed.take(16).toList() : needed;
    const tileHeight = 190.0;
    const gap = 9.0;
    const pad = 24.0;
    double rows(List<ArcCollectionShareItem> items) =>
      (items.length / columns).ceil().toDouble().clamp(1.0, 999.0).toDouble();
    final calculated = 158 + 62 + rows(trade) * tileHeight +
      (wanted.isEmpty ? 0 : 62 + rows(wanted) * tileHeight) + 112;
    final height = portrait ? 1920.0 : calculated;
    if (height > 16000) throw StateError('Collection export too tall');
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bg = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRect(bg, Paint()..shader = ui.Gradient.linear(
      const Offset(0, 0), Offset(width, height),
      [const Color(0xFF08121E), const Color(0xFF133040), const Color(0xFF100C1D)],
      const [0.0, 0.52, 1.0]));
    final horizon = Offset(width * 0.76, height * 0.83);
    canvas.drawCircle(horizon, width * 0.65,
      Paint()..shader = ui.Gradient.radial(horizon, width * 0.65, [
        const Color(0xFF9F246E).withValues(alpha: 0.19),
        const Color(0xFF9F246E).withValues(alpha: 0),
      ]));
    final radar = Paint()..color = const Color(0xFF4FE6F2).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var i = 0; i < 10; i++) {
      canvas.drawCircle(const Offset(915, 120), (i + 1) * 74, radar);
    }
    for (var x = 0.0; x < width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), radar);
    }
    _paintText(canvas, 'UAG / ARC RAIDERS', 30, 22, 36,
      const Color(0xFF5BE7F2), bold: true, maxWidth: 1000);
    _paintText(canvas, '$raider  ·  $title', 30, 80, 25,
      Colors.white, bold: true, maxWidth: 1000);
    final decoded = <String, ui.Image?>{};
    final tileWidth = (width - 2 * pad - (columns - 1) * gap) / columns;
    var y = 158.0;
    Future<void> section(String heading, List<ArcCollectionShareItem> items) async {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(18, y, width - 36, 49), const Radius.circular(9)),
        Paint()..color = const Color(0xFF0F3140).withValues(alpha: 0.96));
      _paintText(canvas, '$heading (${items.length})', 32, y + 9, 25,
        const Color(0xFF5BE7F2), bold: true, maxWidth: 990);
      y += 62;
      if (items.isEmpty) {
        _paintText(canvas, 'None', 32, y + 10, 20, Colors.white70);
        y += tileHeight;
        return;
      }
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final x = pad + (i % columns) * (tileWidth + gap);
        final top = y + (i ~/ columns) * tileHeight;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, tileWidth, tileHeight - 7),
          const Radius.circular(10)), Paint()..color = const Color(0xE60C2836));
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, tileWidth, tileHeight - 7),
          const Radius.circular(10)), Paint()
            ..color = const Color(0xFF27788B)..style = PaintingStyle.stroke);
        final imageSize = math.min(tileWidth - 16, 108.0);
        final imageX = x + (tileWidth - imageSize) / 2;
        if (item.assetPath != null) {
          final path = item.assetPath!;
          if (!decoded.containsKey(path)) {
            try {
              final data = await rootBundle.load(path);
              final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
              final frame = await codec.getNextFrame();
              decoded[path] = frame.image;
              codec.dispose();
            } catch (_) { decoded[path] = null; }
          }
          final image = decoded[path];
          if (image != null) {
            canvas.drawImageRect(image,
              Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
              Rect.fromLTWH(imageX, top + 5, imageSize, imageSize),
              Paint()..filterQuality = FilterQuality.medium);
          }
        }
        _paintText(canvas, item.label, x + 6, top + 112, 14,
          Colors.white, bold: true, maxWidth: tileWidth - 12, maxLines: 3,
          textAlign: TextAlign.center);
        if (item.spares > 0) {
          _paintText(canvas, 'x${item.spares}  ·  ${minimums[item.id] ?? 1}:1',
            x + 6, top + tileHeight - 28, 14,
            const Color(0xFFFF91C8), bold: true, maxWidth: tileWidth - 12,
            textAlign: TextAlign.center);
        }
      }
      y += rows(items) * tileHeight;
    }
    await section('SPARES FOR TRADE', trade);
    if (wanted.isNotEmpty) await section('NEEDED', wanted);
    if (portrait && (trade.length < duplicates.length || wanted.length < needed.length)) {
      _paintText(canvas, 'Full collection available through UAG',
        28, height - 91, 18, Colors.white70, maxWidth: 1000);
    }
    _paintText(canvas, link == null
        ? 'CREATE YOUR PERSONAL RAID LINK IN UAG'
        : 'OPEN THE CLICKABLE RAID LINK IN THE SHARE CAPTION',
      28, height - 51, 18, const Color(0xFF5BE7F2), maxWidth: 1010);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    for (final decodedImage in decoded.values) { decodedImage?.dispose(); }
    if (bytes == null) throw StateError('Could not render PNG');
    return bytes.buffer.asUint8List();
  }

  static void _paintText(Canvas canvas, String value, double x, double y,
      double size, Color color, {bool bold = false, double maxWidth = 350,
      int maxLines = 1, TextAlign textAlign = TextAlign.left}) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: TextStyle(fontSize: size,
        color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, y));
    painter.dispose();
  }
}

class _ArcTradeShareDialog extends StatefulWidget {
  const _ArcTradeShareDialog({required this.title, required this.raider,
    required this.link, required this.needed, required this.duplicates,
    required this.priorityRanks});
  final String title;
  final String raider;
  final String? link;
  final List<ArcCollectionShareItem> needed;
  final List<ArcCollectionShareItem> duplicates;
  final Map<String, int> priorityRanks;
  @override
  State<_ArcTradeShareDialog> createState() => _ArcTradeShareDialogState();
}

class _ArcTradeShareDialogState extends State<_ArcTradeShareDialog> {
  ArcSmartTradeStrategy _strategy = ArcSmartTradeStrategy.balanced;
  bool _prioritiseLoadout = true;
  final Map<String, int> _overrides = {};
  final Map<String, ArcBlueprintDemand> _demand = {};
  String? _chosen;
  bool _publishing = false;
  String? _status;
  String? _inviteLink;
  late String _raiderName;
  bool _refreshingInvite = false;
  bool _sharing = false;

  String? get _verifiedTradeUrl {
    final link = _inviteLink;
    if (link == null) return null;
    final uri = Uri.tryParse(link);
    if (uri == null || UagTradeInviteService.parse(uri) == null) return null;
    return uri.toString();
  }

  String? get _whatsAppCaption {
    final link = _verifiedTradeUrl;
    return link == null ? null : ArcTradeShareCopy.whatsApp(
      raider: _raiderName, link: link);
  }

  String? get _socialCaption {
    final link = _verifiedTradeUrl;
    return link == null ? null : ArcTradeShareCopy.social(
      raider: _raiderName, link: link);
  }

  Future<void> _regeneratePersonalLink() async {
    if (_refreshingInvite) return;
    setState(() { _refreshingInvite = true; _status = null; });
    try {
      final invite = await UagTradeInviteService.instance.create();
      if (!mounted) return;
      final candidate = invite['url']?.toString();
      final uri = candidate == null ? null : Uri.tryParse(candidate);
      if (uri == null || UagTradeInviteService.parse(uri) == null) {
        throw const FormatException('Invalid secure trade URL');
      }
      setState(() {
        _inviteLink = uri.toString();
        _raiderName = invite['alias']?.toString() ?? _raiderName;
        _status = 'Your secure Raider link is ready to share.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _status =
          'Unable to generate your secure Raider link. Sign in and try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingInvite = false);
      }
    }
  }

  Future<void> _copyText(String? content, String confirmation) async {
    if (content == null) {
      setState(() => _status = 'Generate a secure Raider link before copying.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      setState(() => _status = confirmation);
    }
  }

  bool get _isBlueprint => widget.title.toLowerCase() == 'blueprints';
  DocumentReference<Map<String, dynamic>>? get _preferences {
    if (Firebase.apps.isEmpty) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : FirebaseFirestore.instance
        .collection('arc_trade_offer_preferences').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _inviteLink = widget.link;
    _raiderName = widget.raider;
    _chosen = widget.duplicates.isEmpty ? null : widget.duplicates.first.id;
    if (_isBlueprint && Firebase.apps.isNotEmpty) {
      _loadPreferences();
      _loadDemand();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final data = (await _preferences?.get())?.data();
      if (!mounted || data == null) return;
      final mode = data['smartTradeStrategy']?.toString();
      final choices = data['smartTradeOverrides'];
      setState(() {
        _strategy = ArcSmartTradeStrategy.values.firstWhere(
          (s) => s.name == mode,
          orElse: () => ArcSmartTradeStrategy.balanced);
        _prioritiseLoadout = data['smartTradePrioritiseLoadout'] != false;
        if (choices is Map) {
          for (final entry in choices.entries) {
            final count = entry.value is num ? (entry.value as num).toInt() : 0;
            if (count == 1 || count == 2) _overrides[entry.key.toString()] = count;
          }
        }
      });
    } catch (_) { /* Preferences are optional; leave safe defaults. */ }
  }

  Future<void> _loadDemand() async {
    final repository = ArcBlueprintDemandRepository();
    await Future.wait(widget.duplicates
      .where((item) => item.id != null && item.id!.isNotEmpty)
      .take(40).map((item) async {
        try {
          final demand = await repository.getDemand(item.id!);
          if (mounted) setState(() => _demand[item.id!] = demand);
        } catch (_) { /* No trusted sample => 1:1. */ }
      }));
  }

  Future<void> _savePreferences() async {
    final reference = _preferences;
    if (reference == null) return;
    try {
      await reference.set({
        'ownerUid': FirebaseAuth.instance.currentUser!.uid,
        'smartTradeStrategy': _strategy.name,
        'smartTradePrioritiseLoadout': _prioritiseLoadout,
        'smartTradeOverrides': Map<String, int>.from(_overrides),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        setState(() => _status =
          'Could not save trade preferences; review terms before publishing.');
      }
    }
  }

  List<ArcCollectionShareItem> get _orderedWanted {
    final items = [...widget.needed];
    if (_prioritiseLoadout) {
      items.sort((a, b) {
        final x = widget.priorityRanks[a.id] ?? 0;
        final y = widget.priorityRanks[b.id] ?? 0;
        if (x > 0 && y <= 0) return -1;
        if (y > 0 && x <= 0) return 1;
        if (x > 0 && y > 0) return x.compareTo(y);
        return a.label.compareTo(b.label);
      });
    }
    return items;
  }

  Map<String, int> get _minimums => {
    for (final item in widget.duplicates)
      if (item.id != null)
        item.id!: ArcSmartTradeTerms.recommend(
          strategy: _strategy,
          availableWanted: _orderedWanted.map((e) => e.id).whereType<String>().toSet().length,
          rarity: item.rarity,
          demand: _demand[item.id],
          explicitMinimum: _overrides[item.id],
        ).minimumDistinctWanted,
  };

  ArcCollectionShareItem? get _selected {
    for (final item in widget.duplicates) {
      if (item.id == _chosen) return item;
    }
    return null;
  }

  Future<void> _publish() async {
    if (_publishing) return;
    final selected = _selected;
    final id = selected?.id;
    if (selected == null || id == null || selected.spares < 1) return;
    final wanted = _orderedWanted.where((i) => i.id != null && i.id != id)
      .map((i) => (id: i.id!, name: i.label)).toList(growable: false);
    final minimum = _minimums[id] ?? 1;
    if (wanted.length < minimum) {
      setState(() => _status = 'Select enough missing Blueprints to make an offer.');
      return;
    }
    setState(() { _publishing = true; _status = null; });
    try {
      final bundle = ArcSmartTradeTerms.bundleFor(
        offeredId: id, wanted: wanted, minimum: minimum);
      // Existing canonical listing, accepted-bundle and booking pipeline.
      // This creates a proposal-ready listing, never an automatic exchange.
      await TradingRepository().createListing(
        offeredItem: selected.label,
        wantedText: minimum == 1 ? '1 missing Blueprint from my list'
          : '2 distinct missing Blueprints from my list',
        listingType: TradingListingType.specificWant,
        playWindow: 'Flexible',
        smallBundles: 0, mediumBundles: 0, largeBundles: 0,
        acceptsBlueprints: true, acceptsSeeds: false, acceptsResources: false,
        seriousOffersOnly: true,
        notes: 'UAG Smart Trade: $minimum:1 from published Needed collection. '
          'Proposals require confirmation before booking or exchange.',
        expiryDuration: const Duration(days: 3),
        offeredBlueprintNames: [selected.label],
        offeredTradeItemIds: [id], offeredTradeItemNames: [selected.label],
        wantedBlueprintNames: wanted.map((e) => e.name).toList(),
        wantedTradeItemIds: wanted.map((e) => e.id).toList(),
        wantedTradeItemNames: wanted.map((e) => e.name).toList(),
        tradeAsBundle: true, allowPartialOffers: false,
        acceptedBundles: [bundle], allowCustomBundleOffers: false,
        listingMode: TradingListingMode.bestSuitableOffer,
        bestSuitableOffer: true,
      );
      if (mounted) {
        setState(() => _status =
          'Smart listing published. Qualifying offers can now be proposed.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _status =
          'Could not publish. Check your trading profile, age verification and connection.');
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _sharePng({required bool portrait, required bool imageOnly,
      bool social = false}) async {
    if (_sharing) return;
    final caption = social ? _socialCaption : _whatsAppCaption;
    // The anonymous/public invite is a server-issued opaque token, not a UID.
    // Never substitute a generic home URL: it cannot take someone to this Raider.
    if (!imageOnly && caption == null) {
      setState(() => _status =
        'Personal Raider link unavailable. Generate a link before sharing.');
      return;
    }
    setState(() { _sharing = true; _status = null; });
    try {
      // External artwork shows only spares; private needs remain within UAG.
      final png = await ArcCollectionVisualShare._exportPng(widget.title,
        const <ArcCollectionShareItem>[], widget.duplicates,
        portrait: portrait, raider: _raiderName,
        link: _verifiedTradeUrl, minimums: _minimums);
      final name = 'UAG_${widget.title.replaceAll(' ', '_')}_${portrait ? '9x16' : 'trade'}.png';
      // Copy the real URL/caption as a fallback: some receiving apps omit
      // the supplied text when a PNG is shared. The user can paste it there.
      if (!imageOnly && caption != null) {
        try {
          await Clipboard.setData(ClipboardData(text: caption));
        } catch (_) {
          // A share-capable device may have no clipboard; still try native share.
        }
      }
      // Native share sheet: choose WhatsApp or another available app. Some
      // platforms do not accept an image and caption in one share operation.
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile.fromData(png, mimeType: 'image/png', name: name)],
        text: imageOnly ? null : caption,
        subject: social ? ArcTradeShareCopy.headline : 'Trade with $_raiderName',
      );
    } catch (_) {
      // If the platform drops captions or cannot share image+text together,
      // give the user explicit copy controls rather than claiming delivery.
      if (mounted) {
        setState(() => _status =
          'Image sharing is unavailable. Copy the post or try the device share sheet again.');
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final recommendation = selected == null ? null : ArcSmartTradeTerms.recommend(
      strategy: _strategy,
      availableWanted: _orderedWanted.length,
      rarity: selected.rarity,
      demand: _demand[selected.id],
      explicitMinimum: _overrides[selected.id]);
    return Dialog(
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppTheme.cardBackgroundDeep,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 830,
          maxHeight: MediaQuery.sizeOf(context).height * 0.94),
        child: Stack(children: [
          const Positioned.fill(child: _CinematicTradeBackdrop()),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.fromLTRB(12, 7, 5, 0),
              child: Row(children: [
                const Icon(Icons.swap_horiz_rounded, color: AppTheme.neonCyan),
                const SizedBox(width: 7),
                Expanded(child: Text('${widget.title} · TRADE SHARE',
                  style: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 27,
                    color: AppTheme.neonCyan))),
                IconButton(tooltip: 'Close share preview',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70)),
              ])),
            if (_verifiedTradeUrl == null)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8, children: [
                    const Text('Secure Raider link unavailable. Image export remains available.',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                    TextButton.icon(
                      onPressed: _refreshingInvite ? null : _regeneratePersonalLink,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(_refreshingInvite ? 'Generating…' : 'Generate Raider link'),
                    ),
                  ])),
            Expanded(child: Container(key: const Key('collections-share-image'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(children: [
                ArcCollectionVisualShare._previewSection(
                  'SPARES FOR TRADE (${widget.duplicates.length})',
                  widget.duplicates, _minimums,
                  selectedId: _chosen,
                  onSelected: _isBlueprint ? (item) => setState(() => _chosen = item.id) : null),
                ArcCollectionVisualShare._previewSection(
                  'NEEDED (${widget.needed.length})', _orderedWanted, const {}),
                if (_isBlueprint && widget.duplicates.isNotEmpty && widget.needed.isNotEmpty)
                  Padding(padding: const EdgeInsets.fromLTRB(2, 13, 2, 4),
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xE40B2534),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF267E91))),
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('SMART TRADE TERMS', style: TextStyle(
                          fontFamily: 'SpaceGrotesk', fontSize: 23, color: Color(0xFF5DE6F0))),
                        const Text('Select a spare above. 1:1 is the fallback; 2:1 requires recent demand evidence or your own override.',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 5, children: [
                          for (final strategy in ArcSmartTradeStrategy.values)
                            ChoiceChip(label: Text(switch (strategy) {
                                ArcSmartTradeStrategy.fast => 'Fast Trades',
                                ArcSmartTradeStrategy.balanced => 'Balanced',
                                ArcSmartTradeStrategy.maximumValue => 'Max Value',
                              }, style: const TextStyle(fontSize: 11)),
                              selected: _strategy == strategy,
                              onSelected: (_) {
                                setState(() => _strategy = strategy);
                                _savePreferences();
                              }),
                        ]),
                        CheckboxListTile(
                          dense: true, contentPadding: EdgeInsets.zero,
                          title: const Text('Prioritise Favourite Loadout targets',
                            style: TextStyle(fontSize: 12)),
                          value: _prioritiseLoadout,
                          onChanged: (v) {
                            setState(() => _prioritiseLoadout = v ?? true);
                            _savePreferences();
                          },
                        ),
                        if (selected != null && recommendation != null) ...[
                          Text('${selected.label}: ${recommendation.minimumDistinctWanted}:1 · ${recommendation.reason}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFE7F5FB))),
                          Wrap(spacing: 7, children: [
                            for (final choice in [0, 1, 2])
                              ChoiceChip(
                                label: Text(choice == 0 ? 'Auto' : '$choice:1',
                                  style: const TextStyle(fontSize: 11)),
                                selected: choice == (_overrides[selected.id] ?? 0),
                                onSelected: choice == 2 && _orderedWanted.length < 2 ? null : (_) {
                                  setState(() {
                                    if (choice == 0) { _overrides.remove(selected.id); }
                                    else if (selected.id != null) { _overrides[selected.id!] = choice; }
                                  });
                                  _savePreferences();
                                },
                              ),
                          ]),
                          const SizedBox(height: 5),
                          FilledButton.icon(
                            key: const Key('publish-smart-trade-terms'),
                            onPressed: _publishing || selected.id == null ||
                              _orderedWanted.isEmpty ? null : _publish,
                            icon: const Icon(Icons.handshake_outlined, size: 17),
                            label: Text(_publishing ? 'Publishing…' : 'Publish qualifying listing'),
                          ),
                          const Text('Published offers use the existing Trading Hub. Only a proposed match; both Raiders must approve.',
                            style: TextStyle(color: Colors.white60, fontSize: 10)),
                        ],
                        if (_status != null)
                          Text(_status!, style: const TextStyle(
                            color: Color(0xFFFFB5DA), fontSize: 11)),
                      ]),
                    )),
                if (_socialCaption != null)
                  ExpansionTile(
                    key: const Key('share-ready-social-description'),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text('READY-TO-POST SOCIAL CAPTION',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5DE6F0))),
                    subtitle: const Text('Catchy title, personal Raider link and 5 hashtags including #FYP',
                      style: TextStyle(fontSize: 10, color: Colors.white70)),
                    children: [Padding(
                      padding: const EdgeInsets.all(10),
                      child: SelectableText(_socialCaption!,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )],
                  ),
              ]))),
            Padding(padding: const EdgeInsets.fromLTRB(7, 5, 7, 8),
              child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 5,
                children: [
                  OutlinedButton.icon(
                    key: const Key('copy-personal-raider-link'),
                    icon: const Icon(Icons.link, size: 16),
                    onPressed: _verifiedTradeUrl == null ? null : () => _copyText(
                      _verifiedTradeUrl, 'Personal Raider trade link copied.'),
                    label: const Text('Copy link')),
                  OutlinedButton.icon(
                    key: const Key('copy-social-description'),
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: _socialCaption == null ? null : () => _copyText(
                      _socialCaption, 'Headline, social description and trade link copied.'),
                    label: const Text('Copy social post')),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.save_alt, size: 16),
                    onPressed: _sharing ? null : () => _sharePng(
                      portrait: false, imageOnly: true),
                    label: const Text('Export / save PNG')),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.smartphone_rounded, size: 16),
                    onPressed: _sharing ? null : () => _sharePng(
                      portrait: true, imageOnly: true),
                    label: const Text('9:16 social image')),
                  FilledButton.icon(
                    key: const Key('share-to-whatsapp'),
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    onPressed: _sharing || _whatsAppCaption == null ? null :
                      () => _sharePng(portrait: false, imageOnly: false),
                    label: const Text('WhatsApp / chat')),
                  FilledButton.icon(
                    key: const Key('share-social-image-and-caption'),
                    icon: const Icon(Icons.share, size: 16),
                    onPressed: _sharing || _socialCaption == null ? null :
                      () => _sharePng(portrait: true, imageOnly: false, social: true),
                    label: const Text('Share social post')),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text('If the app drops the caption, paste it from the clipboard.',
                      style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ),
                ])),

          ]),
        ]),
      ),
    );
  }
}

class _CinematicTradeBackdrop extends StatelessWidget {
  const _CinematicTradeBackdrop();
  @override
  Widget build(BuildContext context) => IgnorePointer(child: ClipRRect(
    borderRadius: BorderRadius.circular(12), child: CustomPaint(
      painter: _TradeBackdropPainter(), child: const SizedBox.expand())));
}

class _TradeBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(
      Offset.zero, Offset(size.width, size.height),
      const [Color(0xFF07121D), Color(0xFF10303F), Color(0xFF161020)],
      const [0.0, 0.52, 1.0]));
    final radar = Paint()..color = const Color(0xFF5CE9F0).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var radius = 50.0; radius < size.width; radius += 64) {
      canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.19), radius, radar);
    }
    final glow = Offset(size.width * 0.8, size.height * 0.85);
    canvas.drawCircle(glow, size.width * 0.6, Paint()..shader = ui.Gradient.radial(
      glow, size.width * 0.6, [const Color(0x339F2A8B),
        const Color(0x009F2A8B)]));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
