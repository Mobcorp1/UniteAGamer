# PASS 301 Command Centre Relevance

## Objective

Command Centre now consumes canonical user personalisation without replacing the Decision Engine.

Responsibilities remain split:

- Domain engines generate live signals.
- Decision Engine ranks mission/objective/blocker/recommendation candidates.
- Command Centre Engine adapts the Decision Engine output.
- `ArcCommandCentreRelevanceMapper` applies saved user preferences to the view state.

## Ranking Rules

The relevance mapper:

- Maps actions, routes and text labels to `ArcPersonalisationFeature`.
- Adds interest weight to existing status weight.
- Preserves critical blockers above personal preference.
- Promotes a high-interest objective into Today's Mission only when the current priority is not critical.
- Reorders snapshots, objectives, alerts, recommendations and checklist items.
- Hides neutral/success items only when the mapped feature is explicitly `off` and `reduceNoise` is true.
- Never creates fake live-data cards.

## Placeholder Repair

Command Centre no longer uses the generic "coming online later" placeholder fallback. Placeholder actions now report that the action is not available in the beta build.

## Live Update Path

`ArcCommandCentreScreen` watches:

`ArcUserPersonalisationRepository.watchProfile()`

When Settings updates the profile document, the Command Centre stream rebuilds with the new relevance ordering.

## Deferred

Some carousel summary panels are fixed model fields and are not yet fully reorderable as a collection. Their child objectives and recommendations are now preference-ranked, and the fixed panel contract remains stable for this pass.
