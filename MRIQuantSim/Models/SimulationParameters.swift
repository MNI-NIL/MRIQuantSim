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
    case fir = "FIR"
    // Future shape types can be added here
}

// Enum for FIR response magnitude calculation methods
enum FIRResponseMethod: String, Codable, CaseIterable {
    case maximum = "Maximum Value"
    case mean = "Mean Value"
    case meanPositive = "Mean of Positive Values"
    case timeWindow = "Time Window"
}

@Model
final class SimulationParameters {
    // Signal Parameters
    var co2SamplingRate: Double
    var breathingRate: Double
    var mriSamplingInterval: Double
    var mriBaselineSignal: Double
    var mriResponseAmplitude: Double
    var co2ResponseAmplitude: Double
    
    // Response Shape Parameters for Signal Simulation
    // Store as a string to avoid issues with SwiftData and enums
    var responseShapeTypeString: String
    var responseRiseTimeConstant: Double
    var responseFallTimeConstant: Double
    
    // Computed property to convert between string and enum
    @Transient
    var responseShapeType: ResponseShapeType {
        get {
            let shapeType = ResponseShapeType(rawValue: responseShapeTypeString) ?? .boxcar
            // Ensure FIR is not used for simulation - fallback to boxcar
            return shapeType == .fir ? .boxcar : shapeType
        }
        set {
            // Prevent FIR from being set as simulation shape
            let safeValue = newValue == .fir ? .boxcar : newValue
            responseShapeTypeString = safeValue.rawValue
        }
    }
    
    // Analysis Model Parameters (for GLM analysis - potentially different from simulation)
    var analysisModelTypeString: String
    var analysisRiseTimeConstant: Double
    var analysisFallTimeConstant: Double
    var analysisFIRCoverage: Double
    var analysisFIRResponseMethodString: String
    var analysisFIRTimeWindowStart: Double // Start time for FIR time window method (seconds)
    var analysisFIRTimeWindowEnd: Double // End time for FIR time window method (seconds)
    
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
    
