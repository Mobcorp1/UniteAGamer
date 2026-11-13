import 'package:flutter/material.dart';

import '../models/arc_trade_listing.dart';
import '../repositories/arc_trade_listing_repository.dart';
import '../widgets/arc_companion_bottom_dock.dart';
import '../widgets/arc_raiders_screen_shell.dart';
import '../widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcMyTradeListingsScreen extends StatelessWidget {
  const ArcMyTradeListingsScreen({super.key});

  static const routeName = '/arc-my-trade-listings';

  @override
  Widget build(BuildContext context) {
    final repository = ArcTradeListingRepository();

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Trading'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'My Trade Listings',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: StreamBuilder<List<ArcTradeListing>>(
            stream: repository.watchMyListings(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <ArcTradeListing>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: ArcUiTokens.primaryAccent,
                  ),
                );
              }

              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 12, 14, 104),
                    child: ArcRaidersStatePanel(
                      title: 'No trade listings',
                      message:
                          'Create a listing when you have a blueprint ready to trade.',
                      icon: Icons.inventory_2_outlined,
                      accent: ArcUiTokens.secondaryAccent,
                    ),
                  ),
                );
              }

              return ArcRaidersPageList(
                maxWidth: 920,
                bottomPadding: 104,
                children: [
                  ArcRaidersPageHeader(
                    title: 'MY TRADE LISTINGS',
                    subtitle: '${items.length} saved trade listing records.',
                    icon: Icons.inventory_2_outlined,
                    accent: ArcUiTokens.secondaryAccent,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  for (final item in items)
                    ArcRaidersSectionCard(
                      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
                      accent: item.isOpen
                          ? ArcUiTokens.primaryAccent
                          : ArcUiTokens.textTertiary,
                      padding: const EdgeInsets.all(ArcUiTokens.gapM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.offeredBlueprintName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ArcUiTokens.sectionTitle(
                                    fontSize: 18,
                                    color: ArcUiTokens.textPrimary,
                                  ),
                                ),
                              ),
                              ArcTacticalStatusPill(
                                label: item.status,
                                accent: item.isOpen
                                    ? ArcUiTokens.success
                                    : ArcUiTokens.textTertiary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _tradeSide(
                                  'OFFERING',
                                  item.offeredBlueprintName,
                                  ArcUiTokens.secondaryAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tradeSide(
                                  'WANTED',
                                  item.wantedBlueprintName,
                                  ArcUiTokens.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ArcTacticalStatusPill(
                                label: item.region,
                                icon: Icons.public_rounded,
                                accent: ArcUiTokens.primaryAccent,
                              ),
                              ArcTacticalStatusPill(
                                label: item.platform,
                                icon: Icons.sports_esports_rounded,
                                accent: ArcUiTokens.secondaryAccent,
                              ),
                              if (item.note.isNotEmpty)
                                ArcTacticalStatusPill(
                                  label: 'Note',
                                  icon: Icons.sticky_note_2_outlined,
                                  accent: ArcUiTokens.warning,
                                ),
                            ],
                          ),
                          if (item.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ArcUiTokens.bodySmall(
                                color: ArcUiTokens.textTertiary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'close') {
                                  await repository.closeListing(item.id);
                                } else if (value == 'reopen') {
                                  await repository.reopenListing(item.id);
                                } else if (value == 'delete') {
                                  await repository.deleteListing(item.id);
                                }
                              },
                              itemBuilder: (context) => [
                                if (item.isOpen)
                                  const PopupMenuItem(
                                    value: 'close',
                                    child: Text('Close'),
                                  ),
                                if (!item.isOpen)
                                  const PopupMenuItem(
                                    value: 'reopen',
                                    child: Text('Reopen'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tradeSide(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: accent,
        borderOpacity: 0.18,
        radius: ArcUiTokens.radiusM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ArcUiTokens.label(color: accent)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.body(
              color: ArcUiTokens.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
