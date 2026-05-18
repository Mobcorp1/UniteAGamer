import 'package:flutter/material.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/repositories/arc_scrappy_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcScrappyItemSheet extends StatefulWidget {
  const ArcScrappyItemSheet({
    super.key,
    required this.item,
    required this.initialState,
    required this.repository,
    required this.tierColor,
    this.onSaved,
    this.onClear,
  });

  final ArcScrappyItem item;
  final ArcScrappyState initialState;
  final ArcScrappyRepository repository;
  final Color tierColor;
  final VoidCallback? onSaved;
  final Future<void> Function()? onClear;

  @override
  State<ArcScrappyItemSheet> createState() => _ArcScrappyItemSheetState();
}

class _ArcScrappyItemSheetState extends State<ArcScrappyItemSheet> {
  late final TextEditingController _collectedController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _collectedController = TextEditingController(
      text: widget.initialState.collectedCount.toString(),
    );
  }

  @override
  void dispose() {
    _collectedController.dispose();
    super.dispose();
  }

  int get _collectedCount =>
      int.tryParse(_collectedController.text.trim())?.clamp(0, 999999) ?? 0;

  int get _remainingNeeded =>
      (_itemNeeded - _collectedCount).clamp(0, _itemNeeded);
  int get _surplus => (_collectedCount - _itemNeeded).clamp(0, 999999);
  int get _itemNeeded => widget.item.neededCount;
  bool get _completed => _collectedCount >= _itemNeeded;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await widget.repository.saveScrappyState(
        ArcScrappyState(
          itemId: widget.item.id,
          collectedCount: _collectedCount,
          updatedAt: DateTime.now(),
        ),
        neededCount: widget.item.neededCount,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save ${widget.item.name}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(
          radius: 14,
          borderColor: color.withValues(alpha: 0.24),
          backgroundColor: AppTheme.cardBackgroundAlt,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTheme.tradingHeading(fontSize: 20, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundDeep,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: widget.tierColor.withValues(alpha: 0.24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text(
                  widget.item.name,
                  style: AppTheme.tradingHeading(
                    fontSize: 28,
                    color: widget.tierColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.item.group} • Need x${widget.item.neededCount}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                if (widget.item.helperText.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    widget.item.helperText,
                    style: const TextStyle(color: Colors.white60, height: 1.4),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceL),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: AppTheme.tradingCardDecoration(
                    radius: 16,
                    borderColor: widget.tierColor.withValues(alpha: 0.18),
                    backgroundColor: AppTheme.cardBackgroundAlt,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: widget.tierColor.withValues(alpha: 0.18),
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.cardBackgroundAlt,
                              AppTheme.cardBackgroundDeep,
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: SizedBox.expand(
                              child: Image.asset(
                                widget.item.imageAsset,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                                isAntiAlias: true,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      color: widget.tierColor,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Track total collected',
                              style: AppTheme.tradingHeading(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter the full amount you currently own. Anything above the target becomes tradeable surplus automatically.',
                              style: const TextStyle(
                                color: Colors.white60,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                TextField(
                  controller: _collectedController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration:
                      AppTheme.tradingInputDecoration(
                        label: 'Amount Collected',
                      ).copyWith(
                        helperText:
                            'Need ${widget.item.neededCount}. Example: 8 collected from a target of 12 means 4 still needed.',
                        helperStyle: const TextStyle(color: Colors.white54),
                      ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Row(
                  children: [
                    _statCard(
                      label: 'Needed Total',
                      value: _itemNeeded.toString(),
                      color: widget.tierColor,
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    _statCard(
                      label: 'Collected',
                      value: _collectedCount.toString(),
                      color: AppTheme.neonCyan,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceM),
                Row(
                  children: [
                    _statCard(
                      label: 'Still Needed',
                      value: _remainingNeeded.toString(),
                      color: _remainingNeeded > 0
                          ? AppTheme.neonPink
                          : Colors.lightGreenAccent,
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    _statCard(
                      label: 'Surplus',
                      value: _surplus.toString(),
                      color: _surplus > 0 ? Colors.amberAccent : Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceL),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: AppTheme.tradingCardDecoration(
                    radius: 14,
                    borderColor:
                        (_completed
                                ? Colors.lightGreenAccent
                                : AppTheme.neonPink)
                            .withValues(alpha: 0.22),
                    backgroundColor: AppTheme.cardBackgroundAlt,
                  ),
                  child: Text(
                    _completed
                        ? _surplus > 0
                              ? 'Target complete. You have $_surplus spare that can be traded.'
                              : 'Target complete. No spare surplus yet.'
                        : 'You still need $_remainingNeeded more to complete this item.',
                    style: TextStyle(
                      color: _completed
                          ? Colors.lightGreenAccent
                          : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.tierColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Progress',
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),
                if (widget.onClear != null) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Center(
                    child: TextButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              await widget.onClear?.call();
                              if (!mounted) return;
                              Navigator.of(this.context).pop(true);
                            },
                      child: const Text(
                        'Clear this item',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
