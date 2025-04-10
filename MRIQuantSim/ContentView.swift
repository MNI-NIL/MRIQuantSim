//
//  ContentView.swift
//  MRIQuantSim
//
//  Created by Rick Hoge on 2025-04-10.
//

import SwiftUI
import SwiftData
import Charts

// Central simulator class to handle all updates
class SimulationController: ObservableObject {
    @Published var parameters = SimulationParameters()
    @Published var simulationData = SimulationData()
    
    // Property to track initialization state
    private var isInitialized = false
    
    init() {
        // Defer data generation until view appears
        // This avoids potential crashes during init
    }
    
    func updateSimulation() {
        // Safety check to prevent crashes - ensure object is fully initialized
        if !isInitialized {
            isInitialized = true
        }
        
        // Reset and regenerate all data
        simulationData.generateSimulatedData(parameters: parameters)
        
        // Explicitly notify observers of change
        objectWillChange.send()
    }
    
    // Update when any parameter changes
    func parameterChanged() {
        updateSimulation()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedParameters: [SimulationParameters]
    
    // Use StateObject to maintain the simulator between view refreshes
    @StateObject private var simulator = SimulationController()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Graphs container
            VStack(spacing: 8) {
                // CO2 Graph
                SignalGraphView(
                    title: "CO2 Partial Pressure",
                    xLabel: "Time (s)",
                    yLabel: "pCO2 (mmHg)",
                    timePoints: simulator.simulationData.co2TimePoints,
                    dataPoints: simulator.simulationData.co2RawSignal,
                    showRawData: simulator.parameters.showCO2Raw,
                    additionalTimeSeries: getAdditionalCO2TimeSeries(),
                    yRange: 0...50
                )
                
                // MRI Graph
                SignalGraphView(
                    title: "MRI Signal",
                    xLabel: "Time (s)",
                    yLabel: "Signal (a.u.)",
                    timePoints: simulator.simulationData.mriTimePoints,
                    dataPoints: simulator.simulationData.mriRawSignal,
                    showRawData: simulator.parameters.showMRIRaw,
                    additionalTimeSeries: getAdditionalMRITimeSeries(),
                    yRange: getMRIYRange()
                )
            }
            .padding(.horizontal)
            .frame(maxHeight: 450)
            
            Divider()
                .padding(.vertical, 4)
            
            // Tabs for Parameters and Analysis
            TabView(selection: $selectedTab) {
                ParametersTabView(
                    parameters: $simulator.parameters,
                    onParameterChanged: simulator.parameterChanged
                )
                .tabItem {
                    Label("Signal Parameters", systemImage: "waveform")
                }
                .tag(0)
                
                AnalysisTabView(
                    parameters: $simulator.parameters,
                    simulationData: simulator.simulationData,
                    onParameterChanged: simulator.parameterChanged
                )
                .tabItem {
                    Label("Analysis", systemImage: "chart.bar")
                }
                .tag(1)
            }
            .frame(minHeight: 300)
        }
        .padding()
        .onAppear {
            // Delay just slightly to ensure view is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Load parameters if available, otherwise use defaults
                if let savedParams = savedParameters.first {
                    simulator.parameters = savedParams
                }
                
                // Save parameters if none exist
                if savedParameters.isEmpty {
                    modelContext.insert(simulator.parameters)
                }
                
                // Generate simulation data after view has appeared
                simulator.updateSimulation()
            }
        }
    }
    
    private func getAdditionalMRITimeSeries() -> [(times: [Double], values: [Double], color: Color, showPoints: Bool)]? {
        var series: [(times: [Double], values: [Double], color: Color, showPoints: Bool)] = []
        
        // Safety check to ensure we have data
        let hasValidMRIData = !simulator.simulationData.mriTimePoints.isEmpty
        
        if hasValidMRIData {
            if simulator.parameters.showMRIDetrended && !simulator.simulationData.mriDetrendedSignal.isEmpty {
                // Ensure data arrays are the same length
                let dataCount = min(simulator.simulationData.mriTimePoints.count, 
                                  simulator.simulationData.mriDetrendedSignal.count)
                
                if dataCount > 0 {
                    // Create a slightly offset set of time points to ensure separate series
                    let timePoints = Array(simulator.simulationData.mriTimePoints.prefix(dataCount))
                    
                    series.append((
                        times: timePoints,
                        values: Array(simulator.simulationData.mriDetrendedSignal.prefix(dataCount)),
                        color: .green,
                        showPoints: false
                    ))
                }
            }
            
            if simulator.parameters.showModelOverlay && !simulator.simulationData.mriModeledSignal.isEmpty {
                // Ensure data arrays are the same length
                let dataCount = min(simulator.simulationData.mriTimePoints.count, 
                                  simulator.simulationData.mriModeledSignal.count)
                
                if dataCount > 0 {
                    // Create a slightly offset set of time points to ensure separate series 
                    let timePoints = Array(simulator.simulationData.mriTimePoints.prefix(dataCount))
                    
                    series.append((
                        times: timePoints,
                        values: Array(simulator.simulationData.mriModeledSignal.prefix(dataCount)),
                        color: .orange,
                        showPoints: false
                    ))
                }
            }
        }
        
        return series.isEmpty ? nil : series
    }
    
    private func getAdditionalCO2TimeSeries() -> [(times: [Double], values: [Double], color: Color, showPoints: Bool)]? {
        // Safety check to ensure we have data
        if simulator.parameters.showCO2EndTidal && 
           !simulator.simulationData.co2EndTidalTimes.isEmpty && 
           !simulator.simulationData.co2EndTidalSignal.isEmpty {
            
            // Ensure data arrays are the same length
            let dataCount = min(simulator.simulationData.co2EndTidalTimes.count, 
                               simulator.simulationData.co2EndTidalSignal.count)
            
            if dataCount > 0 {
                return [(
                    times: Array(simulator.simulationData.co2EndTidalTimes.prefix(dataCount)),
                    values: Array(simulator.simulationData.co2EndTidalSignal.prefix(dataCount)),
                    color: .red,
                    showPoints: true
                )]
            }
        }
        
        return nil
    }
    
    private func getMRIYRange() -> ClosedRange<Double>? {
        // Always provide a default range as fallback
        let baseline = simulator.parameters.mriBaselineSignal
        let defaultRange = (baseline - 50)...(baseline + 50)
        
        // If not using dynamic range, return fixed range
        if !simulator.parameters.useDynamicMRIRange {
            return defaultRange
        }
        
        // Safety check - ensure we have data
        if simulator.simulationData.mriRawSignal.isEmpty {
            return defaultRange
        }
        
        // Find min and max across all displayed signals
        var allValues: [Double] = []
        
        if simulator.parameters.showMRIRaw {
            allValues.append(contentsOf: simulator.simulationData.mriRawSignal)
        }
        
        if simulator.parameters.showMRIDetrended && !simulator.simulationData.mriDetrendedSignal.isEmpty {
            allValues.append(contentsOf: simulator.simulationData.mriDetrendedSignal)
        }
        
        if simulator.parameters.showModelOverlay && !simulator.simulationData.mriModeledSignal.isEmpty {
            allValues.append(contentsOf: simulator.simulationData.mriModeledSignal)
        }
        
        if allValues.isEmpty {
            return defaultRange
        }
        
        let min = allValues.min() ?? (baseline - 50)
        let max = allValues.max() ?? (baseline + 50)
        
        // Ensure range is not zero or too small
        if max - min < 1.0 {
            return defaultRange
        }
        
        let buffer = (max - min) * 0.1 // 10% buffer
        return (min - buffer)...(max + buffer)
    }
}
