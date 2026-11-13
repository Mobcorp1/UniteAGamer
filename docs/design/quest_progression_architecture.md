# Quest Progression Architecture - PASS 259D

## Current Implementation

Quest tracking still uses the shared ARC tracker implementation:

- Screen: `ScrappyGridScreen.quest`
- Seed data: `ArcQuestRequirementSeedData`
- State: `users/{uid}/arc_scrappy_states/{itemId}`
- Intelligence: `ArcQuestIntelligenceEngine`

Each quest item can be manually tracked, grouped and reset with the shared tracker architecture. PASS 259D adds confirmation before a grouped quest section can be bulk-completed.

## Reset Behaviour

Season reset classifies known quest tracker documents from `ArcQuestRequirementSeedData` and archives/deletes those current-season docs. After reset, quest intelligence rebuilds from the fresh tracker state.

## Deferred Dedicated Model

The repository does not yet contain a dedicated quest-chain model with stable quest instances, prerequisites, objective source types, reward grants, next-quest activation and history documents. Because exact canonical quest content and reward definitions are incomplete, PASS 259D preserves the current tracker model instead of inventing quest content.

This remains a P0 blocker for declaring the closed-beta quest system fully complete.
