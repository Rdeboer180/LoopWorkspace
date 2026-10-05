# Core UI elements

- [Past-meal favorites flow](patterns/past-meal-favorites.md): native secondary action, independent favorite draft, optional absorbed-carb estimate, validation, and regression checks.
- [Rolling carb history](patterns/carb-history-24h.md): an accessible button below the meal list expands it to the preceding 24 hours.

Reuse `CarbEntryView`, `AddEditFavoriteFoodView`, `CarbQuantityRow`, `AbsorptionTimePickerRow`, and `CardBackground` for this flow. These adapt to the native scroll view, system type sizes, and light/dark appearance.
