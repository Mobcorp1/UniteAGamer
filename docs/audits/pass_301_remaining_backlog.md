# PASS 301 Remaining Backlog

## Recommended Next Passes

1. Expand onboarding preference depth.
   - Add communication style, preferred session length, region/time intent and archetype-specific boosts to the canonical profile.

2. Convert fixed Command Centre system panels into a reorderable summary collection.
   - Keep the compact UX but allow full preference ordering of all system summaries.

3. Add target-user admin diagnostics.
   - Let admins inspect a selected UID rather than only their current admin account.

4. Thread canonical personalisation into backend notification senders.
   - Existing delivery engine supports the optional profile gate; repository/cloud-function callers can adopt it when they already load user profiles.

5. Add profile setup shortcuts to the old Tool Deck.
   - Settings now contains personalisation, but Tool Deck could surface a compact "Tune Command Centre" action.

6. Extend feature registry to subscription SKU diagnostics.
   - Current registry records access/admin/personalisation. Subscription product mapping can be attached when the subscription pass needs it.

## Deferred By Design

- No functional Report A Rat, Hunt A Rat or Rat Radar surface.
- No new top-level drawer item for personalisation.
- No redesign of Command Centre, onboarding, Settings, drawers or admin console.
- No changes to Blueprint Grid rendering, BlueprintTile, ownership write logic, duplicate write logic, `_buildGrid`, carousel behaviour or auth flow.
