# Review verification, October 21, 2026

Second pass (Claude), after Astra's October 21 review. Everything below was run
on the exact tree CI produces: pristine submodules (Loop `c2fddb76`, LoopKit
fork `1bdbe685`, LoopOnboarding `4aca97d`, NightscoutService `fe075ef`) with
`patches/01…08` applied in order with `--whitespace=fix`.

## What changed since Astra's review

- **The 🥜 pattern now drives dosing.** Astra's build kept
  `DelayedMetabolicResponsePreview` display-only and routed every entry with a
  pattern identifier to the global model. The user's specification was a real
  curve, so `DelayedMetabolicResponseAbsorption` (LoopKit fork) is selected by
  `CarbEntry.resolvedAbsorptionModel` when the identifier is
  `delayed-metabolic-v1`. `standard-v1` and unknown identifiers use the global
  model; `nil` keeps the legacy 🥜12h / 🌙12h / 🍲8h text-marker behaviour.
- Curve knees are anchored on the six zoodle + 🥜 nights in
  `research/meal-timing-2026-10-20/stacked-meals-results.json`: late-rise
  midpoints 6.12 / 5.84 / 4.31 / 4.56 / 7.61 / 7.66 h after 12 h entries →
  average 0.501 of duration, spread 0.359–0.638. Peak-rate segment 0.43–0.57,
  wave 0.36–0.64. The early/late carb share is a design choice, not measured.
- Fixed Astra's findings: `FavoriteFoodCSV.InvalidFile` has a public
  initializer; the harness compiles (throwing autoclosure); the new Swift
  files and Core Data `Modelv5` are registered in both Xcode projects (without
  this the app would have crashed on launch: the compiled model would not
  contain `absorptionPatternIdentifier`); `profiles` removed from the manual
  workflow's loopandlearn list (the script exits 1 when a customization is
  already applied by patch 07).
- Both workflows now check-then-apply each patch in order. `git apply --check
  a b c` tests every file against the unpatched tree, so patch 08 (which edits
  lines introduced by 01/03/05/06) failed that check even though sequential
  application succeeds. Verified with a two-patch experiment.
- Restored upstream `time = entry.date` in `restoreUserActivityState` (Astra's
  change to `startDate` was unrelated to the request).
- Kept the removal of `.removeDuplicates()` on the favorites publisher and
  documented why: `StoredFavoriteFood ==` compares id only, so in-place edits
  and CSV imports were never written to UserDefaults.
- `PresetReminderStore.notificationCategory` is `nonisolated` so the
  non-main-actor notification delegate can read it.
- Every added line carries a `// CUSTOM (rdeboer180):` marker; patch 08 has 40.

## Checks run

- `tests/MealToolsChecks.swift` + `tests/CarbAbsorptionShim.swift` against the
  unmodified LoopKit sources: **3068 checks passed** — CSV round trip and
  rejections, reminder schedules, curve monotonicity/bounds/non-negative rate,
  inverse round-trip at 1001 points, carb conservation, duration scaling,
  documented milestones, data-anchored knees, "lags PiecewiseLinear",
  preview/model agreement, identifier stability.
- `git apply --check` of patches 01–07 from pristine, then the real apply:
  Loop tree equals Astra's "Local baseline" commit except two trailing-space
  lines that `--whitespace=fix` strips (which is why patch 08 is generated
  against the real CI tree, not that commit).
- Sequential `git apply ./patches/*.patch -v --whitespace=fix` from pristine:
  all eight apply cleanly; patch 07's LoopKit pbxproj hunk still applies on
  the new fork commit; resulting Loop tree is byte-identical to the final
  working tree.
- `plutil -lint` on both project files.
- Xcode builds: see the status lines appended below.

## Not covered

No device/simulator run, no Core Data migration test on a populated store (the
change is one optional attribute, which Core Data's automatic lightweight
migration handles; `PersistenceController` already sets
`NSMigratePersistentStoresAutomaticallyOption`/`NSInferMappingModelAutomaticallyOption`),
no notification-delivery test, no clinical validation of the curve. The
Watch app does not expose the pattern control; Watch and remote entries get
`nil` (legacy behaviour). Nightscout does not receive the pattern identifier,
so LoopStack cannot yet grade these entries against the new curve.

## Build results (October 21, 2026, Xcode 26.6, local)

