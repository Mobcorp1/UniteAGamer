# Loadout Attachment Compatibility Audit

PASS 258B generated this audit from the live Favourite Loadout seed data and
the canonical weapon attachment slot matrix.

Source files:

- `lib/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart`
- `lib/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart`
- `docs/design/loadout_weapon_matrix.md`

## Summary

- Attachment definitions audited: 37
- Structural impossibility rows: 6
- Rows requiring in-game verification: 27
- Structurally aligned rows: 10

## Method

Each attachment was compared against weapons whose canonical ordered slot list
contains the same structural slot type.

The audit does not assume that every structurally eligible weapon should receive
every attachment. Individual weapon restrictions may be real in-game rules.

Only the following are flagged as structural impossibilities:

- An attachment currently lists a weapon.
- That weapon does not expose the attachment's slot type in the canonical matrix.

Possible missing mappings are verification prompts only. Do not automatically add
them without Mike's in-game confirmation.

## Structural Impossibilities

- Extended Medium Mag I currently lists Renegade, but Renegade has no Medium Magazine slot.
- Vertical Grip II currently lists Rattler, but Rattler has no Underbarrel slot.
- Extended Medium Mag II currently lists Renegade, but Renegade has no Medium Magazine slot.
- Extended Barrel currently lists Osprey, Stitcher, Ferro, Arpeggio, Anvil, Burletta and Kettle, but no canonical weapon currently exposes a Barrel slot.
- Extended Medium Mag III currently lists Renegade, but Renegade has no Medium Magazine slot.
- Kinetic Converter currently lists Arpeggio, Kettle, Vulcano, Osprey, Torrente, Ferro and Il Toro, but the canonical Converter slot currently exists only on Rattler.

## Verification Status

See `docs/design/loadout_attachment_compatibility_audit.csv` for every
attachment, current compatible weapon list, structurally eligible weapons,
impossible mappings, possible missing mappings and verification status.

## PASS 258C Guidance

For PASS 258C, verify the impossible mappings in-game first. Then review the
possible missing mappings attachment by attachment. Keep any weapon-specific
restriction that exists in-game, even when the weapon has the structural slot.
