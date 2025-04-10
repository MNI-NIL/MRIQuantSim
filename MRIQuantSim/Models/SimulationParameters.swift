//
//  SimulationParameters.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import Foundation
import SwiftData

@Model
final class SimulationParameters {
    // Signal Parameters
    var co2SamplingRate: Double = 10.0 // Hz
    var breathingRate: Double = 15.0 // breaths per minute
    var mriSamplingInterval: Double = 2.0 // seconds
    var mriBaselineSignal: Double = 1200.0 // arbitrary units
    var mriResponseAmplitude: Double = 25.0 // arbitrary units
    
    // Noise Parameters
    var co2NoiseFrequency: Double = 0.05 // Hz
    var co2NoiseAmplitude: Double = 0.1 // dimensionless multiplier
    var mriNoiseAmplitude: Double = 5.0 // arbitrary units
    
    // Drift Parameters - CO2
    var co2LinearDrift: Double = 1.0 // mmHg
    var co2QuadraticDrift: Double = 1.5 // mmHg
    var co2CubicDrift: Double = 2.5 // mmHg
    
    // Drift Parameters - MRI
    var mriLinearDrift: Double = 3.0 // au
    var mriQuadraticDrift: Double = 3.0 // au
    var mriCubicDrift: Double = 4.0 // au
    
    // Display Parameters
    var showCO2Raw: Bool = true
    var showCO2EndTidal: Bool = true
    var showMRIRaw: Bool = true
    var showMRIDetrended: Bool = false
    var showModelOverlay: Bool = false
    var useDynamicMRIRange: Bool = true
    var enableCO2Noise: Bool = true
    var enableMRINoise: Bool = true
    var enableCO2Drift: Bool = true
    var enableMRIDrift: Bool = true
    
    // Detrending Parameters
    var includeConstantTerm: Bool = true
    var includeLinearTerm: Bool = true
    var includeQuadraticTerm: Bool = true
    var includeCubicTerm: Bool = true
    
    // Computed model parameters (not stored, updated after analysis)
    @Transient var modelBetaParams: [Double] = []
    @Transient var percentChangeMetric: Double = 0.0
    
    init() {}
}
