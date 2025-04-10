//
//  ContentView.swift
//  MRIQuantSim
//
//  Created by Rick Hoge on 2025-04-10.
//

import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedParameters: [SimulationParameters]
    
    @State private var parameters = SimulationParameters()
    @State private var simulationData = SimulationData()
    @State private var needsUpdate = true
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            // CO2 Graph
            SignalGraphView(
                title: "CO2 Partial Pressure",
                xLabel: "Time (s)",
                yLabel: "pCO2 (mmHg)",
                timePoints: simulationData.co2TimePoints,
                dataPoints: simulationData.co2RawSignal,
                showRawData: parameters.showCO2Raw,
                additionalTimeSeries: parameters.showCO2EndTidal ? [
                    (
                        times: simulationData.co2EndTidalTimes,
                        values: simulationData.co2EndTidalSignal,
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
                timePoints: simulationData.mriTimePoints,
                dataPoints: simulationData.mriRawSignal,
                showRawData: parameters.showMRIRaw,
                additionalTimeSeries: getAdditionalMRITimeSeries(),
                yRange: getMRIYRange()
            )
            
            // Tabs for Parameters and Analysis
            TabView(selection: $selectedTab) {
                ParametersTabView(parameters: $parameters, needsUpdate: $needsUpdate)
                    .tabItem {
                        Label("Signal Parameters", systemImage: "waveform")
                    }
                    .tag(0)
                
                AnalysisTabView(parameters: $parameters, simulationData: $simulationData, needsUpdate: $needsUpdate)
                    .tabItem {
                        Label("Analysis", systemImage: "chart.bar")
                    }
                    .tag(1)
            }
        }
        .padding()
        .onChange(of: needsUpdate) { _ in
            if needsUpdate {
                updateSimulation()
                needsUpdate = false
            }
        }
        .onAppear {
            // Load parameters if available, otherwise use defaults
            if let savedParams = savedParameters.first {
                parameters = savedParams
            }
            
            updateSimulation()
        }
    }
    
    private func updateSimulation() {
        simulationData.generateSimulatedData(parameters: parameters)
        
        // Save parameters
        if savedParameters.isEmpty {
            modelContext.insert(parameters)
        }
    }
    
    private func getAdditionalMRITimeSeries() -> [(times: [Double], values: [Double], color: Color, showPoints: Bool)]? {
        var series: [(times: [Double], values: [Double], color: Color, showPoints: Bool)] = []
        
        if parameters.showMRIDetrended {
            series.append((
                times: simulationData.mriTimePoints,
                values: simulationData.mriDetrendedSignal,
                color: .green,
                showPoints: false
            ))
        }
        
        if parameters.showModelOverlay {
            series.append((
                times: simulationData.mriTimePoints,
                values: simulationData.mriModeledSignal,
                color: .orange,
                showPoints: false
            ))
        }
        
        return series.isEmpty ? nil : series
    }
    
    private func getMRIYRange() -> ClosedRange<Double>? {
        if !parameters.useDynamicMRIRange {
            // Fixed range based on baseline
            let baseline = parameters.mriBaselineSignal
            return (baseline - 50)...(baseline + 50)
        }
        
        // Find min and max across all displayed signals
        var allValues: [Double] = []
        
        if parameters.showMRIRaw {
            allValues.append(contentsOf: simulationData.mriRawSignal)
        }
        
        if parameters.showMRIDetrended {
            allValues.append(contentsOf: simulationData.mriDetrendedSignal)
        }
        
        if parameters.showModelOverlay {
            allValues.append(contentsOf: simulationData.mriModeledSignal)
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

#Preview {
    ContentView()
        .modelContainer(for: SimulationParameters.self, inMemory: true)
}
