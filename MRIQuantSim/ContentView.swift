//
//  ContentView.swift
//  MRIQuantSim
//
//  Created by Rick Hoge on 2025-04-10.
//

import SwiftUI
import SwiftData
import Charts

// Central simulator class to handle all updates
class SimulationController: ObservableObject {
    @Published var parameters = SimulationParameters()
    @Published var simulationData = SimulationData()
    @Published var viewRefreshTrigger = 0 // Increment this to force view refreshes
    
    // Property to track initialization state
    private var isInitialized = false
    
    init() {
        // Defer data generation until view appears
        // This avoids potential crashes during init
    }
    
    func updateSimulation(regenerateNoise: Bool = false) {
        // Safety check to prevent crashes - ensure object is fully initialized
        if !isInitialized {
            isInitialized = true
        }
        
        // Reset and regenerate all data
        simulationData.generateSimulatedData(parameters: parameters, regenerateNoise: regenerateNoise)
        
        // Update parameter state cache after a full simulation update
        previousParamState = parameters.getParameterState()
        
        // Explicitly notify observers of change
        objectWillChange.send()
    }
    
    // Update when any parameter changes
    func parameterChanged() {
        // Get current parameter state
        let currentState = parameters.getParameterState()
        
        if let previousState = previousParamState {
            // Check specifically for changes in model terms (detrending components)
            let modelTermsChanged = currentState.modelTermsChangedFrom(previous: previousState)
            
            // Check if only the MRI noise amplitude changed
            let onlyMRINoiseAmplitudeChanged = currentState.onlyNoiseAmplitudeChangedFrom(previous: previousState)
            
            // Check if only CO2 variance parameters changed
            let onlyCO2VarianceChanged = currentState.onlyCO2VarianceParamsChangedFrom(previous: previousState)
            
            // Check if response shape parameters have changed
            let responseShapeChanged = 
                previousState.responseShapeTypeString != currentState.responseShapeTypeString ||
                previousState.responseRiseTimeConstant != currentState.responseRiseTimeConstant ||
                previousState.responseFallTimeConstant != currentState.responseFallTimeConstant
                
            // Check if analysis model parameters have changed
            let analysisModelChanged =
                previousState.analysisModelTypeString != currentState.analysisModelTypeString ||
                previousState.analysisRiseTimeConstant != currentState.analysisRiseTimeConstant ||
                previousState.analysisFallTimeConstant != currentState.analysisFallTimeConstant
            
            print("Parameter change detected:")
            print("  - MRI noise amplitude: \(previousState.mriNoiseAmplitude) -> \(currentState.mriNoiseAmplitude)")
            print("  - CO₂ variance: \(previousState.enableCO2Variance) -> \(currentState.enableCO2Variance)")
            print("  - CO₂ variance frequency: \(previousState.co2VarianceFrequency) -> \(currentState.co2VarianceFrequency)")
            print("  - CO₂ frequency variance: \(previousState.co2VarianceAmplitude) -> \(currentState.co2VarianceAmplitude)")
            print("  - CO₂ amplitude variance: \(previousState.co2AmplitudeVariance) -> \(currentState.co2AmplitudeVariance)")
            print("  - Response shape: \(previousState.responseShapeTypeString) -> \(currentState.responseShapeTypeString)")
            print("  - Response time constants: \(previousState.responseRiseTimeConstant)/\(previousState.responseFallTimeConstant) -> \(currentState.responseRiseTimeConstant)/\(currentState.responseFallTimeConstant)")
            print("  - Model terms changed: \(modelTermsChanged)")
            print("  - Only MRI amplitude changed: \(onlyMRINoiseAmplitudeChanged)")
            print("  - Only CO₂ variance changed: \(onlyCO2VarianceChanged)")
            print("  - Response shape changed: \(responseShapeChanged)")
            print("  - Analysis model changed: \(analysisModelChanged)")
            
            if modelTermsChanged {
                print("Model terms changed, updating analysis and model fit")
                
                // First regenerate the block patterns which may depend on the model terms
                simulationData.generateBlockPatterns(parameters: parameters)
                
                // Then perform model analysis with current parameters
                simulationData.performModelAnalysis(parameters: parameters)
                
                // Force a view refresh by incrementing the trigger
                viewRefreshTrigger += 1
                print("Incremented view refresh trigger to \(viewRefreshTrigger) due to model terms change")
                
                // Update previous parameter state
                previousParamState = currentState
                
                // Notify observers of the change
                objectWillChange.send()
                return
            }
            else if onlyMRINoiseAmplitudeChanged {
                print("Updating with same MRI noise pattern, new amplitude: \(parameters.mriNoiseAmplitude)")
                // Just update MRI signal with the same noise pattern but new amplitude
                simulationData.updateMRISignalWithSameNoisePattern(parameters: parameters)
                
                // Update previousState to current values
                previousParamState = currentState
                return
            }
            else if onlyCO2VarianceChanged {
                print("CO₂ variance changed, regenerating CO₂ signal only")
                // Only regenerate the CO2 signal
                simulationData.updateCO2SignalOnly(parameters: parameters)
                
                // Force a view refresh by incrementing the trigger
                viewRefreshTrigger += 1
                print("Incremented view refresh trigger to \(viewRefreshTrigger)")
                
                // Update previousState to current values
                previousParamState = currentState
                return
            }
            else if responseShapeChanged {
                print("Response shape parameters changed, regenerating full simulation")
                // Generate a full simulation update since response shape affects both CO2 and MRI
                updateSimulation(regenerateNoise: false)
                
                // Update previousState to current values
                previousParamState = currentState
                return
            }
            else if analysisModelChanged {
                print("Analysis model parameters changed, regenerating model analysis only")
                // Only need to regenerate block patterns and rerun the model analysis
                // This doesn't require regenerating the raw signal data
                simulationData.generateBlockPatterns(parameters: parameters)
                simulationData.performModelAnalysis(parameters: parameters)
                
                // Force a view refresh by incrementing the trigger
                viewRefreshTrigger += 1
                print("Incremented view refresh trigger to \(viewRefreshTrigger) due to analysis model change")
                
                // Update previousState to current values
                previousParamState = currentState
                return
            }
        }
        
        // For any other parameter changes, do a full update
        updateSimulation(regenerateNoise: false)
        
        // Store current state for future comparison
        previousParamState = currentState
    }
    
