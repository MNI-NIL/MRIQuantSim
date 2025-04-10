//
//  SignalGraphView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI
import Charts

// Internal data type for points
struct DataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

struct SignalGraphView: View {
    let title: String
    let xLabel: String
    let yLabel: String
    let dataSeries: [TimeSeriesData]
    let yRange: ClosedRange<Double>?
    
    // Simple computed property to get only visible data series
    private var visibleSeries: [TimeSeriesData] {
        return dataSeries.filter { $0.isVisible }
    }
    
    // Convert a TimeSeriesData to an array of DataPoints
    private func pointsFor(series: TimeSeriesData) -> [DataPoint] {
        let count = min(series.xValues.count, series.yValues.count)
        var points: [DataPoint] = []
        
        for i in 0..<count {
            points.append(DataPoint(x: series.xValues[i], y: series.yValues[i]))
        }
        
        return points
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
            // Process each visible series
            ForEach(0..<visibleSeries.count, id: \.self) { index in
                let series = visibleSeries[index]
                let points = pointsFor(series: series)
                
                // Draw connecting line if this should be shown as a line
                //if !series.showPoints || series.showConnectingLine {
                if series.showConnectingLine {
                    // Determine correct line color
                    let lineColor = series.showConnectingLine ? 
                        (series.connectingLineColor ?? series.color.opacity(0.6)) : 
                        series.color
                        
                    // Draw line for this series
                    ForEach(0..<points.count, id: \.self) { i in
                        let point = points[i]
                        LineMark(
                            x: .value("Time", point.x),
                            y: .value("Value", point.y)
                        )
                    }
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: series.lineWidth))
                    .foregroundStyle(by: .value("Series", series.title))
                }
                
                // Draw points if this series should have points
                if series.showPoints {
                    // Draw points for this series
                    ForEach(0..<points.count, id: \.self) { i in
                        let point = points[i]
                        PointMark(
                            x: .value("Time", point.x),
                            y: .value("Value", point.y)
                        )
                    }
                    .foregroundStyle(series.color)
                    .symbolSize(series.symbolSize)
                    .foregroundStyle(by: .value("Series", series.title))
                }
            }
        }
        .chartXAxisLabel(xLabel)
        .chartYAxisLabel(yLabel)
    }
    
    // Calculate a sensible y-range if none provided
    private func calculateYRange() -> ClosedRange<Double> {
        var allValues: [Double] = []
        
        // Collect all y values from visible series only
        for series in visibleSeries {
            if !series.yValues.isEmpty {
                allValues.append(contentsOf: series.yValues)
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
        
        let sampleSeries = [
            TimeSeriesData(
                title: "Sine Wave",
                xValues: timePoints,
                yValues: sampleData,
                color: .blue,
                isVisible: true
            ),
            TimeSeriesData(
                title: "Key Points",
                xValues: [0, 2, 4, 6, 8],
                yValues: [0, 0.9, 0, -0.9, 0],
                color: .red,
                showPoints: true,
                isVisible: true,
                symbolSize: 50,
                showConnectingLine: true,
                connectingLineColor: .red.opacity(0.5)
            ),
            TimeSeriesData(
                title: "Hidden Series",
                xValues: timePoints,
                yValues: timePoints.map { cos($0) },
                color: .green,
                isVisible: false
            )
        ]
        
        return SignalGraphView(
            title: "Sample Signal",
            xLabel: "Time (s)",
            yLabel: "Amplitude",
            dataSeries: sampleSeries,
            yRange: -1.1...1.1
        )
    }
}
