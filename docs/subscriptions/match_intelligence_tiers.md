# Match Intelligence Tiers

## Customer-Facing Copy

| Tier | Match Intelligence | Description |
| --- | --- | --- |
| Free | Basic Match Intelligence | Basic compatibility matching using core profile, platform and availability signals. |
| Essential | Enhanced Match Intelligence | Deeper compatibility analysis using communication style, schedule, squad intent and play preferences. |
| Premium | Advanced Match Intelligence | Full UAG Decision Engine analysis using dozens of private compatibility signals to surface the strongest squad recommendations. |

## Entitlement Mapping

- `free` maps to Basic Match Intelligence.
- `essential` maps to Enhanced Match Intelligence.
- `premium` maps to Advanced Match Intelligence.
- Admin and dev bypass accounts map to Advanced Match Intelligence for test coverage and preview tools.

## Comparison Rows

Subscription comparison surfaces should include:

- Match Intelligence;
- Overall Match %;
- Compatibility Ranking;
- Availability Matching;
- Communication Compatibility;
- Squad Intent Matching;
- Archetype Fit;
- Reputation Weighting;
- Favourite Rider Prioritisation;
- Dynamic Re-ranking;
- Advanced Progression Compatibility;
- Advanced Decision Engine.

Do not add customer-facing rows for hidden blueprint complementarity, exact private inventory matching, or internal score weights.

## UX Notes

- Match Rider cards should present the score first and explain that private details stay hidden.
- Upgrade prompts should sell deeper analysis and stronger ranking, not better players or guaranteed outcomes.
- Downgrades should recompute the feed with the newly available scoring depth.
- Ad behaviour remains owned by the existing entitlement/ad policy models and was not changed in PASS 267.

## Deferred Admin Tuning

PASS 267 includes typed default configuration for Basic, Enhanced, and Advanced weights plus confidence/exclusion thresholds. A future admin editor can read and write those values if a safe admin configuration surface is approved.
