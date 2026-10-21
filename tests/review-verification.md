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
