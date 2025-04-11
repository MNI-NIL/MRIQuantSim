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
    
    func updateSimulation(regenerateNoise: Bool = false) {
        // Safety check to prevent crashes - ensure object is fully initialized
        if !isInitialized {
            isInitialized = true
        }
        
        // Reset and regenerate all data
        simulationData.generateSimulatedData(parameters: parameters, regenerateNoise: regenerateNoise)
        
        // Update parameter state cache after a full simulation update
        previousParamState = parameters.getParameterState()
        
        // Explicitly notify observers of change
        objectWillChange.send()
    }
    
    // Update when any parameter changes
    func parameterChanged() {
        // If only the MRI noise amplitude has changed, just update the MRI signal
        // without regenerating the noise pattern
        let currentState = parameters.getParameterState()
        
        if let previousState = previousParamState {
            let onlyMRINoiseAmplitudeChanged = currentState.onlyNoiseAmplitudeChangedFrom(previous: previousState)
            
            print("Parameter change detected:")
            print("  - MRI noise amplitude: \(previousState.mriNoiseAmplitude) -> \(currentState.mriNoiseAmplitude)")
            print("  - Only amplitude changed: \(onlyMRINoiseAmplitudeChanged)")
            
            if onlyMRINoiseAmplitudeChanged {
                print("Updating with same noise pattern, new amplitude: \(parameters.mriNoiseAmplitude)")
                // Just update MRI signal with the same noise pattern but new amplitude
                simulationData.updateMRISignalWithSameNoisePattern(parameters: parameters)
                
                // Update previousState to current values
                previousParamState = currentState
                return
            }
        }
        
        // For any other parameter changes, do a full update
        updateSimulation(regenerateNoise: false)
        
        // Store current state for future comparison
        previousParamState = currentState
    }
    
    // Keep track of previous parameter state to detect amplitude-only changes
    private var previousParamState: ParameterState?
    
    // Method specifically for regenerating MRI noise
    func regenerateMRINoise() {
        simulationData.regenerateMRINoise(parameters: parameters)
        
        // Update parameter state after regeneration
        previousParamState = parameters.getParameterState()
        
        objectWillChange.send()
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
                    dataSeries: getCO2Series(),
                    yRange: 0...50
                )
                
                // MRI Graph
                SignalGraphView(
                    title: "MRI Signal",
                    xLabel: "Time (s)",
                    yLabel: "Signal (a.u.)",
                    dataSeries: getMRISeries(),
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
                    onParameterChanged: simulator.parameterChanged,
                    onRegenerateNoise: simulator.regenerateMRINoise
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
    
    private func getMRISeries() -> [TimeSeriesData] {
        // Get all MRI series with visibility determined by parameters
        return simulator.simulationData.getMRISeriesData(parameters: simulator.parameters)
    }
    
    private func getCO2Series() -> [TimeSeriesData] {
        // Get all CO2 series with visibility determined by parameters
        return simulator.simulationData.getCO2SeriesData(parameters: simulator.parameters)
    }
    
    private func getMRIYRange() -> ClosedRange<Double>? {
        // Always provide a default range as fallback
        let baseline = simulator.parameters.mriBaselineSignal
        let defaultRange = (baseline - 50)...(baseline + 50)
        
        // If not using dynamic range, return fixed range
        if !simulator.parameters.useDynamicMRIRange {
            return defaultRange
        }
        
        // Get all series that will be displayed
        let series = getMRISeries().filter { $0.isVisible }
        
        // Safety check - ensure we have data
        if series.isEmpty {
            return defaultRange
        }
        
        // Find min and max across all displayed signals
        var allValues: [Double] = []
        
        for dataSeries in series {
            allValues.append(contentsOf: dataSeries.yValues)
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
