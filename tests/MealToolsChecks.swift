// Standalone checks for the meal-tools code and the 🥜 delayed-metabolic curve.
// Run from the workspace root (see tests/review-verification.md):
//
//   swiftc -parse-as-library -o /tmp/mealtools-checks \
//     tests/MealToolsChecks.swift tests/CarbAbsorptionShim.swift \
//     LoopKit/LoopKit/CarbKit/MealTools.swift \
//     LoopKit/LoopKit/CarbKit/DelayedMetabolicResponseAbsorption.swift && /tmp/mealtools-checks
//
// These are math/format checks only. They do not exercise Core Data, the UI,
// notifications, or Loop's dosing pipeline.

import Foundation

@main
struct MealToolsChecks {
    static var checks = 0
    static func require(_ condition: @autoclosure () throws -> Bool, _ message: String) rethrows {
        let ok = try condition()
        precondition(ok, message); checks += 1
    }
    static func rejects(_ text: String) {
        do { _ = try FavoriteFoodCSV.decode(text); fatalError("Invalid CSV accepted") }
        catch { checks += 1 }
    }
    static func near(_ a: Double, _ b: Double, _ tol: Double = 1e-9) -> Bool { abs(a - b) <= tol }

    static func main() throws {
        try csvChecks()
        try reminderChecks()
        try curveChecks()
        print("Passed \(checks) meal-tools checks")
    }

    // MARK: - CSV

    static func csvChecks() throws {
        let rows = [
            FavoriteCSVRecord(id: UUID().uuidString, name: "Apple, \"dessert\"\nsecond line 🥜", grams: 350,
                              foodType: "🥜 nuts", absorptionMinutes: 720, patternIdentifier: MealAbsorptionPattern.delayedMetabolicV1),
            FavoriteCSVRecord(id: UUID().uuidString, name: "=HYPERLINK(\"example\")", grams: 1.5,
                              foodType: "'quoted", absorptionMinutes: 30, patternIdentifier: nil)
        ]
        let csv = FavoriteFoodCSV.encode(rows)
        let decoded = try FavoriteFoodCSV.decode(csv)
        require(decoded == rows, "Unicode, quoting, newlines, formulas and IDs must round trip")
        require(csv.contains("'=HYPERLINK"), "Formula-like text must be escaped")
        try require(try FavoriteFoodCSV.decode("\u{FEFF}" + csv) == rows, "UTF-8 BOM must be accepted")
        try require(try FavoriteFoodCSV.decode(csv.replacingOccurrences(of: "\r\n", with: "\n")) == rows, "LF CSV must be accepted")
        let standardRow = csv.replacingOccurrences(of: MealAbsorptionPattern.delayedMetabolicV1, with: MealAbsorptionPattern.standard)
        try require(try FavoriteFoodCSV.decode(standardRow)[0].patternIdentifier == MealAbsorptionPattern.standard, "Standard pattern must import")
        rejects(csv.replacingOccurrences(of: "350.0", with: "350.1"))
        rejects(csv.replacingOccurrences(of: "350.0", with: "nan"))
        rejects(csv.replacingOccurrences(of: "350.0", with: "inf"))
        rejects(csv.replacingOccurrences(of: "350.0", with: "0"))
        rejects(csv.replacingOccurrences(of: "720.0", with: "721"))
        rejects(csv.replacingOccurrences(of: "30.0", with: "29"))
        rejects(csv.replacingOccurrences(of: MealAbsorptionPattern.delayedMetabolicV1, with: "future-unknown-v9"))
        rejects(csv.replacingOccurrences(of: MealAbsorptionPattern.delayedMetabolicV1, with: "delayed-metabolic-preview-v1"))
        rejects(FavoriteFoodCSV.encode([rows[0], rows[0]]))
        rejects("schema_version,id\n1,abc\n")
        rejects("\"unfinished")
        rejects(csv.replacingOccurrences(of: "\"carbs_g\"", with: "\"grams\""))
        rejects(String(repeating: "a", count: FavoriteFoodCSV.maximumBytes + 1))
        rejects(FavoriteFoodCSV.encode(Array(repeating: rows[0], count: 1001)))
    }

