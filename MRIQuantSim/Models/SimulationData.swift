//
//  SimulationData.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import Foundation
import SwiftUI

// Structure for time window marker visualization
struct TimeWindowMarker {
    let blockStartTime: Double  // When the block starts
    let startOffset: Double     // Window start offset from block start
    let endOffset: Double       // Window end offset from block start
    let color: Color            // Color of the marker
    let opacity: Double         // Opacity of the marker
    
    init(blockStartTime: Double, startOffset: Double, endOffset: Double, 
         color: Color = .blue, opacity: Double = 0.2) {
        self.blockStartTime = blockStartTime
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.color = color
        self.opacity = opacity
    }
}

// Model structure for time series data
struct TimeSeriesData: Identifiable {
    let id = UUID()
    let title: String
    let xValues: [Double]
    let yValues: [Double]
    let color: Color
    let showPoints: Bool
    let isVisible: Bool
    let lineWidth: Double
    let symbolSize: Double
    var showConnectingLine: Bool
    let connectingLineColor: Color?
    var timeWindowMarkers: [TimeWindowMarker]?
    
    init(
        title: String,
        xValues: [Double],
        yValues: [Double],
        color: Color,
        showPoints: Bool = false,
        isVisible: Bool = true,
        lineWidth: Double = 2.0,
        symbolSize: Double = 30.0,
        showConnectingLine: Bool = true,
        connectingLineColor: Color? = nil,
        timeWindowMarkers: [TimeWindowMarker]? = nil
    ) {
        self.title = title
        self.xValues = xValues
        self.yValues = yValues
        self.color = color
        self.showPoints = showPoints
        self.isVisible = isVisible
        self.lineWidth = lineWidth
        self.symbolSize = symbolSize
        self.showConnectingLine = showConnectingLine
        self.connectingLineColor = connectingLineColor
        self.timeWindowMarkers = timeWindowMarkers
    }
}

class SimulationData: ObservableObject {
    @Published var co2RawSignal: [Double] = []
    @Published var co2EndTidalSignal: [Double] = []
    @Published var co2EndTidalTimes: [Double] = []
    @Published var mriRawSignal: [Double] = []
    @Published var mriDetrendedSignal: [Double] = []
    @Published var mriModeledSignal: [Double] = []
    @Published var mriResidualError: [Double] = []
    @Published var co2TimePoints: [Double] = []
    @Published var mriTimePoints: [Double] = []
    @Published var co2BlockPattern: [Double] = []
    @Published var mriBlockPattern: [Double] = []
    @Published var betaParams: [Double] = []
    @Published var percentChangeMetric: Double = 0.0
    @Published var signalToNoiseRatio: Double = 0.0
    @Published var contrastToNoiseRatio: Double = 0.0
    @Published var firResponseMagnitude: Double = 0.0 // Store calculated FIR response magnitude
    @Published var firTimeToMaxResponse: Double = 0.0 // Store time to max response for FIR
    
    // Enum for FIR response magnitude calculation methods
    enum FIRResponseMethod {
        case maximum        // Use the maximum beta value
        case mean           // Use the mean of all beta values
        case meanPositive   // Mean of all positive beta values
        case timeWindow(start: Double, end: Double) // Average beta values within a time window
    }
    
    // Store normalized noise values (mean 0, std 1) separately so they can be reused
    private var mriNormalizedNoiseValues: [Double] = []
    
    // Store random phase offset for CO2 variance
    private var co2VariancePhaseOffset: Double = 0.0
    
    // Storage for FIR response method - this will be set from the parameters
    private var firResponseMethod: FIRResponseMethod = .maximum
    
    // Calculate FIR response magnitude with specified method
    func calculateFIRResponseMagnitude(
        parameters: SimulationParameters,
        method: FIRResponseMethod? = nil,
        firRegressorCount: Int? = nil
    ) -> Double {
        // Use provided method or default
        let method = method ?? firResponseMethod
        
        // Calculate FIR regressor count if not provided
        let firCount = firRegressorCount ?? {
            let samplesPerSecond = 1.0 / parameters.mriSamplingInterval
            return Int(parameters.analysisFIRCoverage * samplesPerSecond)
        }()
        
        // Make sure we have valid beta parameters and FIR count
        guard !betaParams.isEmpty && firCount > 0 else {
            return 0.0
        }
        
        // Calculate response magnitude based on selected method
        switch method {
        case .maximum:
            // Find the maximum beta value
            var maxBeta = 0.0
            var maxIndex = 0
            
            for i in 0..<firCount {
                if i < betaParams.count {
                    let betaValue = abs(betaParams[i])
                    if betaValue > maxBeta {
                        maxBeta = betaValue
                        maxIndex = i
                    }
                }
            }
            
            // Store the time to max response (useful metadata for this method)
            firTimeToMaxResponse = Double(maxIndex) * parameters.mriSamplingInterval
            
            return maxBeta
            
        case .mean:
            // Calculate mean of all FIR beta values
            var sum = 0.0
            var count = 0
            
            for i in 0..<firCount {
                if i < betaParams.count {
                    sum += abs(betaParams[i])
                    count += 1
                }
            }
            
            return count > 0 ? sum / Double(count) : 0.0
            
        case .meanPositive:
            // Mean of positive FIR beta values
            var sum = 0.0
            var positiveCount = 0
            
            for i in 0..<firCount {
                if i < betaParams.count && betaParams[i] > 0 {
                    sum += betaParams[i]
                    positiveCount += 1
                }
            }
            
            // Normalize by number of positive regressors
            return positiveCount > 0 ? sum / Double(positiveCount) : 0.0
            
        case .timeWindow(let startTime, let endTime):
            // Calculate mean beta within a time window
            var sum = 0.0
            var count = 0
            
            // Convert time to indices
            let startIndex = Int(startTime / parameters.mriSamplingInterval)
            let endIndex = Int(endTime / parameters.mriSamplingInterval)
            
            // Make sure indices are within range
            let validStart = max(0, min(startIndex, firCount - 1))
            let validEnd = max(validStart, min(endIndex, firCount - 1))
            
            // Calculate mean within window
            for i in validStart...validEnd {
                if i < betaParams.count {
                    sum += abs(betaParams[i])
                    count += 1
                }
            }
            
            return count > 0 ? sum / Double(count) : 0.0
        }
    }
    
