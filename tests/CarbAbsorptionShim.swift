// Test-only shim: the subset of LoopKit's CarbMath.swift that
// DelayedMetabolicResponseAbsorption.swift depends on, so the curve can be
// compiled and checked with plain swiftc (LoopKitTests does not build).
// Keep in sync with LoopKit/LoopKit/CarbKit/CarbMath.swift.

import Foundation

public protocol CarbAbsorptionComputable {
    func percentAbsorptionAtPercentTime(_ percentTime: Double) -> Double
    func percentTimeAtPercentAbsorption(_ percentAbsorption: Double) -> Double
    func absorptionTime(forPercentAbsorption percentAbsorption: Double, atTime time: TimeInterval) -> TimeInterval
    func absorbedCarbs(of total: Double, atTime time: TimeInterval, absorptionTime: TimeInterval) -> Double
    func unabsorbedCarbs(of total: Double, atTime time: TimeInterval, absorptionTime: TimeInterval) -> Double
    func percentRateAtPercentTime(_ percentTime: Double) -> Double
}

extension CarbAbsorptionComputable {
    public func absorbedCarbs(of total: Double, atTime time: TimeInterval, absorptionTime: TimeInterval) -> Double {
        total * percentAbsorptionAtPercentTime(time / absorptionTime)
    }
    public func unabsorbedCarbs(of total: Double, atTime time: TimeInterval, absorptionTime: TimeInterval) -> Double {
        total * (1.0 - percentAbsorptionAtPercentTime(time / absorptionTime))
    }
    public func absorptionTime(forPercentAbsorption percentAbsorption: Double, atTime time: TimeInterval) -> TimeInterval {
        time / max(percentTimeAtPercentAbsorption(percentAbsorption), .ulpOfOne)
    }
    func timeToAbsorb(forPercentAbsorbed percentAbsorption: Double, totalAbsorptionTime: TimeInterval) -> TimeInterval {
        percentTimeAtPercentAbsorption(percentAbsorption) * totalAbsorptionTime
    }
}

/// The fork's global model (CarbStore .nonlinear), copied for comparison checks.
struct PiecewiseLinearAbsorption: CarbAbsorptionComputable {
    let percentEndOfRise = 0.15
    let percentStartOfFall = 0.5
    var scale: Double { 2.0 / (1.0 + percentStartOfFall - percentEndOfRise) }
    func percentAbsorptionAtPercentTime(_ percentTime: Double) -> Double {
        switch percentTime {
        case let t where t <= 0.0: return 0.0
        case let t where t < percentEndOfRise: return 0.5 * scale * pow(t, 2.0) / percentEndOfRise
        case let t where t >= percentEndOfRise && t < percentStartOfFall: return scale * (t - 0.5 * percentEndOfRise)
        case let t where t >= percentStartOfFall && t < 1.0:
            return scale * (percentStartOfFall - 0.5 * percentEndOfRise + (t - percentStartOfFall) * (1.0 - 0.5 * (t - percentStartOfFall) / (1.0 - percentStartOfFall)))
        default: return 1.0
        }
    }
    func percentTimeAtPercentAbsorption(_ percentAbsorption: Double) -> Double { 0 }
    func percentRateAtPercentTime(_ percentTime: Double) -> Double { 0 }
}
