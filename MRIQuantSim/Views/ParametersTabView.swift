//
//  ParametersTabView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI

struct ParametersTabView: View {
    @Binding var parameters: SimulationParameters
    @Binding var needsUpdate: Bool
    
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
                        .onChange(of: parameters.enableCO2Noise) { _ in needsUpdate = true }
                    
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
                        .onChange(of: parameters.enableMRINoise) { _ in needsUpdate = true }
                    
                    parameterRow(
                        title: "MRI Noise Amplitude (a.u.)",
                        value: $parameters.mriNoiseAmplitude,
                        disabled: !parameters.enableMRINoise
                    )
                }
                
                parameterSection(title: "Drift Parameters") {
                    Toggle("Enable CO2 Drift", isOn: $parameters.enableCO2Drift)
                        .onChange(of: parameters.enableCO2Drift) { _ in needsUpdate = true }
                    
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
                        .onChange(of: parameters.enableMRIDrift) { _ in needsUpdate = true }
                    
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
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
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
                .background(Color.white)
                .cornerRadius(6)
                .onChange(of: value.wrappedValue) { _ in needsUpdate = true }
                .disabled(disabled)
        }
    }
}

struct ParametersTabView_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State var parameters = SimulationParameters()
            @State var needsUpdate = false
            
            var body: some View {
                ParametersTabView(parameters: $parameters, needsUpdate: $needsUpdate)
            }
        }
        
        return PreviewWrapper()
    }
}