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
        ScrollView {
            VStack(spacing: 16) {
                displayOptionsSection
                
                if parameters.showModelOverlay {
                    detrendingOptionsSection
                    modelResultsSection
                }
            }
            .padding()
        }
    }
    
    private var displayOptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Display Options")
                .font(.headline)
                .padding(.bottom, 2)
                
            VStack(spacing: 12) {
                HStack {
                    Text("CO2 Signal")
                        .frame(width: 100, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        ToggleButton(
                            title: "Raw",
                            isOn: $parameters.showCO2Raw,
                            onChange: { needsUpdate = true }
                        )
                        
                        ToggleButton(
                            title: "End-Tidal",
                            isOn: $parameters.showCO2EndTidal,
                            onChange: { needsUpdate = true }
                        )
                    }
                }
                
                HStack {
                    Text("MRI Signal")
                        .frame(width: 100, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        ToggleButton(
                            title: "Raw",
                            isOn: $parameters.showMRIRaw,
                            onChange: { needsUpdate = true }
                        )
                        
                        ToggleButton(
                            title: "Detrended",
                            isOn: $parameters.showMRIDetrended,
                            onChange: { needsUpdate = true }
                        )
                        
                        ToggleButton(
                            title: "Model",
                            isOn: $parameters.showModelOverlay,
                            onChange: { needsUpdate = true }
                        )
                    }
                }
                
                Toggle("Use Dynamic MRI Range", isOn: $parameters.useDynamicMRIRange)
                    .padding(.top, 4)
                    .onChange(of: parameters.useDynamicMRIRange) { _ in needsUpdate = true }
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        .cornerRadius(10)
    }
    
    private var detrendingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detrending Model Components")
                .font(.headline)
                .padding(.bottom, 2)
                
            VStack(alignment: .leading, spacing: 8) {
                modelToggle(title: "Constant Term", isOn: $parameters.includeConstantTerm)
                modelToggle(title: "Linear Term", isOn: $parameters.includeLinearTerm)
                modelToggle(title: "Quadratic Term", isOn: $parameters.includeQuadraticTerm)
                modelToggle(title: "Cubic Term", isOn: $parameters.includeCubicTerm)
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        .cornerRadius(10)
    }
    
    private var modelResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Model Results")
                .font(.headline)
                .padding(.bottom, 2)
                
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Percent Change:")
                        .bold()
                    Spacer()
                    Text(String(format: "%.2f%%", simulationData.percentChangeMetric))
                        .font(.headline)
                }
                .padding(.bottom, 4)
                
                ForEach(Array(simulationData.betaParams.enumerated()), id: \.offset) { index, value in
                    HStack {
                        Text(betaParamName(index: index))
                        Spacer()
                        Text(String(format: "%.2f", value))
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        .cornerRadius(10)
    }
    
    private func modelToggle(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .onChange(of: isOn.wrappedValue) { _ in needsUpdate = true }
    }
    
    private func betaParamName(index: Int) -> String {
        let baseNames = ["Stimulus Response", "Constant Term", "Linear Drift", "Quadratic Drift", "Cubic Drift"]
        return index < baseNames.count ? baseNames[index] : "Parameter \(index)"
    }
}

struct ToggleButton: View {
    let title: String
    @Binding var isOn: Bool
    var onChange: () -> Void
    
    var body: some View {
        Button(action: {
            isOn.toggle()
            onChange()
        }) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isOn ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundColor(isOn ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalysisTabView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State var parameters = SimulationParameters()
            @State var simulationData = SimulationData()
            @State var needsUpdate = false
            
            init() {
                simulationData.betaParams = [25.0, 1200.0, 3.5, 1.2, 0.8]
                simulationData.percentChangeMetric = 2.08
            }
            
            var body: some View {
                AnalysisTabView(
                    parameters: $parameters,
                    simulationData: $simulationData,
                    needsUpdate: $needsUpdate
                )
            }
        }
        
        return PreviewWrapper()
    }
}