    // Keep track of previous parameter state to detect amplitude-only changes
    private var previousParamState: ParameterState?
    
    // Method specifically for regenerating MRI noise
    func regenerateMRINoise() {
        simulationData.regenerateMRINoise(parameters: parameters)
        
        // Update parameter state after regeneration
        previousParamState = parameters.getParameterState()
        
        // Force UI refresh
        viewRefreshTrigger += 1
        objectWillChange.send()
    }
    
    // Method specifically for randomizing CO2 variance phase
    func randomizeCO2VariancePhase() {
        simulationData.randomizeCO2VariancePhase(parameters: parameters)
        
        // Update parameter state after regeneration
        previousParamState = parameters.getParameterState()
        
        // Force UI refresh
        viewRefreshTrigger += 1
        objectWillChange.send()
    }
    
    // Method to explicitly force view refresh without parameter change
    func forceViewRefresh() {
        viewRefreshTrigger += 1
        objectWillChange.send()
    }
    
    // No longer needed since we're using the trigger approach
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedParameters: [SimulationParameters]
    
    // Accept the simulator as a parameter rather than creating it locally
    @ObservedObject var simulator: SimulationController
    @State private var selectedTab = 0
    // Add a computed property to create a model state ID string for view refreshing
    private var modelStateId: String {
        // Include all relevant model parameters to force redraw when they change
        return "modelState-\(simulator.viewRefreshTrigger)-\(simulator.parameters.includeConstantTerm)-\(simulator.parameters.includeLinearTerm)-\(simulator.parameters.includeQuadraticTerm)-\(simulator.parameters.includeCubicTerm)"
    }
    
    // No need for state variable with fixed constraints
    
