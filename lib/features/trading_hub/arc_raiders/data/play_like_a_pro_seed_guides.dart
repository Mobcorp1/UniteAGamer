import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_guide.dart';

class PlayLikeAProSeedGuides {
  const PlayLikeAProSeedGuides._();

  static const guides = <PlayLikeAProGuide>[
    PlayLikeAProGuide(
      id: 'extract-before-greed',
      title: 'Extract Before Greed Takes the Raid',
      summary:
          'A simple decision framework for knowing when value already carried is worth more than one more room.',
      category: PlayLikeAProCategory.extraction,
      skillLevel: PlayLikeAProSkillLevel.starter,
      tags: {'extraction', 'survival', 'decision-making', 'loot'},
      squadScope: PlayLikeAProSquadScope.any,
      featured: true,
      relatedGuideIds: ['solo-contact-triage', 'inventory-three-layers'],
      sections: [
        PlayLikeAProSection(
          heading: 'Set the exit condition before the raid',
          body:
              'The safest extraction decision is made before adrenaline and loot value distort it.',
          bullets: [
            'Choose one primary objective and one fallback objective.',
            'Treat a critical blueprint, quest item or build-defining resource as an immediate re-evaluation trigger.',
            'Once the raid has paid for itself, every extra fight is an optional risk rather than required progress.',
          ],
        ),
        PlayLikeAProSection(
          heading: 'Use a three-signal exit check',
          body:
              'Leave when two of the three signals turn against you: value carried, resources remaining, or route quality.',
          bullets: [
            'High carried value increases the cost of every unnecessary contact.',
            'Low healing, ammunition or mobility options reduce your ability to recover from a bad engagement.',
            'A noisy or collapsing route is a reason to rotate early, not proof that you should force through it.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'solo-contact-triage',
      title: 'Solo Contact Triage: Fight, Fade or Re-route',
      summary:
          'Classify an encounter in seconds so a solo run does not become a forced fair fight.',
      category: PlayLikeAProCategory.soloTactics,
      skillLevel: PlayLikeAProSkillLevel.intermediate,
      tags: {'solo', 'pvp', 'positioning', 'survival'},
      squadScope: PlayLikeAProSquadScope.solo,
      featured: true,
      relatedGuideIds: ['extract-before-greed', 'doorway-discipline'],
      sections: [
        PlayLikeAProSection(
          heading: 'Do not ask only whether you can win',
          body:
              'The useful question is whether winning this fight improves the run enough to justify exposing your position and resources.',
          bullets: [
            'Fight when you have information, cover, an exit and a reason.',
            'Fade when the opponent controls the angle or the reward is irrelevant to your objective.',
            'Re-route when contact blocks the route but does not require immediate commitment.',
          ],
        ),
        PlayLikeAProSection(
          heading: 'Preserve ambiguity',
          body:
              'A solo player gains leverage when the enemy does not know your exact route, equipment or willingness to commit.',
          bullets: [
            'Break line of sight before changing direction.',
            'Avoid repeating the same peek from the same cover.',
            'Use sound and timing to create uncertainty instead of announcing a chase.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'doorway-discipline',
      title: 'Doorway Discipline for Close Encounters',
      summary:
          'Stop turning every doorway into a coin flip by controlling exposure, spacing and the second angle.',
      category: PlayLikeAProCategory.positioning,
      skillLevel: PlayLikeAProSkillLevel.intermediate,
      tags: {'pvp', 'movement', 'cover', 'close-range'},
      squadScope: PlayLikeAProSquadScope.any,
      relatedGuideIds: ['solo-contact-triage', 'squad-crossfire-spacing'],
      sections: [
        PlayLikeAProSection(
          heading: 'Clear with purpose',
          body:
              'Crossing a threshold is a commitment. Gather what you can before giving up outside cover.',
          bullets: [
            'Clear the near threat before exposing yourself to the far angle.',
            'Do not stand centred in the frame while deciding what to do next.',
            'If the room cannot be controlled, keep an exit instead of flooding through blindly.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'squad-crossfire-spacing',
      title: 'Squad Spacing That Creates Crossfire',
      summary:
          'Spread enough to create independent angles without separating so far that teammates cannot trade or recover.',
      category: PlayLikeAProCategory.squadTactics,
      skillLevel: PlayLikeAProSkillLevel.advanced,
      tags: {'squad', 'pvp', 'positioning', 'comms'},
      squadScope: PlayLikeAProSquadScope.squad,
      featured: true,
      relatedGuideIds: ['doorway-discipline', 'callouts-three-parts'],
      sections: [
        PlayLikeAProSection(
          heading: 'Build a triangle, not a queue',
          body:
              'Three players stacked on one angle create one target. Separate sightlines make the opponent solve multiple problems.',
          bullets: [
            'Keep each player within practical support distance.',
            'Avoid all three Raiders peeking from the same piece of cover.',
            'When one player takes attention, the second angle should punish the turn.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'callouts-three-parts',
      title: 'Three-Part Callouts Under Pressure',
      summary: 'Make squad communication actionable: threat, location, intent.',
      category: PlayLikeAProCategory.squadTactics,
      skillLevel: PlayLikeAProSkillLevel.starter,
      tags: {'squad', 'comms', 'combat', 'teamwork'},
      squadScope: PlayLikeAProSquadScope.squad,
      sections: [
        PlayLikeAProSection(
          heading: 'Threat. Location. Intent.',
          body:
              'A useful callout tells teammates what changed and what you are doing about it.',
          bullets: [
            'Threat: player, ARC, movement or unknown contact.',
            'Location: a landmark, direction or relative position everyone can understand.',
            'Intent: holding, rotating, healing, pushing, extracting or disengaging.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'inventory-three-layers',
      title: 'Build Inventory in Three Layers',
      summary:
          'Prepare every raid around survival, objective and optional value so loot decisions stay fast.',
      category: PlayLikeAProCategory.inventoryPreparation,
      skillLevel: PlayLikeAProSkillLevel.starter,
      tags: {'inventory', 'resources', 'loadout', 'survival'},
      loadoutTags: {'survival', 'resource-run'},
      squadScope: PlayLikeAProSquadScope.any,
      relatedGuideIds: ['extract-before-greed', 'loadout-role-check'],
      sections: [
        PlayLikeAProSection(
          heading: 'Layer one: stay alive',
          body:
              'Reserve space and resources for the tools that let the run continue after the first mistake.',
          bullets: [
            'Healing and recovery.',
            'Ammunition appropriate to the planned weapon use.',
            'Mobility or utility that preserves an exit.',
          ],
        ),
        PlayLikeAProSection(
          heading: 'Layer two: complete the objective',
          body:
              'Carry what the specific blueprint, quest, route or event actually needs before adding comfort items.',
        ),
        PlayLikeAProSection(
          heading: 'Layer three: optional profit',
          body:
              'Everything after survival and objective support is flexible. This is the layer you replace first when high-value loot appears.',
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'loadout-role-check',
      title: 'Favourite Loadout Role Check',
      summary:
          'Read your primary and secondary as jobs, not just favourite guns, and make sure the pair solves different problems.',
      category: PlayLikeAProCategory.loadouts,
      skillLevel: PlayLikeAProSkillLevel.intermediate,
      tags: {'loadout', 'weapons', 'attachments', 'preparation'},
      weaponNames: {'Anvil', 'Stitcher'},
      loadoutTags: {'balanced', 'pve', 'pvp'},
      squadScope: PlayLikeAProSquadScope.any,
      featured: true,
      relatedGuideIds: ['attachment-purpose-check', 'inventory-three-layers'],
      sections: [
        PlayLikeAProSection(
          heading: 'Give each weapon a job',
          body:
              'A pair that only excels at the same range leaves a predictable weakness.',
          bullets: [
            'Primary: define the range and engagement you actively want.',
            'Secondary: solve the failure state of the primary rather than duplicating it.',
            'Attachments should strengthen the job you selected instead of chasing stats without a plan.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'attachment-purpose-check',
      title: 'Attachment Purpose Check',
      summary:
          'Evaluate an attachment by the problem it fixes in your actual build, not by whether the stat line looks stronger.',
      category: PlayLikeAProCategory.attachments,
      skillLevel: PlayLikeAProSkillLevel.intermediate,
      tags: {'attachments', 'weapons', 'loadout'},
      loadoutTags: {'pvp', 'pve', 'balanced'},
      squadScope: PlayLikeAProSquadScope.any,
      relatedGuideIds: ['loadout-role-check'],
      sections: [
        PlayLikeAProSection(
          heading: 'Start from the failure state',
          body:
              'Identify what makes the weapon miss its job: handling, control, capacity, recovery or another limitation.',
          bullets: [
            'Do not spend a slot solving a problem the weapon does not have in your intended range.',
            'Compare the attachment against the whole build, including penalties and crafting cost.',
            'If an attachment changes how you should play the weapon, update the role instead of ignoring the trade-off.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'blue-gate-route-priorities',
      title: 'Blue Gate: Route Priorities Before You Spawn',
      summary:
          'Use Raid Intelligence to decide what matters before movement starts instead of improvising every stop.',
      category: PlayLikeAProCategory.mapRoutes,
      skillLevel: PlayLikeAProSkillLevel.intermediate,
      tags: {'map', 'route', 'blueprints', 'raid-intelligence'},
      mapIds: {ArcMapAssetRegistry.blueGateMapId},
      squadScope: PlayLikeAProSquadScope.any,
      featured: true,
      relatedGuideIds: ['blueprint-route-discipline', 'extract-before-greed'],
      sections: [
        PlayLikeAProSection(
          heading: 'Rank stops by objective value',
          body:
              'The route should serve your current progression rather than trying to visit every interesting location.',
          bullets: [
            'Use current blueprint and route intelligence to identify the highest-value stop.',
            'Keep one alternate route if the first path becomes contested.',
            'Treat extraction as part of route planning, not a decision left until the final minute.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'blueprint-route-discipline',
      title: 'Blueprint Route Discipline',
      summary:
          'Hunt missing blueprints without turning the raid into a blind sprint between every reported location.',
      category: PlayLikeAProCategory.blueprintRoutes,
      skillLevel: PlayLikeAProSkillLevel.advanced,
      tags: {'blueprints', 'map', 'route', 'loot'},
      mapIds: {
        ArcMapAssetRegistry.blueGateMapId,
        ArcMapAssetRegistry.damBattlegroundsMapId,
        ArcMapAssetRegistry.buriedCityMapId,
        ArcMapAssetRegistry.spaceportMapId,
        ArcMapAssetRegistry.stellaMontisMapId,
        ArcMapAssetRegistry.rivenTidesMapId,
      },
      squadScope: PlayLikeAProSquadScope.any,
      relatedGuideIds: ['blue-gate-route-priorities', 'extract-before-greed'],
      sections: [
        PlayLikeAProSection(
          heading: 'Rank evidence, then route',
          body:
              'A drop report is an input, not an instruction to cross the entire map regardless of risk.',
          bullets: [
            'Prioritise routes that combine multiple current needs.',
            'Use nearby optional stops only when they do not break the extraction plan.',
            'Once the target blueprint is secured, immediately switch from acquisition logic to survival logic.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'arc-pve-space-control',
      title: 'PvE: Keep Space While You Damage ARC',
      summary:
          'Preserve movement lanes and recovery space instead of letting damage output trap you in a bad position.',
      category: PlayLikeAProCategory.pve,
      skillLevel: PlayLikeAProSkillLevel.intermediate,
      tags: {'pve', 'arc', 'positioning', 'movement'},
      squadScope: PlayLikeAProSquadScope.any,
      sections: [
        PlayLikeAProSection(
          heading: 'Do not trade mobility for damage',
          body:
              'The best firing position is not useful if it removes the route you need when the encounter changes.',
          bullets: [
            'Keep hard cover or a clean break route available.',
            'Reposition before pressure forces the move for you.',
            'Avoid burning all recovery resources just to finish an optional ARC fight faster.',
          ],
        ),
      ],
    ),
    PlayLikeAProGuide(
      id: 'event-prep-objective-first',
      title: 'Event Prep: Objective First, Loot Second',
      summary:
          'Prepare the loadout, inventory and exit around the event objective so side loot cannot silently become the mission.',
      category: PlayLikeAProCategory.eventPreparation,
      skillLevel: PlayLikeAProSkillLevel.intermediate,
      tags: {'events', 'preparation', 'loadout', 'inventory'},
      squadScope: PlayLikeAProSquadScope.any,
      eventIds: {'any-event'},
      sections: [
        PlayLikeAProSection(
          heading: 'Define the event success condition',
          body:
              'Before entering, decide what must happen for the run to count as a success and what can be abandoned.',
          bullets: [
            'Carry tools that support the event rather than a generic comfortable loadout.',
            'Agree squad roles before contact if the objective requires coordinated actions.',
            'Leave optional loot behind when it threatens the event timing or extraction window.',
          ],
        ),
      ],
    ),
  ];
}