    // Set the FIR response method to use (from a string method name)
    func setFIRResponseMethod(methodName: String, timeWindowStart: Double = 10.0, timeWindowEnd: Double = 30.0) {
        // Map from string to our internal enum
        if methodName == "Maximum Value" {
            firResponseMethod = .maximum
        } else if methodName == "Mean Value" {
            firResponseMethod = .mean
        } else if methodName == "Mean of Positive Values" {
            firResponseMethod = .meanPositive
        } else if methodName == "Time Window" {
            // For Time Window method, use provided start and end times
            firResponseMethod = .timeWindow(start: timeWindowStart, end: timeWindowEnd)
        } else {
            // Default to maximum if method not recognized
            firResponseMethod = .maximum
        }
        
        // Recalculate FIR response magnitude if we have beta parameters
        if !betaParams.isEmpty {
            firResponseMagnitude = calculateFIRResponseMagnitude(parameters: SimulationParameters())
        }
    }
    
    // Helper methods to create TimeSeriesData objects
    func getCO2SeriesData(parameters: SimulationParameters) -> [TimeSeriesData] {
        var seriesData: [TimeSeriesData] = []
        
        // Raw CO2 signal
        if !co2TimePoints.isEmpty && !co2RawSignal.isEmpty {
            let count = min(co2TimePoints.count, co2RawSignal.count)
            seriesData.append(TimeSeriesData(
                title: "Raw CO₂",
                xValues: Array(co2TimePoints.prefix(count)),
                yValues: Array(co2RawSignal.prefix(count)),
                color: .blue,
                isVisible: parameters.showCO2Raw,
            ))
        }
        
        // End-tidal CO2 data
        if !co2EndTidalTimes.isEmpty && !co2EndTidalSignal.isEmpty {
            let count = min(co2EndTidalTimes.count, co2EndTidalSignal.count)
            let xValues = Array(co2EndTidalTimes.prefix(count))
            let yValues = Array(co2EndTidalSignal.prefix(count))
            
            // Single time series with both points and connecting line
            seriesData.append(TimeSeriesData(
                title: "End-tidal CO₂",
                xValues: xValues,
                yValues: yValues,
                color: .red,
                showPoints: true,
                isVisible: parameters.showCO2EndTidal,
                symbolSize: 30,
                showConnectingLine: true,
                connectingLineColor: Color(red: 0.6, green: 0.0, blue: 0.0)
            ))
        }
        
        return seriesData
    }
    
    func getMRISeriesData(parameters: SimulationParameters) -> [TimeSeriesData] {
        var seriesData: [TimeSeriesData] = []
        
        // Create time window markers if using FIR time window method
        var timeWindowMarkers: [TimeWindowMarker]? = nil
        if parameters.analysisModelType == .fir && parameters.analysisFIRResponseMethod == .timeWindow {
            timeWindowMarkers = []
            
            // Find block onset times (for odd-numbered blocks which are the stimulus blocks)
            let blockDuration = 60.0 // 1 minute blocks
            let totalDuration = 300.0 // 5 minutes total
            
            // Calculate block start times
            for blockNumber in 0...4 { // 5 blocks in 5 minutes (0-based indexing)
                let blockStartTime = Double(blockNumber) * blockDuration
                
                // Only add markers for stimulus blocks (odd-numbered blocks)
                if blockNumber % 2 == 1 && blockStartTime < totalDuration {
                    timeWindowMarkers?.append(
                        TimeWindowMarker(
                            blockStartTime: blockStartTime,
                            startOffset: parameters.analysisFIRTimeWindowStart,
                            endOffset: parameters.analysisFIRTimeWindowEnd,
                            color: .blue,
                            opacity: 0.15
                        )
                    )
                }
            }
        }
        
        // Raw MRI signal
        if !mriTimePoints.isEmpty && !mriRawSignal.isEmpty {
            let count = min(mriTimePoints.count, mriRawSignal.count)
            seriesData.append(TimeSeriesData(
                title: "Raw MRI Signal",
                xValues: Array(mriTimePoints.prefix(count)),
                yValues: Array(mriRawSignal.prefix(count)),
                color: .blue,
                isVisible: parameters.showMRIRaw,
                timeWindowMarkers: timeWindowMarkers
            ))
        }
        
        // Model-fitted MRI signal
        if !mriTimePoints.isEmpty && !mriModeledSignal.isEmpty {
            let count = min(mriTimePoints.count, mriModeledSignal.count)
            seriesData.append(TimeSeriesData(
                title: "Model Fit",
                xValues: Array(mriTimePoints.prefix(count)),
                yValues: Array(mriModeledSignal.prefix(count)),
                color: .orange,
                isVisible: parameters.showModelOverlay,
                timeWindowMarkers: timeWindowMarkers
            ))
        }
        
        // Detrended MRI signal
        if !mriTimePoints.isEmpty && !mriDetrendedSignal.isEmpty {
            let count = min(mriTimePoints.count, mriDetrendedSignal.count)
            seriesData.append(TimeSeriesData(
                title: "Detrended MRI Signal",
                xValues: Array(mriTimePoints.prefix(count)),
                yValues: Array(mriDetrendedSignal.prefix(count)),
                color: .green,
                isVisible: parameters.showMRIDetrended,
                timeWindowMarkers: timeWindowMarkers
            ))
        }
        
        // Residual error points (raw data minus model fit)
        if !mriTimePoints.isEmpty && !mriResidualError.isEmpty {
            let count = min(mriTimePoints.count, mriResidualError.count)
            seriesData.append(TimeSeriesData(
                title: "Residual Error",
                xValues: Array(mriTimePoints.prefix(count)),
                yValues: Array(mriResidualError.prefix(count)),
                color: .purple,
                showPoints: true,
                isVisible: parameters.showResidualError,
                symbolSize: 20,
                timeWindowMarkers: timeWindowMarkers
            ))
        }
        
        return seriesData
    }
    
    // Constants for the simulation
    let totalDuration: Double = 300.0 // 5 minutes in seconds
    let blockDuration: Double = 60.0 // 1 minute in seconds
    let normalAirMinCO2: Double = 0.0 // mmHg
    let normalAirMaxCO2: Double = 40.0 // mmHg
    let enrichedAirMinCO2: Double = 38.0 // mmHg (5% of 760mmHg)
    
