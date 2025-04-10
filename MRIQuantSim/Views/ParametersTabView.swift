//
//  ParametersTabView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI

struct ParametersTabView: View {
    @Binding var parameters: SimulationParameters
    var onParameterChanged: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                parameterSection(title: "Signal Parameters") {
                    parameterRow(title: "CO2 Sampling Rate (Hz)", value: $parameters.co2SamplingRate)
                    parameterRow(title: "Breathing Rate (breaths/min)", value: $parameters.breathingRate)
                    parameterRow(title: "MRI Sampling Interval (s)", value: $parameters.mriSamplingInterval)
                    parameterRow(title: "MRI Baseline Signal (a.u.)", value: $parameters.mriBaselineSignal)
                    parameterRow(title: "MRI Response Amplitude (a.u.)", value: $parameters.mriResponseAmplitude)
                }
                
                parameterSection(title: "Noise Parameters") {
                    Toggle("Enable CO2 Noise", isOn: $parameters.enableCO2Noise)
                        .onChange(of: parameters.enableCO2Noise) { _, _ in onParameterChanged() }
                    
                    parameterRow(
                        title: "CO2 Noise Frequency (Hz)", 
                        value: $parameters.co2NoiseFrequency,
                        disabled: !parameters.enableCO2Noise
                    )
                    
                    parameterRow(
                        title: "CO2 Noise Amplitude",
                        value: $parameters.co2NoiseAmplitude,
                        disabled: !parameters.enableCO2Noise
                    )
                    
                    Toggle("Enable MRI Noise", isOn: $parameters.enableMRINoise)
                        .onChange(of: parameters.enableMRINoise) { _, _ in onParameterChanged() }
                    
                    parameterRow(
                        title: "MRI Noise Amplitude (a.u.)",
                        value: $parameters.mriNoiseAmplitude,
                        disabled: !parameters.enableMRINoise
                    )
                }
                
                parameterSection(title: "Drift Parameters") {
                    Toggle("Enable CO2 Drift", isOn: $parameters.enableCO2Drift)
                        .onChange(of: parameters.enableCO2Drift) { _, _ in onParameterChanged() }
                    
                    parameterRow(
                        title: "CO2 Linear Drift (mmHg)",
                        value: $parameters.co2LinearDrift,
                        disabled: !parameters.enableCO2Drift
                    )
                    
                    parameterRow(
                        title: "CO2 Quadratic Drift (mmHg)",
                        value: $parameters.co2QuadraticDrift,
                        disabled: !parameters.enableCO2Drift
                    )
                    
                    parameterRow(
                        title: "CO2 Cubic Drift (mmHg)",
                        value: $parameters.co2CubicDrift,
                        disabled: !parameters.enableCO2Drift
                    )
                    
                    Toggle("Enable MRI Drift", isOn: $parameters.enableMRIDrift)
                        .onChange(of: parameters.enableMRIDrift) { _, _ in onParameterChanged() }
                    
                    parameterRow(
                        title: "MRI Linear Drift (%)",
                        value: $parameters.mriLinearDrift,
                        disabled: !parameters.enableMRIDrift
                    )
                    
                    parameterRow(
                        title: "MRI Quadratic Drift (%)",
                        value: $parameters.mriQuadraticDrift,
                        disabled: !parameters.enableMRIDrift
                    )
                    
                    parameterRow(
                        title: "MRI Cubic Drift (%)",
                        value: $parameters.mriCubicDrift,
                        disabled: !parameters.enableMRIDrift
                    )
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func parameterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            
            content()
                .padding(.leading, 8)
        }
        .padding()
        .background(sectionBackgroundColor)
        .cornerRadius(10)
    }
    
    private func parameterRow(title: String, value: Binding<Double>, disabled: Bool = false) -> some View {
        HStack(spacing: 15) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("", value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .padding(8)
                .background(textFieldBackgroundColor)
                .foregroundColor(textFieldTextColor)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                // Use onSubmit instead of onChange to update only when editing is completed
                .onSubmit { onParameterChanged() }
                .disabled(disabled)
        }
    }
    
    // MARK: - Color helpers for dark mode support
    
    private var sectionBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95)
    }
    
    private var textFieldBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
    
    private var textFieldTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
}

// Preview light mode
struct ParametersTabView_LightPreview: PreviewProvider {
    static var previews: some View {
        ParametersTabView(
            parameters: .constant(SimulationParameters()),
            onParameterChanged: {}
        )
        .preferredColorScheme(.light)
    }
}

// Preview dark mode
struct ParametersTabView_DarkPreview: PreviewProvider {
    static var previews: some View {
        ParametersTabView(
            parameters: .constant(SimulationParameters()),
            onParameterChanged: {}
        )
        .preferredColorScheme(.dark)
    }
}
