# Customizations in this workspace

Compared with upstream/update_dev_to_3.14.4, this branch keeps a forked LoopKit with parabolic carbohydrate absorption, the 🥜12h delayed dessert curve (including legacy 🌙 labels), the 🍲8h heavy-meal curve, and a 12-hour model absorption ceiling.

Both GitHub build workflows apply the local patches before building:

- 01: allow absorption times up to 12 hours and carb entries up to four hours ahead.
- 02: default absorption presets of 2.5, 4, and 6 hours.
- 03: large-meal confirmation only above 200 grams; the entry maximum remains 250 grams. At exactly 200 grams there is no large-meal confirmation.
- 04: bypass LoopKit device authentication for bolus and therapy-settings actions (Face ID, Touch ID, and passcode).

The manual build workflow additionally retains the existing remote selections: profiles, basal_lock, and negative_insulin. The automatic workflow did not previously include these and still does not. No additional optional features have been enabled.

Local source has these four patches applied for Xcode builds. GitHub checkouts start from clean submodule pins and apply patches during the build. Do not commit the patched submodule source and also advance its gitlink while retaining the same patches: that would apply them twice. Keep these changes as workspace patches. Both workflows check patch applicability and fail rather than silently building without them.

Other prepared options to choose from: a current-time line on charts; two days or one week of meal history; CGM sensor-status notes in Nightscout; a 50–200% insulin-needs picker in 5% increments; a 10-minute remote-command window; xDrip4iOS integration; and alternate app/watch presentation. Availability and compatibility must be checked against the selected Loop version before enabling.

Source: https://www.loopandlearn.org/custom-code/