    func generateSimulatedData(parameters: SimulationParameters, regenerateNoise: Bool = false, regenerateVariancePhase: Bool = false) {
        // Reset all arrays to ensure clean state
        co2RawSignal = []
        co2EndTidalSignal = []
        co2EndTidalTimes = []
        mriRawSignal = []
        mriDetrendedSignal = []
        mriModeledSignal = []
        mriResidualError = []
        co2TimePoints = []
        mriTimePoints = []
        co2BlockPattern = []
        mriBlockPattern = []
        betaParams = []
        
        // Randomize CO2 variance phase offset if requested
        if regenerateVariancePhase {
            co2VariancePhaseOffset = Double.random(in: 0..<(2.0 * Double.pi))
            print("Generated new CO2 variance phase offset: \(co2VariancePhaseOffset)")
        }
        
        // Generate new data
        generateCO2Signal(parameters: parameters)
        generateMRISignal(parameters: parameters, regenerateNoise: regenerateNoise)
        extractEndTidalCO2(parameters: parameters)
        generateBlockPatterns(parameters: parameters)
        
        // Always perform detrending analysis regardless of display settings
        // This ensures the model results are always up-to-date
        performDetrendingAnalysis(parameters: parameters)
        
        // Force UI refresh by triggering objectWillChange
        self.objectWillChange.send()
    }
    
    /// Update the MRI signal using current parameters but keeping the same noise pattern
    /// This is used when parameters like noise amplitude change but we want to keep the pattern
    func updateMRISignalWithSameNoisePattern(parameters: SimulationParameters) {
        print("Updating MRI signal with same noise pattern, amplitude: \(parameters.mriNoiseAmplitude)")
        
        // Only update if we have valid normalized noise values
        if !mriNormalizedNoiseValues.isEmpty && !mriTimePoints.isEmpty {
            print("Using existing \(mriNormalizedNoiseValues.count) normalized noise values")
            
            // Generate new signal using existing noise pattern but with updated amplitude
            let actualSamples = mriTimePoints.count
            mriRawSignal = Array(repeating: 0.0, count: actualSamples)
            
            // Generate signal using existing normalized noise but current amplitude
            for i in 0..<actualSamples {
                let time = mriTimePoints[i]
                
                // Base MRI signal - default to baseline
                var signalValue = parameters.mriBaselineSignal
                
                // Determine current block and calculate time within this block
                let blockNumber = Int(time / blockDuration)
                let isEnrichedBlock = blockNumber % 2 == 1 && time < totalDuration
                let timeInBlock = time - (Double(blockNumber) * blockDuration)
                
                // Calculate response factor (0.0-1.0) based on selected response shape
                var responseFactor = 0.0
                
                if isEnrichedBlock {
                    // We're in an enriched block
                    switch parameters.responseShapeType {
                    case .boxcar:
                        // Simple step response
                        responseFactor = 1.0
                        
                    case .exponential:
                        // Exponential approach to plateau during rising phase
                        let riseTimeConstant = parameters.responseRiseTimeConstant
                        if riseTimeConstant > 0 {
                            responseFactor = 1.0 - exp(-timeInBlock / riseTimeConstant)
                        } else {
                            // Fallback to boxcar if time constant is invalid
                            responseFactor = 1.0
                        }
                        
                    case .fir:
                        // For FIR, just use a boxcar (simple step) response for the simulation
                        responseFactor = 1.0
                    }
                } else if blockNumber > 0 && time < totalDuration {
                    // If we're in a baseline block after an enriched block, apply exponential decay
                    if parameters.responseShapeType == .exponential {
                        let fallTimeConstant = parameters.responseFallTimeConstant
                        if fallTimeConstant > 0 {
                            // Calculate time since end of last enriched block
                            responseFactor = exp(-timeInBlock / fallTimeConstant)
                        }
                    }
                }
                
                // Add scaled response to the base signal
                signalValue += parameters.mriResponseAmplitude * responseFactor
                
                // Add scaled noise if enabled - multiply normalized noise by current amplitude
                if parameters.enableMRINoise && i < mriNormalizedNoiseValues.count {
                    signalValue += mriNormalizedNoiseValues[i] * parameters.mriNoiseAmplitude
                }
                
                // Add drift terms if enabled
                if parameters.enableMRIDrift {
                    let normalizedTime = time / totalDuration
                    signalValue += parameters.mriLinearDrift * normalizedTime * parameters.mriBaselineSignal / 100.0
                    signalValue += parameters.mriQuadraticDrift * pow(normalizedTime, 2) * parameters.mriBaselineSignal / 100.0
                    signalValue += parameters.mriCubicDrift * pow(normalizedTime, 3) * parameters.mriBaselineSignal / 100.0
                }
                
                mriRawSignal[i] = signalValue
            }
            
            // Initialize detrended and modeled signals
            mriDetrendedSignal = mriRawSignal
            mriModeledSignal = mriRawSignal
            mriResidualError = Array(repeating: 0.0, count: mriRawSignal.count)
            
            // Always generate block patterns
            generateBlockPatterns(parameters: parameters)
            
            // Always perform detrending analysis regardless of display settings
            // This ensures the model results are always up-to-date
            performDetrendingAnalysis(parameters: parameters)
            
            // Force UI refresh
            objectWillChange.send()
        }
    }
    
