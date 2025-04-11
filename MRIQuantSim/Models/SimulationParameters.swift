//
//  SimulationParameters.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import Foundation
import SwiftData

// Enum for different response shape types
enum ResponseShapeType: String, Codable, CaseIterable {
    case boxcar = "Boxcar"
    case exponential = "Exponential"
    // Future shape types can be added here
}

@Model
final class SimulationParameters {
    // Signal Parameters
    var co2SamplingRate: Double = 10.0 // Hz
    var breathingRate: Double = 15.0 // breaths per minute
    var mriSamplingInterval: Double = 2.0 // seconds
    var mriBaselineSignal: Double = 1200.0 // arbitrary units
    var mriResponseAmplitude: Double = 25.0 // arbitrary units
    var co2ResponseAmplitude: Double = 5.0 // mmHg
    
    // Response Shape Parameters for Signal Simulation
    // Store as a string to avoid issues with SwiftData and enums
    var responseShapeTypeString: String = ResponseShapeType.boxcar.rawValue
    var responseRiseTimeConstant: Double = 20.0 // seconds
    var responseFallTimeConstant: Double = 20.0 // seconds
    
    // Computed property to convert between string and enum
    @Transient
    var responseShapeType: ResponseShapeType {
        get {
            ResponseShapeType(rawValue: responseShapeTypeString) ?? .boxcar
        }
        set {
            responseShapeTypeString = newValue.rawValue
        }
    }
    
    // Analysis Model Parameters (for GLM analysis - potentially different from simulation)
    var analysisModelTypeString: String = ResponseShapeType.boxcar.rawValue
    var analysisRiseTimeConstant: Double = 20.0 // seconds
    var analysisFallTimeConstant: Double = 20.0 // seconds
    
    // Computed property for analysis model type
    @Transient
    var analysisModelType: ResponseShapeType {
        get {
            ResponseShapeType(rawValue: analysisModelTypeString) ?? .boxcar
        }
        set {
            analysisModelTypeString = newValue.rawValue
        }
    }
    
    // Method to copy simulation time constants to analysis time constants
    func copySimulationTimeConstantsToAnalysis() {
        // Only make sense if simulation is using exponential model
        if responseShapeType == .exponential {
            analysisModelTypeString = responseShapeTypeString
            analysisRiseTimeConstant = responseRiseTimeConstant
            analysisFallTimeConstant = responseFallTimeConstant
        }
    }
    
    // Function to check if the simulation model is using exponential shape
    func isSimulationUsingExponential() -> Bool {
        return responseShapeType == .exponential
    }
    
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
            co2ResponseAmplitude: co2ResponseAmplitude,
            co2VarianceFrequency: co2VarianceFrequency,
            co2VarianceAmplitude: co2VarianceAmplitude,
            co2AmplitudeVariance: co2AmplitudeVariance,
            enableCO2Variance: enableCO2Variance,
            
            // Response shape parameters (for simulation)
            responseShapeTypeString: responseShapeTypeString,
            responseRiseTimeConstant: responseRiseTimeConstant,
            responseFallTimeConstant: responseFallTimeConstant,
            
            // Analysis model parameters
            analysisModelTypeString: analysisModelTypeString,
            analysisRiseTimeConstant: analysisRiseTimeConstant,
            analysisFallTimeConstant: analysisFallTimeConstant,
            
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
    let co2ResponseAmplitude: Double
    let co2VarianceFrequency: Double
    let co2VarianceAmplitude: Double
    let co2AmplitudeVariance: Double
    let enableCO2Variance: Bool
    
    // Response shape parameters (for simulation)
    let responseShapeTypeString: String
    let responseRiseTimeConstant: Double
    let responseFallTimeConstant: Double
    
    // Analysis model parameters
    let analysisModelTypeString: String
    let analysisRiseTimeConstant: Double
    let analysisFallTimeConstant: Double
    
    // Computed properties for convenience
    var responseShapeType: ResponseShapeType {
        ResponseShapeType(rawValue: responseShapeTypeString) ?? .boxcar
    }
    
    var analysisModelType: ResponseShapeType {
        ResponseShapeType(rawValue: analysisModelTypeString) ?? .boxcar
    }
    
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
               co2ResponseAmplitude == previous.co2ResponseAmplitude &&
               co2VarianceFrequency == previous.co2VarianceFrequency &&
               co2VarianceAmplitude == previous.co2VarianceAmplitude &&
               co2AmplitudeVariance == previous.co2AmplitudeVariance &&
               enableCO2Variance == previous.enableCO2Variance &&
               
