import SwiftUI
import Charts
import Combine

struct Earning: Identifiable, Equatable, Codable {
    var id = UUID()
    let date: Date
    var amount: Double
}

struct Earnings {
    let earnings: [Earning]
}

class ChartViewModel: BaseViewModel {
    @Published var earningsData: [Earning]
    @Published var selectedTimeFrame: TimeFrame = .oneMonth {
        didSet {
            updateData(for: selectedTimeFrame)
        }
    }
    @Published var chartLoaded: Bool = false
    @Published var currentBalance: Double?
    @Published var balance: Double?
    
    @Published var earningsAt: Double?
    @Published var earningsAtPercentage: Double?
    @Published var earningsDate: Date?
    
    @Published var totalEarnings: Double?
    @Published var totalEarningsPercentage: Double?
    @Published var lastMonthEarnings: Double?
    @Published var lastMonthEarningsPercentage: Double?
    
    private var allEarningsData: [Earning]
    
   override init() {
       let sampleData = generateEmptySampleData()
       currentBalance = sampleData.last?.amount
       balance = sampleData.last?.amount
        self.allEarningsData = sampleData
        self.earningsData = sampleData
        super.init()
        updateData(for: selectedTimeFrame)
        
    }
    
    var balanceFormatted: String? {
        if let balance {
            return balance.formatAmount()
        }
        
        return currentBalance?.formatAmount() ?? nil
    }
    
    var earningsAtFormatted: String { (earningsAt ?? 0.0).formatAmount() ?? "" }
    var earningsAtPercentageFormatted: String { (earningsAtPercentage ?? 0.0).formatAsPercentageWithBrackets() }
    var earningsDateFormatted: String { earningsDate?.formatted(.dateTime.day().month().year()) ?? Date().formatted(.dateTime.day().month().year()) }
    
    var earningsDisplayText: String? {
        guard let lastMonthEarningsFormatted, let lastMonthEarningsPercentageFormatted else { return nil}
        
        return "\(lastMonthEarningsFormatted) \(lastMonthEarningsPercentageFormatted) Past 30 days"
    }
    
    var lastMonthEarningsText: String? {
        guard let lastMonthEarningsFormatted, let lastMonthEarningsPercentageFormatted else { return nil }
        
        return "+\(lastMonthEarningsFormatted) \(lastMonthEarningsPercentageFormatted)"
    }

    var totalEarningsText: String? {
        guard let totalEarningsFormatted, let totalEarningsPercentageFormatted else { return nil }
        
        return "+\(totalEarningsFormatted) \(totalEarningsPercentageFormatted)"
    }
    
    var lastMonthEarningsFormatted: String? {
        guard let lastMonthEarnings else { return nil }
        
        return lastMonthEarnings.formatAmount() ?? ""
    }
    
    var lastMonthEarningsPercentageFormatted: String? {
        guard let lastMonthEarningsPercentage else { return nil }

        return lastMonthEarningsPercentage.formatAsPercentageWithBrackets()
    }
    
    var totalEarningsFormatted: String? {
        guard let totalEarnings else { return nil }
        
        return totalEarnings.formatAmount() ?? ""
    }
    
    var totalEarningsPercentageFormatted: String? {
        guard let totalEarningsPercentage else { return nil }
        
        return totalEarningsPercentage.formatAsPercentageWithBrackets()
    }
    
    

    

    

  
    
    func dragUpdated(to value: Earning) {
        guard let initialEarning = earningsData.first else {
            return
        }
        
        self.balance = value.amount
        self.earningsAt = value.amount - initialEarning.amount
        self.earningsAtPercentage = value.amount == 0.0 ? 0.0 : ((value.amount - initialEarning.amount) / value.amount) * 100
        self.earningsDate = value.date
    }
    
    func dragEnded() {
        self.balance = currentBalance
        self.earningsAt = nil
        self.earningsAtPercentage = nil
        self.earningsDate = nil
    }
    
    /// Updates the earnings data based on the selected time frame.
    func updateData(for timeframe: TimeFrame) {
        earningsData = earningsForLast(timeframe.value, timeframe.calendarComponent, from: allEarningsData)
    }
    
    /// Filters earnings data for the last specified duration.
    private func earningsForLast(_ value: Int, _ component: Calendar.Component, from allData: [Earning]) -> [Earning] {
        guard let dateBack = Calendar.current.date(byAdding: component, value: -value, to: Date()) else { return [] }
        return allData.filter { $0.date >= dateBack }
    }
}


extension Double {
    func formatAsPercentage() -> String {
        "\(String(format: "%.2f", self))%"
    }
    func formatAsPercentageWithBrackets() -> String {
        "(\(String(format: "%.2f", self))%)"
    }
    func formatAmount() -> String? {
        ""
    }
}


func generateEmptySampleData() -> [Earning] {
    let totalPoints = 30
    var earningsData: [Earning] = []
    
    let startDate = Calendar.current.date(byAdding: .day, value: -totalPoints, to: Date())!
    
    for pointIndex in 0..<totalPoints {
        let date = Calendar.current.date(byAdding: .day, value: pointIndex, to: startDate)!
        let amount = Double.random(in: 100...1000) + Double.random(in: 0...100) * sin(Double(pointIndex) * Double.pi / 10)
        earningsData.append(Earning(date: date, amount: amount))
    }
    
    return earningsData
}