    var body: some View {
        // Use HSplitView for a side-by-side layout with graphs on left, controls on right
        HSplitView {
            // LEFT SECTION: Graphs container
            VStack(spacing: 12) {
                // CO2 Graph
                SignalGraphView(
                    title: "CO₂ Partial Pressure",
                    xLabel: "Time (s)",
                    yLabel: "pCO₂ (mmHg)",
                    dataSeries: getCO2Series(),
                    yRange: 0...50
                )
                .padding(.top, 12)
                .id("co2Graph-\(simulator.viewRefreshTrigger)") // Force redraw when trigger changes
                
                // MRI Graph
                VStack {
                    // Important: Create a custom view to wrap the graph that ONLY depends on 
                    // the specific state needed for rendering - this forces a redraw
                    // when these values change
                    let _ = (
                        simulator.viewRefreshTrigger,
                        simulator.parameters.includeConstantTerm,
                        simulator.parameters.includeLinearTerm, 
                        simulator.parameters.includeQuadraticTerm,
                        simulator.parameters.includeCubicTerm
                    )
                    
                    SignalGraphView(
                        title: "MRI Signal",
                        xLabel: "Time (s)",
                        yLabel: "Signal (a.u.)",
                        dataSeries: getMRISeries(),
                        yRange: getMRIYRange()
                    )
                }
                
                // Parameter comparison chart (only show when model is visible)
                parameterComparisonView
            }
            .padding(.horizontal)
            .frame(minWidth: 500)
            .background(Color(NSColor.textBackgroundColor))
            
            // RIGHT SECTION: Parameters, Display and Analysis Tabs
            VStack {
                TabView(selection: $selectedTab) {
                    ParametersTabView(
                        parameters: $simulator.parameters,
                        onParameterChanged: simulator.parameterChanged,
                        onRegenerateNoise: simulator.regenerateMRINoise,
                        onRandomizeCO2VariancePhase: simulator.randomizeCO2VariancePhase
                    )
                    .tabItem {
                        Label("Signal", systemImage: "waveform")
                    }
                    .tag(0)
                    
                    AnalysisTabView(
                        parameters: $simulator.parameters,
                        simulationData: simulator.simulationData,
                        onParameterChanged: simulator.parameterChanged,
                        onRegenerateNoise: simulator.regenerateMRINoise,
                        onForceRefresh: simulator.forceViewRefresh
                    )
                    .tabItem {
                        Label("Analysis", systemImage: "chart.bar")
                    }
                    .tag(1)
                    
                    DisplayTabView(
                        parameters: $simulator.parameters,
                        onParameterChanged: simulator.parameterChanged,
                        onForceRefresh: simulator.forceViewRefresh
                    )
                    .tabItem {
                        Label("Display", systemImage: "display")
                    }
                    .tag(2)
                }
            }
            .frame(minWidth: 280, maxWidth: 400)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .padding(20)
        .onAppear {
            // Delay just slightly to ensure view is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Load parameters if available, otherwise use defaults
                if let savedParams = savedParameters.first {
                    simulator.parameters = savedParams
                }
                
                // Save parameters if none exist
                if savedParameters.isEmpty {
                    modelContext.insert(simulator.parameters)
                }
                
                // Generate simulation data after view has appeared
                simulator.updateSimulation()
            }
        }
    }
    
    private func getMRISeries() -> [TimeSeriesData] {
        // Get all MRI series with visibility determined by parameters
        
        // DEBUG: Log model params state to help debug the issue
        print("getMRISeries called. Model terms:")
        print("  - Constant: \(simulator.parameters.includeConstantTerm)")
        print("  - Linear: \(simulator.parameters.includeLinearTerm)")
        print("  - Quadratic: \(simulator.parameters.includeQuadraticTerm)")
        print("  - Cubic: \(simulator.parameters.includeCubicTerm)")
        
        // Check if any series data is needed - this will force a refresh
        _ = simulator.simulationData.betaParams
        
        // Get all visible MRI series data
        let result = simulator.simulationData.getMRISeriesData(parameters: simulator.parameters)
        
        // DEBUG: Log the returned series to verify model overlay is included
        print("MRI Series count: \(result.count)")
        for series in result {
            print("  - \(series.title): visible=\(series.isVisible), \(series.yValues.count) values")
        }
        
        return result
    }
    
    private func getCO2Series() -> [TimeSeriesData] {
        // Get all CO2 series with visibility determined by parameters
        return simulator.simulationData.getCO2SeriesData(parameters: simulator.parameters)
    }
    
    // Get the parameter labels for the bar chart
    private func getParameterBarLabels() -> [String] {
        let params = simulator.parameters
        let simData = simulator.simulationData
        
        // If no model results, return empty array
        if simData.betaParams.isEmpty || !params.showModelOverlay {
            return []
        }
        
        // Get the parameter names directly - these already reflect what's in the model
        // This ensures consistency between labels and displayed values
        let (paramNames, _, _) = prepareParameterData()
        
        // Convert parameter names for nicer display
        let labels = paramNames.map { name -> String in
            switch name {
            case "BOLD % Change": return "% Change"
            case "Response": return "Response"
            case "Baseline": return "Baseline"
            case "Linear": return "Linear"
            case "Quadratic": return "Quadratic"
            case "Cubic": return "Cubic"
            default: return name
            }
        }
        
        return labels
    }
    
