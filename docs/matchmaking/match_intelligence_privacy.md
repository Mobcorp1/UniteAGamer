# Match Intelligence Privacy

## Principle

Match Intelligence should help players find compatible squadmates without exposing another player's private inventory, missing blueprints, internal score factors, or exact progression needs.

## Private Inputs

The engine may privately consider:

- availability and timezone signals;
- communication style;
- squad intent;
- archetypes and play preferences;
- reputation and reliability;
- Favourite Rider relationship state;
- shared or complementary objective categories;
- hidden blueprint complementarity;
- hidden competition risk;
- progression and trade-adjacent signals.

## Public Outputs

The Match Rider UI may show only:

- overall match percentage;
- broad label: `Strong fit`, `Good fit`, `Compatible`, or `Worth a look`;
- tier badge;
- confidence label;
- broad non-sensitive tags;
- privacy-safe explanation.

## Never Expose

Do not expose:

- another player's owned blueprint list;
- another player's missing blueprint list;
- internal factor weights;
- internal scoring breakdowns;
- exact inventory or duplicate state;
- statements implying players must share or gift items;
- cached advanced scoring for users who are not entitled to Advanced Match Intelligence.

## Firestore Behaviour

New Match Rider profile saves use `toPublicMap()` and delete legacy private objective fields from `arc_match_rider_profiles`. Legacy reads remain tolerant so existing documents do not crash the app while data is cleaned up.

Private objective and inventory state should remain in existing user-owned/profile-owned documents governed by the current rules and future server-side scoring work.

## Test Coverage

PASS 267 adds tests for:

- privacy-safe public result maps;
- public label bands;
- public profile delete payloads;
- no blueprint/objective values in public output;
- incomplete profile fallback;
- hidden, blocked, incompatible, and unsafe exclusions;
- deterministic sorting;
- stale-profile handling.

## Future Review

Before external scale, review Firestore rules and indexes for `arc_match_rider_profiles`, `arc_favourite_riders`, and private profile documents to confirm the public/private boundary is enforced server-side as well as in the client.
