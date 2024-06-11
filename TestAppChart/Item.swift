//
//  Item.swift
//  TestAppChart
//
//  Created by daniel Steigman on 6/10/24.
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
