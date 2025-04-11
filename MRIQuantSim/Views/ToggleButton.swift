//
//  ToggleButton.swift
//  MRIQuantSim
//
//  Created on 2025-04-11.
//

import SwiftUI

struct ToggleButton: View {
    let title: String
    @Binding var isOn: Bool
    var onChange: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            isOn.toggle()
            onChange()
        }) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(buttonBackgroundColor)
                .foregroundColor(buttonTextColor)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonBackgroundColor: Color {
        if isOn {
            return Color.accentColor
        } else {
            return colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.9)
        }
    }
    
    private var buttonTextColor: Color {
        if isOn {
            return .white
        } else {
            return colorScheme == .dark ? Color.white : Color.primary
        }
    }
}