import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

import '../data/uag_avatar_catalog.dart';
import 'uag_raider_avatar.dart';

class UagAvatarLockerSheet extends StatefulWidget {
  const UagAvatarLockerSheet({super.key, required this.currentAvatarId});

  final String currentAvatarId;

  static Future<String?> show(
    BuildContext context, {
    required String currentAvatarId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UagAvatarLockerSheet(currentAvatarId: currentAvatarId),
    );
  }

  @override
  State<UagAvatarLockerSheet> createState() => _UagAvatarLockerSheetState();
}

class _UagAvatarLockerSheetState extends State<UagAvatarLockerSheet> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = UagAvatarCatalog.byId(widget.currentAvatarId).id;
  }

  @override
  Widget build(BuildContext context) {
    final selected = UagAvatarCatalog.byId(_selectedId);
    final height = MediaQuery.sizeOf(context).height * 0.84;
    return SafeArea(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVATAR LOCKER',
                          style: AppTheme.tradingHeading(
                            fontSize: 20,
                            color: AppTheme.neonCyan,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Choose your UAG Raider identity.',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  UagRaiderAvatar(
                    avatarId: selected.id,
                    displayName: selected.label,
                    size: 64,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECTED',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          selected.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _selectedId),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('EQUIP'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 118,
                  mainAxisExtent: 132,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: UagAvatarCatalog.options.length,
                itemBuilder: (context, index) {
                  final option = UagAvatarCatalog.options[index];
                  final active = option.id == _selectedId;
                  final card = InkWell(
                    borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                    onTap: () => setState(() => _selectedId = option.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.neonCyan.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.025),
                        borderRadius: BorderRadius.circular(
                          ArcUiTokens.radiusM,
                        ),
                        border: Border.all(
                          color: active ? AppTheme.neonCyan : Colors.white12,
                          width: active ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: UagRaiderAvatar(
                                avatarId: option.id,
                                displayName: option.label,
                                size: 78,
                                accent: active
                                    ? AppTheme.neonCyan
                                    : ArcUiTokens.textTertiary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active
                                  ? AppTheme.neonCyan
                                  : Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  return ElectricChargeBorder(
                    active: active,
                    radius: ArcUiTokens.radiusM,
                    child: card,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
