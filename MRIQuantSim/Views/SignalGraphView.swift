//
//  SignalGraphView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI
import Charts

// Define a struct to hold each data point
struct DataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
}

// Define a struct for each data series
struct DataSeries: Identifiable {
    let id = UUID()
    let points: [DataPoint]
    let color: Color
    let showPoints: Bool
    let seriesName: String
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
    
    // Process data into series
    private var allSeries: [DataSeries] {
        var result: [DataSeries] = []
        
        // Add main series if needed
        if showRawData && !timePoints.isEmpty && !dataPoints.isEmpty {
            let mainPoints = zip(timePoints, dataPoints)
                .prefix(min(timePoints.count, dataPoints.count))
                .map { DataPoint(x: $0.0, y: $0.1) }
            
            result.append(DataSeries(
                points: mainPoints,
                color: .blue,
                showPoints: false,
                seriesName: "Raw"
            ))
        }
        
        // Add additional series
        if let additionalSeries = additionalTimeSeries {
            for (idx, series) in additionalSeries.enumerated() {
                if !series.times.isEmpty && !series.values.isEmpty {
                    let count = min(series.times.count, series.values.count)
                    let points = zip(series.times, series.values)
                        .prefix(count)
                        .map { DataPoint(x: $0.0, y: $0.1) }
                    
                    result.append(DataSeries(
                        points: points,
                        color: series.color,
                        showPoints: series.showPoints,
                        seriesName: "Series\(idx)"
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
                chart
                    .chartYScale(domain: range)
                    .frame(height: 200)
            } else {
                chart
                    .frame(height: 200)
            }
        }
        .padding()
    }
    
    private var chart: some View {
        Chart {
            ForEach(allSeries) { series in
                // For each series, create a separate ForEach with different ID
                if series.showPoints {
                    // Point series - just show points
                    ForEach(series.points) { point in
                        PointMark(
                            x: .value("\(xLabel) (\(series.seriesName))", point.x),
                            y: .value(yLabel, point.y)
                        )
                        .foregroundStyle(series.color)
                    }
                } else {
                    // Line series - create individual points
                    ForEach(series.points) { point in
                        LineMark(
                            x: .value("\(xLabel) (\(series.seriesName))", point.x),
                            y: .value(yLabel, point.y)
                        )
                        .foregroundStyle(series.color)
                        .lineStyle(StrokeStyle(lineWidth: series.seriesName == "Raw" ? 2 : 1))
                    }
                }
            }
        }
        .chartXAxisLabel(xLabel)
        .chartYAxisLabel(yLabel)
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
