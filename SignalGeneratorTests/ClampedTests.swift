import Testing
@testable import SignalGenerator

@Suite("Comparable.clamped")
struct ClampedTests {

    @Test func withinRange() {
        #expect(5.0.clamped(to: 0...10) == 5.0)
    }

    @Test func belowRange() {
        #expect((-5.0).clamped(to: 0...10) == 0.0)
    }

    @Test func aboveRange() {
        #expect(15.0.clamped(to: 0...10) == 10.0)
    }

    @Test func atLowerBound() {
        #expect(0.0.clamped(to: 0...10) == 0.0)
    }

    @Test func atUpperBound() {
        #expect(10.0.clamped(to: 0...10) == 10.0)
    }

    @Test func integerClamping() {
        #expect((-1).clamped(to: 0...10) == 0)
        #expect(11.clamped(to: 0...10) == 10)
        #expect(5.clamped(to: 0...10) == 5)
    }
}