    // Create data series for parameter comparison bar chart
    private func getParameterComparisonSeries() -> [TimeSeriesData] {
        let params = simulator.parameters
        let simData = simulator.simulationData
        
        // Only include this chart if we have model results
        if simData.betaParams.isEmpty || !params.showModelOverlay {
            return []
        }
        
        // Get parameter information
        let (paramNames, estimatedValues, trueValues) = prepareParameterData()
        
        // Create the series data array with the processed values
        var seriesData: [TimeSeriesData] = []
        
        // Create estimated values series
        let xValues = paramNames.indices.map { Double($0) }
        
        // Estimated values series
        seriesData.append(createSeriesData(
            title: "Estimated Values",
            xValues: xValues,
            yValues: estimatedValues,
            color: .blue
        ))
        
        // True values series
        seriesData.append(createSeriesData(
            title: "True Values",
            xValues: xValues,
            yValues: trueValues,
            color: .green
        ))
        
        return seriesData
    }
    
    // Helper to create a TimeSeriesData instance with common defaults
    private func createSeriesData(
        title: String,
        xValues: [Double],
        yValues: [Double],
        color: Color
    ) -> TimeSeriesData {
        return TimeSeriesData(
            title: title,
            xValues: xValues,
            yValues: yValues,
            color: color,
            showPoints: true,
            isVisible: true,
            lineWidth: 1.5,
            symbolSize: 30
        )
    }
    
    // Helper function to calculate the parameter data values
    private func prepareParameterData() -> (paramNames: [String], estimated: [Double], true: [Double]) {
        let params = simulator.parameters
        let simData = simulator.simulationData
        
        // Parameter names and values
        var paramNames: [String] = []
        var estimatedValues: [Double] = []
        var trueValues: [Double] = []
        
        // Only proceed if we have beta parameters to work with
        if simData.betaParams.isEmpty {
            return ([], [], [])
        }
        
        // Add percent change as first parameter - always show this
        paramNames.append("BOLD % Change")
        estimatedValues.append(simData.percentChangeMetric)
        trueValues.append((params.mriResponseAmplitude / params.mriBaselineSignal) * 100.0)
        
        // Determine which terms are actually included in the model
        // IMPORTANT: We only include terms that are actually included in the estimation model
        var estimationIncludedTerms = [Bool]()
        
        // Response is always included as first parameter in the design matrix
        estimationIncludedTerms.append(true)
        
        // Add other terms only if included in the model
        estimationIncludedTerms.append(params.includeConstantTerm && !params.excludeBaselineFromChart)
        estimationIncludedTerms.append(params.includeLinearTerm)
        estimationIncludedTerms.append(params.includeQuadraticTerm)
        estimationIncludedTerms.append(params.includeCubicTerm)
        
        let allTerms = ["Response", "Baseline", "Linear", "Quadratic", "Cubic"]
        
        // Add parameters for each included term
        addParametersBasedOnDesignMatrix(
            includedTerms: estimationIncludedTerms,
            termNames: allTerms,
            paramNames: &paramNames,
            estimatedValues: &estimatedValues,
            trueValues: &trueValues
        )
        
        return (paramNames, estimatedValues, trueValues)
    }
    
