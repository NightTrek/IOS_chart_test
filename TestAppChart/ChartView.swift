import SwiftUI
import Charts
import Combine

struct ChartView: View {
    @ObservedObject var viewModel: ChartViewModel
    @State private var timeFramePickerHeight: CGFloat = 0
    @State private var selectedElement: Earning? = nil
    @GestureState private var xDragLocation: CGPoint = .zero  // Use GestureState instead of State

    @State private var longPressLocation: CGPoint = .zero
    @State private var shadowRadius: CGFloat = 0
    
    private let lineWidth = 2.0
    private let axisLineWidth = 1.0
    private let chartColor: Color = .black
    private let emptyAxisColor: Color = Color.black.opacity(0.2)
    private let lollipopColor: Color = .black
    private let circleDimension: CGFloat = 8.0
    private let timeFramePickerSpacing: CGFloat = 4
    private var viewHeight: CGFloat {
        viewModel.chartLoaded ? chartHeight + timeFramePickerSpacing*2 : chartHeight
    }
    private var chartHeight: CGFloat {
        264
    }
    private var minYValue: Double {
        viewModel.earningsData.min(by: { $0.amount < $1.amount })?.amount ?? 0
    }
    
    private var maxYValue: Double {
        viewModel.earningsData.max(by: { $0.amount < $1.amount })?.amount ?? 0
    }
    
    @State private var isDragging: Bool = false
    @State private var selectedAmount: String? = nil
    
    var body: some View {
        if viewModel.currentBalance ?? 0.0 < 0.01 {
            chartZero
        } else {
            chartWithBackground
        }
    }
    
    private var chartZero: some View {
        VStack {
            Image("chartZero")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    GeometryReader { geometry in
                        VStack {
                            Spacer().frame(height: geometry.size.height * 0.29)
                            HStack(spacing: 2) {
                                indicatorCircle
                                    .onAppear {
                                        withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                            shadowRadius = 10
                                        }
                                    }
                                Text("4.6%")
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                )
        }
    }
    
    private var indicatorCircle: some View {
        Ellipse()
            .foregroundColor(.clear)
            .frame(width: 8, height: 8)
            .background(Color.green)
            .cornerRadius(4)
            .shadow(color: Color.green.opacity(0.5), radius: shadowRadius, x: 0, y: 0)
    }
    
    private var chart: some View {
        
        Chart {
            
            ForEach(viewModel.earningsData) { dataPoint in
                LineMark(
                    x: .value("Date", "\(dataPoint.date)"),
                    y: .value("Amount", dataPoint.amount)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(viewModel.chartLoaded ? chartColor : emptyAxisColor)
                .lineStyle(StrokeStyle(lineWidth: lineWidth))
                .symbol { symbolView(for: dataPoint) }
            }
            
            //-------------------------------------------------- Selected Value
            
            if selectedAmount != nil {
                selectedValueView(selectedAmount: $selectedAmount, plotData: viewModel.earningsData)
            }
            
        }
       // .chartOverlay { selectionOverlay(proxy: $0) }
        .chartYScale(domain: minYValue...maxYValue)
        .chartXAxis {}
        .chartYAxis {}
        .frame(height: chartHeight)
        .animation(nil, value: viewModel.earningsData)
        .offset(y: -timeFramePickerSpacing)
        .chartXSelection(value: $selectedAmount)
        
    }
    
    private func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> Earning? {
        let relativeXPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        return proxy.value(atX: relativeXPosition)
            .flatMap { $0 as Date? }
            .flatMap { date in
                viewModel.earningsData.min { abs($0.date.distance(to: date)) < abs($1.date.distance(to: date)) }
            }
    }
    
    private func symbolView(for dataPoint: Earning) -> some View {
        Group {
            if selectedElement == dataPoint {
                Circle()
                    .fill(lollipopColor)
                    .frame(width: circleDimension, height: circleDimension)
            } else {
                EmptyView()
            }
        }
        .opacity(xDragLocation == .zero ? 0 : 1)
    }
    
    @ViewBuilder
    private func selectionOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: 0.0)
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onChanged({ value in  // Get value of the gesture
                            switch value {
                            case .second(true, let drag):
                                if let longPressLocation = drag?.location {
                                    dragGesture(longPressLocation, proxy: proxy, geometry: geometry)
                                }
                            default:
                                break
                            }
                        })
                        // Hide indicator when finish
                        .onEnded({ value in
                            viewModel.dragEnded()
                            isDragging = false
                            selectedElement = nil
                        })
                )

