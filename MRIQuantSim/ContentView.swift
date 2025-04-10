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
    
    init() {
        // Initial generation of data
        updateSimulation()
    }
    
    func updateSimulation() {
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
                    additionalTimeSeries: simulator.parameters.showCO2EndTidal ? [
                        (
                            times: simulator.simulationData.co2EndTidalTimes,
                            values: simulator.simulationData.co2EndTidalSignal,
                            color: .red,
                            showPoints: true
                        )
                    ] : nil,
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
            // Load parameters if available, otherwise use defaults
            if let savedParams = savedParameters.first {
                simulator.parameters = savedParams
                simulator.updateSimulation()
            }
            
            // Save parameters if none exist
            if savedParameters.isEmpty {
                modelContext.insert(simulator.parameters)
            }
        }
    }
    
    private func getAdditionalMRITimeSeries() -> [(times: [Double], values: [Double], color: Color, showPoints: Bool)]? {
        var series: [(times: [Double], values: [Double], color: Color, showPoints: Bool)] = []
        
        if simulator.parameters.showMRIDetrended {
            series.append((
                times: simulator.simulationData.mriTimePoints,
                values: simulator.simulationData.mriDetrendedSignal,
                color: .green,
                showPoints: false
            ))
        }
        
        if simulator.parameters.showModelOverlay {
            series.append((
                times: simulator.simulationData.mriTimePoints,
                values: simulator.simulationData.mriModeledSignal,
                color: .orange,
                showPoints: false
            ))
        }
        
        return series.isEmpty ? nil : series
    }
    
    private func getMRIYRange() -> ClosedRange<Double>? {
        if !simulator.parameters.useDynamicMRIRange {
            // Fixed range based on baseline
            let baseline = simulator.parameters.mriBaselineSignal
            return (baseline - 50)...(baseline + 50)
        }
        
        // Find min and max across all displayed signals
        var allValues: [Double] = []
        
        if simulator.parameters.showMRIRaw {
            allValues.append(contentsOf: simulator.simulationData.mriRawSignal)
        }
        
        if simulator.parameters.showMRIDetrended {
            allValues.append(contentsOf: simulator.simulationData.mriDetrendedSignal)
        }
        
        if simulator.parameters.showModelOverlay {
            allValues.append(contentsOf: simulator.simulationData.mriModeledSignal)
        }
        
        if allValues.isEmpty {
            return nil
        }
        
        let min = allValues.min() ?? 0
        let max = allValues.max() ?? 0
        let buffer = (max - min) * 0.1 // 10% buffer
        
        return (min - buffer)...(max + buffer)
    }
}