    // Add parameters based on the design matrix ordering
    private func addParametersBasedOnDesignMatrix(
        includedTerms: [Bool],
        termNames: [String],
        paramNames: inout [String],
        estimatedValues: inout [Double],
        trueValues: inout [Double]
    ) {
        let params = simulator.parameters
        let simData = simulator.simulationData
        
        // Print all beta parameters for debugging
        print("Debug: Beta parameters: \(simData.betaParams)")
        print("Debug: Included terms: \(includedTerms)")
        
        // Let's directly create the mapping according to the order in the design matrix
        var designMatrixOrder = [0] // Always start with Response as the first term
        
        // Add the order of terms based on which ones are included
        if params.includeConstantTerm { designMatrixOrder.append(1) } // Baseline
        if params.includeLinearTerm { designMatrixOrder.append(2) }   // Linear
        if params.includeQuadraticTerm { designMatrixOrder.append(3) } // Quadratic
        if params.includeCubicTerm { designMatrixOrder.append(4) }    // Cubic
        
        print("Debug: Design matrix order: \(designMatrixOrder)")
        
        // Now process only the terms that are included in our display (based on includedTerms)
        let displayOrder = (0..<includedTerms.count).filter { includedTerms[$0] }
        print("Debug: Display order: \(displayOrder)")
        
        // For each term to display, find its corresponding beta parameter
        for displayIndex in displayOrder {
            // Find the position in the design matrix order for this display term
            if let betaIndex = designMatrixOrder.firstIndex(of: displayIndex),
               betaIndex < simData.betaParams.count {
                
                // Add parameter name
                paramNames.append(termNames[displayIndex])
                
                print("Debug: Adding term \(termNames[displayIndex]) with beta \(betaIndex): \(simData.betaParams[betaIndex])")
                
                // Add estimated value from the correct beta parameter
                estimatedValues.append(simData.betaParams[betaIndex])
                
                // Add corresponding true value
                switch displayIndex {
                case 0: // Response
                    trueValues.append(params.mriResponseAmplitude)
                case 1: // Baseline
                    trueValues.append(params.mriBaselineSignal)
                case 2: // Linear Drift
                    let trueLinearDrift = params.mriLinearDrift * params.mriBaselineSignal / 100.0
                    trueValues.append(params.enableMRIDrift ? trueLinearDrift : 0)
                case 3: // Quadratic Drift
                    let trueQuadDrift = params.mriQuadraticDrift * params.mriBaselineSignal / 100.0
                    trueValues.append(params.enableMRIDrift ? trueQuadDrift : 0)
                case 4: // Cubic Drift
                    let trueCubicDrift = params.mriCubicDrift * params.mriBaselineSignal / 100.0
                    trueValues.append(params.enableMRIDrift ? trueCubicDrift : 0)
                default:
                    trueValues.append(0)
                }
            }
        }
    }
    
    // Get the Y range for the parameter comparison chart - this is kept for reference
    // but not used anymore as we now use per-parameter scaling in singleParameterChart
    private func calculateGlobalYRange() -> ClosedRange<Double>? {
        // Get all parameter data
        let paramData = getParameterData()
        
        // If no parameters, use default range
        if paramData.isEmpty {
            return 0...100
        }
        
        // Collect all values
        var allValues: [Double] = []
        for data in paramData {
            allValues.append(data.estimatedValue)
            allValues.append(data.trueValue)
        }
        
        // Find min and max, with safety fallbacks
        let min = allValues.min() ?? 0.0
        let max = allValues.max() ?? 100.0
        
        // Add some padding
        let range = max - min
        let paddedMin = min < 0 ? min * 1.1 : min * 0.9
        let paddedMax = max * 1.1
        
        // Ensure we don't end up with zero range
        if range < 0.001 {
            return (max - 0.5)...(max + 0.5)
        }
        
        return paddedMin...paddedMax
    }
    
    private func getMRIYRange() -> ClosedRange<Double>? {
        // Always provide a default range as fallback
        let baseline = simulator.parameters.mriBaselineSignal
        let defaultRange = (0.0 - 5.0)...(baseline + 50.0)
        
        // Get all series that will be displayed
        let series = getMRISeries().filter { $0.isVisible }
        
        // Safety check - ensure we have data
        if series.isEmpty {
            return defaultRange
        }
        
        // Find min and max across all displayed signals
        var allValues: [Double] = []
        
        for dataSeries in series {
            allValues.append(contentsOf: dataSeries.yValues)
        }
        
        if allValues.isEmpty {
            return defaultRange
        }
        
        // Get actual min and max of the data
        let actualMin = allValues.min() ?? 0.0
        let actualMax = allValues.max() ?? (baseline + 50.0)
        
        // Ensure range is not too small
        if actualMax - actualMin < 1.0 {
            return defaultRange
        }
        
        // Calculate buffer - 10% of the range or at least 5.0
        let bufferAmount = max((actualMax - actualMin) * 0.1, 5.0)
        
        // For dynamic range: use actual min and max with buffer
        if simulator.parameters.useMRIDynamicRange {
            return (actualMin - bufferAmount)...(actualMax + bufferAmount)
        } 
        // For fixed range: use zero as minimum and actual max
        else {
            // Use zero as the minimum (with small buffer below zero)
            let minBuffer = bufferAmount * 0.2 // smaller buffer below zero
            return (0.0 - minBuffer)...(actualMax + bufferAmount)
        }
    }
    
