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
                // Detrending Model Components
                if parameters.showModelOverlay {
                    detrendingOptionsSection
                }
                
                // Model Results section remains full width
                if parameters.showModelOverlay {
                    modelResultsSection
                }
            }
            .padding()
        }
    }
    
    // Display options have been moved to a dedicated Display tab
    
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

// ToggleButton has been moved to a separate file

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
