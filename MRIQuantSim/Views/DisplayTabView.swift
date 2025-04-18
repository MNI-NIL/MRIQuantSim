//
//  DisplayTabView.swift
//  MRIQuantSim
//
//  Created on 2025-04-11.
//

import SwiftUI

struct DisplayTabView: View {
    @Binding var parameters: SimulationParameters
    var onParameterChanged: () -> Void
    var onForceRefresh: () -> Void = {} // Add optional callback to force UI refresh
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Waveform Display Options Section
                CollapsibleSection(title: "Waveform Display", sectionId: "waveform_display") {
                    VStack(alignment: .leading, spacing: 12) {
                        // CO2 Signal group
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CO₂ Signal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ToggleButton(
                                    title: "Raw",
                                    isOn: $parameters.showCO2Raw,
                                    onChange: { 
                                        onParameterChanged() 
                                        onForceRefresh()
                                    }
                                )
                                
                                ToggleButton(
                                    title: "End-Tidal",
                                    isOn: $parameters.showCO2EndTidal,
                                    onChange: { 
                                        onParameterChanged() 
                                        onForceRefresh()
                                    }
                                )
                                
                                Spacer()
                            }
                        }
                        
                        // MRI Signal group
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MRI Signal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ToggleButton(
                                    title: "Raw",
                                    isOn: $parameters.showMRIRaw,
                                    onChange: { 
                                        onParameterChanged() 
                                        onForceRefresh()
                                    }
                                )
                                
                                ToggleButton(
                                    title: "Model Fit",
                                    isOn: $parameters.showModelOverlay,
                                    onChange: { 
                                        onParameterChanged() 
                                        onForceRefresh()
                                    }
                                )
                                
                                ToggleButton(
                                    title: "Detrended",
                                    isOn: $parameters.showMRIDetrended,
                                    onChange: { 
                                        onParameterChanged() 
                                        onForceRefresh()
                                    }
                                )
                                
                                ToggleButton(
                                    title: "Residuals",
                                    isOn: $parameters.showResidualError,
                                    onChange: { 
                                        onParameterChanged() 
                                        onForceRefresh()
                                    }
                                )
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Scaling Options Section
                CollapsibleSection(title: "Scaling Options", sectionId: "scaling_options") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ToggleButton(
                                title: "Zoom to MRI Dynamic Range",
                                isOn: $parameters.useMRIDynamicRange,
                                onChange: { 
                                    onParameterChanged() 
                                    onForceRefresh()
                                }
                            )
                            
                            Spacer()
                        }
                        .padding(.bottom, 4)
                        
                        Text("When enabled, the MRI graph's y-axis will automatically scale to fit all visible data.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Note: Parameter chart options removed since each parameter now has its own chart with individual scaling
                
                // Note: Noise regeneration button has been moved to the Signal tab
            }
            .padding(.vertical)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

// Preview in light mode
struct DisplayTabView_LightPreview: PreviewProvider {
    static var previews: some View {
        DisplayTabView(
            parameters: .constant(SimulationParameters()),
            onParameterChanged: {}
        )
        .preferredColorScheme(.light)
    }
}

// Preview in dark mode
struct DisplayTabView_DarkPreview: PreviewProvider {
    static var previews: some View {
        DisplayTabView(
            parameters: .constant(SimulationParameters()),
            onParameterChanged: {}
        )
        .preferredColorScheme(.dark)
    }
}
