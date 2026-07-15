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

  try {
    await env.clearFirestore();

    const owner = env.authenticatedContext("owner").firestore();
    const outsider = env.authenticatedContext("outsider").firestore();
    const anon = env.unauthenticatedContext().firestore();

    const questRef = owner.doc(
      "users/owner/arc_quest_progress/quest-chain-shani-clearer-skies",
    );
    const scrappyRef = owner.doc("users/owner/arc_scrappy_progress/current");
    const benchRef = owner.doc("users/owner/arc_bench_progress/bench-gunsmith");

    await assertSucceeds(
      questRef.set({
        questId: "quest-chain-shani-clearer-skies",
        seasonId: "closed-beta-season-1",
        status: "completed",
      }),
    );
    await assertSucceeds(
      scrappyRef.set({
        seasonId: "closed-beta-season-1",
        currentLevel: 2,
        maximumLevelReachedThisSeason: 2,
      }),
    );
    await assertSucceeds(
      benchRef.set({
        benchId: "bench-gunsmith",
        station: "Gunsmith",
        seasonId: "closed-beta-season-1",
        currentLevel: 1,
      }),
    );

    await assertSucceeds(questRef.get());
    await assertSucceeds(scrappyRef.get());
    await assertSucceeds(benchRef.get());

    await assertFails(
      outsider.doc("users/owner/arc_quest_progress/quest-chain-shani-clearer-skies").get(),
    );
    await assertFails(
      outsider.doc("users/owner/arc_scrappy_progress/current").set({
        currentLevel: 3,
      }),
    );
    await assertFails(
      anon.doc("users/owner/arc_bench_progress/bench-gunsmith").get(),
    );

    console.log("Firestore progression rules tests passed.");
  } finally {
    await env.cleanup();
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
