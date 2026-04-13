import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/trading_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingMakeOfferScreen extends StatefulWidget {
  const TradingMakeOfferScreen({super.key, required this.listing});

  final TradingListing listing;

  @override
  State<TradingMakeOfferScreen> createState() => _TradingMakeOfferScreenState();
}

class _TradingMakeOfferScreenState extends State<TradingMakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TradingRepository _repository = TradingRepository();

  final TextEditingController _blueprintController = TextEditingController();
  final TextEditingController _resourcesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _includesResources = false;
  bool _isSaving = false;
  bool _isLoadingMatches = true;
  List<String> _matchingDupes = <String>[];
  Set<String> _selectedDupes = <String>{};

  int _smallBundles = 0;
  int _mediumBundles = 0;
  int _largeBundles = 0;

  int get _seedTotal =>
      (_smallBundles * 10) + (_mediumBundles * 50) + (_largeBundles * 100);

  @override
  void initState() {
    super.initState();
    _loadMatchingDupes();
  }

  Future<void> _loadMatchingDupes() async {
    try {
      final matches = await _repository.getMatchingDuplicateBlueprintNames(
        widget.listing,
      );
      if (!mounted) return;
      setState(() {
        _matchingDupes = matches;
        _selectedDupes = matches.toSet();
        _blueprintController.text = matches.join(', ');
        _isLoadingMatches = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMatches = false;
      });
    }
  }

  void _syncBlueprintTextFromSelection() {
    final values = _selectedDupes.toList()..sort();
    _blueprintController.text = values.join(', ');
  }

  @override
  void dispose() {
    _blueprintController.dispose();
    _resourcesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 21,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          child,
        ],
      ),
    );
  }

  Widget _bundleRow({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(
            Icons.remove_circle_outline,
            color: AppTheme.neonPink,
          ),
        ),
        Text(
          '$value',
          style: AppTheme.tradingHeading(
            fontSize: 22,
            color: AppTheme.neonCyan,
          ),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonPink),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.tradingInputDecoration(label: label),
    );
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.createOffer(
        listing: widget.listing,
        offeredBlueprintText: _blueprintController.text,
        smallBundles: _smallBundles,
        mediumBundles: _mediumBundles,
        largeBundles: _largeBundles,
        includesResources: _includesResources,
        resourcesText: _resourcesController.text,
        note: _noteController.text,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Offer sent successfully.'),
          backgroundColor: AppTheme.neonPink,
        ),
      );

      navigator.pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not send offer: $error'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('Make Offer', style: AppTheme.tradingHeading(fontSize: 25)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.pageMaxWidth,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: AppTheme.pagePadding,
                    children: [
                      _sectionCard(
                        title: 'Listing Summary',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: AppTheme.tradingHeading(fontSize: 22),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Offering: ${listing.offeredSummary}',
                              style: TextStyle(
                                color: AppTheme.tradingMutedText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Wants: ${listing.wantedSummary}',
                              style: TextStyle(
                                color: AppTheme.tradingMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _sectionCard(
                        title: 'Auto Matches',
                        child: _isLoadingMatches
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.neonCyan,
                                ),
                              )
                            : _matchingDupes.isEmpty
                                ? Text(
                                    'No matching dupes found in your collection yet. You can still type a manual offer below.',
                                    style: TextStyle(color: AppTheme.tradingMutedText),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _matchingDupes.map((name) {
                                      final selected = _selectedDupes.contains(name);
                                      return FilterChip(
                                        selected: selected,
                                        label: Text(name),
                                        labelStyle: TextStyle(
                                          color: selected
                                              ? Colors.black
                                              : Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        selectedColor: AppTheme.neonCyan,
                                        checkmarkColor: Colors.black,
                                        backgroundColor: AppTheme.tradingCardBackground,
                                        side: BorderSide(
                                          color: selected
                                              ? AppTheme.neonCyan
                                              : AppTheme.tradingSoftBorder,
                                        ),
                                        onSelected: (value) {
                                          setState(() {
                                            if (value) {
                                              _selectedDupes.add(name);
                                            } else {
                                              _selectedDupes.remove(name);
                                            }
                                            _syncBlueprintTextFromSelection();
                                          });
                                        },
                                      );
                                    }).toList(growable: false),
                                  ),
                      ),
                      _sectionCard(
                        title: 'Your Offer',
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _blueprintController,
                              label: 'Blueprints You Are Offering',
                              validator: (value) {
                                final hasBlueprint =
                                    value != null && value.trim().isNotEmpty;
                                final hasSeeds = _seedTotal > 0;
                                final hasResources =
                                    _includesResources &&
                                    _resourcesController.text.trim().isNotEmpty;

                                if (!hasBlueprint && !hasSeeds && !hasResources) {
                                  return 'Add at least one blueprint, seed bundle or resource.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            SwitchListTile(
                              value: _includesResources,
                              activeThumbColor: AppTheme.neonPink,
                              title: const Text(
                                'Include Resources',
                                style: TextStyle(color: Colors.white),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _includesResources = value;
                                });
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            _buildTextField(
                              controller: _resourcesController,
                              label: 'Resource Summary',
                              maxLines: 3,
                              enabled: _includesResources,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Seed Bundles',
                                style: AppTheme.tradingHeading(
                                  fontSize: 18,
                                  color: AppTheme.neonCyan,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _bundleRow(
                              label: '10 Seed Bundles',
                              value: _smallBundles,
                              onMinus: () {
                                if (_smallBundles == 0) return;
                                setState(() => _smallBundles -= 1);
                              },
                              onPlus: () {
                                setState(() => _smallBundles += 1);
                              },
                            ),
                            _bundleRow(
                              label: '50 Seed Bundles',
                              value: _mediumBundles,
                              onMinus: () {
                                if (_mediumBundles == 0) return;
                                setState(() => _mediumBundles -= 1);
                              },
                              onPlus: () {
                                setState(() => _mediumBundles += 1);
                              },
                            ),
                            _bundleRow(
                              label: '100 Seed Bundles',
                              value: _largeBundles,
                              onMinus: () {
                                if (_largeBundles == 0) return;
                                setState(() => _largeBundles -= 1);
                              },
                              onPlus: () {
                                setState(() => _largeBundles += 1);
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Seed Total: $_seedTotal',
                                style: AppTheme.tradingHeading(
                                  fontSize: 18,
                                  color: AppTheme.neonPink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _noteController,
                              label: 'Message To Trader',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submitOffer,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSaving ? 'Sending Offer...' : 'Send Offer',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPink,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
