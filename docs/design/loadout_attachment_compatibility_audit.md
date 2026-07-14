# Loadout Attachment Compatibility Audit

PASS 258B generated this audit from the live Favourite Loadout seed data and
the canonical weapon attachment slot matrix.

Source files:

- `lib/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart`
- `lib/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart`
- `docs/design/loadout_weapon_matrix.md`

## Summary

- Attachment definitions audited: 37
- Structural impossibility rows: 0
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

## PASS 258C Resolution

PASS 258C removed the six structural impossibilities found in PASS 258B:

- Removed Renegade from Extended Medium Mag I, II and III because Renegade has no Medium Magazine slot.
- Removed Rattler from Vertical Grip II because Rattler has no Underbarrel slot.
- Cleared Extended Barrel compatible weapons because no canonical weapon currently exposes a Barrel slot.
- Restricted Kinetic Converter to Rattler because Rattler is the only canonical weapon with a Converter slot.

## Structural Impossibilities

No structural impossibilities remain after PASS 258C.

## Verification Status

See `docs/design/loadout_attachment_compatibility_audit.csv` for every
attachment, current compatible weapon list, structurally eligible weapons,
impossible mappings, possible missing mappings and verification status.

## PASS 258C Guidance

For the next compatibility pass, review the possible missing mappings attachment
by attachment. Keep any weapon-specific restriction that exists in-game, even
when the weapon has the structural slot.