- `xcodebuild -project LoopKit/LoopKit.xcodeproj -target LoopKit -target LoopKitUI -sdk iphoneos` on the CI tree: **BUILD SUCCEEDED**, no errors, no warnings in changed files, `Modelv5.xcdatamodel` compiled.
- `xcodebuild -workspace LoopWorkspace.xcworkspace -scheme LoopWorkspace -configuration Release -destination generic/platform=iOS` (fastlane's scheme and configuration) on the CI tree with signing disabled: **BUILD SUCCEEDED**; `MealToolsView.swift` and `PresetRemindersView.swift` compiled; the only warning in a touched file is the pre-existing upstream `String: Identifiable` conformance in SettingsView.
- Local prerequisites that CI already has: the watchOS 26.5 platform (installed during this review) and TrueTime's nested `External/xcconfigs` submodule (initialised recursively).
- Two earlier attempts with `-scheme Loop` failed before compiling anything ("unable to resolve module dependency: 'LoopKit'" in LoopCore) because that scheme relies on implicit dependencies; CI does not use it.

## Nightscout absorption-pattern marker and LoopStack lockstep (October 21, 2026)

Closes the gap noted above ("Nightscout does not receive the pattern
identifier"). No dosing change on either side.

- `patches/09-nightscout-absorption-pattern.patch` (NightscoutService is a
  submodule with no fork, so this is a workspace patch like 07). It edits one
  file, `NightscoutService/NightscoutServiceKit/Extensions/SyncCarbObject.swift`:
  the carb treatment's `notes` becomes `"[<absorptionPatternIdentifier>]"`
  (`[delayed-metabolic-v1]` or `[standard-v1]`) when the entry carries an
  identifier, and stays `nil` otherwise, so legacy 🥜12h / 🌙12h / 🍲8h
  entries, Watch entries and remote entries upload exactly as before.
  `CarbCorrectionNightscoutTreatment` already accepted `notes`; nothing in
  NightscoutKit changes. Loop never reads carb treatments back from
  Nightscout, so the marker is upload-only. Every added line carries a
  `CUSTOM (rdeboer180)` marker.
  **Revert:** delete the patch file (CI applies whatever is in `patches/`);
  locally, `git -C NightscoutService checkout -- NightscoutServiceKit/Extensions/SyncCarbObject.swift`.
  Entries uploaded while the patch was live keep their `[…]` note on the
  Nightscout site; LoopStack treats a missing marker as "no identifier".
- Generated against the CI tree (pristine submodules + 01–08 with
  `--whitespace=fix`) in a scratch clone. Verified: from a fully pristine
  scratch tree (`git clean -fdx` in the superproject too — `profiles.loopcustomization`
  is git-ignored and patch 07 creates it) the per-patch
  `git apply --check` / `git apply` loop applies 01–09 in order; the local
  `NightscoutService` working tree after applying 09 is byte-identical to the
  scratch CI tree.
- LoopStack (`Loopstack/src/lib/metabolism/carbAbsorption.ts`): new kind
  `delayedMetabolicV1` whose `MODEL_KNEES` entry is the Swift
  `DelayedMetabolicResponseAbsorption.knees` verbatim (checked by script:
  the nine (t, p) pairs parsed from the Swift file equal the TS pairs);
  `absorptionPatternFromNotes` parses the `[<name>-v<N>]` marker from the
  Nightscout treatment notes; `modelKindForEntry` mirrors
  `CarbEntry.resolvedAbsorptionModel(default:)` — identifier first
  (`delayed-metabolic-v1` → the new curve, `standard-v1` or an unknown
  identifier → the global piecewise model even over a legacy marker), and
  only a missing identifier reaches the untouched `modelKindForLabel` path.
  `CarbEntry.absorptionPattern` is filled by the Nightscout data source from
  `notes`; a sitting (`combineCarbEntries`) is delayed-metabolic if any entry
  is, drops to the legacy label path if any entry has no identifier, and keeps
  a pinned identifier only when every entry pins one. Preset naming shows
  "12h 🥜 delayed" so it never reads as the legacy "12h 🥜".
- LoopStack tests (`carbAbsorption.test.ts`, `mealCombining.test.ts`): knee
  table equals the Swift table, strictly increasing in both axes from (0,0)
  to (1,1), segment shares sum to 1 and the rate integrates to 1 at 12 h,
  documented milestones (5% @ 1.5 h … 86% @ 9.6 h), monotone and inverse
  round-trip at 1001 points each way, peak window 0.43–0.57 centred on 0.50
  at 1.93× the mean rate, lags PiecewiseLinear at 25%/50%; marker parsing
  (case-sensitive, ignores non-identifier brackets); resolver precedence;
  sitting combination. Full suite: 41 files, 669 tests passed (`npm test`).
- Not covered: HealthKit-sourced LoopStack entries still have no identifier.
  Loop writes it to HealthKit metadata under
  `com.loopkit.CarbKit.AbsorptionPatternIdentifier`, and LoopStack's
  `ios/App/App/HealthDiabetesPlugin.swift` already forwards food type and
  `com.loopkit.AbsorptionTime` from sample metadata, but not that key — a
  small follow-up in the plugin plus `healthKitDataSource.ts`. Until then
  HealthKit entries grade by legacy marker; Nightscout is the source now in
  lockstep. No device run. Nothing pushed, no build triggered.
- Build (October 21, 2026, local, Xcode 26.6): `xcodebuild -workspace
  LoopWorkspace.xcworkspace -scheme LoopWorkspace -configuration Release
  -destination generic/platform=iOS` with signing disabled, on the local tree
  with patch 09 applied: **BUILD SUCCEEDED**; `NightscoutServiceKit/Extensions/SyncCarbObject.swift`
  recompiled with no warnings, no compiler errors anywhere.

## Second review of patch 09 + LoopStack, and new pre-meal icon (October 21, 2026)

- Patch 09 reviewed: one `notes:` argument on the carb treatment, which
  NightscoutKit's `CarbCorrectionNightscoutTreatment.init` already accepts.
  Nothing in Loop, LoopKit or NightscoutService reads carb treatments or their
  notes back, so the marker is upload-only and cannot reach dosing.
- Patch loop re-run from pristine submodules (Loop `c2fddb76`, LoopKit
  `1bdbe685`) with 01–09: every tracked and new file in Loop, LoopKit,
  LoopOnboarding and NightscoutService is identical to the tree the LoopStack
  session built.
- LoopStack reviewed and committed locally as `6874797` (no git remote
  exists, so nothing was pushed). Only the eight absorption-curve files were
  committed; the unrelated in-progress DataChat / AI / BottomNav work was left
  uncommitted. On a clean worktree of LoopStack `9a19cd3` with only those
  eight files applied: 654 tests passed, `tsc --noEmit` clean.
- **Pre-meal toolbar icon.** `OverrideAssetsLoop.xcassets/Pre-Meal.imageset`
  and `Pre-Meal Selected.imageset` replace Loop's plate-with-timer icon with
  the same fork and knife around a plate holding a down arrow (pre-meal lowers
  the target), so it no longer reads as a second carb button. Loop's
  `build-derived-assets.sh` copies this catalog over its own assets at build
  time, so no Loop patch is involved. Vector PDFs on the original 40×40 pt
  canvas, template rendering, generated by `tests/make-premeal-icons.swift`.
  Not changed: the small pre-meal glyph in the status row (`Pre-Meal-symbol`),
  the Watch and widget icons.
  **Revert:** delete the two `Pre-Meal*.imageset` folders from
  `OverrideAssetsLoop.xcassets`.

## Widget glucose "---" after the Modelv5 update, and patch 10 (October 21, 2026)

- **Widget symptom:** after installing the first build with Modelv5, the
  home-screen widget showed loop status, eventual glucose and basal (from the
  app-group `StatusExtensionContext`) but "---" for current glucose. The
  widget reads current glucose from LoopKit's shared Core Data store
  (`StatusWidgetTimelineProvider` → `PersistenceController.controllerInAppGroupDirectory()`
  → `GlucoseStore`). A failed open leaves the controller in an error state for
  the life of that widget process, and a failed fetch is shown as "---".
- **Cause:** the store's first lightweight migration (v4 → v5) ran while iOS
  was relaunching both the app and the widget after the update; the widget's
  controller lost that race. Confirmed by the fix: installing the next build
  (fresh widget process, store already v5) restored glucose. It can recur
  only on an update that changes LoopKit's Core Data model again; if it does,
  installing any later build or restarting the phone clears it.
- **Patch 10** (`patches/10-premeal-blue-and-favorites-replace.patch`, Loop):
  pre-meal toolbar button tinted `.glucoseTintColor` (the workout heart's
  blue) instead of `.carbTintColor`; Favorites CSV import preview gains
  "Replace all", which loads the file as the complete list in file order
  behind a confirmation dialog (merge is unchanged and renamed "Merge").
  Revert: delete the patch file.
- Patch loop 01–10 from pristine submodules reproduces the working tree
  exactly.
