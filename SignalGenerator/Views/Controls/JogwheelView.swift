import SwiftUI

struct JogwheelView: View {
    @Binding var frequency: Double
    let stepIncrement: Double

    // Rotation tracking
    @State private var wheelAngle: Double = 0
    @State private var lastDragAngle: Double = 0
    @State private var isDragging: Bool = false


    // Sensitivity: degrees of rotation per step-increment unit
    private let sensitivity: Double = 0.3

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Outer ring
                Circle()
                    .fill(Theme.bodyDarkest)
                    .overlay(
                        Circle()
                            .strokeBorder(Theme.bodyDark, lineWidth: 5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 4)

                // Tick marks
                ForEach(0..<40, id: \.self) { i in
                    let isMajor = i % 5 == 0
                    Rectangle()
                        .fill(isMajor ? Theme.textDim : Theme.textFaint)
                        .frame(width: isMajor ? 2.5 : 2, height: isMajor ? 11 : 7)
                        .offset(y: -(geo.size.width / 2 - (isMajor ? 10 : 11)))
                        .rotationEffect(.degrees(Double(i) * 9))
                }

                // Wheel face
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#484848"),
                                Color(hex: "#353535"),
                                Color(hex: "#282828"),
                                Color(hex: "#1e1e1e")
                            ]),
                            center: UnitPoint(x: 0.45, y: 0.4),
                            startRadius: 0,
                            endRadius: geo.size.width * 0.5
                        )
                    )
                    .frame(width: geo.size.width * 0.72, height: geo.size.width * 0.72)
                    // Thumb indent — concave scoop at top
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#1a1a1c"),
                                        Color(hex: "#2a2a2c"),
                                        Color(hex: "#353535")
                                    ]),
                                    center: UnitPoint(x: 0.5, y: 0.6),
                                    startRadius: 0,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.5), radius: 4, y: -2)
                            .padding(.top, 10)
                    }
                    .rotationEffect(.degrees(wheelAngle))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let angle = atan2(
                            value.location.y - center.y,
                            value.location.x - center.x
                        ) * 180 / .pi

                        if !isDragging {
                            isDragging = true
                            lastDragAngle = angle
                        }

                        var delta = angle - lastDragAngle

                        // Handle 180° wrap-around
                        if delta > 180 { delta -= 360 }
                        if delta < -180 { delta += 360 }

                        lastDragAngle = angle

                        wheelAngle += delta
                        applyDelta(delta)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }


    private func applyDelta(_ delta: Double) {
        let freqDelta = delta * stepIncrement * sensitivity
        var newFreq = frequency + freqDelta
        if stepIncrement >= 1 {
            newFreq = (newFreq / stepIncrement).rounded() * stepIncrement
        }
        frequency = max(10, min(20000, newFreq))
    }
}

