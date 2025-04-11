//
//  ChemicalFormula.swift
//  MRIQuantSim
//
//  Created on 2025-04-11.
//

import SwiftUI

struct ChemicalFormula: View {
    let formula: String
    let fontSize: CGFloat
    let color: Color?
    
    init(_ formula: String, fontSize: CGFloat = 14, color: Color? = nil) {
        self.formula = formula
        self.fontSize = fontSize
        self.color = color
    }
    
    var body: some View {
        // Simple implementation that replaces "CO2" with "CO₂"
        let displayText = formula.replacingOccurrences(of: "CO2", with: "CO₂")
        return Text(displayText)
            .font(.system(size: fontSize))
            .foregroundColor(color)
    }
}

// No extension needed - we're directly replacing Text with the proper subscript
// Instead of trying to extend Text, we'll just use the component directly

// Preview Provider
struct ChemicalFormula_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ChemicalFormula("CO2")
            ChemicalFormula("CO2", fontSize: 24, color: .blue)
            ChemicalFormula("CO2 Variance", fontSize: 18)
        }
        .padding()
    }
}