    // Computed property for FIR response method
    @Transient
    var analysisFIRResponseMethod: FIRResponseMethod {
        get {
            FIRResponseMethod(rawValue: analysisFIRResponseMethodString) ?? .maximum
        }
        set {
            analysisFIRResponseMethodString = newValue.rawValue
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
    var co2VarianceFrequency: Double
    var co2VarianceAmplitude: Double
    var co2AmplitudeVariance: Double
    var mriNoiseAmplitude: Double
    
    // Drift Parameters - CO2
    var co2LinearDrift: Double
    var co2QuadraticDrift: Double
    var co2CubicDrift: Double
    
    // Drift Parameters - MRI
    var mriLinearDrift: Double
    var mriQuadraticDrift: Double
    var mriCubicDrift: Double
    
    // Display Parameters
    var showCO2Raw: Bool
    var showCO2EndTidal: Bool
    var showMRIRaw: Bool
    var showMRIDetrended: Bool
    var showModelOverlay: Bool
    var showResidualError: Bool
    var useMRIDynamicRange: Bool
    var excludeBaselineFromChart: Bool
    var enableCO2Variance: Bool
    var enableMRINoise: Bool
    var enableCO2Drift: Bool
    var enableMRIDrift: Bool
    
    // Detrending Parameters
    var includeConstantTerm: Bool
    var includeLinearTerm: Bool
    var includeQuadraticTerm: Bool
    var includeCubicTerm: Bool
    
    // Computed model parameters (not stored, updated after analysis)
    @Transient var modelBetaParams: [Double] = []
    @Transient var percentChangeMetric: Double = 0.0
    
    init() {
        // Signal Parameters
        co2SamplingRate = 10.0 // Hz
        breathingRate = 15.0 // breaths per minute
        mriSamplingInterval = 2.0 // seconds
        mriBaselineSignal = 1200.0 // arbitrary units
        mriResponseAmplitude = 100.0 // arbitrary units
        co2ResponseAmplitude = 10.0 // mmHg
        
        // Response Shape Parameters
        responseShapeTypeString = ResponseShapeType.exponential.rawValue
        responseRiseTimeConstant = 10.0 // seconds
        responseFallTimeConstant = 5.0 // seconds
        
        // Analysis Model Parameters
        analysisModelTypeString = ResponseShapeType.exponential.rawValue
        analysisRiseTimeConstant = 10.0 // seconds
        analysisFallTimeConstant = 5.0 // seconds
        analysisFIRCoverage = 90.0 // seconds - default FIR coverage duration
        analysisFIRResponseMethodString = FIRResponseMethod.timeWindow.rawValue // default to time window FIR response method
        analysisFIRTimeWindowStart = 30.0 // seconds - default start time for time window method
        analysisFIRTimeWindowEnd = 60.0 // seconds - default end time for time window method
        
        // Noise Parameters
        co2VarianceFrequency = 0.05 // Hz
        co2VarianceAmplitude = 1.5 // dimensionless multiplier for frequency modulation
        co2AmplitudeVariance = 0.5 // mmHg - amplitude modulation
        mriNoiseAmplitude = 5.0 // arbitrary units
        
        // Drift Parameters - CO2
        co2LinearDrift = 5.0 // mmHg
        co2QuadraticDrift = -5.5 // mmHg
        co2CubicDrift = -10.0 // mmHg
        
        // Drift Parameters - MRI
        mriLinearDrift = 3.0 // au
        mriQuadraticDrift = 3.0 // au
        mriCubicDrift = 4.0 // au
        
        // Display Parameters
        showCO2Raw = true
        showCO2EndTidal = true
        showMRIRaw = true
        showMRIDetrended = false
        showModelOverlay = true
        showResidualError = false
        useMRIDynamicRange = true
        excludeBaselineFromChart = true // Default to exclude baseline as it's much larger
        enableCO2Variance = true
        enableMRINoise = true
        enableCO2Drift = true
        enableMRIDrift = true
        
        // Detrending Parameters
        includeConstantTerm = true
        includeLinearTerm = true
        includeQuadraticTerm = true
        includeCubicTerm = true
    }
    
    // Function to reset all parameters to their default values
    func resetToDefaults() {
        // Create a new instance with default values
        let defaults = SimulationParameters()
        
        // Copy all properties from the default instance
        // Signal Parameters
        co2SamplingRate = defaults.co2SamplingRate
        breathingRate = defaults.breathingRate
        mriSamplingInterval = defaults.mriSamplingInterval
        mriBaselineSignal = defaults.mriBaselineSignal
        mriResponseAmplitude = defaults.mriResponseAmplitude
        co2ResponseAmplitude = defaults.co2ResponseAmplitude
        
        // Response Shape Parameters
        responseShapeTypeString = defaults.responseShapeTypeString
        responseRiseTimeConstant = defaults.responseRiseTimeConstant
        responseFallTimeConstant = defaults.responseFallTimeConstant
        
        // Analysis Model Parameters
        analysisModelTypeString = defaults.analysisModelTypeString
        analysisRiseTimeConstant = defaults.analysisRiseTimeConstant
        analysisFallTimeConstant = defaults.analysisFallTimeConstant
        analysisFIRCoverage = defaults.analysisFIRCoverage
        analysisFIRResponseMethodString = defaults.analysisFIRResponseMethodString
        analysisFIRTimeWindowStart = defaults.analysisFIRTimeWindowStart
        analysisFIRTimeWindowEnd = defaults.analysisFIRTimeWindowEnd
        
        // Noise Parameters
        co2VarianceFrequency = defaults.co2VarianceFrequency
        co2VarianceAmplitude = defaults.co2VarianceAmplitude
        co2AmplitudeVariance = defaults.co2AmplitudeVariance
        mriNoiseAmplitude = defaults.mriNoiseAmplitude
        
        // Drift Parameters - CO2
        co2LinearDrift = defaults.co2LinearDrift
        co2QuadraticDrift = defaults.co2QuadraticDrift
        co2CubicDrift = defaults.co2CubicDrift
        
        // Drift Parameters - MRI
        mriLinearDrift = defaults.mriLinearDrift
        mriQuadraticDrift = defaults.mriQuadraticDrift
        mriCubicDrift = defaults.mriCubicDrift
        
        // Display Parameters
        showCO2Raw = defaults.showCO2Raw
        showCO2EndTidal = defaults.showCO2EndTidal
        showMRIRaw = defaults.showMRIRaw
        showMRIDetrended = defaults.showMRIDetrended
        showModelOverlay = defaults.showModelOverlay
        showResidualError = defaults.showResidualError
        useMRIDynamicRange = defaults.useMRIDynamicRange
        excludeBaselineFromChart = defaults.excludeBaselineFromChart
        enableCO2Variance = defaults.enableCO2Variance
        enableMRINoise = defaults.enableMRINoise
        enableCO2Drift = defaults.enableCO2Drift
        enableMRIDrift = defaults.enableMRIDrift
        
        // Detrending Parameters
        includeConstantTerm = defaults.includeConstantTerm
        includeLinearTerm = defaults.includeLinearTerm
        includeQuadraticTerm = defaults.includeQuadraticTerm
        includeCubicTerm = defaults.includeCubicTerm
    }
    
    // Parameter metadata for UI controls
    struct ParameterMetadata {
        let defaultValue: Double
        let minValue: Double
        let maxValue: Double
        let step: Double
    }
    
    // Function to get parameter metadata (default, range, step) for a parameter
    func getParameterMetadata(forParameter paramName: String) -> ParameterMetadata {
        switch paramName {
        // FIR Model Parameters
        case "FIR Coverage Duration (s)":
            return ParameterMetadata(defaultValue: 90.0, minValue: 30.0, maxValue: 150.0, step: 10.0)
        case "FIR Time Window Start (s)":
            return ParameterMetadata(defaultValue: 30.0, minValue: 0.0, maxValue: 150.0, step: 1.0)
        case "FIR Time Window End (s)":
            return ParameterMetadata(defaultValue: 60.0, minValue: 0.0, maxValue: 150.0, step: 1.0)
        // Signal Parameters
        case "CO₂ Sampling Rate (Hz)":
            return ParameterMetadata(defaultValue: 10.0, minValue: 1.0, maxValue: 20.0, step: 1.0)
        case "Breathing Rate (breaths/min)":
            return ParameterMetadata(defaultValue: 15.0, minValue: 5.0, maxValue: 30.0, step: 1.0)
        case "MRI Sampling Interval (s)":
            return ParameterMetadata(defaultValue: 2.0, minValue: 0.5, maxValue: 5.0, step: 0.5)
        case "MRI Baseline Signal (a.u.)":
            return ParameterMetadata(defaultValue: 1200.0, minValue: 800.0, maxValue: 1600.0, step: 50.0)
        case "MRI Response Amplitude (a.u.)":
            return ParameterMetadata(defaultValue: 100.0, minValue: 0.0, maxValue: 200.0, step: 5.0)
        case "CO₂ Response Amplitude (mmHg)":
            return ParameterMetadata(defaultValue: 10.0, minValue: 0.0, maxValue: 20.0, step: 1.0)
            
        // Response Shape Parameters
        case "Rise Time Constant (s)":
            return ParameterMetadata(defaultValue: 10.0, minValue: 1.0, maxValue: 20.0, step: 1.0)
        case "Fall Time Constant (s)":
            return ParameterMetadata(defaultValue: 5.0, minValue: 1.0, maxValue: 10.0, step: 1.0)
            
        // Noise Parameters
        case "CO₂ Variance Frequency (Hz)":
            return ParameterMetadata(defaultValue: 0.05, minValue: 0.01, maxValue: 0.2, step: 0.01)
        case "CO₂ Frequency Variance":
            return ParameterMetadata(defaultValue: 1.5, minValue: 0.0, maxValue: 3.0, step: 0.1)
        case "CO₂ Amplitude Variance (mmHg)":
            return ParameterMetadata(defaultValue: 0.5, minValue: 0.0, maxValue: 2.0, step: 0.1)
        case "MRI Noise Amplitude (a.u.)":
            return ParameterMetadata(defaultValue: 5.0, minValue: 0.0, maxValue: 20.0, step: 1.0)
            
        // Drift Parameters - CO2
        case "CO₂ Linear Drift (mmHg)":
            return ParameterMetadata(defaultValue: 5.0, minValue: -10.0, maxValue: 10.0, step: 1.0)
        case "CO₂ Quadratic Drift (mmHg)":
            return ParameterMetadata(defaultValue: -5.5, minValue: -10.0, maxValue: 10.0, step: 1.0)
        case "CO₂ Cubic Drift (mmHg)":
            return ParameterMetadata(defaultValue: -10.0, minValue: -20.0, maxValue: 10.0, step: 1.0)
            
        // Drift Parameters - MRI
        case "MRI Linear Drift (%)":
            return ParameterMetadata(defaultValue: 3.0, minValue: -10.0, maxValue: 10.0, step: 1.0)
        case "MRI Quadratic Drift (%)":
            return ParameterMetadata(defaultValue: 3.0, minValue: -10.0, maxValue: 10.0, step: 1.0)
        case "MRI Cubic Drift (%)":
            return ParameterMetadata(defaultValue: 4.0, minValue: -10.0, maxValue: 10.0, step: 1.0)
            
        // Fallback with generic values
        default:
            return ParameterMetadata(defaultValue: 0.0, minValue: 0.0, maxValue: 10.0, step: 1.0)
        }
    }
    
    // Function to get just the default value for a specific parameter (for backward compatibility)
    func getDefaultValue(forParameter paramName: String) -> Double {
        return getParameterMetadata(forParameter: paramName).defaultValue
    }
    
    // Function to get the default boolean value for toggle parameters
    func getDefaultToggleValue(forFeature featureName: String) -> Bool {
        let defaults = SimulationParameters()
        
        switch featureName {
        case "CO₂ Variance":
            return defaults.enableCO2Variance
        case "MRI Noise":
            return defaults.enableMRINoise
        case "CO₂ Drift":
            return defaults.enableCO2Drift
        case "MRI Drift":
            return defaults.enableMRIDrift
        default:
            return true
        }
    }
    
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
            analysisFIRCoverage: analysisFIRCoverage,
            analysisFIRResponseMethodString: analysisFIRResponseMethodString,
            analysisFIRTimeWindowStart: analysisFIRTimeWindowStart,
            analysisFIRTimeWindowEnd: analysisFIRTimeWindowEnd,
            
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
    let analysisFIRCoverage: Double
    let analysisFIRResponseMethodString: String
    let analysisFIRTimeWindowStart: Double
    let analysisFIRTimeWindowEnd: Double
    
    // Computed properties for convenience
    var responseShapeType: ResponseShapeType {
        ResponseShapeType(rawValue: responseShapeTypeString) ?? .boxcar
    }
    
    var analysisModelType: ResponseShapeType {
        ResponseShapeType(rawValue: analysisModelTypeString) ?? .boxcar
    }
    
    var analysisFIRResponseMethod: FIRResponseMethod {
        FIRResponseMethod(rawValue: analysisFIRResponseMethodString) ?? .maximum
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
            analysisFallTimeConstant != previous.analysisFallTimeConstant ||
            analysisFIRCoverage != previous.analysisFIRCoverage ||
            analysisFIRResponseMethodString != previous.analysisFIRResponseMethodString ||
            analysisFIRTimeWindowStart != previous.analysisFIRTimeWindowStart ||
            analysisFIRTimeWindowEnd != previous.analysisFIRTimeWindowEnd;
            
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
