import SwiftUI

/// Represents different time frames for filtering or displaying data.
enum TimeFrame: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "ALL"
    
    /// Display text for each time frame.
    var text: String {
        self.rawValue
    }
    
    /// Text color when a time frame is deselected.
    var deselectedTextColor: Color {
        .white
    }
    
    /// Text color when a time frame is selected.
    var selectedTextColor: Color {
        .black
    }
    
    /// Background color when a time frame is selected.
    var selectedBackgroundColor: Color {
        .green // Assumes .success is defined elsewhere as a Color
    }
    
    /// Background color when a time frame is deselected.
    var deselectedBackgroundColor: Color {
        .clear
    }
    
    /// The value associated with each time frame. This might represent days, months, etc., depending on the context.
    var value: Int {
        switch self {
        case .oneDay:
            return 1
        case .oneWeek:
            return 7
        case .oneMonth:
            return 1
        case .threeMonths:
            return 3
        case .sixMonths:
            return 6
        case .oneYear:
            return 12
        case .all:
            return 18
        }
    }
    
    /// The appropriate calendar component associated with each time frame for date calculations.
    var calendarComponent: Calendar.Component {
        switch self {
        case .oneDay, .oneWeek:
            return .day
        case .oneMonth, .threeMonths, .sixMonths, .oneYear, .all:
            return .month
        }
    }
}
