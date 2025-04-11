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
    var onRegenerateNoise: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Waveform Display Options Section
                CollapsibleSection(title: "Waveform Display", sectionId: "waveform_display") {
                    VStack(alignment: .leading, spacing: 12) {
                        // CO2 Signal group
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
                        
                        // MRI Signal group
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
                                    title: "Model Fit",
                                    isOn: $parameters.showModelOverlay,
                                    onChange: { onParameterChanged() }
                                )
                                
                                ToggleButton(
                                    title: "Detrended",
                                    isOn: $parameters.showMRIDetrended,
                                    onChange: { onParameterChanged() }
                                )
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Scaling Options Section
                CollapsibleSection(title: "Scaling Options", sectionId: "scaling_options") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Use MRI Dynamic Range", isOn: $parameters.useMRIDynamicRange)
                            .onChange(of: parameters.useMRIDynamicRange) { _, _ in onParameterChanged() }
                            .padding(.bottom, 4)
                        
                        Text("When enabled, the MRI graph's y-axis will automatically scale to fit all visible data.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Noise Options Section
                CollapsibleSection(title: "Noise Options", sectionId: "noise_options") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MRI noise can be regenerated to simulate different noise realizations while maintaining the same statistical properties.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        Button(action: {
                            onRegenerateNoise()
                        }) {
                            HStack {
                                Image(systemName: "waveform.path")
                                Text("Regenerate MRI Noise")
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
                }
            }
            .padding()
        }
    }
}

// Preview in light mode
struct DisplayTabView_LightPreview: PreviewProvider {
    static var previews: some View {
        DisplayTabView(
            parameters: .constant(SimulationParameters()),
            onParameterChanged: {},
            onRegenerateNoise: {}
        )
        .preferredColorScheme(.light)
    }
}

// Preview in dark mode
struct DisplayTabView_DarkPreview: PreviewProvider {
    static var previews: some View {
        DisplayTabView(
            parameters: .constant(SimulationParameters()),
            onParameterChanged: {},
            onRegenerateNoise: {}
        )
        .preferredColorScheme(.dark)
    }
}