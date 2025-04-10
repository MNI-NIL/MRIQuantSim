//
//  Item.swift
//  MRIQuantSim
//
//  Created by Rick Hoge on 2025-04-10.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
