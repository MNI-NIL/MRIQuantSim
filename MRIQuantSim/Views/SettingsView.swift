//
//  SettingsView.swift
//  MRIQuantSim
//
//  Created on 2025-04-11.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var savedParameters: [SimulationParameters]
    var onParameterChanged: () -> Void
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .padding(.top, 20)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 20) {
                Button {
                    resetToDefaults()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset All Settings to Defaults")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("This will restore all simulation parameters to their default values.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 300)
    }
    
    func resetToDefaults() {
        // Get the saved parameters
        if let existingParams = savedParameters.first {
            // Reset to defaults using the convenient method
            existingParams.resetToDefaults()
            
            // Save the changes
            try? modelContext.save()
            
            // Call parameter changed to update the simulation
            onParameterChanged()
            
            // Show confirmation to user
            let alert = NSAlert()
            alert.messageText = "Settings Reset"
            alert.informativeText = "All settings have been restored to their default values."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            
            // Close the settings window
            dismiss()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onParameterChanged: {})
    }
}