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
                        onChange: { 
                            // Prevent turning off the constant term if it's the last one enabled
                            let wouldAllBeOff = !parameters.includeConstantTerm && 
                                               !parameters.includeLinearTerm && 
                                               !parameters.includeQuadraticTerm && 
                                               !parameters.includeCubicTerm
                            
                            if parameters.includeConstantTerm && wouldAllBeOff {
                                // Don't allow turning off all terms - constant remains on
                                print("Warning: At least one model term must be included")
                            } else {
                                onParameterChanged()
                            }
                        }
                    )
                    
                    ToggleButton(
                        title: "Linear",
                        isOn: $parameters.includeLinearTerm,
                        onChange: { 
                            // Prevent turning off the last model term
                            let wouldAllBeOff = !parameters.includeConstantTerm && 
                                               !parameters.includeLinearTerm && 
                                               !parameters.includeQuadraticTerm && 
                                               !parameters.includeCubicTerm
                            
                            if parameters.includeLinearTerm && wouldAllBeOff {
                                // If this would turn off all terms, turn on the constant term instead
                                parameters.includeConstantTerm = true
                            }
                            
                            onParameterChanged()
                        }
                    )
                    
                    ToggleButton(
                        title: "Quadratic",
                        isOn: $parameters.includeQuadraticTerm,
                        onChange: { 
                            // Prevent turning off the last model term
                            let wouldAllBeOff = !parameters.includeConstantTerm && 
                                               !parameters.includeLinearTerm && 
                                               !parameters.includeQuadraticTerm && 
                                               !parameters.includeCubicTerm
                            
                            if parameters.includeQuadraticTerm && wouldAllBeOff {
                                // If this would turn off all terms, turn on the constant term instead
                                parameters.includeConstantTerm = true
                            }
                            
                            onParameterChanged()
                        }
                    )
                    
                    ToggleButton(
                        title: "Cubic",
                        isOn: $parameters.includeCubicTerm,
                        onChange: { 
                            // Prevent turning off the last model term
                            let wouldAllBeOff = !parameters.includeConstantTerm && 
                                               !parameters.includeLinearTerm && 
                                               !parameters.includeQuadraticTerm && 
                                               !parameters.includeCubicTerm
                            
                            if parameters.includeCubicTerm && wouldAllBeOff {
                                // If this would turn off all terms, turn on the constant term instead
                                parameters.includeConstantTerm = true
                            }
                            
                            onParameterChanged()
                        }
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
    
    // Using ToggleButton instead of individual Toggle components
    
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
