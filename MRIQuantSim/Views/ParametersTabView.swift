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
        Form {
            Section(header: Text("Signal Parameters")) {
                HStack {
                    Text("CO2 Sampling Rate (Hz)")
                    Spacer()
                    TextField("", value: $parameters.co2SamplingRate, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.co2SamplingRate) { _ in needsUpdate = true }
                }
                
                HStack {
                    Text("Breathing Rate (breaths/min)")
                    Spacer()
                    TextField("", value: $parameters.breathingRate, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.breathingRate) { _ in needsUpdate = true }
                }
                
                HStack {
                    Text("MRI Sampling Interval (s)")
                    Spacer()
                    TextField("", value: $parameters.mriSamplingInterval, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.mriSamplingInterval) { _ in needsUpdate = true }
                }
                
                HStack {
                    Text("MRI Baseline Signal (a.u.)")
                    Spacer()
                    TextField("", value: $parameters.mriBaselineSignal, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.mriBaselineSignal) { _ in needsUpdate = true }
                }
                
                HStack {
                    Text("MRI Response Amplitude (a.u.)")
                    Spacer()
                    TextField("", value: $parameters.mriResponseAmplitude, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.mriResponseAmplitude) { _ in needsUpdate = true }
                }
            }
            
            Section(header: Text("Noise Parameters")) {
                Toggle("Enable CO2 Noise", isOn: $parameters.enableCO2Noise)
                    .onChange(of: parameters.enableCO2Noise) { _ in needsUpdate = true }
                
                HStack {
                    Text("CO2 Noise Frequency (Hz)")
                    Spacer()
                    TextField("", value: $parameters.co2NoiseFrequency, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.co2NoiseFrequency) { _ in needsUpdate = true }
                        .disabled(!parameters.enableCO2Noise)
                }
                
                HStack {
                    Text("CO2 Noise Amplitude")
                    Spacer()
                    TextField("", value: $parameters.co2NoiseAmplitude, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.co2NoiseAmplitude) { _ in needsUpdate = true }
                        .disabled(!parameters.enableCO2Noise)
                }
                
                Toggle("Enable MRI Noise", isOn: $parameters.enableMRINoise)
                    .onChange(of: parameters.enableMRINoise) { _ in needsUpdate = true }
                
                HStack {
                    Text("MRI Noise Amplitude (a.u.)")
                    Spacer()
                    TextField("", value: $parameters.mriNoiseAmplitude, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.mriNoiseAmplitude) { _ in needsUpdate = true }
                        .disabled(!parameters.enableMRINoise)
                }
            }
            
            Section(header: Text("Drift Parameters")) {
                Toggle("Enable CO2 Drift", isOn: $parameters.enableCO2Drift)
                    .onChange(of: parameters.enableCO2Drift) { _ in needsUpdate = true }
                
                HStack {
                    Text("CO2 Linear Drift (mmHg)")
                    Spacer()
                    TextField("", value: $parameters.co2LinearDrift, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.co2LinearDrift) { _ in needsUpdate = true }
                        .disabled(!parameters.enableCO2Drift)
                }
                
                HStack {
                    Text("CO2 Quadratic Drift (mmHg)")
                    Spacer()
                    TextField("", value: $parameters.co2QuadraticDrift, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.co2QuadraticDrift) { _ in needsUpdate = true }
                        .disabled(!parameters.enableCO2Drift)
                }
                
                HStack {
                    Text("CO2 Cubic Drift (mmHg)")
                    Spacer()
                    TextField("", value: $parameters.co2CubicDrift, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.co2CubicDrift) { _ in needsUpdate = true }
                        .disabled(!parameters.enableCO2Drift)
                }
                
                Toggle("Enable MRI Drift", isOn: $parameters.enableMRIDrift)
                    .onChange(of: parameters.enableMRIDrift) { _ in needsUpdate = true }
                
                HStack {
                    Text("MRI Linear Drift (%)")
                    Spacer()
                    TextField("", value: $parameters.mriLinearDrift, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.mriLinearDrift) { _ in needsUpdate = true }
                        .disabled(!parameters.enableMRIDrift)
                }
                
                HStack {
                    Text("MRI Quadratic Drift (%)")
                    Spacer()
                    TextField("", value: $parameters.mriQuadraticDrift, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.mriQuadraticDrift) { _ in needsUpdate = true }
                        .disabled(!parameters.enableMRIDrift)
                }
                
                HStack {
                    Text("MRI Cubic Drift (%)")
                    Spacer()
                    TextField("", value: $parameters.mriCubicDrift, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: parameters.mriCubicDrift) { _ in needsUpdate = true }
                        .disabled(!parameters.enableMRIDrift)
                }
            }
        }
    }
}

#Preview {
    @State var parameters = SimulationParameters()
    @State var needsUpdate = false
    
    return ParametersTabView(parameters: $parameters, needsUpdate: $needsUpdate)
}
