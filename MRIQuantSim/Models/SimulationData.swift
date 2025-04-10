//
//  SimulationData.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import Foundation
import SwiftUI

class SimulationData: ObservableObject {
    @Published var co2RawSignal: [Double] = []
    @Published var co2EndTidalSignal: [Double] = []
    @Published var co2EndTidalTimes: [Double] = []
    @Published var mriRawSignal: [Double] = []
    @Published var mriDetrendedSignal: [Double] = []
    @Published var mriModeledSignal: [Double] = []
    @Published var co2TimePoints: [Double] = []
    @Published var mriTimePoints: [Double] = []
    @Published var co2BlockPattern: [Double] = []
    @Published var mriBlockPattern: [Double] = []
    @Published var betaParams: [Double] = []
    @Published var percentChangeMetric: Double = 0.0
    
    // Constants for the simulation
    let totalDuration: Double = 300.0 // 5 minutes in seconds
    let blockDuration: Double = 60.0 // 1 minute in seconds
    let normalAirMinCO2: Double = 0.0 // mmHg
    let normalAirMaxCO2: Double = 40.0 // mmHg
    let enrichedAirMinCO2: Double = 38.0 // mmHg (5% of 760mmHg)
    let enrichedAirMaxCO2: Double = 45.0 // mmHg
    
    func generateSimulatedData(parameters: SimulationParameters) {
        // Reset all arrays to ensure clean state
        co2RawSignal = []
        co2EndTidalSignal = []
        co2EndTidalTimes = []
        mriRawSignal = []
        mriDetrendedSignal = []
        mriModeledSignal = []
        co2TimePoints = []
        mriTimePoints = []
        co2BlockPattern = []
        mriBlockPattern = []
        betaParams = []
        
        // Generate new data
        generateCO2Signal(parameters: parameters)
        generateMRISignal(parameters: parameters)
        extractEndTidalCO2(parameters: parameters)
        generateBlockPatterns(parameters: parameters)
        
        if parameters.showModelOverlay {
            performDetrendingAnalysis(parameters: parameters)
        }
        
        // Force UI refresh by triggering objectWillChange
        self.objectWillChange.send()
    }
    
