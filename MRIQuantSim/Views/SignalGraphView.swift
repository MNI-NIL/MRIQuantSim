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
                    .frame(minHeight: 200, idealHeight: 250, maxHeight: 300)
            } else {
                chartView
                    .chartYScale(domain: calculateYRange())
                    .frame(minHeight: 200, idealHeight: 250, maxHeight: 300)
            }
        }
        .padding()
    }
    
    private var chartView: some View {
        Chart {
            // First render any time window markers if present
            ForEach(0..<visibleSeries.count, id: \.self) { index in
                let series = visibleSeries[index]
                
                // Only render markers for the first visible series (to avoid duplicates)
                if index == 0, let markers = series.timeWindowMarkers {
                    ForEach(0..<markers.count, id: \.self) { markerIndex in
                        let marker = markers[markerIndex]
                        
                        // Draw a rectangle area for the time window
                        RectangleMark(
                            xStart: .value("Window Start", marker.blockStartTime + marker.startOffset),
                            xEnd: .value("Window End", marker.blockStartTime + marker.endOffset),
                            yStart: .value("Min Y", calculateYRange().lowerBound),
                            yEnd: .value("Max Y", calculateYRange().upperBound)
                        )
                        .foregroundStyle(marker.color.opacity(marker.opacity))
                        .annotation(position: .top, alignment: .center) {
                            if markerIndex == 0 { // Only show annotation for first marker
                                Text("Time Window")
                                    .font(.caption2)
                                    .foregroundColor(marker.color)
                                    .padding(2)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(2)
                            }
                        }
                    }
                }
            }
            
            // Second render all line-based series
            ForEach(0..<visibleSeries.count, id: \.self) { index in
                let series = visibleSeries[index]
                
                // Only process line-based series in this loop
                if !series.showPoints {
                    let points = pointsFor(series: series)
                    
                    // Draw line for this series
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Time", point.x),
                            y: .value("Value", point.y)
                        )
                        .lineStyle(StrokeStyle(lineWidth: series.lineWidth))
                    }
                    // Let SwiftUI assign colors by series title
                    .foregroundStyle(by: .value("Series", series.title))
                }
            }
            
            // Then render all point-based series
            ForEach(0..<visibleSeries.count, id: \.self) { index in
                let series = visibleSeries[index]
                
                // Only process point-based series in this loop
                if series.showPoints {
                    let points = pointsFor(series: series)
                    
                    // First draw connecting line if needed
                    if series.showConnectingLine {
                        // Draw connecting line with darker variant
                        ForEach(points) { point in
                            LineMark(
                                x: .value("Time", point.x),
                                y: .value("Value", point.y)
                            )
                            .lineStyle(StrokeStyle(lineWidth: series.lineWidth))
                            .opacity(0.6) // Make it slightly transparent
                        }
                        // Associate with same series but don't add to legend
                        .foregroundStyle(by: .value("Series", series.title))
                    }
                    
                    // Then draw points on top
                    ForEach(points) { point in
                        PointMark(
                            x: .value("Time", point.x),
                            y: .value("Value", point.y)
                        )
                        .symbolSize(series.symbolSize)
                    }
                    // Let SwiftUI assign colors by series title
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