    private func generateCO2Signal(parameters: SimulationParameters) {
        let samplingRate = parameters.co2SamplingRate
        let breathingRateHz = parameters.breathingRate / 60.0 // Convert to Hz
        
        // Generate time points up to exactly the total duration
        co2TimePoints = stride(from: 0, to: totalDuration, by: 1.0/samplingRate).map { $0 }
        
        // Ensure we include the exact end point if needed
        if co2TimePoints.last != totalDuration {
            co2TimePoints.append(totalDuration)
        }
        
        let actualSamples = co2TimePoints.count
        co2RawSignal = Array(repeating: 0.0, count: actualSamples)
        
        // Compute base and response CO2 levels
        let baseCO2Min = normalAirMinCO2
        let baseCO2Max = normalAirMaxCO2
        let responseCO2Min = enrichedAirMinCO2
        let responseCO2Max = normalAirMaxCO2 + parameters.co2ResponseAmplitude
        
        for i in 0..<actualSamples {
            let time = co2TimePoints[i]
            
            // Base respiratory oscillation
            var respiratoryPhase = 2.0 * Double.pi * breathingRateHz * time
            
            // Determine current block and response factor based on response shape type
            let blockNumber = Int(time / blockDuration)
            let isEnrichedBlock = blockNumber % 2 == 1 && time < totalDuration
            let timeInBlock = time - (Double(blockNumber) * blockDuration)
            
            // Calculate response factor (0.0-1.0) based on selected response shape
            var responseFactor = 0.0
            
            if isEnrichedBlock {
                switch parameters.responseShapeType {
                case .boxcar:
                    // Simple step response
                    responseFactor = 1.0
                    
                case .exponential:
                    // Exponential approach to plateau during rising phase
                    let riseTimeConstant = parameters.responseRiseTimeConstant
                    if riseTimeConstant > 0 {
                        responseFactor = 1.0 - exp(-timeInBlock / riseTimeConstant)
                    } else {
                        // Fallback to boxcar if time constant is invalid
                        responseFactor = 1.0
                    }
                    
                case .fir:
                    // For FIR, just use a boxcar (simple step) response for the simulation
                    responseFactor = 1.0
                }
            } else if blockNumber > 0 && time < totalDuration {
                // If we're in a baseline block after an enriched block, apply exponential decay if needed
                if parameters.responseShapeType == .exponential {
                    let fallTimeConstant = parameters.responseFallTimeConstant
                    if fallTimeConstant > 0 {
                        // Calculate time since end of last enriched block
                        responseFactor = exp(-timeInBlock / fallTimeConstant)
                    }
                }
                // For FIR model in baseline blocks, we don't need special handling
                // as the FIR regressors handle the shape in the analysis stage
            }
            
            // For the minCO2, use a simple boxcar function (binary transition)
            // The minCO2 applies a simple step transition between blocks
            let minCO2 = isEnrichedBlock ? responseCO2Min : baseCO2Min
                
            // For the maxCO2 (end-tidal), apply the exponential curve
            let maxCO2 = baseCO2Max + responseFactor * (responseCO2Max - baseCO2Max)
            
            // Add noise to respiratory frequency if enabled
            var amplitudeModulation = 1.0 // Default amplitude multiplier (no modulation)
            
            if parameters.enableCO2Variance {
                // Apply the random phase offset to the variance signal
                let varianceSignal = sin(2.0 * Double.pi * parameters.co2VarianceFrequency * time + co2VariancePhaseOffset)
                
                // Apply frequency modulation
                let frequencyVariance = varianceSignal * parameters.co2VarianceAmplitude
                respiratoryPhase += frequencyVariance
                
                // Apply amplitude modulation - scale by a factor that varies around 1.0
                // This creates a variance of +/- co2AmplitudeVariance mmHg in the final CO2 values
                let meanCO2Range = (maxCO2 - minCO2)
                let relativeVariance = parameters.co2AmplitudeVariance / meanCO2Range
                amplitudeModulation = 1.0 + (varianceSignal * relativeVariance)
            }
            
            // Apply amplitude modulation to the respiratory wave
            let respiratoryWave = sin(respiratoryPhase)
            
            // First map to [0,1] range, then apply amplitude modulation to the range
            let normalizedWave = (respiratoryWave + 1.0) / 2.0
            let mappedValue = minCO2 + normalizedWave * (maxCO2 - minCO2) * amplitudeModulation
            
            // Add drift terms if enabled
            var driftTerm = 0.0
            if parameters.enableCO2Drift {
                let normalizedTime = time / totalDuration
                driftTerm += parameters.co2LinearDrift * normalizedTime
                driftTerm += parameters.co2QuadraticDrift * pow(normalizedTime, 2)
                driftTerm += parameters.co2CubicDrift * pow(normalizedTime, 3)
            }
            
            co2RawSignal[i] = mappedValue + driftTerm
        }
    }
    
    private func generateMRISignal(parameters: SimulationParameters, regenerateNoise: Bool = false) {
        let samplingInterval = parameters.mriSamplingInterval
        //let totalSamples = Int(totalDuration / samplingInterval)
        
        // Generate time points exactly up to but not exceeding the total duration
        mriTimePoints = stride(from: 0, to: totalDuration, by: samplingInterval).map { $0 }
        
        // Ensure the last time point is exactly at the total duration if needed
        if mriTimePoints.last != totalDuration {
            mriTimePoints.append(totalDuration)
        }
        
        let actualSamples = mriTimePoints.count
        mriRawSignal = Array(repeating: 0.0, count: actualSamples)
        
        // Generate or regenerate normalized noise values if needed
        // Only regenerate if explicitly requested or if array is empty/wrong size
        if mriNormalizedNoiseValues.isEmpty || regenerateNoise || mriNormalizedNoiseValues.count != actualSamples {
            print("Generating NEW normalized noise values")
            print("  - regenerateNoise: \(regenerateNoise)")
            print("  - isEmpty: \(mriNormalizedNoiseValues.isEmpty)")
            print("  - countMismatch: \(mriNormalizedNoiseValues.count) vs \(actualSamples)")
            
            // Generate normalized Gaussian noise values (mean 0, std 1)
            mriNormalizedNoiseValues = Array(repeating: 0.0, count: actualSamples)
            
            // Use Box-Muller transform to generate normally distributed random values
            for i in 0..<actualSamples {
                let u1 = Double.random(in: 0..<1)
                let u2 = Double.random(in: 0..<1)
                let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * Double.pi * u2)
                
                // Store normalized noise (mean 0, std 1)
                mriNormalizedNoiseValues[i] = z0
            }
            
            // Print the first normalized noise value for debugging
            if actualSamples > 0 {
                print("First normalized noise value: \(mriNormalizedNoiseValues[0])")
            }
        }
        