    // MARK: - Reminders

    static func reminderChecks() throws {
        let reminder = RecurringPresetReminder(presetID: UUID(), weekdays: [2, 4, 6], hour: 9, minute: 30)
        require(reminder.isValid, "Weekday schedule should validate")
        require(reminder.calendarComponents.map(\.weekday) == [2, 4, 6], "Every selected weekday needs one trigger")
        require(reminder.calendarComponents.allSatisfy { $0.timeZone == nil && $0.hour == 9 && $0.minute == 30 }, "Reminders must follow local wall time")
        var invalid = reminder; invalid.weekdays = []
        require(!invalid.isValid && invalid.calendarComponents.isEmpty, "Empty schedules should be rejected")
        invalid = reminder; invalid.hour = 24
        require(!invalid.isValid, "Invalid hours must be rejected")
        invalid = reminder; invalid.weekdays = [0, 8]
        require(!invalid.isValid, "Invalid weekdays must be rejected")
        invalid = reminder; invalid.enabled = false
        require(invalid.calendarComponents.isEmpty, "Disabled reminders must schedule nothing")
        let restored = try JSONDecoder().decode(RecurringPresetReminder.self, from: JSONEncoder().encode(reminder))
        require(restored == reminder, "Schedule identity and timing must survive relaunch")
    }

    // MARK: - 🥜 Delayed metabolic response curve

