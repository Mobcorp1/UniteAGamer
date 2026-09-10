import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import '../models/arc_trade_listing.dart';
import '../models/arc_trader_profile.dart';
import '../repositories/arc_trade_listing_repository.dart';
import '../repositories/arc_trader_profile_repository.dart';

class ArcCreateTradeListingScreen extends StatefulWidget {
  const ArcCreateTradeListingScreen({super.key});

  static const routeName = '/arc-create-trade-listing';

  @override
  State<ArcCreateTradeListingScreen> createState() =>
      _ArcCreateTradeListingScreenState();
}

class _ArcCreateTradeListingScreenState
    extends State<ArcCreateTradeListingScreen> {
  final ArcTradeListingRepository _listingRepository =
      ArcTradeListingRepository();
  final ArcTraderProfileRepository _profileRepository =
      ArcTraderProfileRepository();

  final TextEditingController _offeredBlueprintIdController =
      TextEditingController();
  final TextEditingController _offeredBlueprintNameController =
      TextEditingController();
  final TextEditingController _wantedBlueprintIdController =
      TextEditingController();
  final TextEditingController _wantedBlueprintNameController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  ArcTraderProfile? _profile;
  bool _loadingProfile = true;
  bool _profileLoadFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileLoadFailed = false;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _loadingProfile = false;
          _profile = null;
        });
        return;
      }
      final profile = await _profileRepository.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileLoadFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _offeredBlueprintIdController.dispose();
    _offeredBlueprintNameController.dispose();
    _wantedBlueprintIdController.dispose();
    _wantedBlueprintNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null || _saving) return;
    setState(() => _saving = true);

    final listing = ArcTradeListing(
      id: '',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      offeredBlueprintId: _offeredBlueprintIdController.text.trim(),
      offeredBlueprintName: _offeredBlueprintNameController.text.trim(),
      wantedBlueprintId: _wantedBlueprintIdController.text.trim(),
      wantedBlueprintName: _wantedBlueprintNameController.text.trim(),
      region: profile.region,
      platform: profile.platform,
      status: 'open',
      note: _noteController.text.trim(),
    );

    try {
      await _listingRepository.createListing(listing);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create this listing. Try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _blueprintField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
      decoration: ArcUiTokens.inputDecoration(
        labelText: label,
        prefixIcon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Create Trade Listing',
          style: ArcUiTokens.sectionTitle(fontSize: 22),
        ),
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: ArcRaidersPageList(
            maxWidth: 860,
            bottomPadding: 112,
            children: [
              const ArcRaidersPageHeader(
                title: 'TRADE REQUEST',
                subtitle:
                    'Declare what you can offer and what you need in return.',
                icon: Icons.swap_horiz_rounded,
                accent: ArcUiTokens.secondaryAccent,
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              if (_loadingProfile)
                const ArcRaidersStatePanel(
                  title: 'Loading trader identity',
                  message: 'Linking this listing to your region and platform.',
                  icon: Icons.sync_rounded,
                  accent: ArcUiTokens.primaryAccent,
                  action: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_profileLoadFailed)
                ArcRaidersStatePanel(
                  title: 'Trader profile unavailable',
                  message:
                      'Your profile could not be loaded, so the listing cannot be published safely yet.',
                  icon: Icons.cloud_off_rounded,
                  accent: ArcUiTokens.warning,
                  action: TextButton.icon(
                    style: ArcUiTokens.textButtonStyle(
                      accent: ArcUiTokens.primaryAccent,
                    ),
                    onPressed: _loadProfile,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                )
              else if (profile == null)
                const ArcRaidersStatePanel(
                  title: 'Complete your Hub Profile first',
                  message:
                      'Trade listings need a Raider identity, region and platform before they can go live.',
                  icon: Icons.person_off_outlined,
                  accent: ArcUiTokens.warning,
                )
              else ...[
                Wrap(
                  spacing: ArcUiTokens.gapS,
                  runSpacing: ArcUiTokens.gapS,
                  children: [
                    ArcTacticalStatusPill(
                      label: profile.region.isEmpty
                          ? 'Region not set'
                          : profile.region,
                      icon: Icons.public_rounded,
                      accent: ArcUiTokens.primaryAccent,
                    ),
                    ArcTacticalStatusPill(
                      label: profile.platform.isEmpty
                          ? 'Platform not set'
                          : profile.platform,
                      icon: Icons.sports_esports_rounded,
                      accent: ArcUiTokens.secondaryAccent,
                    ),
                    const ArcTacticalStatusPill(
                      label: 'Open listing',
                      icon: Icons.radio_button_checked_rounded,
                      accent: ArcUiTokens.success,
                    ),
                  ],
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                ArcRaidersSectionCard(
                  accent: ArcUiTokens.secondaryAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOU OFFER',
                        style: ArcUiTokens.sectionTitle(
                          fontSize: 16,
                          color: ArcUiTokens.secondaryAccent,
                        ),
                      ),
                      const SizedBox(height: ArcUiTokens.gapS),
                      _blueprintField(
                        controller: _offeredBlueprintNameController,
                        label: 'Offered Blueprint Name',
                        icon: Icons.inventory_2_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: ArcUiTokens.gapS),
                      _blueprintField(
                        controller: _offeredBlueprintIdController,
                        label: 'Offered Blueprint ID',
                        icon: Icons.tag_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                ArcRaidersSectionCard(
                  accent: ArcUiTokens.primaryAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOU NEED',
                        style: ArcUiTokens.sectionTitle(
                          fontSize: 16,
                          color: ArcUiTokens.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: ArcUiTokens.gapS),
                      _blueprintField(
                        controller: _wantedBlueprintNameController,
                        label: 'Wanted Blueprint Name',
                        icon: Icons.search_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: ArcUiTokens.gapS),
                      _blueprintField(
                        controller: _wantedBlueprintIdController,
                        label: 'Wanted Blueprint ID',
                        icon: Icons.tag_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                ArcRaidersSectionCard(
                  accent: ArcUiTokens.textTertiary,
                  child: TextField(
                    controller: _noteController,
                    maxLines: 4,
                    maxLength: 300,
                    style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                    decoration: ArcUiTokens.inputDecoration(
                      labelText: 'Trade note',
                      hintText:
                          'Add useful context such as preferred timing or equivalent offers.',
                      prefixIcon: Icons.notes_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapL),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: ArcUiTokens.textButtonStyle(
                      accent: ArcUiTokens.secondaryAccent,
                      primary: true,
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: Text(
                      _saving ? 'Publishing...' : 'Publish Trade Listing',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