        // Generate signal with consistent noise pattern but current amplitude
        for i in 0..<actualSamples {
            let time = mriTimePoints[i]
            
            // Base MRI signal - default to baseline
            var signalValue = parameters.mriBaselineSignal
            
            // Determine current block and calculate time within this block
            let blockNumber = Int(time / blockDuration)
            let isEnrichedBlock = blockNumber % 2 == 1 && time < totalDuration
            let timeInBlock = time - (Double(blockNumber) * blockDuration)
            
            // Calculate response factor (0.0-1.0) based on selected response shape
            var responseFactor = 0.0
            
            if isEnrichedBlock {
                // We're in an enriched block
                switch parameters.responseShapeType {
                case .boxcar:
                    // Simple step response
                    responseFactor = 1.0
                    
                case .exponential:
                    // Exponential approach to plateau during rising phase
                    let riseTimeConstant = parameters.responseRiseTimeConstant
                    if riseTimeConstant > 0 {
                        responseFactor = 1.0 - exp(-timeInBlock / riseTimeConstant)
                    } else {
                        // Fallback to boxcar if time constant is invalid
                        responseFactor = 1.0
                    }
                    
                case .fir:
                    // For FIR, just use a boxcar (simple step) response for the simulation
                    responseFactor = 1.0
                }
            } else if blockNumber > 0 && time < totalDuration {
                // If we're in a baseline block after an enriched block, apply exponential decay
                if parameters.responseShapeType == .exponential {
                    let fallTimeConstant = parameters.responseFallTimeConstant
                    if fallTimeConstant > 0 {
                        // Calculate time since end of last enriched block
                        responseFactor = exp(-timeInBlock / fallTimeConstant)
                    }
                }
                // For FIR model in baseline blocks, we don't need special handling
                // as the FIR regressors handle the shape in the analysis stage
            }
            
            // Add scaled response to the base signal
            signalValue += parameters.mriResponseAmplitude * responseFactor
            
            // Add scaled noise if enabled - multiply normalized noise by current amplitude
            if parameters.enableMRINoise {
                signalValue += mriNormalizedNoiseValues[i] * parameters.mriNoiseAmplitude
            }
            
            // Add drift terms if enabled
            if parameters.enableMRIDrift {
                let normalizedTime = time / totalDuration
                signalValue += parameters.mriLinearDrift * normalizedTime * parameters.mriBaselineSignal / 100.0
                signalValue += parameters.mriQuadraticDrift * pow(normalizedTime, 2) * parameters.mriBaselineSignal / 100.0
                signalValue += parameters.mriCubicDrift * pow(normalizedTime, 3) * parameters.mriBaselineSignal / 100.0
            }
            
            mriRawSignal[i] = signalValue
        }
        