                .overlay(
                    overlayView(proxy: proxy, geometry: geometry),
                    alignment: .topLeading
                )
        }
    }

    

    
    private func overlayView(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        let plotAreaFrame = geometry[proxy.plotAreaFrame]
        return VStack {
            dashLine(plotAreaFrame: plotAreaFrame, proxy: proxy)
        }
    }
    
    private func xPosition(of element: Earning, in plotAreaFrame: CGRect, proxy: ChartProxy) -> CGFloat? {
        guard let xValue = proxy.position(forX: element.date) else { return nil }
        return plotAreaFrame.origin.x + xValue
    }

    
    private func dashLine(plotAreaFrame: CGRect, proxy: ChartProxy) -> some View {
        Path { path in
            let yStart = plotAreaFrame.origin.y
            let yEnd = plotAreaFrame.maxY
            
            if let selectedElement = selectedElement,
               let x = xPosition(of: selectedElement, in: plotAreaFrame, proxy: proxy) {
                path.move(to: CGPoint(x: x, y: yStart))
                path.addLine(to: CGPoint(x: x, y: yEnd))
            }
        }
        .stroke(style: StrokeStyle(lineWidth: axisLineWidth, dash: [5]))
        .foregroundColor(.green)
        .opacity(0.54)
        .opacity(selectedElement == nil ? 0 : 1)
    }

    
    private func longPressGesture(proxy: ChartProxy, geometry: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onChanged { state in
                // Handle long press initiation here
                print(state)
                longPressLocation = geometry.frame(in: .local).origin

                DispatchQueue.main.async {
                    print("Long press detected \(longPressLocation)")
                    // Find the nearest element on long press
                    if let newElement = findElement(location: longPressLocation, proxy: proxy, geometry: geometry) {
                        if selectedElement != newElement {
                            viewModel.dragUpdated(to: newElement)
                        }
                        selectedElement = newElement
                    }
//                    isDragging = true
                }
            }
            .onEnded { _ in
                print("longPressEnded")
                DispatchQueue.main.async {
                    if isDragging == false {
                        viewModel.dragEnded()
                        selectedElement = nil
                    }
                }
            }
    }

    
//    private func dragGesture(proxy: ChartProxy, geometry: GeometryProxy) -> some Gesture {
//        DragGesture(minimumDistance: 0, coordinateSpace: .local) // minimumDistance: 0 to start immediately
//            .updating($xDragLocation) { value, state, _ in
//                state = value.location
//            }
//            .onChanged { value in
//                DispatchQueue.main.async {
//                    isDragging = true
//                    let newElement = findElement(location: value.location, proxy: proxy, geometry: geometry)
//                    if selectedElement != newElement {
//                        Haptics.impact(style: .light)
//                        if let newElement = newElement {
//                            viewModel.dragUpdated(to: newElement)
//                        }
//                    }
//                    selectedElement = newElement
//                }
//            }
//            .onEnded { _ in
//                DispatchQueue.main.async {
//                    isDragging = false
//                    viewModel.dragEnded()
//                    selectedElement = nil
//                }
//            }
//    }

    private func dragGesture(_ location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        DispatchQueue.main.async {
            isDragging = true
            let newElement = findElement(location: location, proxy: proxy, geometry: geometry)
            if selectedElement != newElement {
                if let newElement = newElement {
                    viewModel.dragUpdated(to: newElement)
                }
            }
            selectedElement = newElement
        }
    }


    private var chartWithBackground: some View {
        VStack(spacing: .zero) {
            chart
                .frame(height: viewHeight)
           
        }
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .black.opacity(0), location: 0.00),
                    Gradient.Stop(color: Color.gray, location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.90),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color.green.opacity(0.09), location: 0.33),
                    Gradient.Stop(color: Color.green.opacity(0), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.44, y: 1),
                endPoint: UnitPoint(x: 0.44, y: 0.47)
            )
        )
    }
    

}


// MARK: - Helper Functions
// MARK: -
extension ChartView {
    
    func selectedValueView(selectedAmount: Binding<String?>, plotData: [Earning]) -> some ChartContent {
        
        RuleMark(
            x: .value("Selected", selectedAmount.wrappedValue ?? "")
        )
        .foregroundStyle(Color.gray.opacity(0.3))
        .offset(yStart: -10)
        .zIndex(-1)
        .annotation(
            position: .automatic, spacing: 0,
            overflowResolution: .init(
                x: .fit(to: .chart),
                y: .fit(to: .automatic)
            )
        ) {
            
            HStack {
                
                ForEach(plotData.filter({ "\($0.date)" == selectedAmount.wrappedValue ?? ""})){ value in
                    
                    VStack {
                        
                        //------------------------------------------- Date
                        
                        HStack {
                            
                            Text("Date:")
                                .bold()
                            
                            Text(formatDate(value.date))
                            
                            Spacer()
                            
                        }
                        .font(.system(size: 12, weight: .regular))
                        
                        //------------------------------------------- Amount
                        
                        HStack {
                            
                            Text("Amount:")
                                .bold()
                            
                            Text(String(format: "%.1f", value.amount))
                            
                            Spacer()
                            
                        }
                        .font(.system(size: 12, weight: .regular))
                        
                        
                        
                    }
                    .foregroundStyle(Color.black)
                    
                }
                
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background {
                Color(uiColor: UIColor.systemGray6).cornerRadius(4)
            }
        }

        
    }
    
    func formatDate(_ date: Date?, format: String = "dd-MMM-yyyy", locale: Locale = Locale(identifier: "en_US_POSIX")) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = locale
        guard let date = date else { return "" }
        return dateFormatter.string(from: date)
    }
    
}

// MARK: - Preview
#if DEBUG
#Preview {
    ChartView(viewModel: ChartViewModel())
}
#endif
