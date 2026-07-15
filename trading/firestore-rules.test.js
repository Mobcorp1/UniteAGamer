const fs = require("fs");
const path = require("path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

const projectId = "uag-arc-raiders-progression-rules";
const rules = fs.readFileSync(
  path.resolve(__dirname, "../firestore.rules"),
  "utf8",
);

async function run() {
  const env = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });

  let checks = 0;
  const succeeds = async (operation) => {
    await assertSucceeds(operation);
    checks += 1;
  };
  const fails = async (operation) => {
    await assertFails(operation);
    checks += 1;
  };

  try {
    await env.clearFirestore();

    const owner = env.authenticatedContext("owner").firestore();
    const outsider = env.authenticatedContext("outsider").firestore();
    const admin = env.authenticatedContext("admin").firestore();
    const anon = env.unauthenticatedContext().firestore();

    await succeeds(admin.doc("users/admin").set({ isAdmin: true }));

    const userRef = owner.doc("users/owner");
    await succeeds(
      userRef.set({
        uid: "owner",
        arcOnboarding: { completed: true },
      }),
    );
    await succeeds(userRef.get());
    await fails(outsider.doc("users/owner").get());
    await succeeds(admin.doc("users/owner").get());

    const questRef = owner.doc(
      "users/owner/arc_quest_progress/quest-chain-shani-clearer-skies",
    );
    const scrappyRef = owner.doc("users/owner/arc_scrappy_progress/current");
    const benchRef = owner.doc("users/owner/arc_bench_progress/bench-gunsmith");

    await succeeds(
      questRef.set({
        questId: "quest-chain-shani-clearer-skies",
        seasonId: "closed-beta-season-1",
        status: "completed",
      }),
    );
    await succeeds(
      scrappyRef.set({
        seasonId: "closed-beta-season-1",
        currentLevel: 2,
        maximumLevelReachedThisSeason: 2,
      }),
    );
    await succeeds(
      benchRef.set({
        benchId: "bench-gunsmith",
        station: "Gunsmith",
        seasonId: "closed-beta-season-1",
        currentLevel: 1,
      }),
    );

    await succeeds(questRef.get());
    await succeeds(scrappyRef.get());
    await succeeds(benchRef.get());

    await fails(
      outsider
        .doc("users/owner/arc_quest_progress/quest-chain-shani-clearer-skies")
        .get(),
    );
    await fails(
      outsider.doc("users/owner/arc_scrappy_progress/current").set({
        currentLevel: 3,
      }),
    );
    await fails(
      anon.doc("users/owner/arc_bench_progress/bench-gunsmith").get(),
    );

    const seasonRef = owner.doc("users/owner/arc_season_state/current");
    const seasonHistoryRef = owner.doc(
      "users/owner/arc_season_history/reset-2026-07-16",
    );
    await succeeds(
      seasonRef.set({
        currentSeasonId: "closed-beta-season-1",
        resetStatus: "idle",
      }),
    );
    await succeeds(
      seasonHistoryRef.set({
        resetId: "reset-2026-07-16",
        sourceSeasonId: "closed-beta-season-1",
      }),
    );
    await fails(
      outsider.doc("users/owner/arc_season_state/current").set({
        resetStatus: "complete",
      }),
    );
    await fails(
      outsider.doc("users/owner/arc_season_history/reset-2026-07-16").get(),
    );

    const operationSummaryRef = owner.doc("arc_operation_progress/owner");
    const operationRef = owner.doc(
      "arc_operation_progress/owner/operations/first-loadout",
    );
    const telemetryRef = owner.doc(
      "arc_operation_telemetry/owner/events/evt-first-loadout",
    );
    await succeeds(
      operationSummaryRef.set({
        lastRewardReconciliation: "2026-07-16T00:00:00.000Z",
      }),
    );
    await succeeds(
      operationRef.set({
        operationId: "first-loadout",
        progress: 1,
        target: 1,
      }),
    );
    await succeeds(
      telemetryRef.set({
        type: "first_loadout_completed",
        operationId: "first-loadout",
      }),
    );
    await fails(
      outsider.doc("arc_operation_progress/owner/operations/first-loadout").set({
        progress: 2,
      }),
    );
    await fails(
      outsider.doc("arc_operation_telemetry/owner/events/evt-first-loadout").get(),
    );
    await succeeds(
      admin.doc("arc_operation_progress/owner/operations/first-loadout").get(),
    );

    const rewardRef = owner.doc(
      "arc_rewards_inventory/owner/items/closed-beta-veteran-badge",
    );
    const equippedRef = owner.doc("arc_equipped_cosmetics/owner");
    await succeeds(
      rewardRef.set({
        rewardId: "closed-beta-veteran-badge",
        owned: true,
      }),
    );
    await succeeds(
      equippedRef.set({
        equippedBadgeId: "closed-beta-veteran-badge",
      }),
    );
    await fails(
      outsider
        .doc("arc_rewards_inventory/owner/items/closed-beta-veteran-badge")
        .set({
          owned: false,
        }),
    );
    await fails(
      outsider.doc("arc_equipped_cosmetics/owner").set({
        equippedBadgeId: "outsider-badge",
      }),
    );
    await succeeds(
      admin
        .doc("arc_rewards_inventory/owner/items/closed-beta-veteran-badge")
        .get(),
    );

    console.log(`Firestore release candidate rules checks passed: ${checks}.`);
  } finally {
    await env.cleanup();
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
