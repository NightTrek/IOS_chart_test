//
//  ContentView.swift
//  TestAppChart
//
//  Created by daniel Steigman on 6/10/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        ScrollView{
            Text("Chart header")
            Spacer()
            ChartView(viewModel: ChartViewModel())
            Text("section 1")
            Text("section 2")
            Text("section 3")
            Text("section 4")
            Text("section 5")
        }
        
    }


}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
