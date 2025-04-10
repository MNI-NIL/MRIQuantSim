//
//  SignalGraphView.swift
//  MRIQuantSim
//
//  Created on 2025-04-10.
//

import SwiftUI
import Charts

struct SignalGraphView: View {
    let title: String
    let xLabel: String
    let yLabel: String
    let timePoints: [Double]
    let dataPoints: [Double]
    let showRawData: Bool
    let additionalTimeSeries: [(times: [Double], values: [Double], color: Color, showPoints: Bool)]?
    let yRange: ClosedRange<Double>?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            if let range = yRange {
                chartViewWithRange(range)
                    .frame(height: 200)
            } else {
                chartViewWithoutRange
                    .frame(height: 200)
            }
        }
        .padding()
    }
    
    private var chartViewWithoutRange: some View {
        Chart {
            // Main data series
            if showRawData {
                mainDataSeries
            }
            
            // Additional time series if provided
            if let additionalSeries = additionalTimeSeries {
                additionalDataSeries(additionalSeries)
            }
        }
        .chartXAxisLabel(xLabel)
        .chartYAxisLabel(yLabel)
    }
    
    private func chartViewWithRange(_ range: ClosedRange<Double>) -> some View {
        Chart {
            // Main data series
            if showRawData {
                mainDataSeries
            }
            
            // Additional time series if provided
            if let additionalSeries = additionalTimeSeries {
                additionalDataSeries(additionalSeries)
            }
        }
        .chartXAxisLabel(xLabel)
        .chartYAxisLabel(yLabel)
        .chartYScale(domain: range)
    }
    
    @ChartContentBuilder
    private var mainDataSeries: some ChartContent {
        ForEach(0..<timePoints.count, id: \.self) { i in
            LineMark(
                x: .value(xLabel, timePoints[i]),
                y: .value(yLabel, dataPoints[i])
            )
            .foregroundStyle(.blue)
        }
    }
    
    @ChartContentBuilder
    private func additionalDataSeries(_ series: [(times: [Double], values: [Double], color: Color, showPoints: Bool)]) -> some ChartContent {
        ForEach(0..<series.count, id: \.self) { seriesIndex in
            let currentSeries = series[seriesIndex]
            seriesLines(currentSeries)
            
            if currentSeries.showPoints {
                seriesPoints(currentSeries)
            }
        }
    }
    
    @ChartContentBuilder
    private func seriesLines(_ series: (times: [Double], values: [Double], color: Color, showPoints: Bool)) -> some ChartContent {
        ForEach(0..<series.times.count, id: \.self) { i in
            LineMark(
                x: .value(xLabel, series.times[i]),
                y: .value(yLabel, series.values[i])
            )
            .foregroundStyle(series.color)
        }
    }
    
    @ChartContentBuilder
    private func seriesPoints(_ series: (times: [Double], values: [Double], color: Color, showPoints: Bool)) -> some ChartContent {
        ForEach(0..<series.times.count, id: \.self) { i in
            PointMark(
                x: .value(xLabel, series.times[i]),
                y: .value(yLabel, series.values[i])
            )
            .foregroundStyle(series.color)
        }
    }
}

#Preview {
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