               // All response shape parameters must be the same
               responseShapeTypeString == previous.responseShapeTypeString &&
               responseRiseTimeConstant == previous.responseRiseTimeConstant &&
               responseFallTimeConstant == previous.responseFallTimeConstant &&
               
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
            co2ResponseAmplitude != previous.co2ResponseAmplitude ||
            co2VarianceFrequency != previous.co2VarianceFrequency ||
            co2VarianceAmplitude != previous.co2VarianceAmplitude ||
            co2AmplitudeVariance != previous.co2AmplitudeVariance ||
            enableCO2Variance != previous.enableCO2Variance;
            
        // Note: Response shape parameters are NOT included here because they affect both CO2 and MRI signals
        // and should trigger a full simulation update when changed
            
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
    
    // Helper method to check if only response shape parameters changed
    func responseShapeParamsChangedFrom(previous: ParameterState) -> Bool {
        // Check if any response shape parameter changed
        let shapeParamsChanged = 
            responseShapeTypeString != previous.responseShapeTypeString ||
            responseRiseTimeConstant != previous.responseRiseTimeConstant ||
            responseFallTimeConstant != previous.responseFallTimeConstant;
            
        // And all other parameters remain the same
        return shapeParamsChanged &&
               // All MRI parameters must be the same
               mriNoiseAmplitude == previous.mriNoiseAmplitude &&
               mriBaselineSignal == previous.mriBaselineSignal &&
               mriResponseAmplitude == previous.mriResponseAmplitude &&
               mriLinearDrift == previous.mriLinearDrift &&
               mriQuadraticDrift == previous.mriQuadraticDrift &&
               mriCubicDrift == previous.mriCubicDrift &&
               enableMRINoise == previous.enableMRINoise &&
               enableMRIDrift == previous.enableMRIDrift &&
               
               // All CO2 parameters must be the same
               co2ResponseAmplitude == previous.co2ResponseAmplitude &&
               co2VarianceFrequency == previous.co2VarianceFrequency &&
               co2VarianceAmplitude == previous.co2VarianceAmplitude &&
               co2AmplitudeVariance == previous.co2AmplitudeVariance &&
               enableCO2Variance == previous.enableCO2Variance &&
               
               // All analysis model parameters must be the same
               analysisModelTypeString == previous.analysisModelTypeString &&
               analysisRiseTimeConstant == previous.analysisRiseTimeConstant &&
               analysisFallTimeConstant == previous.analysisFallTimeConstant &&
               
               // All model terms must be the same
               includeConstantTerm == previous.includeConstantTerm &&
               includeLinearTerm == previous.includeLinearTerm &&
               includeQuadraticTerm == previous.includeQuadraticTerm &&
               includeCubicTerm == previous.includeCubicTerm
    }
    
    // Helper method to check if only analysis model parameters changed
    func analysisModelParamsChangedFrom(previous: ParameterState) -> Bool {
        // Check if any analysis model parameter changed
        let analysisParamsChanged = 
            analysisModelTypeString != previous.analysisModelTypeString ||
            analysisRiseTimeConstant != previous.analysisRiseTimeConstant ||
            analysisFallTimeConstant != previous.analysisFallTimeConstant;
            
        // And all other parameters remain the same
        return analysisParamsChanged &&
               // All MRI parameters must be the same
               mriNoiseAmplitude == previous.mriNoiseAmplitude &&
               mriBaselineSignal == previous.mriBaselineSignal &&
               mriResponseAmplitude == previous.mriResponseAmplitude &&
               mriLinearDrift == previous.mriLinearDrift &&
               mriQuadraticDrift == previous.mriQuadraticDrift &&
               mriCubicDrift == previous.mriCubicDrift &&
               enableMRINoise == previous.enableMRINoise &&
               enableMRIDrift == previous.enableMRIDrift &&
               
               // All CO2 parameters must be the same
               co2ResponseAmplitude == previous.co2ResponseAmplitude &&
               co2VarianceFrequency == previous.co2VarianceFrequency &&
               co2VarianceAmplitude == previous.co2VarianceAmplitude &&
               co2AmplitudeVariance == previous.co2AmplitudeVariance &&
               enableCO2Variance == previous.enableCO2Variance &&
               
               // All simulation response shape parameters must be the same
               responseShapeTypeString == previous.responseShapeTypeString &&
               responseRiseTimeConstant == previous.responseRiseTimeConstant &&
               responseFallTimeConstant == previous.responseFallTimeConstant &&
               
               // All model terms must be the same
               includeConstantTerm == previous.includeConstantTerm &&
               includeLinearTerm == previous.includeLinearTerm &&
               includeQuadraticTerm == previous.includeQuadraticTerm &&
               includeCubicTerm == previous.includeCubicTerm
    }
}
