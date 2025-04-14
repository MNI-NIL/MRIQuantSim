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
    var onForceRefresh: () -> Void = {} // Optional callback to force UI refresh
    @Environment(\.colorScheme) var colorScheme
    
    // Check if all model terms would be disabled and prevent that
    func checkToggleAndUpdate() {
        // Check if all terms are now off
        let allTermsOff = !parameters.includeConstantTerm && 
                         !parameters.includeLinearTerm && 
                         !parameters.includeQuadraticTerm && 
                         !parameters.includeCubicTerm
        
        // Log the model terms state
        print("Model term toggle detected:")
        print("  - Constant: \(parameters.includeConstantTerm)")
        print("  - Linear: \(parameters.includeLinearTerm)")
        print("  - Quadratic: \(parameters.includeQuadraticTerm)")
        print("  - Cubic: \(parameters.includeCubicTerm)")
        
        // If all would be off, turn constant term back on
        if allTermsOff {
            parameters.includeConstantTerm = true
            print("Forcing constant term to remain on")
        }
        
        // Call parameter changed to update the model
        onParameterChanged()
        
        // Force UI refresh
        onForceRefresh()
        
        print("Model terms toggled, forcing UI refresh")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Analysis Model Specification
                analysisModelSection
                
                // Detrending Model Components
                if parameters.showModelOverlay {
                    detrendingOptionsSection
                }
                
                // Model Results section
                if parameters.showModelOverlay {
                    modelResultsSection
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity) // Ensure VStack takes available width
        }
        .frame(maxWidth: .infinity) // Ensure ScrollView takes available width
    }
    
    // Display options have been moved to a dedicated Display tab
    
    private var analysisModelSection: some View {
        CollapsibleSection(title: "Analysis Model Specification", sectionId: "analysis_model") {
            VStack(alignment: .leading, spacing: 12) {
                // Description text
                Text("Specify the shape of the hemodynamic response function used in the GLM analysis. This can be different from the signal simulation model to demonstrate model mis-specification effects.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                // Response shape picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Model Shape")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $parameters.analysisModelType) {
                        ForEach(ResponseShapeType.allCases, id: \.self) { shapeType in
                            Text(shapeType.rawValue).tag(shapeType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: parameters.analysisModelType) { _, _ in 
                        onParameterChanged()
                        onForceRefresh() // Force immediate refresh
                    }
                    .padding(.bottom, 4)
                }
                
                // Show model-specific parameters based on the selected model type
                if parameters.analysisModelType == .exponential {
                    // Exponential model parameters
                    VStack(alignment: .leading, spacing: 10) {
                        // Rise time constant with slider
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Rise Time Constant (s)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                // Slider with range from parameter metadata
                                let metadata = parameters.getParameterMetadata(forParameter: "Rise Time Constant (s)")
                                Slider(
                                    value: $parameters.analysisRiseTimeConstant,
                                    in: metadata.minValue...metadata.maxValue,
                                    step: metadata.step
                                )
                                .onChange(of: parameters.analysisRiseTimeConstant) { _, _ in
                                    onParameterChanged()
                                    onForceRefresh() // Force immediate refresh
                                }
                                
                                // Text field for precise input
                                TextField("", value: $parameters.analysisRiseTimeConstant, format: .number)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 70)
                                    .padding(6)
                                    .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .onSubmit { 
                                        onParameterChanged() 
                                        onForceRefresh() // Force immediate refresh
                                    }
                                
                                // Reset button - to the right of the text field
                                Button(action: {
                                    parameters.analysisRiseTimeConstant = parameters.getParameterMetadata(forParameter: "Rise Time Constant (s)").defaultValue
                                    onParameterChanged()
                                    onForceRefresh()
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 12))
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Reset to default value")
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Fall time constant with slider
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Fall Time Constant (s)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                // Slider with range from parameter metadata
                                let metadata = parameters.getParameterMetadata(forParameter: "Fall Time Constant (s)")
                                Slider(
                                    value: $parameters.analysisFallTimeConstant,
                                    in: metadata.minValue...metadata.maxValue,
                                    step: metadata.step
                                )
                                .onChange(of: parameters.analysisFallTimeConstant) { _, _ in
                                    onParameterChanged()
                                    onForceRefresh() // Force immediate refresh
                                }
                                
                                // Text field for precise input
                                TextField("", value: $parameters.analysisFallTimeConstant, format: .number)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 70)
                                    .padding(6)
                                    .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .onSubmit { 
                                        onParameterChanged() 
                                        onForceRefresh() // Force immediate refresh
                                    }
                                
                                // Reset button - to the right of the text field
                                Button(action: {
                                    parameters.analysisFallTimeConstant = parameters.getParameterMetadata(forParameter: "Fall Time Constant (s)").defaultValue
                                    onParameterChanged()
                                    onForceRefresh()
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 12))
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Reset to default value")
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Copy from simulation button
                        HStack {
                            Spacer()
                            Button(action: {
                                parameters.copySimulationTimeConstantsToAnalysis()
                                onParameterChanged()
                                onForceRefresh() // Force immediate refresh
                            }) {
                                Text("Copy from Simulation Model")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(parameters.isSimulationUsingExponential() ? Color.accentColor : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(!parameters.isSimulationUsingExponential())
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 8)
                    }
                } else if parameters.analysisModelType == .fir {
                    // FIR model parameters
                    VStack(alignment: .leading, spacing: 10) {
                        // FIR coverage duration with slider
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FIR Coverage Duration (s)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                // Slider with range from parameter metadata
                                let metadata = parameters.getParameterMetadata(forParameter: "FIR Coverage Duration (s)")
                                Slider(
                                    value: $parameters.analysisFIRCoverage,
                                    in: metadata.minValue...metadata.maxValue,
                                    step: metadata.step
                                )
                                .onChange(of: parameters.analysisFIRCoverage) { _, _ in
                                    onParameterChanged()
                                    onForceRefresh() // Force immediate refresh
                                }
                                
                                // Text field for precise input
                                TextField("", value: $parameters.analysisFIRCoverage, format: .number)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 70)
                                    .padding(6)
                                    .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .onSubmit { 
                                        onParameterChanged() 
                                        onForceRefresh() // Force immediate refresh
                                    }
                                
                                // Reset button - to the right of the text field
                                Button(action: {
                                    parameters.analysisFIRCoverage = parameters.getParameterMetadata(forParameter: "FIR Coverage Duration (s)").defaultValue
                                    onParameterChanged()
                                    onForceRefresh()
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 12))
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Reset to default value")
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // FIR Response Method Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FIR Response Method")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                
                            Picker("", selection: $parameters.analysisFIRResponseMethod) {
                                ForEach(FIRResponseMethod.allCases, id: \.self) { method in
                                    Text(method.rawValue).tag(method)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: parameters.analysisFIRResponseMethod) { _, _ in
                                onParameterChanged()
                                onForceRefresh() // Force immediate refresh
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                        
                        // Time Window parameters (only show when Time Window method is selected)
                        if parameters.analysisFIRResponseMethod == .timeWindow {
                            VStack(alignment: .leading, spacing: 10) {
                                // Time Window Start with slider
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Window Start Time (s)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 12) {
                                        // Slider with range from 0 to coverage duration (without tick marks)
                                        Slider(
                                            value: $parameters.analysisFIRTimeWindowStart,
                                            in: 0...parameters.analysisFIRCoverage
                                        )
                                        .onChange(of: parameters.analysisFIRTimeWindowStart) { _, newValue in
                                            // Ensure start time is before end time
                                            if newValue >= parameters.analysisFIRTimeWindowEnd {
                                                parameters.analysisFIRTimeWindowEnd = min(newValue + 1.0, parameters.analysisFIRCoverage)
                                            }
                                            onParameterChanged()
                                            onForceRefresh() // Force immediate refresh
                                        }
                                        
                                        // Text field for precise input with one decimal place
                                        TextField("", value: $parameters.analysisFIRTimeWindowStart, format: .number.precision(.fractionLength(1)))
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 70)
                                            .padding(6)
                                            .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .onSubmit { 
                                                // Ensure start time is valid
                                                parameters.analysisFIRTimeWindowStart = max(0, min(parameters.analysisFIRTimeWindowStart, parameters.analysisFIRCoverage))
                                                // Ensure start time is before end time
                                                if parameters.analysisFIRTimeWindowStart >= parameters.analysisFIRTimeWindowEnd {
                                                    parameters.analysisFIRTimeWindowEnd = min(parameters.analysisFIRTimeWindowStart + 1.0, parameters.analysisFIRCoverage)
                                                }
                                                onParameterChanged() 
                                                onForceRefresh() // Force immediate refresh
                                            }
                                            
                                        // Reset button
                                        Button(action: {
                                            parameters.analysisFIRTimeWindowStart = parameters.getParameterMetadata(forParameter: "FIR Time Window Start (s)").defaultValue
                                            onParameterChanged()
                                            onForceRefresh()
                                        }) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.system(size: 12))
                                                .foregroundColor(.accentColor)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .help("Reset to default value")
                                    }
                                }
                                .padding(.vertical, 4)
                                
                                // Time Window End with slider
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Window End Time (s)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 12) {
                                        // Slider with range from start to coverage duration (without tick marks)
                                        Slider(
                                            value: $parameters.analysisFIRTimeWindowEnd,
                                            in: (parameters.analysisFIRTimeWindowStart + 1.0)...parameters.analysisFIRCoverage
                                        )
                                        .onChange(of: parameters.analysisFIRTimeWindowEnd) { _, _ in
                                            onParameterChanged()
                                            onForceRefresh() // Force immediate refresh
                                        }
                                        
                                        // Text field for precise input with one decimal place
                                        TextField("", value: $parameters.analysisFIRTimeWindowEnd, format: .number.precision(.fractionLength(1)))
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 70)
                                            .padding(6)
                                            .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .onSubmit { 
                                                // Ensure end time is valid
                                                parameters.analysisFIRTimeWindowEnd = max(parameters.analysisFIRTimeWindowStart + 1.0, min(parameters.analysisFIRTimeWindowEnd, parameters.analysisFIRCoverage))
                                                onParameterChanged() 
                                                onForceRefresh() // Force immediate refresh
                                            }
                                            
                                        // Reset button
                                        Button(action: {
                                            parameters.analysisFIRTimeWindowEnd = parameters.getParameterMetadata(forParameter: "FIR Time Window End (s)").defaultValue
                                            // Ensure end time is after start time
                                            if parameters.analysisFIRTimeWindowEnd <= parameters.analysisFIRTimeWindowStart {
                                                parameters.analysisFIRTimeWindowStart = max(0, parameters.analysisFIRTimeWindowEnd - 30.0)
                                            }
                                            onParameterChanged()
                                            onForceRefresh()
                                        }) {
                                            Image(systemName: "arrow.counterclockwise")
                                                .font(.system(size: 12))
                                                .foregroundColor(.accentColor)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .help("Reset to default value")
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Information about FIR model
                        Text("The FIR model uses separate regressors for each time point after stimulus onset, allowing flexible modeling of the hemodynamic response shape. The coverage duration determines how far the model extends after stimulus onset. The response method controls how the overall response magnitude is calculated from individual FIR coefficients.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
    
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
            VStack(spacing: 16) {
                // Results card - more compact, well-aligned view
                VStack(spacing: 0) {
                    // Header with accent color background
                    HStack {
                        Text("Model Fit Results")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.accentColor)
                    
                    // Results table
                    VStack(spacing: 0) {
                        // Headers
                        HStack(alignment: .firstTextBaseline) {
                            Text("Parameter")
                                .frame(minWidth: 80, idealWidth: 120, maxWidth: 150, alignment: .leading)
                            Spacer()
                            Text("Estimated")
                                .frame(width: 80, alignment: .trailing)
                            Text("True Value")
                                .frame(width: 80, alignment: .trailing)
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(white: colorScheme == .dark ? 0.2 : 0.95))
                        
                        Divider()
                        
                        // Percent Change row
                        HStack(alignment: .firstTextBaseline) {
                            Text("BOLD % Change")
                                .font(.subheadline)
                                .frame(minWidth: 80, idealWidth: 120, maxWidth: 150, alignment: .leading)
                            Spacer()
                            Text(String(format: "%.2f%%", simulationData.percentChangeMetric))
                                .foregroundColor(.primary)
                                .frame(width: 80, alignment: .trailing)
                            Text(String(format: "%.2f%%", 
                                       (parameters.mriResponseAmplitude / parameters.mriBaselineSignal) * 100.0))
                                .foregroundColor(.green)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(white: colorScheme == .dark ? 0.15 : 1.0))
                        
                        // Only show FIR Response Magnitude row if using FIR model
                        if parameters.analysisModelType == .fir {
                            Divider()
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text("FIR Response")
                                    .font(.subheadline)
                                    .frame(minWidth: 80, idealWidth: 120, maxWidth: 150, alignment: .leading)
                                Spacer()
                                Text(String(format: "%.2f", simulationData.firResponseMagnitude))
                                    .foregroundColor(.primary)
                                    .frame(width: 80, alignment: .trailing)
                                Text(String(format: "%.2f", parameters.mriResponseAmplitude))
                                    .foregroundColor(.green)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(white: colorScheme == .dark ? 0.17 : 0.97))
                        }
                        
                        // Model parameter rows
                        ForEach(Array(simulationData.betaParams.enumerated()), id: \.offset) { index, value in
                            Divider()
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text(betaParamName(index: index))
                                    .font(.subheadline)
                                    .frame(minWidth: 80, idealWidth: 120, maxWidth: 150, alignment: .leading)
                                Spacer()
                                Text(String(format: "%.2f", value))
                                    .foregroundColor(.primary)
                                    .frame(width: 80, alignment: .trailing)
                                // Get the true value based on parameter type
                                Group {
                                    if parameters.analysisModelType == .fir {
                                        // For FIR model, handle differently
                                        let paramName = betaParamName(index: index)
                                        
                                        if paramName.hasPrefix("FIR") {
                                            // For FIR beta parameters, show placeholder
                                            // because there's no single "true" value for each FIR regressor
                                            Text("-")
                                                .foregroundColor(.secondary.opacity(0.5))
                                                
                                        } else if paramName == "Constant Term" {
                                            // Constant term (baseline)
                                            Text(String(format: "%.2f", parameters.mriBaselineSignal))
                                                .foregroundColor(.green)
                                                
                                        } else if paramName == "Linear Drift" && parameters.enableMRIDrift {
                                            // Linear drift
                                            let trueLinearDrift = parameters.mriLinearDrift * parameters.mriBaselineSignal / 100.0
                                            Text(String(format: "%.2f", trueLinearDrift))
                                                .foregroundColor(.green)
                                                
                                        } else if paramName == "Quadratic Drift" && parameters.enableMRIDrift {
                                            // Quadratic drift
                                            let trueQuadDrift = parameters.mriQuadraticDrift * parameters.mriBaselineSignal / 100.0
                                            Text(String(format: "%.2f", trueQuadDrift))
                                                .foregroundColor(.green)
                                                
                                        } else if paramName == "Cubic Drift" && parameters.enableMRIDrift {
                                            // Cubic drift
                                            let trueCubicDrift = parameters.mriCubicDrift * parameters.mriBaselineSignal / 100.0
                                            Text(String(format: "%.2f", trueCubicDrift))
                                                .foregroundColor(.green)
                                                
                                        } else {
                                            // For other parameters, just use a placeholder
                                            Text("-")
                                                .foregroundColor(.secondary.opacity(0.5))
                                        }
                                    } else {
                                        // For non-FIR models, use the original logic
                                        if index == 0 {
                                            // Stimulus response
                                            Text(String(format: "%.2f", parameters.mriResponseAmplitude))
                                                .foregroundColor(.green)
                                        } else if index == 1 && parameters.includeConstantTerm {
                                            // Constant term (baseline)
                                            Text(String(format: "%.2f", parameters.mriBaselineSignal))
                                                .foregroundColor(.green)
                                        } else if parameters.enableMRIDrift && parameters.includeLinearTerm && 
                                                 betaParamName(index: index) == "Linear Drift" {
                                            // Linear drift
                                            let trueLinearDrift = parameters.mriLinearDrift * parameters.mriBaselineSignal / 100.0
                                            Text(String(format: "%.2f", trueLinearDrift))
                                                .foregroundColor(.green)
                                        } else if parameters.enableMRIDrift && parameters.includeQuadraticTerm && 
                                                 betaParamName(index: index) == "Quadratic Drift" {
                                            // Quadratic drift
                                            let trueQuadDrift = parameters.mriQuadraticDrift * parameters.mriBaselineSignal / 100.0
                                            Text(String(format: "%.2f", trueQuadDrift))
                                                .foregroundColor(.green)
                                        } else if parameters.enableMRIDrift && parameters.includeCubicTerm && 
                                                 betaParamName(index: index) == "Cubic Drift" {
                                            // Cubic drift
                                            let trueCubicDrift = parameters.mriCubicDrift * parameters.mriBaselineSignal / 100.0
                                            Text(String(format: "%.2f", trueCubicDrift))
                                                .foregroundColor(.green)
                                        } else {
                                            // For other parameters, just use a placeholder to maintain alignment
                                            Text("-")
                                                .foregroundColor(.secondary.opacity(0.5))
                                        }
                                    }
                                }
                                .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(index % 2 == 0 ? 
                                    Color(white: colorScheme == .dark ? 0.17 : 0.97) : 
                                    Color(white: colorScheme == .dark ? 0.15 : 1.0))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
                .id("modelResults-\(parameters.includeConstantTerm)-\(parameters.includeLinearTerm)-\(parameters.includeQuadraticTerm)-\(parameters.includeCubicTerm)-\(parameters.analysisModelTypeString)-\(parameters.analysisRiseTimeConstant)-\(parameters.analysisFallTimeConstant)-\(parameters.analysisFIRCoverage)-\(parameters.analysisFIRResponseMethodString)-\(simulationData.percentChangeMetric)")
                
                // Model Information tooltip
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note: Green values show the true parameters from the simulation.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                // SNR and CNR card
                VStack(spacing: 0) {
                    // Header with accent color background
                    HStack {
                        Text("Signal & Contrast Metrics")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.accentColor)
                    
                    // SNR and CNR metrics table
                    VStack(spacing: 0) {
                        // Headers
                        HStack(alignment: .firstTextBaseline) {
                            Text("Metric")
                                .frame(minWidth: 80, idealWidth: 120, maxWidth: 150, alignment: .leading)
                            Spacer()
                            Text("Value")
                                .frame(width: 80, alignment: .trailing)
                            Text("Units")
                                .frame(width: 80, alignment: .trailing)
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(white: colorScheme == .dark ? 0.2 : 0.95))
                        
                        Divider()
                        
                        // SNR row
                        HStack(alignment: .firstTextBaseline) {
                            Text("Signal-to-Noise")
                                .font(.subheadline)
                                .frame(minWidth: 80, idealWidth: 120, maxWidth: 150, alignment: .leading)
                            Spacer()
                            Text(String(format: "%.2f", simulationData.signalToNoiseRatio))
                                .foregroundColor(.primary)
                                .frame(width: 80, alignment: .trailing)
                            Text("ratio")
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(white: colorScheme == .dark ? 0.17 : 0.97))
                        
                        Divider()
                        
                        // CNR row
                        HStack(alignment: .firstTextBaseline) {
                            Text("Contrast-to-Noise")
                                .font(.subheadline)
                                .frame(minWidth: 80, idealWidth: 120, maxWidth: 150, alignment: .leading)
                            Spacer()
                            Text(String(format: "%.2f", simulationData.contrastToNoiseRatio))
                                .foregroundColor(.primary)
                                .frame(width: 80, alignment: .trailing)
                            Text("ratio")
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(white: colorScheme == .dark ? 0.15 : 1.0))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
                .id("snrCnrMetrics-\(parameters.includeConstantTerm)-\(parameters.includeLinearTerm)-\(parameters.includeQuadraticTerm)-\(parameters.includeCubicTerm)-\(parameters.analysisModelTypeString)-\(parameters.analysisFIRCoverage)-\(simulationData.signalToNoiseRatio)-\(simulationData.contrastToNoiseRatio)")
                
                // SNR and CNR information tooltip
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SNR = Signal/Noise, CNR = Contrast/Noise, where Noise is the RMS of residual error.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }
    
    // Alternate approach for macOS without UIKit dependencies
    private var headerBackground: some View {
        VStack(spacing: 0) {
            Color.accentColor
                .frame(height: 8)
            Color.clear
        }
    }
    
    // Using ToggleButton instead of individual Toggle components
    
    private func betaParamName(index: Int) -> String {
        // For FIR model, handle differently since there are multiple response regressors
        if parameters.analysisModelType == .fir {
            // Calculate the number of FIR regressors
            let samplesPerSecond = 1.0 / parameters.mriSamplingInterval
            let samplesInCoverage = Int(parameters.analysisFIRCoverage * samplesPerSecond)
            
            // Check if this index corresponds to a FIR regressor
            if index < samplesInCoverage {
                // This is a FIR regressor
                let timeOffset = Double(index) * parameters.mriSamplingInterval
                return String(format: "FIR %.1fs", timeOffset)
            }
            
            // Offset the index to account for multiple FIR regressors
            let adjustedIndex = index - samplesInCoverage
            
            // Handle other parameters (constant, drift terms)
            let driftTerms = ["Constant Term", "Linear Drift", "Quadratic Drift", "Cubic Drift"]
            let includedDriftTerms = [
                parameters.includeConstantTerm,
                parameters.includeLinearTerm,
                parameters.includeQuadraticTerm,
                parameters.includeCubicTerm
            ]
            
            // Count through included drift terms to find the right one
            var driftTermIndex = -1
            var trueCount = -1
            
            for i in 0..<includedDriftTerms.count {
                if includedDriftTerms[i] {
                    trueCount += 1
                    if trueCount == adjustedIndex {
                        driftTermIndex = i
                        break
                    }
                }
            }
            
            // Return the appropriate drift term name if found
            if driftTermIndex >= 0 && driftTermIndex < driftTerms.count {
                return driftTerms[driftTermIndex]
            }
            
            // Fallback for any other parameters
            return "Parameter \(index)"
        } else {
            // For non-FIR models, use the original approach
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
    }
    
    // MARK: - Helper methods
    
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
