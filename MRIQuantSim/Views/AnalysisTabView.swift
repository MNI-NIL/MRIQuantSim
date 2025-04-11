//
//  AnalysisTabView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI

struct AnalysisTabView: View {
    @Binding var parameters: SimulationParameters
    let simulationData: SimulationData
    var onParameterChanged: () -> Void
    var onRegenerateNoise: () -> Void // Add a new callback for noise regeneration
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Place Display Options and Detrending Model Components side by side
                HStack(alignment: .top, spacing: 16) {
                    displayOptionsSection
                        .frame(maxWidth: .infinity)
                    
                    // If model overlay is not shown, display an empty spacer with same width
                    if parameters.showModelOverlay {
                        detrendingOptionsSection
                            .frame(maxWidth: .infinity)
                    } else {
                        // This is an invisible placeholder with the same size to maintain layout
                        Color.clear
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Model Results section remains full width
                if parameters.showModelOverlay {
                    modelResultsSection
                }
            }
            .padding()
        }
    }
    
    private var displayOptionsSection: some View {
        CollapsibleSection(title: "Display Options", sectionId: "analysis_display_options") {
            VStack(alignment: .leading, spacing: 12) {
                // CO2 Signal group with left alignment
                VStack(alignment: .leading, spacing: 6) {
                    Text("CO2 Signal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ToggleButton(
                            title: "Raw",
                            isOn: $parameters.showCO2Raw,
                            onChange: { onParameterChanged() }
                        )
                        
                        ToggleButton(
                            title: "End-Tidal",
                            isOn: $parameters.showCO2EndTidal,
                            onChange: { onParameterChanged() }
                        )
                        
                        Spacer()
                    }
                }
                
                // MRI Signal group with left alignment
                VStack(alignment: .leading, spacing: 6) {
                    Text("MRI Signal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ToggleButton(
                            title: "Raw",
                            isOn: $parameters.showMRIRaw,
                            onChange: { onParameterChanged() }
                        )
                        
                        ToggleButton(
                            title: "Detrended",
                            isOn: $parameters.showMRIDetrended,
                            onChange: { onParameterChanged() }
                        )
                        
                        ToggleButton(
                            title: "Model",
                            isOn: $parameters.showModelOverlay,
                            onChange: { onParameterChanged() }
                        )
                        
                        Spacer()
                    }
                }
                
                // Dynamic MRI Range option
                VStack(alignment: .leading, spacing: 6) {
                    Text("Scale Options")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Toggle("Use MRI Dynamic Range", isOn: $parameters.useMRIDynamicRange)
                        .onChange(of: parameters.useMRIDynamicRange) { _, _ in onParameterChanged() }
                }
                .padding(.top, 4)
                
                // Noise regeneration option
                VStack(alignment: .leading, spacing: 6) {
                    Text("Noise Options")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        // Call the regenerate noise callback
                        onRegenerateNoise()
                    }) {
                        HStack {
                            Image(systemName: "waveform.path")
                            Text("Re-generate MRI Noise")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!parameters.enableMRINoise)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var detrendingOptionsSection: some View {
        // Get the shared CollapsibleSection component from ParametersTabView
        CollapsibleSection(title: "Detrending Model Components", sectionId: "detrending_options") {
            VStack(alignment: .leading, spacing: 8) {
                modelToggle(title: "Constant Term", isOn: $parameters.includeConstantTerm)
                modelToggle(title: "Linear Term", isOn: $parameters.includeLinearTerm)
                modelToggle(title: "Quadratic Term", isOn: $parameters.includeQuadraticTerm)
                modelToggle(title: "Cubic Term", isOn: $parameters.includeCubicTerm)
            }
        }
    }
    
    private var modelResultsSection: some View {
        CollapsibleSection(title: "Model Results", sectionId: "model_results") {
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
        }
    }
    
    private func modelToggle(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .onChange(of: isOn.wrappedValue) { _, _ in onParameterChanged() }
    }
    
    private func betaParamName(index: Int) -> String {
        let baseNames = ["Stimulus Response", "Constant Term", "Linear Drift", "Quadratic Drift", "Cubic Drift"]
        return index < baseNames.count ? baseNames[index] : "Parameter \(index)"
    }
    
    // MARK: - Color helpers for dark mode support
    
    private var sectionBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95)
    }
}

struct ToggleButton: View {
    let title: String
    @Binding var isOn: Bool
    var onChange: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            isOn.toggle()
            onChange()
        }) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(buttonBackgroundColor)
                .foregroundColor(buttonTextColor)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonBackgroundColor: Color {
        if isOn {
            return Color.accentColor
        } else {
            return colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.9)
        }
    }
    
    private var buttonTextColor: Color {
        if isOn {
            return .white
        } else {
            return colorScheme == .dark ? Color.white : Color.primary
        }
    }
}

// Preview light mode
struct AnalysisTabView_LightPreview: PreviewProvider {
    static var previews: some View {
        let simData = SimulationData()
        simData.betaParams = [25.0, 1200.0, 3.5, 1.2, 0.8]
        simData.percentChangeMetric = 2.08
        
        return AnalysisTabView(
            parameters: .constant(SimulationParameters()),
            simulationData: simData,
            onParameterChanged: {},
            onRegenerateNoise: {}
        )
        .preferredColorScheme(.light)
    }
}

// Preview dark mode
struct AnalysisTabView_DarkPreview: PreviewProvider {
    static var previews: some View {
        let simData = SimulationData()
        simData.betaParams = [25.0, 1200.0, 3.5, 1.2, 0.8]
        simData.percentChangeMetric = 2.08
        
        return AnalysisTabView(
            parameters: .constant(SimulationParameters()),
            simulationData: simData,
            onParameterChanged: {},
            onRegenerateNoise: {}
        )
        .preferredColorScheme(.dark)
    }
}