    // MARK: - Parameter Comparison View
    private var parameterComparisonView: some View {
        Group {
            if simulator.parameters.showModelOverlay && !simulator.simulationData.betaParams.isEmpty {
                VStack {
                    // Force view refresh when any relevant state changes
                    let _ = (
                        simulator.viewRefreshTrigger,
                        simulator.parameters.includeConstantTerm,
                        simulator.parameters.includeLinearTerm, 
                        simulator.parameters.includeQuadraticTerm,
                        simulator.parameters.includeCubicTerm,
                        simulator.simulationData.signalToNoiseRatio,
                        simulator.simulationData.contrastToNoiseRatio
                    )
                    
                    parameterChartContent
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        .cornerRadius(10)
                }
            } else {
                Spacer()
                    .frame(height: 20) // Small spacer when comparison chart is hidden
            }
        }
    }
    
    // Further break down the chart view to reduce complexity
    private var parameterChartContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with title and legend
            VStack(alignment: .leading, spacing: 8) {
                Text("Parameter Comparison")
                    .font(.headline)
                
                // Legend
                HStack(spacing: 16) {
                    HStack {
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 12, height: 12)
                        Text("Estimated")
                            .font(.caption)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(Color.green.opacity(0.7))
                            .frame(width: 12, height: 12)
                        Text("True")
                            .font(.caption)
                    }
                }
            }
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Use GeometryReader to get available space and adjust layout accordingly
            GeometryReader { geometry in
                let parameters = getParameterData()
                let cardWidth: CGFloat = 115 // Width of each chart card (match the parameterCard width)
                let spacing: CGFloat = 12 // Spacing between cards
                let totalCardWidth = cardWidth * CGFloat(parameters.count) + spacing * CGFloat(max(0, parameters.count - 1))
                let availableWidth = geometry.size.width
                
                // If charts fit within available width, center them, otherwise make them scrollable
                Group {
                    if totalCardWidth <= availableWidth {
                        // Center the charts when they fit within available width
                        HStack(alignment: .top, spacing: spacing) {
                            Spacer(minLength: 0)
                            
                            ForEach(parameters) { paramData in
                                parameterCard(for: paramData)
                            }
                            
                            Spacer(minLength: 0)
                        }
                    } else {
                        // Make scrollable when there are too many charts to fit
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: spacing) {
                                ForEach(parameters) { paramData in
                                    parameterCard(for: paramData)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 190) // Ensure sufficient height for the chart area with the taller cards
        }
    }
    
    // Parameter data structure for individual charts
    struct ParameterData: Identifiable {
        var id = UUID()
        var name: String
        var estimatedValue: Double
        var trueValue: Double
        var showTrueValue: Bool = true
        
        // Default initializer with all parameters showing true values
        init(name: String, estimatedValue: Double, trueValue: Double) {
            self.name = name
            self.estimatedValue = estimatedValue
            self.trueValue = trueValue
            self.showTrueValue = true
        }
        
        // Initializer with option to hide true value (for SNR/CNR metrics)
        init(name: String, estimatedValue: Double, trueValue: Double, showTrueValue: Bool) {
            self.name = name
            self.estimatedValue = estimatedValue
            self.trueValue = trueValue
            self.showTrueValue = showTrueValue
        }
    }
    
    // Get parameter data as an array of individual parameter data points
    private func getParameterData() -> [ParameterData] {
        let params = simulator.parameters
        let simData = simulator.simulationData
        var result: [ParameterData] = []
        
        // Empty check
        if simData.betaParams.isEmpty || !params.showModelOverlay {
            return []
        }
        
        // Add SNR parameter first
        result.append(ParameterData(
            name: "SNR",
            estimatedValue: simData.signalToNoiseRatio,
            trueValue: 0.0, // No true value for SNR
            showTrueValue: false
        ))
        
        // Add CNR parameter second 
        result.append(ParameterData(
            name: "CNR",
            estimatedValue: simData.contrastToNoiseRatio,
            trueValue: 0.0, // No true value for CNR
            showTrueValue: false
        ))
        
        // Add percent change parameter third - this is calculated from other parameters
        result.append(ParameterData(
            name: "% Change",
            estimatedValue: simData.percentChangeMetric,
            trueValue: (params.mriResponseAmplitude / params.mriBaselineSignal) * 100.0
        ))
        
        // Build a mapping between design matrix positions and parameter indices
        // -----------------------------------------------------------------------
        // First, determine which terms are included in the design matrix
        // This must match the exact order used in SimulationData.performDetrendingAnalysis
        var designMatrixColumns: [(index: Int, name: String)] = []
        
        // Response (block pattern) is always first
        designMatrixColumns.append((0, "Response"))
        
        // The rest follow in fixed order IF they're included
        if params.includeConstantTerm {
            designMatrixColumns.append((designMatrixColumns.count, "Baseline"))
        }
        
        if params.includeLinearTerm {
            designMatrixColumns.append((designMatrixColumns.count, "Linear"))
        }
        
        if params.includeQuadraticTerm {
            designMatrixColumns.append((designMatrixColumns.count, "Quadratic"))
        }
        
        if params.includeCubicTerm {
            designMatrixColumns.append((designMatrixColumns.count, "Cubic"))
        }
        
        // Now create parameter data for each term in the design matrix
        for (index, name) in designMatrixColumns {
            // Skip if we're out of bounds in the beta parameters
            if index >= simData.betaParams.count {
                continue
            }
            
            // We now always show all parameters since each has its own mini-chart with proper scaling
            // The exclusion setting is no longer necessary, but we'll keep the code that respects it
            // to maintain backward compatibility with existing preferences
            if name == "Baseline" && params.excludeBaselineFromChart {
                continue
            }
            
            // Create the appropriate parameter data based on the term name
            switch name {
            case "Response":
                result.append(ParameterData(
                    name: "Response",
                    estimatedValue: simData.betaParams[index],
                    trueValue: params.mriResponseAmplitude
                ))
                
            case "Baseline":
                result.append(ParameterData(
                    name: "Baseline",
                    estimatedValue: simData.betaParams[index],
                    trueValue: params.mriBaselineSignal
                ))
                
            case "Linear":
                let trueLinearDrift = params.mriLinearDrift * params.mriBaselineSignal / 100.0
                result.append(ParameterData(
                    name: "Linear",
                    estimatedValue: simData.betaParams[index],
                    trueValue: params.enableMRIDrift ? trueLinearDrift : 0
                ))
                
            case "Quadratic":
                let trueQuadDrift = params.mriQuadraticDrift * params.mriBaselineSignal / 100.0
                result.append(ParameterData(
                    name: "Quadratic",
                    estimatedValue: simData.betaParams[index],
                    trueValue: params.enableMRIDrift ? trueQuadDrift : 0
                ))
                
            case "Cubic":
                let trueCubicDrift = params.mriCubicDrift * params.mriBaselineSignal / 100.0
                result.append(ParameterData(
                    name: "Cubic",
                    estimatedValue: simData.betaParams[index],
                    trueValue: params.enableMRIDrift ? trueCubicDrift : 0
                ))
                
            default:
                break
            }
        }
        
        return result
    }
    
    // Function for rendering charts with two types:
    // 1) Original comparison charts (for beta params)
    // 2) Single value charts (for SNR/CNR)
    private func singleParameterChart(data: ParameterData) -> AnyView {
        if !data.showTrueValue {
            // For SNR and CNR, use single-bar chart with no comparison
            return AnyView(singleValueChart(name: data.name, value: data.estimatedValue))
        } 
        
        // FOR COMPARISON PARAMETERS: Use the original chart implementation unchanged
        // Calculate a good y-range for this parameter
        let maxValue = max(data.estimatedValue, data.trueValue)
        let minValue = min(min(data.estimatedValue, data.trueValue), 0) // Include 0 if both values are positive
        let range = max(maxValue - minValue, 0.001) // Prevent division by zero
        
        // Add more padding to ensure values aren't clipped
        let paddedMax = maxValue + range * 0.15 // Add 15% padding at top
        let paddedMin = minValue < 0 ? minValue * 1.15 : 0 // More padding below zero or use zero as minimum
        
        return AnyView(
            Chart {
                // Estimated value bar
                BarMark(
                    x: .value("Type", 0), // Use 0 instead of "Est" for positioning
                    y: .value("Value", data.estimatedValue),
                    width: .fixed(30) // Set fixed width for consistent appearance
                )
                .foregroundStyle(Color.blue.opacity(0.7))
                .annotation(position: .top) {
                    if paddedMax - paddedMin > 5 { // Only show values for larger ranges
                        Text(String(format: "%.1f", data.estimatedValue))
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                    }
                }
                
                // True value bar
                BarMark(
                    x: .value("Type", 1), // Use 1 instead of "True" for positioning
                    y: .value("Value", data.trueValue),
                    width: .fixed(30) // Set fixed width for consistent appearance
                )
                .foregroundStyle(Color.green.opacity(0.7))
                .annotation(position: .top) {
                    if paddedMax - paddedMin > 5 { // Only show values for larger ranges
                        Text(String(format: "%.1f", data.trueValue))
                            .font(.system(size: 8))
                            .foregroundColor(.green)
                    }
                }
            }
            .chartYScale(domain: paddedMin...paddedMax)
            .chartYAxis {
                // Ensure we have enough axis marks for visibility
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel() {
                        // Only show value if it's a whole number
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.0f", doubleValue))
                                .font(.system(size: 8))
                        }
                    }
                }
            }
            .chartXAxis(.hidden) // Hide the X-axis labels completely
            .chartXScale(domain: -0.5...1.5) // Add some padding to x-axis for better bar spacing
            // Set chart size with enough room for axis labels
            .frame(height: 120)
            .padding(.horizontal, 4)
            .padding(.bottom, 8) // Extra padding at bottom to ensure Y-axis labels aren't clipped
        )
    }
    
    // Special chart for SNR and CNR that only shows one value
    private func singleValueChart(name: String, value: Double) -> some View {
        // Constants for thresholds
        let thresholdValue = 10000.0  // Consider values above this to be effectively infinite
        
        // Check if value is valid (positive and not too large)
        let isInfinite = !value.isFinite || value > thresholdValue
        let isValidValue = value > 0 && !isInfinite
        
        // Calculate appropriate y-scale for the metric
        let maxValue = isValidValue ? max(value * 1.2, 0.1) : 0.1
        
        // Use distinctive colors different from the blue/green of comparison charts
        let barColor = name == "SNR" ? Color.orange.opacity(0.7) : Color.teal.opacity(0.7)
        
        return Chart {
            // Only show bar if we have a valid value that's not too large
            if isValidValue {
                BarMark(
                    x: .value("Position", 0),
                    y: .value("Value", value),
                    width: .fixed(45) // Wider since there's only one bar
                )
                .foregroundStyle(barColor)
                .annotation(position: .top) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 9))
                        .foregroundColor(barColor)
                }
            }
        }
        .chartYScale(domain: 0...maxValue)
        .chartYAxis {
            // Only show axis labels if we have a valid value
            if isValidValue {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(String(format: "%.1f", val))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // Empty axis when value is invalid
                AxisMarks { _ in }
            }
        }
        .chartXAxis(.hidden)
        .chartXScale(domain: -0.5...0.5) // Add padding on X-axis for consistency
        // Set chart size with matching padding to comparison charts
        .frame(height: 120)
        .padding(.horizontal, 4)
        .padding(.bottom, 8) // Match the bottom padding of comparison charts
        .overlay(
            // Show appropriate text for different states
            Group {
                if isInfinite {
                    // Show infinity symbol for values above threshold
                    Text("∞")
                        .font(.system(size: 24))
                        .foregroundColor(barColor.opacity(0.8))
                } else if !isValidValue {
                    // Show N/A for invalid values
                    Text("N/A")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        )
    }
    
    // Helper to create a consistent card for each parameter
    private func parameterCard(for paramData: ParameterData) -> some View {
        VStack(alignment: .center, spacing: 6) {
            // Parameter name as title
            Text(paramData.name)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.top, 6)
            
            // Chart showing just this parameter
            singleParameterChart(data: paramData)
                .frame(width: 100)
                .padding(.bottom, 4) // Extra padding at bottom within the chart area
            
            // No legend below the chart - original design
        }
        .frame(width: 115, height: 160) // Explicit frame size with more height
        .background(Color(NSColor.textBackgroundColor).opacity(0.4))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.vertical, 2) // Slight padding to ensure shadow isn't clipped
    }
}
