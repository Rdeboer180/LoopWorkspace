# Rolling 24-hour carb history

Reading this as a native carb-review flow, prioritizing discoverability, time context, and reuse of recorded meals. Calm data-product mode; variance 2, motion 1, density 5, system rigor 9.

Patch `06-carb-history-24h.patch` extends `CarbAbsorptionViewController` after patch 05. Remove patch 06 to revert on a clean build.

**See past 24 hours** is a native button row below the carb entry list, including when the recent list is empty. It expands the list inline to entries with start times in the preceding 24 hours, excluding future entries. Fully absorbed meals are included. Entries remain newest first, with a date and time to distinguish yesterday's meals. The list header becomes **Past 24 Hours**, and **Show recent carbs** restores the original list window.

History has its own absorption-status query. The original recent query still supplies the COB summary, and the chart and since-midnight total retain their current windows. Entries keep their existing edit permissions and Save to Favorites flow. Deleted and superseded entries are excluded by CarbStore's existing query.

During loading, the history action shows **Loading carb entries…** and rejects repeated taps. A history query failure displays the existing error alert. Native text wraps, supports Dynamic Type, uses the existing tint, and announces a button trait. The button is estimated at 44 points high and grows with content.

Validation: Swift syntax parsing and sequential application after patches 01–03 and 05 pass. Runtime layout and full app build remain to be verified using a simulator with the required watchOS runtime or the GitHub build workflow.