    private func generateCO2Signal(parameters: SimulationParameters) {
        let samplingRate = parameters.co2SamplingRate
        let totalSamples = Int(totalDuration * samplingRate)
        let breathingRateHz = parameters.breathingRate / 60.0 // Convert to Hz
        
        co2TimePoints = stride(from: 0, to: totalDuration, by: 1.0/samplingRate).map { $0 }
        co2RawSignal = Array(repeating: 0.0, count: totalSamples)
        
        for i in 0..<totalSamples {
            let time = co2TimePoints[i]
            
            // Determine if we're in a CO2 block
            let blockNumber = Int(time / blockDuration)
            let isEnrichedBlock = blockNumber % 2 == 1
            
            // Base respiratory oscillation
            var respiratoryPhase = 2.0 * Double.pi * breathingRateHz * time
            
            // Add noise to respiratory frequency if enabled
            if parameters.enableCO2Noise {
                let frequencyNoise = sin(2.0 * Double.pi * parameters.co2NoiseFrequency * time) * parameters.co2NoiseAmplitude
                respiratoryPhase += frequencyNoise
            }
            
            let respiratoryWave = sin(respiratoryPhase)
            
            // Map the sine wave [-1,1] to the appropriate CO2 range based on block type
            let minCO2 = isEnrichedBlock ? enrichedAirMinCO2 : normalAirMinCO2
            let maxCO2 = isEnrichedBlock ? enrichedAirMaxCO2 : normalAirMaxCO2
            let mappedValue = minCO2 + (respiratoryWave + 1.0) / 2.0 * (maxCO2 - minCO2)
            
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
    
    private func generateMRISignal(parameters: SimulationParameters) {
        let samplingInterval = parameters.mriSamplingInterval
        let totalSamples = Int(totalDuration / samplingInterval) + 1
        
        mriTimePoints = stride(from: 0, to: totalDuration, by: samplingInterval).map { $0 }
        if mriTimePoints.count < totalSamples {
            mriTimePoints.append(totalDuration) // Ensure we have the right number of time points
        }
        
        mriRawSignal = Array(repeating: 0.0, count: totalSamples)
        
        for i in 0..<totalSamples {
            let time = mriTimePoints[i]
            
            // Determine if we're in a CO2 block
            let blockNumber = Int(time / blockDuration)
            let isEnrichedBlock = blockNumber % 2 == 1
            
            // Base MRI signal
            var signalValue = parameters.mriBaselineSignal
            if isEnrichedBlock {
                signalValue += parameters.mriResponseAmplitude
            }
            
            // Add noise if enabled
            if parameters.enableMRINoise {
                // Gaussian noise
                let noiseStdDev = parameters.mriNoiseAmplitude
                let u1 = Double.random(in: 0..<1)
                let u2 = Double.random(in: 0..<1)
                let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * Double.pi * u2)
                signalValue += z0 * noiseStdDev
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
    }
    
    private func extractEndTidalCO2(parameters: SimulationParameters) {
        co2EndTidalSignal = []
        co2EndTidalTimes = []
        
        // Look for local maxima in the CO2 signal to identify end-tidal points
        let windowSize = max(1, Int(60.0 / parameters.breathingRate * parameters.co2SamplingRate))
        
        for i in windowSize..<co2RawSignal.count - windowSize {
            let startIdx = max(0, i-windowSize)
            let endIdx = min(co2RawSignal.count - 1, i+windowSize)
            let localWindow = co2RawSignal[startIdx...endIdx]
            if co2RawSignal[i] == localWindow.max() {
                co2EndTidalSignal.append(co2RawSignal[i])
                co2EndTidalTimes.append(co2TimePoints[i])
            }
        }
    }
    
    private func generateBlockPatterns(parameters: SimulationParameters) {
        // Generate CO2 block pattern at CO2 sampling rate
        co2BlockPattern = co2TimePoints.map { time -> Double in
            let blockNumber = Int(time / blockDuration)
            return blockNumber % 2 == 1 ? 1.0 : 0.0
        }
        
        // Generate MRI block pattern at MRI sampling rate
        mriBlockPattern = mriTimePoints.map { time -> Double in
            let blockNumber = Int(time / blockDuration)
            return blockNumber % 2 == 1 ? 1.0 : 0.0
        }
    }
    
    private func performDetrendingAnalysis(parameters: SimulationParameters) {
        // Construct design matrix for MRI signal
        var designMatrix: [[Double]] = []
        
        // Add block pattern (stimulus regressor)
        designMatrix.append(mriBlockPattern)
        
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
        
        // Transpose design matrix to the form expected by the GLM solver
        let X = transposeMatrix(designMatrix)
        
        // Solve the GLM: Y = Xβ + ε
        betaParams = solveGLM(designMatrix: X, observedValues: mriRawSignal)
        
        // Calculate percent change metric if we have the stimulus and constant terms
        if betaParams.count >= 2 && parameters.includeConstantTerm {
            let responseAmplitude = abs(betaParams[0])
            let baseline = abs(betaParams[1])
            percentChangeMetric = (responseAmplitude / baseline) * 100.0
        }
        
        // Generate modeled signal
        mriModeledSignal = Array(repeating: 0.0, count: mriTimePoints.count)
        for i in 0..<mriTimePoints.count {
            var modelValue = 0.0
            for j in 0..<betaParams.count {
                modelValue += betaParams[j] * X[i][j]
            }
            mriModeledSignal[i] = modelValue
        }
        
        // Generate detrended signal by removing drift components
        mriDetrendedSignal = Array(repeating: 0.0, count: mriTimePoints.count)
        for i in 0..<mriTimePoints.count {
            var trendComponents = 0.0
            // Start from j=2 to skip stimulus and constant terms
            for j in 2..<betaParams.count {
                trendComponents += betaParams[j] * X[i][j]
            }
            mriDetrendedSignal[i] = mriRawSignal[i] - trendComponents
        }
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
