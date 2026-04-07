import SwiftUI
import UIKit

struct JogwheelView: View {
    @Binding var frequency: Double
    let stepIncrement: Double

    // Rotation tracking
    @State private var wheelAngle: Double = 0
    @State private var lastDragAngle: Double = 0
    @State private var isDragging: Bool = false

    private let stepFeedback = UIImpactFeedbackGenerator(style: .light)
    private let startFeedback = UIImpactFeedbackGenerator(style: .soft)


    // Accumulated rotation for step-based snapping
    @State private var accumulatedSteps: Double = 0

    // Degrees of jogwheel rotation needed to advance one step
    private var degreesPerStep: Double {
        switch stepIncrement {
        case 100:  return 15
        case 10:   return 10
        case 1:    return 5
        default:   return 3
        }
    }

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
                    // Thumb indent — smooth round groove
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#222224"),
                                        Color(hex: "#333335")
                                    ]),
                                    center: UnitPoint(x: 0.5, y: 0.55),
                                    startRadius: 0,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(hex: "#383838"), lineWidth: 1)
                            )
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
                            startFeedback.impactOccurred(intensity: 0.5)
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
        if stepIncrement >= 1 {
            // Accumulate rotation, only change frequency on full steps
            accumulatedSteps += delta / degreesPerStep
            let wholeSteps = accumulatedSteps.rounded(.towardZero)
            if wholeSteps != 0 {
                frequency = max(10, min(20000, frequency + wholeSteps * stepIncrement))
                accumulatedSteps -= wholeSteps
                stepFeedback.impactOccurred(intensity: 0.5)
            }
        } else {
            // Sub-Hz: continuous movement
            let freqDelta = delta * stepIncrement / degreesPerStep
            frequency = max(10, min(20000, frequency + freqDelta))
        }
    }
}