    static func curveChecks() throws {
        // Source data: six zoodle-dinner nights, 12 h entries (stacked-meals-results.json).
        let data = DelayedMetabolicResponseData.observedLateRiseMidpointHours
        require(data == [6.12, 5.84, 4.31, 4.56, 7.61, 7.66], "Observed midpoints must match the research JSON")
        require(near(DelayedMetabolicResponseData.averageFraction, 6.0166666667 / 12, 1e-6), "Average late rise is 6h01m after a 12h entry (50.1%)")
        require(near(DelayedMetabolicResponseData.earliestFraction, 4.31 / 12, 1e-9) && near(DelayedMetabolicResponseData.latestFraction, 7.66 / 12, 1e-9), "Observed spread 35.9%–63.8%")

        let model = DelayedMetabolicResponseAbsorption()
        let knees = DelayedMetabolicResponseAbsorption.knees

        // Knees are anchored on the data: wave bounds = rounded earliest/latest midpoints, peak segment centred on the mean.
        require(near(knees[3].t, (DelayedMetabolicResponseData.earliestFraction * 100).rounded() / 100), "Wave onset knee = earliest observed midpoint fraction")
        require(near(knees[6].t, (DelayedMetabolicResponseData.latestFraction * 100).rounded() / 100), "Wave end knee = latest observed midpoint fraction")
        let peak = DelayedMetabolicResponseAbsorption.peakRateWindow
        require(near((peak.lowerBound + peak.upperBound) / 2, 0.50) && abs(DelayedMetabolicResponseData.averageFraction - 0.50) < 0.005, "Peak-rate segment is centred on the observed 50% average")

        // Shape invariants.
        require(knees.first!.t == 0 && knees.first!.p == 0 && knees.last!.t == 1 && knees.last!.p == 1, "Curve spans 0→1")
        for i in 1..<knees.count {
            require(knees[i].t > knees[i - 1].t && knees[i].p > knees[i - 1].p, "Knees strictly increasing (invertible)")
        }
        var maxRate = 0.0, maxSeg = -1
        for i in 1..<knees.count {
            let r = (knees[i].p - knees[i - 1].p) / (knees[i].t - knees[i - 1].t)
            if r > maxRate { maxRate = r; maxSeg = i }
        }
        require(knees[maxSeg - 1].t == peak.lowerBound && knees[maxSeg].t == peak.upperBound, "Fastest segment is the advertised peak window 0.43–0.57")
        require(maxRate < 2.0 && maxRate > 1.5, "Peak rate (1.93× mean) stays below the parabolic model's 2× peak")

        // Pointwise: monotone, bounded, rate non-negative, inverse consistent, totals conserved.
        var last = -1.0
        for i in 0...1000 {
            let t = Double(i) / 1000
            let p = model.percentAbsorptionAtPercentTime(t)
            require(p >= last - 1e-12 && p >= 0 && p <= 1, "Cumulative absorption monotone and bounded at t=\(t)")
            require(model.percentRateAtPercentTime(t) >= 0, "Rate never negative")
            require(near(model.percentTimeAtPercentAbsorption(p), t, 1e-9), "Inverse round-trips at t=\(t)")
            last = p
        }
        require(model.percentAbsorptionAtPercentTime(-0.1) == 0 && model.percentAbsorptionAtPercentTime(1.5) == 1, "Clamped outside 0…1")
        require(near(model.absorbedCarbs(of: 300, atTime: 12 * 3600, absorptionTime: 12 * 3600), 300), "All 300 g absorbed at the end of a 12 h entry")
        require(near(model.absorbedCarbs(of: 300, atTime: 6 * 3600, absorptionTime: 12 * 3600) + model.unabsorbedCarbs(of: 300, atTime: 6 * 3600, absorptionTime: 12 * 3600), 300), "Absorbed + unabsorbed = total")

        // Duration scaling: the same percent-time shape applies to any selected duration.
        for hours in [6.0, 8.0, 9.0, 12.0] {
            let d = hours * 3600
            require(near(model.absorbedCarbs(of: 100, atTime: 0.5 * d, absorptionTime: d), 100 * model.percentAbsorptionAtPercentTime(0.5)), "Half-way absorption identical at \(hours) h")
            let window = DelayedMetabolicResponsePreview().peakAbsorptionWindow(after: d)
            require(near(window.lowerBound, 0.43 * d) && near(window.upperBound, 0.57 * d), "Preview peak window scales with duration (\(hours) h)")
        }

        // Numbers quoted in the curve's doc comment / UI, at a 12 h entry.
        func pct(_ h: Double) -> Double { model.percentAbsorptionAtPercentTime(h / 12) }
        require(near(pct(1.5), 0.05) && near(pct(3), 0.13) && near(pct(4.32), 0.23) && near(pct(6.84), 0.60) && near(pct(9.6), 0.86), "Documented 12 h milestones")
        require(near(model.absorbedCarbs(of: 100, atTime: 6 * 3600, absorptionTime: 12 * 3600), 46.5, 0.01), "46.5% absorbed at the 6 h midpoint of a 12 h entry")

        // It is genuinely more delayed than the fork's global model.
        let pl = PiecewiseLinearAbsorption()
        for t in [0.25, 0.5, 0.75] {
            require(model.percentAbsorptionAtPercentTime(t) < pl.percentAbsorptionAtPercentTime(t), "Delayed curve lags PiecewiseLinear at \(t)")
        }

        // Preview text and model agree.
        let preview = DelayedMetabolicResponsePreview()
        require(near(preview.averageLateResponse(after: 12 * 3600) / 3600, 6.0166666667, 1e-6), "Preview average = data average")
        require(near(preview.averageLateResponse(after: 6 * 3600) * 2, preview.averageLateResponse(after: 12 * 3600)), "Preview timing scales with duration")
        let range = preview.observedTimingRange(after: 12 * 3600)
        require(near(range.lowerBound / 3600, 4.31, 1e-6) && near(range.upperBound / 3600, 7.66, 1e-6), "Preview spread = observed spread")

        // Identifiers are stable and the retired preview identifier is not accepted.
        require(MealAbsorptionPattern.delayedMetabolicV1 == "delayed-metabolic-v1" && MealAbsorptionPattern.standard == "standard-v1", "Persisted identifiers unchanged")
        require(MealAbsorptionPattern.isSupported(nil) && !MealAbsorptionPattern.isSupported("delayed-metabolic-preview-v1"), "nil is legacy; unknown ids unsupported")
    }
}
