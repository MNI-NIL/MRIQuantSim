//
//  ParametersTabView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI

// Reusable collapsible section component with state persistence
struct CollapsibleSection<Content: View>: View {
    let title: String
    let sectionId: String  // Unique identifier for persisting state
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) var colorScheme
    
    // State that persists to UserDefaults
    @State private var isExpanded: Bool
    
    // Initializer to load persisted state
    init(title: String, sectionId: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.sectionId = sectionId
        self.content = content
        
        // Generate a consistent UserDefaults key
        let defaultsKey = "CollapsibleSection_\(sectionId)"
        
        // Load initial state from UserDefaults, default to expanded if not found
        let savedState = UserDefaults.standard.object(forKey: defaultsKey) as? Bool
        _isExpanded = State(initialValue: savedState ?? true)
    }
    
    private var sectionBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95)
    }
    
    private func persistExpandedState(_ isExpanded: Bool) {
        let defaultsKey = "CollapsibleSection_\(sectionId)"
        UserDefaults.standard.set(isExpanded, forKey: defaultsKey)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with chevron
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                    persistExpandedState(isExpanded)
                }
            }) {
                HStack {
                    Text(title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(sectionBackgroundColor)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content that can collapse
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    content()
                        .padding(.leading, 8)
                }
                .padding()
                .background(sectionBackgroundColor)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ParametersTabView: View {
    @Binding var parameters: SimulationParameters
    var onParameterChanged: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CollapsibleSection(title: "Signal Parameters", sectionId: "signal_params") {
                    parameterRow(title: "CO2 Sampling Rate (Hz)", value: $parameters.co2SamplingRate)
                    parameterRow(title: "Breathing Rate (breaths/min)", value: $parameters.breathingRate)
                    parameterRow(title: "MRI Sampling Interval (s)", value: $parameters.mriSamplingInterval)
                    parameterRow(title: "MRI Baseline Signal (a.u.)", value: $parameters.mriBaselineSignal)
                    parameterRow(title: "MRI Response Amplitude (a.u.)", value: $parameters.mriResponseAmplitude)
                }
                
                CollapsibleSection(title: "Noise Parameters", sectionId: "noise_params") {
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
                
                CollapsibleSection(title: "Drift Parameters", sectionId: "drift_params") {
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
                
                CollapsibleSection(title: "Display Options", sectionId: "display_options") {
                    Toggle("Show Raw CO2 Signal", isOn: $parameters.showCO2Raw)
                        .onChange(of: parameters.showCO2Raw) { _, _ in onParameterChanged() }
                    
                    Toggle("Show End-Tidal CO2 Points", isOn: $parameters.showCO2EndTidal)
                        .onChange(of: parameters.showCO2EndTidal) { _, _ in onParameterChanged() }
                    
                    Toggle("Show Raw MRI Signal", isOn: $parameters.showMRIRaw)
                        .onChange(of: parameters.showMRIRaw) { _, _ in onParameterChanged() }
                    
                    Toggle("Show Detrended MRI Signal", isOn: $parameters.showMRIDetrended)
                        .onChange(of: parameters.showMRIDetrended) { _, _ in onParameterChanged() }
                    
                    Toggle("Show Model Overlay", isOn: $parameters.showModelOverlay)
                        .onChange(of: parameters.showModelOverlay) { _, _ in onParameterChanged() }
                    
                    Toggle("Use Dynamic MRI Range", isOn: $parameters.useDynamicMRIRange)
                        .onChange(of: parameters.useDynamicMRIRange) { _, _ in onParameterChanged() }
                }
            }
            .padding()
        }
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