//
//  SignalGraphView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI
import Charts

// Data types for chart series
struct DataSeries: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let showPoints: Bool
    let points: [DataPoint]
}

struct DataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

struct SignalGraphView: View {
    let title: String
    let xLabel: String
    let yLabel: String
    let timePoints: [Double]
    let dataPoints: [Double]
    let showRawData: Bool
    let additionalTimeSeries: [(times: [Double], values: [Double], color: Color, showPoints: Bool)]?
    let yRange: ClosedRange<Double>?
    
    // Prepare data in the format expected by the chart
    private var chartData: [DataSeries] {
        var result: [DataSeries] = []
        
        // Main data series
        if showRawData && !timePoints.isEmpty && !dataPoints.isEmpty {
            let count = min(timePoints.count, dataPoints.count)
            var points: [DataPoint] = []
            
            for i in 0..<count {
                points.append(DataPoint(x: timePoints[i], y: dataPoints[i]))
            }
            
            result.append(DataSeries(
                name: "raw",
                color: .blue,
                showPoints: false,
                points: points
            ))
        }
        
        // Additional series
        if let additionalSeries = additionalTimeSeries {
            for (idx, series) in additionalSeries.enumerated() {
                let count = min(series.times.count, series.values.count)
                var points: [DataPoint] = []
                
                for i in 0..<count {
                    points.append(DataPoint(x: series.times[i], y: series.values[i]))
                }
                
                // For point series (like end-tidal CO2), we'll create both a line and points
                if series.showPoints {
                    // First add a line in a contrasting color (dark red or maroon)
                    result.append(DataSeries(
                        name: "series_\(idx)_line",
                        color: Color(red: 0.6, green: 0.0, blue: 0.0), // Dark red/maroon for the line
                        showPoints: false, // This is the line part
                        points: points
                    ))
                    
                    // Then add the points in the original color (typically bright red)
                    result.append(DataSeries(
                        name: "series_\(idx)_points",
                        color: series.color,
                        showPoints: true, // This is the points part
                        points: points
                    ))
                } else {
                    // Normal line series
                    result.append(DataSeries(
                        name: "series_\(idx)",
                        color: series.color,
                        showPoints: series.showPoints,
                        points: points
                    ))
                }
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            if let range = yRange {
                chartView
                    .chartYScale(domain: range)
                    .frame(height: 200)
            } else {
                chartView
                    .chartYScale(domain: calculateYRange())
                    .frame(height: 200)
            }
        }
        .padding()
    }
    
    private var chartView: some View {
        Chart {
            // First draw all lines (to make sure they're behind the points)
            ForEach(chartData.filter { !$0.showPoints }) { series in
                // Line plot with series-specific identifiers
                ForEach(series.points) { point in
                    LineMark(
                        x: .value("x_\(series.name)", point.x),
                        y: .value("y_\(series.name)", point.y)
                    )
                    .foregroundStyle(series.color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .foregroundStyle(by: .value("Series", series.name))
            }
            
            // Then draw all points (to ensure they appear on top)
            ForEach(chartData.filter { $0.showPoints }) { series in
                // Scatter plot (points only)
                ForEach(series.points) { point in
                    PointMark(
                        x: .value("x_\(series.name)", point.x),
                        y: .value("y_\(series.name)", point.y)
                    )
                    .foregroundStyle(series.color)
                    .symbolSize(30)
                }
            }
        }
        .chartXAxisLabel(xLabel)
        .chartYAxisLabel(yLabel)
    }
    
    // Calculate a sensible y-range if none provided
    private func calculateYRange() -> ClosedRange<Double> {
        var allValues: [Double] = []
        
        // Add main series values if shown
        if showRawData, !dataPoints.isEmpty {
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
        let sampleData = timePoints.map { sin($0) }
        
        return SignalGraphView(
            title: "Sample Signal",
            xLabel: "Time (s)",
            yLabel: "Amplitude",
            timePoints: timePoints,
            dataPoints: sampleData,
            showRawData: true,
            additionalTimeSeries: [
                (times: [0, 2, 4, 6, 8], values: [0, 0.9, 0, -0.9, 0], color: .red, showPoints: true)
            ],
            yRange: -1.1...1.1
        )
    }
}