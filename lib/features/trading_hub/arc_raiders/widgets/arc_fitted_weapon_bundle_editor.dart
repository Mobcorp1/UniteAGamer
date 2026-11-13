import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_fitted_weapon_trade_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcFittedWeaponBundleEditor {
  const ArcFittedWeaponBundleEditor._();

  static Future<ArcTradeBundleComponent?> show(
    BuildContext context, {
    ArcTradeBundleComponent? initialValue,
  }) {
    const engine = ArcFittedWeaponTradeEngine();
    final weapons = engine.weapons;
    var weaponName =
        initialValue?.fittedWeapon?.weaponName ??
        (weapons.isEmpty ? '' : weapons.first.name);
    var quantity = initialValue?.quantity ?? 1;
    var requirements = <String, String>{
      ...?initialValue?.fittedWeapon?.attachmentsBySlot,
    };

    void normaliseRequirements() {
      final slots = engine.slotsForWeapon(weaponName);
      requirements = <String, String>{
        for (final slot in slots)
          slot:
              requirements[slot] ??
              ArcFittedWeaponConfiguration.anyCompatibleAttachment,
      };
    }

    normaliseRequirements();

    return showModalBottomSheet<ArcTradeBundleComponent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ArcUiTokens.surfaceOverlay,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final slots = engine.slotsForWeapon(weaponName);
            final config = ArcFittedWeaponConfiguration(
              weaponId: weaponName.toLowerCase().replaceAll(' ', '-'),
              weaponName: weaponName,
              attachmentsBySlot: requirements,
            );
            final errors = engine.validate(config);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  18 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fully Kitted Weapon',
                          style: ArcUiTokens.sectionTitle(
                            fontSize: 24,
                            color: ArcUiTokens.primaryAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set the exact weapon and what is required in each real attachment slot.',
                          style: ArcUiTokens.body(
                            color: ArcUiTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          initialValue: weaponName,
                          dropdownColor: ArcUiTokens.surfaceOverlay,
                          decoration: ArcUiTokens.inputDecoration(
                            labelText: 'Weapon',
                          ),
                          style: ArcUiTokens.body(
                            color: ArcUiTokens.textPrimary,
                          ),
                          items: weapons
                              .map(
                                (weapon) => DropdownMenuItem<String>(
                                  value: weapon.name,
                                  child: Text(weapon.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() {
                              weaponName = value;
                              normaliseRequirements();
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Quantity',
                                style: ArcUiTokens.body(
                                  color: ArcUiTokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: quantity <= 1
                                  ? null
                                  : () => setSheetState(() => quantity -= 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$quantity',
                              style: ArcUiTokens.numeric(
                                fontSize: 22,
                                color: ArcUiTokens.primaryAccent,
                              ),
                            ),
                            IconButton(
                              onPressed: quantity >= 99
                                  ? null
                                  : () => setSheetState(() => quantity += 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        if (slots.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              '$weaponName has no attachment slots.',
                              style: ArcUiTokens.bodySmall(
                                color: ArcUiTokens.textSecondary,
                              ),
                            ),
                          ),
                        ...slots.map((slot) {
                          final options = engine.attachmentsForSlot(
                            weaponName: weaponName,
                            slotLabel: slot,
                          );
                          final value =
                              requirements[slot] ??
                              ArcFittedWeaponConfiguration
                                  .anyCompatibleAttachment;
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: DropdownButtonFormField<String>(
                              initialValue: value,
                              dropdownColor: ArcUiTokens.surfaceOverlay,
                              decoration: ArcUiTokens.inputDecoration(
                                labelText: slot,
                              ),
                              style: ArcUiTokens.body(
                                color: ArcUiTokens.textPrimary,
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: ArcFittedWeaponConfiguration
                                      .anyCompatibleAttachment,
                                  child: Text('Any compatible attachment'),
                                ),
                                ...options.map(
                                  (attachment) => DropdownMenuItem<String>(
                                    value: attachment.name,
                                    child: Text(attachment.name),
                                  ),
                                ),
                              ],
                              onChanged: (next) {
                                if (next == null) return;
                                setSheetState(() {
                                  requirements[slot] = next;
                                });
                              },
                            ),
                          );
                        }),
                        if (errors.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ...errors.map(
                            (error) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                error,
                                style: ArcUiTokens.bodySmall(
                                  color: ArcUiTokens.warning,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: ArcUiTokens.textButtonStyle(
                                  accent: ArcUiTokens.primaryAccent,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                style: ArcUiTokens.textButtonStyle(
                                  accent: ArcUiTokens.secondaryAccent,
                                  primary: true,
                                ),
                                onPressed: errors.isNotEmpty
                                    ? null
                                    : () {
                                        Navigator.of(context).pop(
                                          ArcTradeBundleComponent(
                                            id:
                                                initialValue?.id ??
                                                'fitted-${DateTime.now().microsecondsSinceEpoch}',
                                            type: ArcTradeBundleComponentType
                                                .fittedWeapon,
                                            itemId: config.weaponId,
                                            itemName:
                                                'Fully kitted ${config.weaponName}',
                                            quantity: quantity,
                                            fittedWeapon: config,
                                          ),
                                        );
                                      },
                                child: const Text('Add Weapon'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