        // Initialize detrended signal as a copy of raw signal
        mriDetrendedSignal = mriRawSignal
        mriModeledSignal = mriRawSignal
        mriResidualError = Array(repeating: 0.0, count: mriRawSignal.count)
    }
    
    /// Public method to perform model analysis without regenerating signals
    func performModelAnalysis(parameters: SimulationParameters) {
        print("Performing model analysis with current parameters")
        
        // Run the detrending analysis with current parameters
        performDetrendingAnalysis(parameters: parameters)
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    /// Public method to update only the CO2 signal when CO2 variance parameters change
    func updateCO2SignalOnly(parameters: SimulationParameters) {
        print("Regenerating CO2 signal with updated variance parameters")
        
        // Only regenerate the CO2 signal
        generateCO2Signal(parameters: parameters)
        
        // Extract end-tidal CO2 based on the new signal
        extractEndTidalCO2(parameters: parameters)
        
        // Update the CO2 block pattern
        generateBlockPatterns(parameters: parameters)
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    /// Public method to randomize the CO2 variance phase
    func randomizeCO2VariancePhase(parameters: SimulationParameters) {
        print("Randomizing CO2 variance phase")
        
        // Generate a new random phase offset
        co2VariancePhaseOffset = Double.random(in: 0..<(2.0 * Double.pi))
        print("New CO2 variance phase offset: \(co2VariancePhaseOffset)")
        
        // Reset CO2 variance phase by regenerating CO2 signal with the new phase offset
        generateCO2Signal(parameters: parameters)
        
        // Extract end-tidal CO2 based on the new signal
        extractEndTidalCO2(parameters: parameters)
        
        // Update the CO2 block pattern
        generateBlockPatterns(parameters: parameters)
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    /// Public method to regenerate MRI noise values
    func regenerateMRINoise(parameters: SimulationParameters) {
        print("Explicitly regenerating MRI noise pattern")
        
        // First, explicitly clear the normalized noise values to force regeneration
        print("  - Clearing \(mriNormalizedNoiseValues.count) existing normalized noise values")
        mriNormalizedNoiseValues = []
        
        // Regenerate the signal with completely new noise pattern
        print("  - Generating new noise pattern with regenerateNoise=true")
        generateMRISignal(parameters: parameters, regenerateNoise: true)
        
        // Re-run downstream analysis that depends on the signal
        extractEndTidalCO2(parameters: parameters)
        generateBlockPatterns(parameters: parameters)
        
        // Always perform detrending analysis regardless of display settings
        // This ensures the model results are always up-to-date
        performDetrendingAnalysis(parameters: parameters)
        
        // Print some debug info - will appear in console
        print("MRI Noise regenerated successfully, \(mriNormalizedNoiseValues.count) normalized values generated")
        
        // Force UI refresh
        objectWillChange.send()
    }
    
    private func extractEndTidalCO2(parameters: SimulationParameters) {
        co2EndTidalSignal = []
        co2EndTidalTimes = []
        
        // Skip first and last points to avoid edge effects
        // Simple approach: a point is a local maximum if it's higher than both adjacent points
        for i in 1..<co2RawSignal.count - 1 {
            if co2RawSignal[i] > co2RawSignal[i-1] && co2RawSignal[i] > co2RawSignal[i+1] {
                // To refine further, check if this is truly the peak of a breath cycle
                // Estimate points per breath cycle
                let pointsPerBreath = parameters.co2SamplingRate * 60.0 / parameters.breathingRate
                
                // Find the local maximum within a narrower window (1/4 of a breath cycle)
                let halfWindow = max(2, Int(pointsPerBreath / 4))
                let startIdx = max(0, i - halfWindow)
                let endIdx = min(co2RawSignal.count - 1, i + halfWindow)
                
                // Only keep this point if it's the maximum in this smaller window
                if co2RawSignal[i] == co2RawSignal[startIdx...endIdx].max() {
                    co2EndTidalSignal.append(co2RawSignal[i])
                    co2EndTidalTimes.append(co2TimePoints[i])
                }
            }
        }
    }
    
    func generateBlockPatterns(parameters: SimulationParameters) {
        // Generate CO2 block pattern at CO2 sampling rate - only include valid time points
        // For CO2, we always use simple boxcar function since this is for visualization only
        co2BlockPattern = co2TimePoints.map { time -> Double in
            // Only consider blocks within the simulation time range
            if time < totalDuration {
                let blockNumber = Int(time / blockDuration)
                return blockNumber % 2 == 1 ? 1.0 : 0.0
            } else {
                return 0.0 // Anything outside simulation time is baseline
            }
        }
        
        // Generate MRI block pattern at MRI sampling rate with the specified analysis model
        mriBlockPattern = Array(repeating: 0.0, count: mriTimePoints.count)
        
        // For FIR model, we'll only use the block pattern for visualization
        // The actual FIR regressors are generated in performDetrendingAnalysis
        if parameters.analysisModelType != .fir {
            // Generate the block pattern based on analysis model type
            for i in 0..<mriTimePoints.count {
                let time = mriTimePoints[i]
                
                // Skip if outside simulation time
                if time >= totalDuration {
                    continue
                }
                
                // Determine current block and time within this block
                let blockNumber = Int(time / blockDuration)
                let isEnrichedBlock = blockNumber % 2 == 1
                let timeInBlock = time - (Double(blockNumber) * blockDuration)
                
                // Calculate response factor (0.0-1.0) based on selected analysis model
                var responseFactor = 0.0
                
                if isEnrichedBlock {
                    // We're in an enriched block
                    switch parameters.analysisModelType {
                    case .boxcar:
                        // Simple step response (boxcar)
                        responseFactor = 1.0
                        
                    case .exponential:
                        // Exponential approach to plateau during rising phase
                        let riseTimeConstant = parameters.analysisRiseTimeConstant
                        if riseTimeConstant > 0 {
                            responseFactor = 1.0 - exp(-timeInBlock / riseTimeConstant)
                        } else {
                            // Fallback to boxcar if time constant is invalid
                            responseFactor = 1.0
                        }
                    case .fir:
                        // This should not be reached since we check for FIR above
                        responseFactor = 1.0
                    }
                } else if blockNumber > 0 {
                    // If we're in a baseline block after an enriched block, apply exponential decay
                    if parameters.analysisModelType == .exponential {
                        let fallTimeConstant = parameters.analysisFallTimeConstant
                        if fallTimeConstant > 0 {
                            // Calculate time since end of last enriched block
                            responseFactor = exp(-timeInBlock / fallTimeConstant)
                        }
                    }
                }
                
                // Store the response factor as the block pattern value
                mriBlockPattern[i] = responseFactor
            }
        } else {
            // For FIR model, we'll just use a boxcar for visualization purposes
            for i in 0..<mriTimePoints.count {
                let time = mriTimePoints[i]
                
                // Skip if outside simulation time
                if time >= totalDuration {
                    continue
                }
                
                // Create simple boxcar pattern for visualization
                let blockNumber = Int(time / blockDuration)
                let isEnrichedBlock = blockNumber % 2 == 1
                mriBlockPattern[i] = isEnrichedBlock ? 1.0 : 0.0
            }
        }
    }
    
    private func performDetrendingAnalysis(parameters: SimulationParameters) {
        // Construct design matrix for MRI signal
        var designMatrix: [[Double]] = []
        var firRegressorCount = 0
        
        // Check if any model term is included
        let hasAnyModelTerm = parameters.includeConstantTerm || 
                             parameters.includeLinearTerm || 
                             parameters.includeQuadraticTerm || 
                             parameters.includeCubicTerm
        
        // If no model terms are included, set model signals to zeros and return
        if !hasAnyModelTerm {
            print("Warning: No model terms selected. Model will be all zeros.")
            mriModeledSignal = Array(repeating: 0.0, count: mriTimePoints.count)
            mriDetrendedSignal = mriRawSignal  // Just use raw signal with no detrending
            betaParams = []
            percentChangeMetric = 0.0
            signalToNoiseRatio = 0.0
            contrastToNoiseRatio = 0.0
            return
        }
        
        // Handle the response regressors based on model type
        if parameters.analysisModelType == .fir {
            // For FIR model, create multiple stimulus regressors, one for each time offset
            
            // First, create a basic boxcar pattern (block design)
            var blockPattern = Array(repeating: 0.0, count: mriTimePoints.count)
            for i in 0..<mriTimePoints.count {
                if i < mriTimePoints.count {
                    let time = mriTimePoints[i]
                    // Skip if outside simulation time
                    if time < totalDuration {
                        let blockNumber = Int(time / blockDuration)
                        blockPattern[i] = blockNumber % 2 == 1 ? 1.0 : 0.0
                    }
                }
            }
            
            // Calculate the number of FIR regressors based on the coverage and sampling interval
            let samplesPerSecond = 1.0 / parameters.mriSamplingInterval
            let samplesInCoverage = Int(parameters.analysisFIRCoverage * samplesPerSecond)
            firRegressorCount = samplesInCoverage
            
            // Calculate regressors based on coverage and sampling rate
            
            // Generate FIR regressors
            // First, create a basic boxcar pattern (block design) to use as reference
            var blockOnsets: [Int] = []
            
            // Find all block onset time points
            for i in 0..<mriTimePoints.count {
                let time = mriTimePoints[i]
                if time >= totalDuration {
                    continue
                }
                
                // Check if this is the first time point in a stimulus block
                let blockNumber = Int(time / blockDuration)
                let blockStartTime = Double(blockNumber) * blockDuration
                let isBlockStart = abs(time - blockStartTime) < parameters.mriSamplingInterval / 2
                
                // Only check for odd block numbers (stimulus blocks)
                if isBlockStart && blockNumber % 2 == 1 {
                    blockOnsets.append(i)
                }
            }
            
            // Store block onsets for FIR regressor generation
            
            // Generate FIR regressors
            for offset in 0..<firRegressorCount {
                var firRegressor = Array(repeating: 0.0, count: mriTimePoints.count)
                
                // For each block onset, mark the corresponding offset point as 1.0
                for onsetIndex in blockOnsets {
                    let targetIndex = onsetIndex + offset
                    
                    // Make sure we don't go beyond the array bounds
                    if targetIndex < mriTimePoints.count {
                        firRegressor[targetIndex] = 1.0
                    }
                }
                
                // Add this regressor to the design matrix
                designMatrix.append(firRegressor)
                
                // Count non-zero elements in each regressor (useful for validation)
                let _ = firRegressor.filter { $0 > 0 }.count
            }
        } else {
            // For non-FIR models (Boxcar or Exponential), just add a single response regressor
            designMatrix.append(mriBlockPattern)
        }
        
        // Add constant term
        if parameters.includeConstantTerm {
            designMatrix.append(Array(repeating: 1.0, count: mriTimePoints.count))
        }
        
        // Add linear term
        if parameters.includeLinearTerm {
            let normalizedTimes = mriTimePoints.map { $0 / totalDuration }
            designMatrix.append(normalizedTimes)
        }
        
        // Add quadratic term
        if parameters.includeQuadraticTerm {
            let normalizedTimes = mriTimePoints.map { pow($0 / totalDuration, 2) }
            designMatrix.append(normalizedTimes)
        }
        
        // Add cubic term
        if parameters.includeCubicTerm {
            let normalizedTimes = mriTimePoints.map { pow($0 / totalDuration, 3) }
            designMatrix.append(normalizedTimes)
        }
        
        // Ensure we have at least one regressor (should never happen with the check above, but as extra safety)
        if designMatrix.isEmpty {
            print("Error: Empty design matrix. Setting model to zeros.")
            mriModeledSignal = Array(repeating: 0.0, count: mriTimePoints.count)
            mriDetrendedSignal = mriRawSignal
            betaParams = []
            percentChangeMetric = 0.0
            signalToNoiseRatio = 0.0
            contrastToNoiseRatio = 0.0
            return
        }
        
        // Transpose design matrix to the form expected by the GLM solver
        let X = transposeMatrix(designMatrix)
        
        // Solve the GLM: Y = Xβ + ε
        betaParams = solveGLM(designMatrix: X, observedValues: mriRawSignal)
        
        // Calculate percent change metric based on model type
        if parameters.analysisModelType == .fir && firRegressorCount > 0 {
            // Convert parameters FIR response method to our internal type
            let methodString = parameters.analysisFIRResponseMethodString
            
            // Map from parameters enum to local enum
            if methodString == "Maximum Value" {
                firResponseMethod = .maximum
            } else if methodString == "Mean Value" {
                firResponseMethod = .mean
            } else if methodString == "Mean of Positive Values" {
                firResponseMethod = .meanPositive
            } else if methodString == "Time Window" {
                // For Time Window method, use start and end times from parameters
                firResponseMethod = .timeWindow(start: parameters.analysisFIRTimeWindowStart, 
                                              end: parameters.analysisFIRTimeWindowEnd)
            } else {
                // Default to maximum if method not recognized
                firResponseMethod = .maximum
            }
            
            // Calculate FIR response magnitude using the current method
            firResponseMagnitude = calculateFIRResponseMagnitude(
                parameters: parameters,
                method: firResponseMethod,
                firRegressorCount: firRegressorCount
            )
            
            // Store FIR response information
            // These details are used for reporting in the UI
            
            // Find constant term index (follows all the FIR regressors)
            let constTermIndex = firRegressorCount
            
            // Calculate percent change if constant term is included
            if parameters.includeConstantTerm && constTermIndex < betaParams.count {
                let baseline = abs(betaParams[constTermIndex])
                if baseline > 0 {
                    percentChangeMetric = (firResponseMagnitude / baseline) * 100.0
                } else {
                    percentChangeMetric = 0.0
                }
            } else {
                percentChangeMetric = 0.0
            }
        } else {
            // For Boxcar and Exponential models, use the standard approach
            if betaParams.count >= 2 && parameters.includeConstantTerm {
                let responseAmplitude = abs(betaParams[0])
                let baseline = abs(betaParams[1])
                percentChangeMetric = (responseAmplitude / baseline) * 100.0
            } else {
                percentChangeMetric = 0.0
            }
        }
        
        // Generate modeled signal
        mriModeledSignal = Array(repeating: 0.0, count: mriTimePoints.count)
        
        if !betaParams.isEmpty {
            // For all model types, generate the true model fit first
            // This gives the complete modeled signal with all components
            for i in 0..<mriTimePoints.count {
                var modelValue = 0.0
                for j in 0..<betaParams.count {
                    modelValue += betaParams[j] * X[i][j]
                }
                mriModeledSignal[i] = modelValue
            }
            
            // For FIR model, we'll report additional information about response magnitudes
            if parameters.analysisModelType == .fir && firRegressorCount > 0 {
                // Find the maximum FIR beta value like we did for percent change
                var maxFirBeta = 0.0
                var maxFirIndex = 0
                var sumFirBetas = 0.0
                
                // Find the peak FIR beta and its index
                for i in 0..<firRegressorCount {
                    if i < betaParams.count {
                        let betaValue = abs(betaParams[i])
                        sumFirBetas += betaValue
                        if betaValue > maxFirBeta {
                            maxFirBeta = betaValue
                            maxFirIndex = i
                        }
                    }
                }
                
                // Compute what time offset this represents
                let peakTimeOffset = Double(maxFirIndex) * parameters.mriSamplingInterval
                
                print("FIR visualization metrics:")
                print("  - Max beta: \(maxFirBeta) at index \(maxFirIndex) (time = \(peakTimeOffset)s)")
                print("  - Sum of all FIR betas: \(sumFirBetas)")
                print("  - Average of FIR betas: \(sumFirBetas/Double(firRegressorCount))")
            }
        }
        
        // Calculate residual error (raw data minus model fit)
        mriResidualError = Array(repeating: 0.0, count: mriTimePoints.count)
        for i in 0..<mriTimePoints.count {
            mriResidualError[i] = mriRawSignal[i] - mriModeledSignal[i]
        }
        
        // Generate detrended signal by removing drift components
        mriDetrendedSignal = Array(repeating: 0.0, count: mriTimePoints.count)
        
        if parameters.analysisModelType == .fir && firRegressorCount > 0 {
            // For FIR model, drift terms start after all FIR regressors plus constant term
            // First determine starting index for drift terms
            let driftStartIndex = firRegressorCount + (parameters.includeConstantTerm ? 1 : 0)
            
            // Check if we have any drift terms
            if betaParams.count > driftStartIndex {
                for i in 0..<mriTimePoints.count {
                    var trendComponents = 0.0
                    // Start from drift terms (after FIR regressors and constant)
                    for j in driftStartIndex..<betaParams.count {
                        trendComponents += betaParams[j] * X[i][j]
                    }
                    mriDetrendedSignal[i] = mriRawSignal[i] - trendComponents
                }
                
                // Subtract drift components from raw signal to get detrended signal
            } else {
                // If no drift components, detrended signal equals raw signal
                mriDetrendedSignal = mriRawSignal
            }
        } else {
            // For non-FIR models (Boxcar or Exponential)
            if betaParams.count > 2 {
                for i in 0..<mriTimePoints.count {
                    var trendComponents = 0.0
                    // Start from j=2 to skip stimulus and constant terms
                    for j in 2..<betaParams.count {
                        trendComponents += betaParams[j] * X[i][j]
                    }
                    mriDetrendedSignal[i] = mriRawSignal[i] - trendComponents
                }
            } else {
                // If no drift components, detrended signal equals raw signal
                mriDetrendedSignal = mriRawSignal
            }
        }
        
        // Calculate SNR and CNR metrics
        // Using RMS of residual error as noise
        let noiseRMS = calculateRMS(mriResidualError)
        
        // Signal is the constant term (baseline signal)
        var signal = 0.0
        // Contrast is the response amplitude (different calculation based on model type)
        var contrast = 0.0
        
        if parameters.analysisModelType == .fir && firRegressorCount > 0 {
            // For FIR model, calculate differently
            
            // Signal is still the constant term, but its index depends on firRegressorCount
            let constTermIndex = firRegressorCount
            if parameters.includeConstantTerm && constTermIndex < betaParams.count {
                signal = abs(betaParams[constTermIndex])
            }
            
            // Contrast is the FIR response magnitude (already calculated)
            contrast = firResponseMagnitude
            
            // Store signal and contrast values for SNR and CNR calculations
        } else {
            // For Boxcar and Exponential models
            
            // Signal is the constant term
            if parameters.includeConstantTerm && betaParams.count >= 2 {
                signal = abs(betaParams[1]) // Second beta is constant term
            }
            
            // Contrast is the first beta
            if !betaParams.isEmpty {
                contrast = abs(betaParams[0]) // First beta is response amplitude
            }
        }
        
        // Calculate Signal-to-Noise Ratio (SNR)
        if noiseRMS > 0 && signal > 0 {
            signalToNoiseRatio = signal / noiseRMS
        } else {
            signalToNoiseRatio = 0.0
        }
        
        // Calculate Contrast-to-Noise Ratio (CNR)
        if noiseRMS > 0 && contrast > 0 {
            contrastToNoiseRatio = contrast / noiseRMS
        } else {
            contrastToNoiseRatio = 0.0
        }
        
        // Metrics calculation complete
    }
    
    // Calculate Root Mean Square (RMS) of a data array
    private func calculateRMS(_ data: [Double]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        let sumOfSquares = data.reduce(0.0) { sum, value in
            return sum + (value * value)
        }
        
        return sqrt(sumOfSquares / Double(data.count))
    }
    
    private func transposeMatrix(_ matrix: [[Double]]) -> [[Double]] {
        let rowCount = matrix.count
        guard rowCount > 0 else { return [] }
        let columnCount = matrix[0].count
        
        var result = Array(repeating: Array(repeating: 0.0, count: rowCount), count: columnCount)
        
        for i in 0..<rowCount {
            for j in 0..<columnCount {
                result[j][i] = matrix[i][j]
            }
        }
        
        return result
    }
    
    private func solveGLM(designMatrix: [[Double]], observedValues: [Double]) -> [Double] {
        // Very basic GLM solver using the normal equations: β = (X^T X)^(-1) X^T Y
        // This is a simplified approach and not robust for ill-conditioned matrices
        
        // Calculate X^T
        let Xt = transposeMatrix(designMatrix)
        
        // Calculate X^T X
        let XtX = matrixMultiply(Xt, designMatrix)
        
        // Calculate (X^T X)^(-1)
        guard let XtXInv = invertMatrix(XtX) else {
            // Return empty array if matrix is not invertible
            return []
        }
        
        // Calculate X^T Y
        let XtY = matrixVectorMultiply(Xt, observedValues)
        
        // Calculate β = (X^T X)^(-1) X^T Y
        let beta = matrixVectorMultiply(XtXInv, XtY)
        
        return beta
    }
    
    private func matrixMultiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        let rowsA = A.count
        let colsA = A[0].count
        let colsB = B[0].count
        
        var C = Array(repeating: Array(repeating: 0.0, count: colsB), count: rowsA)
        
        for i in 0..<rowsA {
            for j in 0..<colsB {
                for k in 0..<colsA {
                    C[i][j] += A[i][k] * B[k][j]
                }
            }
        }
        
        return C
    }
    
    private func matrixVectorMultiply(_ A: [[Double]], _ b: [Double]) -> [Double] {
        let rowsA = A.count
        let colsA = A[0].count
        
        var c = Array(repeating: 0.0, count: rowsA)
        
        for i in 0..<rowsA {
            for j in 0..<colsA {
                c[i] += A[i][j] * b[j]
            }
        }
        
        return c
    }
    
    private func invertMatrix(_ A: [[Double]]) -> [[Double]]? {
        let n = A.count
        var result = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        var tmp = A
        
        // Initialize result as identity matrix
        for i in 0..<n {
            result[i][i] = 1.0
        }
        
        // Gaussian elimination
        for i in 0..<n {
            // Find pivot
            var pivotRow = i
            for j in i+1..<n {
                if abs(tmp[j][i]) > abs(tmp[pivotRow][i]) {
                    pivotRow = j
                }
            }
            
            // Check if matrix is singular
            if abs(tmp[pivotRow][i]) < 1e-10 {
                return nil
            }
            
            // Swap rows
            if pivotRow != i {
                tmp.swapAt(i, pivotRow)
                result.swapAt(i, pivotRow)
            }
            
            // Scale row i
            let pivot = tmp[i][i]
            for j in 0..<n {
                tmp[i][j] /= pivot
                result[i][j] /= pivot
            }
            
            // Eliminate other rows
            for j in 0..<n {
                if j != i {
                    let factor = tmp[j][i]
                    for k in 0..<n {
                        tmp[j][k] -= factor * tmp[i][k]
                        result[j][k] -= factor * result[i][k]
                    }
                }
            }
        }
        
        return result
    }
}
