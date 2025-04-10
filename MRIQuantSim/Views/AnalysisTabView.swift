//
//  AnalysisTabView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI

struct AnalysisTabView: View {
    @Binding var parameters: SimulationParameters
    @Binding var simulationData: SimulationData
    @Binding var needsUpdate: Bool
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Display Options")) {
                    HStack {
                        Text("CO2 Signal")
                        Spacer()
                        Toggle("Raw", isOn: $parameters.showCO2Raw)
                            .toggleStyle(.button)
                            .onChange(of: parameters.showCO2Raw) { _ in needsUpdate = true }
                        
                        Toggle("End-Tidal", isOn: $parameters.showCO2EndTidal)
                            .toggleStyle(.button)
                            .onChange(of: parameters.showCO2EndTidal) { _ in needsUpdate = true }
                    }
                    
                    HStack {
                        Text("MRI Signal")
                        Spacer()
                        Toggle("Raw", isOn: $parameters.showMRIRaw)
                            .toggleStyle(.button)
                            .onChange(of: parameters.showMRIRaw) { _ in needsUpdate = true }
                        
                        Toggle("Detrended", isOn: $parameters.showMRIDetrended)
                            .toggleStyle(.button)
                            .onChange(of: parameters.showMRIDetrended) { _ in needsUpdate = true }
                        
                        Toggle("Model", isOn: $parameters.showModelOverlay)
                            .toggleStyle(.button)
                            .onChange(of: parameters.showModelOverlay) { _ in needsUpdate = true }
                    }
                    
                    Toggle("Use Dynamic MRI Range", isOn: $parameters.useDynamicMRIRange)
                        .onChange(of: parameters.useDynamicMRIRange) { _ in needsUpdate = true }
                }
                
                if parameters.showModelOverlay {
                    Section(header: Text("Detrending Model Components")) {
                        Toggle("Constant Term", isOn: $parameters.includeConstantTerm)
                            .onChange(of: parameters.includeConstantTerm) { _ in needsUpdate = true }
                        
                        Toggle("Linear Term", isOn: $parameters.includeLinearTerm)
                            .onChange(of: parameters.includeLinearTerm) { _ in needsUpdate = true }
                        
                        Toggle("Quadratic Term", isOn: $parameters.includeQuadraticTerm)
                            .onChange(of: parameters.includeQuadraticTerm) { _ in needsUpdate = true }
                        
                        Toggle("Cubic Term", isOn: $parameters.includeCubicTerm)
                            .onChange(of: parameters.includeCubicTerm) { _ in needsUpdate = true }
                    }
                    
                    Section(header: Text("Model Results")) {
                        HStack {
                            Text("Percent Change:")
                            Spacer()
                            Text(String(format: "%.2f%%", simulationData.percentChangeMetric))
                                .font(.headline)
                        }
                        
                        ForEach(Array(simulationData.betaParams.enumerated()), id: \.offset) { index, value in
                            HStack {
                                Text(betaParamName(index: index))
                                Spacer()
                                Text(String(format: "%.2f", value))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func betaParamName(index: Int) -> String {
        let baseNames = ["Stimulus Response", "Constant Term", "Linear Drift", "Quadratic Drift", "Cubic Drift"]
        return index < baseNames.count ? baseNames[index] : "Parameter \(index)"
    }
}

#Preview {
    @State var parameters = SimulationParameters()
    @State var simulationData = SimulationData()
    @State var needsUpdate = false
    
    return AnalysisTabView(
        parameters: $parameters,
        simulationData: $simulationData,
        needsUpdate: $needsUpdate
    )
}
