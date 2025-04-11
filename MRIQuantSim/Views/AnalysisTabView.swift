//
//  AnalysisTabView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI
// ToggleButton is imported automatically since it's in the same module

struct AnalysisTabView: View {
    @Binding var parameters: SimulationParameters
    let simulationData: SimulationData
    var onParameterChanged: () -> Void
    var onRegenerateNoise: () -> Void // Add a new callback for noise regeneration
    @Environment(\.colorScheme) var colorScheme
    
    // Check if all model terms would be disabled and prevent that
    func checkToggleAndUpdate() {
        // Check if all terms are now off
        let allTermsOff = !parameters.includeConstantTerm && 
                         !parameters.includeLinearTerm && 
                         !parameters.includeQuadraticTerm && 
                         !parameters.includeCubicTerm
        
        // If all would be off, turn constant term back on
        if allTermsOff {
            parameters.includeConstantTerm = true
            print("Forcing constant term to remain on")
        }
        
        // Always call parameter changed to update the model
        onParameterChanged()
    }
    
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Include in model:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ToggleButton(
                        title: "Constant",
                        isOn: $parameters.includeConstantTerm,
                        onChange: { checkToggleAndUpdate() }
                    )
                    
                    ToggleButton(
                        title: "Linear",
                        isOn: $parameters.includeLinearTerm,
                        onChange: { checkToggleAndUpdate() }
                    )
                    
                    ToggleButton(
                        title: "Quadratic",
                        isOn: $parameters.includeQuadraticTerm,
                        onChange: { checkToggleAndUpdate() }
                    )
                    
                    ToggleButton(
                        title: "Cubic",
                        isOn: $parameters.includeCubicTerm,
                        onChange: { checkToggleAndUpdate() }
                    )
                    
                    Spacer()
                }
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
                
                // Add an ID based on the parameters to force refresh when model terms change
                ForEach(Array(simulationData.betaParams.enumerated()), id: \.offset) { index, value in
                    HStack {
                        Text(betaParamName(index: index))
                        Spacer()
                        Text(String(format: "%.2f", value))
                    }
                }
                .id("modelResults-\(parameters.includeConstantTerm)-\(parameters.includeLinearTerm)-\(parameters.includeQuadraticTerm)-\(parameters.includeCubicTerm)")
            }
        }
    }
    
    // Using ToggleButton instead of individual Toggle components
    
    private func betaParamName(index: Int) -> String {
        // Determine included terms to map parameter indices to the correct names
        let includedTerms = [
            true, // Stimulus regressor is always included
            parameters.includeConstantTerm,
            parameters.includeLinearTerm,
            parameters.includeQuadraticTerm,
            parameters.includeCubicTerm
        ]
        
        let allTerms = ["Stimulus Response", "Constant Term", "Linear Drift", "Quadratic Drift", "Cubic Drift"]
        
        // Count how many true values there are before 'index' in includedTerms
        var includedIndex = 0
        var trueCount = 0
        
        for i in 0..<includedTerms.count {
            if includedTerms[i] {
                if trueCount == index {
                    includedIndex = i
                    break
                }
                trueCount += 1
            }
        }
        
        // Return the name for the included term at position 'index'
        return includedIndex < allTerms.count ? allTerms[includedIndex] : "Parameter \(index)"
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
