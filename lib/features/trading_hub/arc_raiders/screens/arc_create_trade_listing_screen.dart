import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await _profileRepository.getProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
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
    if (_profile == null) return;
    setState(() => _saving = true);

    final listing = ArcTradeListing(
      id: '',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      offeredBlueprintId: _offeredBlueprintIdController.text.trim(),
      offeredBlueprintName: _offeredBlueprintNameController.text.trim(),
      wantedBlueprintId: _wantedBlueprintIdController.text.trim(),
      wantedBlueprintName: _wantedBlueprintNameController.text.trim(),
      region: _profile!.region,
      platform: _profile!.platform,
      status: 'open',
      note: _noteController.text.trim(),
    );

    await _listingRepository.createListing(listing);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Trade Listing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Load or complete your trader profile first.'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Listing will use ${profile.region} • ${profile.platform}',
              ),
            ),
          TextField(
            controller: _offeredBlueprintIdController,
            decoration: const InputDecoration(
              labelText: 'Offered Blueprint ID',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _offeredBlueprintNameController,
            decoration: const InputDecoration(
              labelText: 'Offered Blueprint Name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wantedBlueprintIdController,
            decoration: const InputDecoration(labelText: 'Wanted Blueprint ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wantedBlueprintNameController,
            decoration: const InputDecoration(
              labelText: 'Wanted Blueprint Name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving || profile == null ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Create Listing'),
          ),
        ],
      ),
    );
  }
}
