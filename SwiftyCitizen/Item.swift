//
//  Item.swift
//  SwiftyCitizen
//
//  Created by andres paladines on 9/10/26.
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
