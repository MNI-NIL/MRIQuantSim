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
    var co2VarianceFrequency: Double = 0.05 // Hz
    var co2VarianceAmplitude: Double = 0.1 // dimensionless multiplier for frequency modulation
    var co2AmplitudeVariance: Double = 1.0 // mmHg - amplitude modulation
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
    var useMRIDynamicRange: Bool = true
    var enableCO2Variance: Bool = true
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
    
    // Create a representation of parameter state as a struct
    // This avoids using copy() which might not be compatible with @Model
    @Transient var cachedParamState: ParameterState?
    
    func getParameterState() -> ParameterState {
        return ParameterState(
            // MRI parameters
            mriNoiseAmplitude: mriNoiseAmplitude,
            mriBaselineSignal: mriBaselineSignal,
            mriResponseAmplitude: mriResponseAmplitude,
            mriLinearDrift: mriLinearDrift,
            mriQuadraticDrift: mriQuadraticDrift,
            mriCubicDrift: mriCubicDrift,
            enableMRINoise: enableMRINoise,
            enableMRIDrift: enableMRIDrift,
            
            // CO2 parameters
            co2VarianceFrequency: co2VarianceFrequency,
            co2VarianceAmplitude: co2VarianceAmplitude,
            co2AmplitudeVariance: co2AmplitudeVariance,
            enableCO2Variance: enableCO2Variance,
            
            // Model terms
            includeConstantTerm: includeConstantTerm,
            includeLinearTerm: includeLinearTerm,
            includeQuadraticTerm: includeQuadraticTerm,
            includeCubicTerm: includeCubicTerm
        )
    }
}

// Separate struct to hold parameter state for comparison
struct ParameterState: Equatable {
    // MRI parameters
    let mriNoiseAmplitude: Double
    let mriBaselineSignal: Double
    let mriResponseAmplitude: Double
    let mriLinearDrift: Double
    let mriQuadraticDrift: Double
    let mriCubicDrift: Double
    let enableMRINoise: Bool
    let enableMRIDrift: Bool
    
    // CO2 parameters
    let co2VarianceFrequency: Double
    let co2VarianceAmplitude: Double
    let co2AmplitudeVariance: Double
    let enableCO2Variance: Bool
    
    // Model terms
    let includeConstantTerm: Bool
    let includeLinearTerm: Bool
    let includeQuadraticTerm: Bool
    let includeCubicTerm: Bool
    
    // Helper method to check if only the MRI noise amplitude changed
    func onlyNoiseAmplitudeChangedFrom(previous: ParameterState) -> Bool {
        return mriNoiseAmplitude != previous.mriNoiseAmplitude &&
               // All other MRI parameters must be the same
               mriBaselineSignal == previous.mriBaselineSignal &&
               mriResponseAmplitude == previous.mriResponseAmplitude &&
               mriLinearDrift == previous.mriLinearDrift &&
               mriQuadraticDrift == previous.mriQuadraticDrift &&
               mriCubicDrift == previous.mriCubicDrift &&
               enableMRINoise == previous.enableMRINoise &&
               enableMRIDrift == previous.enableMRIDrift &&
               
               // All CO2 parameters must be the same
               co2VarianceFrequency == previous.co2VarianceFrequency &&
               co2VarianceAmplitude == previous.co2VarianceAmplitude &&
               co2AmplitudeVariance == previous.co2AmplitudeVariance &&
               enableCO2Variance == previous.enableCO2Variance &&
               
               // All model terms must be the same
               includeConstantTerm == previous.includeConstantTerm &&
               includeLinearTerm == previous.includeLinearTerm &&
               includeQuadraticTerm == previous.includeQuadraticTerm &&
               includeCubicTerm == previous.includeCubicTerm
    }
    
    // Helper method to check if only CO2 variance parameters changed
    func onlyCO2VarianceParamsChangedFrom(previous: ParameterState) -> Bool {
        // Check if any CO2 variance parameter changed
        let co2ParamsChanged = 
            co2VarianceFrequency != previous.co2VarianceFrequency ||
            co2VarianceAmplitude != previous.co2VarianceAmplitude ||
            co2AmplitudeVariance != previous.co2AmplitudeVariance ||
            enableCO2Variance != previous.enableCO2Variance;
            
        // And all other parameters remain the same
        return co2ParamsChanged &&
               // All MRI parameters must be the same
               mriNoiseAmplitude == previous.mriNoiseAmplitude &&
               mriBaselineSignal == previous.mriBaselineSignal &&
               mriResponseAmplitude == previous.mriResponseAmplitude &&
               mriLinearDrift == previous.mriLinearDrift &&
               mriQuadraticDrift == previous.mriQuadraticDrift &&
               mriCubicDrift == previous.mriCubicDrift &&
               enableMRINoise == previous.enableMRINoise &&
               enableMRIDrift == previous.enableMRIDrift &&
               
               // All model terms must be the same
               includeConstantTerm == previous.includeConstantTerm &&
               includeLinearTerm == previous.includeLinearTerm &&
               includeQuadraticTerm == previous.includeQuadraticTerm &&
               includeCubicTerm == previous.includeCubicTerm
    }
    
    // Helper method to check if any model terms changed
    func modelTermsChangedFrom(previous: ParameterState) -> Bool {
        return includeConstantTerm != previous.includeConstantTerm ||
               includeLinearTerm != previous.includeLinearTerm ||
               includeQuadraticTerm != previous.includeQuadraticTerm ||
               includeCubicTerm != previous.includeCubicTerm
    }
}
