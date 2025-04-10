//
//  SignalGraphView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI
import Charts

// Basic chart implementation to address Swift type-checking
struct SignalGraphView: View {
    let title: String
    let xLabel: String
    let yLabel: String
    let timePoints: [Double]
    let dataPoints: [Double]
    let showRawData: Bool
    let additionalTimeSeries: [(times: [Double], values: [Double], color: Color, showPoints: Bool)]?
    let yRange: ClosedRange<Double>?
    
    // Simple data type for chart points to avoid connecting lines
    struct ChartPoint: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double 
        let seriesIndex: Int
        let color: Color
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            // Create the chart
            createFinalChart()
                .frame(height: 200)
        }
        .padding()
    }
    
    // Create the final chart with all data
    private func createFinalChart() -> some View {
        // Construct data points to ensure separate, disconnected lines
        let allPoints = getAllDataPoints()
        let effectiveYRange = yRange ?? calculateYRange()
        
        // Create the basic chart
        return constructBasicChart(allPoints: allPoints)
            .chartYScale(domain: effectiveYRange)
            .chartXAxisLabel(xLabel)
            .chartYAxisLabel(yLabel)
    }
    
    // Create a basic chart with points
    private func constructBasicChart(allPoints: [ChartPoint]) -> some View {
        Chart {
            // Draw individual data points - simpler for type checking
            ForEach(allPoints) { point in
                if point.seriesIndex == -1 {
                    // Main data series (raw data)
                    LineMark(
                        x: .value("XMain", point.x),
                        y: .value("YMain", point.y)
                    )
                    .foregroundStyle(.blue)
                }
                else if point.seriesIndex >= 0 {
                    // Additional series with custom color
                    LineMark(
                        x: .value("X\(point.seriesIndex)", point.x),
                        y: .value("Y\(point.seriesIndex)", point.y)
                    )
                    .foregroundStyle(point.color)
                }
            }
        }
    }
    
    // Get all data points
    private func getAllDataPoints() -> [ChartPoint] {
        var points: [ChartPoint] = []
        
        // Add raw data points with series index -1
        if showRawData && !timePoints.isEmpty && !dataPoints.isEmpty {
            let count = min(timePoints.count, dataPoints.count)
            for i in 0..<count {
                points.append(ChartPoint(
                    x: timePoints[i],
                    y: dataPoints[i],
                    seriesIndex: -1,
                    color: .blue
                ))
            }
        }
        
        // Add additional series points with series index ≥ 0
        if let additionalSeries = additionalTimeSeries {
            for (idx, series) in additionalSeries.enumerated() {
                if !series.times.isEmpty && !series.values.isEmpty {
                    let count = min(series.times.count, series.values.count)
                    for i in 0..<count {
                        points.append(ChartPoint(
                            x: series.times[i],
                            y: series.values[i],
                            seriesIndex: idx,
                            color: series.color
                        ))
                    }
                }
            }
        }
        
        return points
    }
    
    // Calculate a sensible y-range if none provided
    private func calculateYRange() -> ClosedRange<Double> {
        var allValues: [Double] = []
        
        // Add main series values if shown
        if showRawData && !dataPoints.isEmpty {
            allValues.append(contentsOf: dataPoints)
        }
        
        // Add additional series values
        if let additionalSeries = additionalTimeSeries {
            for series in additionalSeries {
                if !series.values.isEmpty {
                    allValues.append(contentsOf: series.values)
                }
            }
        }
        
        // Fallback if no values
        if allValues.isEmpty {
            return 0...100
        }
        
        let min = allValues.min() ?? 0.0
        let max = allValues.max() ?? 100.0
        
        // If min equals max, add a buffer
        if min == max {
            return (min - 10)...(max + 10)
        }
        
        // Add buffer around the range
        let buffer = (max - min) * 0.1
        return (min - buffer)...(max + buffer)
    }
}

struct SignalGraphView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let timePoints = stride(from: 0.0, to: 10.0, by: 0.1).map { $0 }
        let dataPoints = timePoints.map { sin($0) }
        
        return SignalGraphView(
            title: "Sample Signal",
            xLabel: "Time (s)",
            yLabel: "Amplitude",
            timePoints: timePoints,
            dataPoints: dataPoints,
            showRawData: true,
            additionalTimeSeries: [
                (times: [0, 2, 4, 6, 8], values: [0, 0.9, 0, -0.9, 0], color: .red, showPoints: true)
            ],
            yRange: -1.1...1.1
        )
    }
}
