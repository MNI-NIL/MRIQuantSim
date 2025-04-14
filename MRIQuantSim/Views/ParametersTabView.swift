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
        
        // Check if the app has been launched before
        let appHasLaunchedBefore = UserDefaults.standard.bool(forKey: "AppHasLaunchedBefore")
        
        // If this is the first launch, start with all sections collapsed
        if !appHasLaunchedBefore {
            _isExpanded = State(initialValue: false)
        } else {
            // Load saved state from UserDefaults, default to collapsed if not found
            let savedState = UserDefaults.standard.object(forKey: defaultsKey) as? Bool
            _isExpanded = State(initialValue: savedState ?? false)
        }
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
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
    var onRegenerateNoise: (() -> Void)? = nil  // Optional callback for noise regeneration
    var onRandomizeCO2VariancePhase: (() -> Void)? = nil  // Optional callback for CO2 variance phase randomization
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CollapsibleSection(title: "Signal Parameters", sectionId: "signal_params") {
                    parameterRow(title: "CO₂ Sampling Rate (Hz)", value: $parameters.co2SamplingRate)
                    parameterRow(title: "Breathing Rate (breaths/min)", value: $parameters.breathingRate)
                    parameterRow(title: "MRI Sampling Interval (s)", value: $parameters.mriSamplingInterval)
                    parameterRow(title: "MRI Baseline Signal (a.u.)", value: $parameters.mriBaselineSignal)
                    parameterRow(title: "MRI Response Amplitude (a.u.)", value: $parameters.mriResponseAmplitude)
                }
                
                CollapsibleSection(title: "Noise Parameters", sectionId: "noise_params") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CO₂ Variance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Toggle("Enable", isOn: $parameters.enableCO2Variance)
                            .onChange(of: parameters.enableCO2Variance) { _, _ in onParameterChanged() }
                            .padding(.vertical, 4)
                    }
                    
                    parameterRow(
                        title: "CO₂ Variance Frequency (Hz)",
                        value: $parameters.co2VarianceFrequency,
                        disabled: !parameters.enableCO2Variance
                    )
                    
                    parameterRow(
                        title: "CO₂ Frequency Variance",
                        value: $parameters.co2VarianceAmplitude,
                        disabled: !parameters.enableCO2Variance
                    )
                    
                    parameterRow(
                        title: "CO₂ Amplitude Variance (mmHg)",
                        value: $parameters.co2AmplitudeVariance,
                        disabled: !parameters.enableCO2Variance
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MRI Noise")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Toggle("Enable", isOn: $parameters.enableMRINoise)
                            .onChange(of: parameters.enableMRINoise) { _, _ in onParameterChanged() }
                            .padding(.vertical, 4)
                    }
                    
                    parameterRow(
                        title: "MRI Noise Amplitude (a.u.)",
                        value: $parameters.mriNoiseAmplitude,
                        disabled: !parameters.enableMRINoise
                    )
                    
                    // Add regenerate noise button if the callback is provided
                    if let regenerateCallback = onRegenerateNoise {
                        VStack(alignment: .leading, spacing: 6) {
                            Divider()
                                .padding(.vertical, 8)
                            
                            Text("Regenerate MRI Noise")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                
                            Text("Generate new random values while keeping the same statistical properties.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 4)
                            
                            Button(action: {
                                regenerateCallback()
                            }) {
                                HStack {
                                    Image(systemName: "waveform.path")
                                    Text("Regenerate")
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!parameters.enableMRINoise)
                            .padding(.vertical, 4)
                        }
                        
                        if parameters.enableCO2Variance {
                            VStack(alignment: .leading, spacing: 6) {
                                Divider()
                                    .padding(.vertical, 8)
                                
                                Text("Regenerate CO₂ Variance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    
                                Text("Randomize the phase of the CO₂ variance waveform.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                
                                Button(action: {
                                    // Call the randomizeCO2VariancePhase handler from ContentView
                                    onRandomizeCO2VariancePhase?()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Regenerate")
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!parameters.enableCO2Variance)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                CollapsibleSection(title: "Drift Parameters", sectionId: "drift_params") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CO₂ Drift")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Toggle("Enable", isOn: $parameters.enableCO2Drift)
                            .onChange(of: parameters.enableCO2Drift) { _, _ in onParameterChanged() }
                            .padding(.vertical, 4)
                    }
                    
                    parameterRow(
                        title: "CO₂ Linear Drift (mmHg)",
                        value: $parameters.co2LinearDrift,
                        disabled: !parameters.enableCO2Drift
                    )
                    
                    parameterRow(
                        title: "CO₂ Quadratic Drift (mmHg)",
                        value: $parameters.co2QuadraticDrift,
                        disabled: !parameters.enableCO2Drift
                    )
                    
                    parameterRow(
                        title: "CO₂ Cubic Drift (mmHg)",
                        value: $parameters.co2CubicDrift,
                        disabled: !parameters.enableCO2Drift
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MRI Drift")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Toggle("Enable", isOn: $parameters.enableMRIDrift)
                            .onChange(of: parameters.enableMRIDrift) { _, _ in onParameterChanged() }
                            .padding(.vertical, 4)
                    }
                    
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
                
                CollapsibleSection(title: "Response Parameters", sectionId: "response_params") {
                    // Response amplitudes
                    parameterRow(title: "CO₂ Response Amplitude (mmHg)", value: $parameters.co2ResponseAmplitude)
                    parameterRow(title: "MRI Response Amplitude (a.u.)", value: $parameters.mriResponseAmplitude)
                    
                    Divider().padding(.vertical, 8)
                    
                    // Response shape picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Response Shape")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $parameters.responseShapeType) {
                            ForEach(ResponseShapeType.allCases, id: \.self) { shapeType in
                                Text(shapeType.rawValue).tag(shapeType)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: parameters.responseShapeType) { _, _ in onParameterChanged() }
                        .padding(.vertical, 4)
                    }
                    
                    // Only show time constants if exponential is selected
                    if parameters.responseShapeType == .exponential {
                        parameterRow(title: "Rise Time Constant (s)", value: $parameters.responseRiseTimeConstant)
                        parameterRow(title: "Fall Time Constant (s)", value: $parameters.responseFallTimeConstant)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Time Constants")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Control the speed of transition at the beginning (rise) and end (fall) of each response block.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Display options have been moved to a dedicated Display tab
            }
            .padding()
        }
    }
    
    private func parameterRow(title: String, value: Binding<Double>, disabled: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // Slider with appropriate range based on parameter type
                Slider(
                    value: value,
                    in: getRange(for: title),
                    step: getStep(for: title)
                )
                .onChange(of: value.wrappedValue) { _, _ in 
                    // Use a debounce approach for sliders to avoid excessive updates
                    onParameterChanged()
                }
                .disabled(disabled)
                
                // Text field for precise input
                TextField("", value: value, format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .padding(6)
                    .background(textFieldBackgroundColor)
                    .foregroundColor(textFieldTextColor)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit { onParameterChanged() }
                    .disabled(disabled)
                
                // Reset button - now next to the text field
                Button(action: {
                    // Get default value from parameters
                    let defaultValue = parameters.getDefaultValue(forParameter: title)
                    // Update the value
                    value.wrappedValue = defaultValue
                    // Notify of parameter change
                    onParameterChanged()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(disabled)
                .help("Reset to default value")
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper functions to determine appropriate slider ranges based on parameter name
    private func getRange(for parameterName: String) -> ClosedRange<Double> {
        switch parameterName {
        // Specific parameters with custom ranges
        case "CO₂ Response Amplitude (mmHg)":
            return 0.0...50.0
        case "MRI Response Amplitude (a.u.)":
            return 0.0...200.0
        case "MRI Baseline Signal (a.u.)":
            return 800.0...2000.0
        case "CO₂ Sampling Rate (Hz)":
            return 1.0...50.0
        case "Breathing Rate (breaths/min)":
            return 5.0...30.0
        case "MRI Sampling Interval (s)":
            return 0.5...10.0
            
        // General parameter types
        case _ where parameterName.contains("Amplitude") && !parameterName.contains("Response"):
            return 0.0...50.0
        case _ where parameterName.contains("Noise"):
            return 0.0...50.0
        case _ where parameterName.contains("Drift"):
            return -20.0...20.0
        case _ where parameterName.contains("Time Constant"):
            return 1.0...30.0
        case _ where parameterName.contains("Breathing Rate"):
            return 5.0...30.0
        case _ where parameterName.contains("Sampling Rate"):
            return 1.0...50.0
        case _ where parameterName.contains("Interval"):
            return 0.5...10.0
        case _ where parameterName.contains("Frequency"):
            return 0.05...1.0
        case _ where parameterName.contains("Variance"):
            return 0.0...10.0
        default:
            return 0.0...100.0
        }
    }
    
    private func getStep(for parameterName: String) -> Double {
        switch parameterName {
        // Specific parameters with custom step values
        case "MRI Baseline Signal (a.u.)":
            return 50.0
        case "CO₂ Response Amplitude (mmHg)":
            return 1.0
        case "MRI Response Amplitude (a.u.)":
            return 5.0
            
        // Parameter types
        case _ where parameterName.contains("Frequency"):
            return 0.05
        case _ where parameterName.contains("Time Constant"):
            return 1.0
        case _ where parameterName.contains("Interval"):
            return 0.5
        case _ where parameterName.contains("Sampling"):
            return 1.0
        case _ where parameterName.contains("Breathing"):
            return 1.0
        case _ where parameterName.contains("Drift"):
            return 2.0
        case _ where parameterName.contains("Noise"):
            return 2.0
        case _ where parameterName.contains("Amplitude"):
            return 5.0
        case _ where parameterName.contains("Variance"):
            return 0.5
        default:
            return 1.0
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
            onParameterChanged: {},
            onRegenerateNoise: {}
        )
        .preferredColorScheme(.light)
    }
}

// Preview dark mode
struct ParametersTabView_DarkPreview: PreviewProvider {
    static var previews: some View {
        ParametersTabView(
            parameters: .constant(SimulationParameters()),
            onParameterChanged: {},
            onRegenerateNoise: {}
        )
        .preferredColorScheme(.dark)
    }
}
