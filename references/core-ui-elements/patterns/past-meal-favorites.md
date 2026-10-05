# Save a past meal to favorites

## Intent and source

Use this flow when reviewing a meal in Active Carbohydrates and making a reusable favorite. Patch `05-past-meal-favorites.patch` contains the implementation and tests; removing it reverts the feature in a clean build.

Reading this as a native health-data review flow, prioritizing recorded values, explicit choices, and persistence. Calm data-product mode; variance 2, motion 1, density 5, system rigor 9.

## Interaction

1. Select an editable meal in Active Carbohydrates.
2. Tap **Save to Favorites**, immediately below Continue. No changes to the meal are required.
3. The existing New Favorite Food sheet copies carbs, absorption duration, and the complete food type (including custom curve markers). Enter a name and edit any draft fields.
4. When available, the sheet displays the same observed absorbed-carb amount shown in the meal row. Recorded carbs stay selected initially. **Use absorbed estimate** explicitly replaces only the favorite draft's carb amount; **Use recorded amount** restores its initial amount.
5. Save uses existing quantity limits and large-meal confirmation, stores the favorite, and closes the sheet. Cancel discards the draft. Neither path updates the past meal or opens bolus entry.

The absorbed amount is Loop's estimate from glucose response, not a measured food carb count or a recommendation. If absorption is still active, show that the estimate is partial and disable using it. Missing, non-positive, or non-finite estimates hide the evidence panel. Estimates above the existing carb limit are shown but cannot be applied. Absorption is a snapshot from row selection; reopen the meal to refresh it.

## Native presentation and accessibility

Reuse system typography, native Buttons, existing card surfaces, and the editable quantity/duration controls. Choices stack vertically, wrap on narrow displays, and have at least 44-point touch targets. Selection changes the visible carb field. Explain disabled choices in text; no new color semantics or animation are needed.

## Implementation and checks

The controller passes the meal's `AbsorbedCarbValue` to the editor, which passes it to an independent favorite draft. The past-meal initializer starts favorite persistence but does not subscribe to applying favorite selection back to the entry.

`PastMealFavoriteTests` in the existing `LoopTests.swift` covers opt-in use, preserving 12-hour duration and marker, restoring recorded carbs, rejecting partial/invalid/excessive estimates, and saving without absorption evidence.

Before shipping, verify the app build and run these tests. Manually confirm persistence after relaunch, cancel behavior, an unchanged meal, active/finished absorption states, Dynamic Type, and VoiceOver labels.
