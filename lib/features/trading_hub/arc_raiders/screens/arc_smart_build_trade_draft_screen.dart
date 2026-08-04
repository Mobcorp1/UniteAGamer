import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_integration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_integration_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcSmartBuildTradeDraftScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/smart-build-trade-draft';

  const ArcSmartBuildTradeDraftScreen({super.key});

  @override
  State<ArcSmartBuildTradeDraftScreen> createState() =>
      _ArcSmartBuildTradeDraftScreenState();
}

class _ArcSmartBuildTradeDraftScreenState
    extends State<ArcSmartBuildTradeDraftScreen> {
  final ArcSavedLoadoutRepository _loadouts = ArcSavedLoadoutRepository();
  final ArcBlueprintRepository _blueprints = ArcBlueprintRepository();

  String _bundleText(
    ArcGeneratedLoadoutPlan plan,
    ArcLoadoutIntegrationSnapshot integration,
  ) {
    final lines = <String>[
      'UAG SMART BUILD TRADE DRAFT',
      plan.displayName,
      '',
      if (integration.missingBlueprints.isNotEmpty) 'MISSING BLUEPRINTS',
      for (final item in integration.missingBlueprints)
        '- ${item.itemName} (${item.slotLabel}, priority ${item.priorityRank})',
      if (integration.missingResources.isNotEmpty) '',
      if (integration.missingResources.isNotEmpty) 'MISSING RESOURCES',
      for (final item in integration.missingResources)
        '- ${item.missingQuantity}x ${item.itemName}',
      '',
      integration.tradeTemplate.allowEquivalentOffers
          ? 'Value build: equivalent offers may be considered.'
          : 'Meta build: exact components preferred.',
    ];
    return lines.join('\n');
  }

  Future<void> _copyBundle(
    ArcGeneratedLoadoutPlan plan,
    ArcLoadoutIntegrationSnapshot integration,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: _bundleText(plan, integration)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Smart Build trade draft copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cardBackgroundDeep,
      appBar: AppBar(
        title: const Text('Smart Build Trade Draft'),
        backgroundColor: AppTheme.cardBackgroundDeep,
      ),
      body: StreamBuilder(
        stream: _loadouts.watchFavouriteLoadout(),
        builder: (context, loadoutSnapshot) {
          if (loadoutSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loadout = loadoutSnapshot.data;
          final plan = ArcGeneratedLoadoutPlan.fromMap(loadout?.smartBuildData);
          if (plan == null) {
            return _emptyState(
              icon: Icons.tune_rounded,
              title: 'No active Smart Build',
              message:
                  'Generate and save a Smart Build in Favourite Loadout first.',
              actionLabel: 'Back to Favourite Loadout',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          return StreamBuilder<Map<String, ArcBlueprintState>>(
            stream: _blueprints.watchMyBlueprintStates(),
            builder: (context, blueprintSnapshot) {
              final states =
                  blueprintSnapshot.data ?? const <String, ArcBlueprintState>{};
              final integration = ArcLoadoutIntegrationEngine.evaluate(
                plan: plan,
                blueprintStates: states,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(plan, integration),
                  const SizedBox(height: 14),
                  _section(
                    title: 'Missing Blueprints',
                    icon: Icons.grid_view_rounded,
                    accent: AppTheme.neonPink,
                    children: integration.missingBlueprints.isEmpty
                        ? const [
                            Text(
                              'All Blueprint requirements are secured.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ]
                        : [
                            for (final item in integration.missingBlueprints)
                              _requirementRow(
                                '${item.itemName} Blueprint',
                                '${item.slotLabel} • Priority ${item.priorityRank}',
                                AppTheme.neonPink,
                              ),
                          ],
                  ),
                  const SizedBox(height: 12),
                  _section(
                    title: 'Missing Resources',
                    icon: Icons.inventory_2_rounded,
                    accent: Colors.amberAccent,
                    children: integration.missingResources.isEmpty
                        ? const [
                            Text(
                              'No tracked resource gaps remain.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ]
                        : [
                            for (final item in integration.missingResources)
                              _requirementRow(
                                '${item.missingQuantity}x ${item.itemName}',
                                '${item.ownedQuantity}/${item.requiredQuantity} owned',
                                Colors.amberAccent,
                              ),
                          ],
                  ),
                  const SizedBox(height: 12),
                  _section(
                    title: 'Trade Rules',
                    icon: Icons.rule_rounded,
                    accent: AppTheme.neonCyan,
                    children: [
                      _requirementRow(
                        '${integration.tradeTemplate.components.length} exact requirements',
                        integration.tradeTemplate.allowEquivalentOffers
                            ? 'Value build accepts equivalent alternatives.'
                            : 'Meta build prefers exact components.',
                        AppTheme.neonCyan,
                      ),
                      _requirementRow(
                        'Minimum complete bundle',
                        '${integration.tradeTemplate.terms.minimumRequiredQuantity} total item units',
                        AppTheme.neonCyan,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: integration.tradeTemplate.components.isEmpty
                            ? null
                            : () => _copyBundle(plan, integration),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy Exact Bundle'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(SmartTradeAssistScreen.routeName),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Open Smart Trade'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(TraderHubScreen.routeName),
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Open Trader Hub'),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(
    ArcGeneratedLoadoutPlan plan,
    ArcLoadoutIntegrationSnapshot integration,
  ) {
    final accent = integration.complete
        ? Colors.lightGreenAccent
        : AppTheme.neonCyan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: integration.completionPercent / 100,
                  strokeWidth: 7,
                  color: accent,
                  backgroundColor: Colors.white12,
                ),
                Text(
                  '${integration.completionPercent}%',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  integration.nextMove,
                  style: const TextStyle(color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _requirementRow(String title, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.chevron_right_rounded, color: color, size: 20),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.neonCyan, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
