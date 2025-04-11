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
    @Published var viewRefreshTrigger = 0 // Increment this to force view refreshes
    
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
        // Get current parameter state
        let currentState = parameters.getParameterState()
        
        if let previousState = previousParamState {
            // Check specifically for changes in model terms (detrending components)
            let modelTermsChanged = currentState.modelTermsChangedFrom(previous: previousState)
            
            // Check if only the MRI noise amplitude changed
            let onlyMRINoiseAmplitudeChanged = currentState.onlyNoiseAmplitudeChangedFrom(previous: previousState)
            
            // Check if only CO2 variance parameters changed
            let onlyCO2VarianceChanged = currentState.onlyCO2VarianceParamsChangedFrom(previous: previousState)
            
            print("Parameter change detected:")
            print("  - MRI noise amplitude: \(previousState.mriNoiseAmplitude) -> \(currentState.mriNoiseAmplitude)")
            print("  - CO2 variance: \(previousState.enableCO2Variance) -> \(currentState.enableCO2Variance)")
            print("  - CO2 variance frequency: \(previousState.co2VarianceFrequency) -> \(currentState.co2VarianceFrequency)")
            print("  - CO2 variance amplitude: \(previousState.co2VarianceAmplitude) -> \(currentState.co2VarianceAmplitude)")
            print("  - Model terms changed: \(modelTermsChanged)")
            print("  - Only MRI amplitude changed: \(onlyMRINoiseAmplitudeChanged)")
            print("  - Only CO2 variance changed: \(onlyCO2VarianceChanged)")
            
            if modelTermsChanged {
                print("Model terms changed, updating analysis without regenerating signals")
                // Force re-analysis with the current model terms
                simulationData.performModelAnalysis(parameters: parameters)
                
                // Update previous parameter state
                previousParamState = currentState
                
                // Notify observers of the change
                objectWillChange.send()
                return
            }
            else if onlyMRINoiseAmplitudeChanged {
                print("Updating with same MRI noise pattern, new amplitude: \(parameters.mriNoiseAmplitude)")
                // Just update MRI signal with the same noise pattern but new amplitude
                simulationData.updateMRISignalWithSameNoisePattern(parameters: parameters)
                
                // Update previousState to current values
                previousParamState = currentState
                return
            }
            else if onlyCO2VarianceChanged {
                print("CO2 variance changed, regenerating CO2 signal only")
                // Only regenerate the CO2 signal
                simulationData.updateCO2SignalOnly(parameters: parameters)
                
                // Force a view refresh by incrementing the trigger
                viewRefreshTrigger += 1
                print("Incremented view refresh trigger to \(viewRefreshTrigger)")
                
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
    
    // No longer needed since we're using the trigger approach
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedParameters: [SimulationParameters]
    
    // Use StateObject to maintain the simulator between view refreshes
    @StateObject private var simulator = SimulationController()
    @State private var selectedTab = 0
    
    var body: some View {
        // Use VSplitView for a draggable divider between the graph and parameters sections
        VSplitView {
            // UPPER SECTION: Graphs container
            VStack(spacing: 8) {
                // CO2 Graph
                SignalGraphView(
                    title: "CO2 Partial Pressure",
                    xLabel: "Time (s)",
                    yLabel: "pCO2 (mmHg)",
                    dataSeries: getCO2Series(),
                    yRange: 0...50
                )
                .padding(.top, 12)
                .id("co2Graph-\(simulator.viewRefreshTrigger)") // Force redraw when trigger changes
                
                // MRI Graph
                SignalGraphView(
                    title: "MRI Signal",
                    xLabel: "Time (s)",
                    yLabel: "Signal (a.u.)",
                    dataSeries: getMRISeries(),
                    yRange: getMRIYRange()
                )
                .id("mriGraph-\(simulator.viewRefreshTrigger)") // Force redraw when trigger changes
            }
            .padding(.horizontal)
            .frame(minHeight: 300, idealHeight: 450, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
            
            // LOWER SECTION: Parameters, Display and Analysis Tabs
            TabView(selection: $selectedTab) {
                ParametersTabView(
                    parameters: $simulator.parameters,
                    onParameterChanged: simulator.parameterChanged,
                    onRegenerateNoise: simulator.regenerateMRINoise
                )
                .tabItem {
                    Label("Signal", systemImage: "waveform")
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
                
                DisplayTabView(
                    parameters: $simulator.parameters,
                    onParameterChanged: simulator.parameterChanged
                )
                .tabItem {
                    Label("Display", systemImage: "display")
                }
                .tag(2)
            }
            .frame(minHeight: 250, idealHeight: 300, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
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
        let defaultRange = (0.0 - 5.0)...(baseline + 50.0)
        
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
        
        // Get actual min and max of the data
        let actualMin = allValues.min() ?? 0.0
        let actualMax = allValues.max() ?? (baseline + 50.0)
        
        // Ensure range is not too small
        if actualMax - actualMin < 1.0 {
            return defaultRange
        }
        
        // Calculate buffer - 10% of the range or at least 5.0
        let bufferAmount = max((actualMax - actualMin) * 0.1, 5.0)
        
        // For dynamic range: use actual min and max with buffer
        if simulator.parameters.useMRIDynamicRange {
            return (actualMin - bufferAmount)...(actualMax + bufferAmount)
        } 
        // For fixed range: use zero as minimum and actual max
        else {
            // Use zero as the minimum (with small buffer below zero)
            let minBuffer = bufferAmount * 0.2 // smaller buffer below zero
            return (0.0 - minBuffer)...(actualMax + bufferAmount)
        }
    }
}
