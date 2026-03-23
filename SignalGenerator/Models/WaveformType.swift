import Foundation

enum WaveformType: Int32, CaseIterable, Identifiable {
    case sine     = 0
    case square   = 1
    case saw      = 2
    case triangle = 3
    case white    = 4
    case pink     = 5

    var id: Int32 { rawValue }

    var label: String {
        switch self {
        case .sine:     return "Sine"
        case .square:   return "Square"
        case .saw:      return "Saw"
        case .triangle: return "Triangle"
        case .white:    return "White"
        case .pink:     return "Pink"
        }
    }

    var shortLabel: String {
        switch self {
        case .sine:     return "SINE"
        case .square:   return "SQUARE"
        case .saw:      return "SAW"
        case .triangle: return "TRI"
        case .white:    return "WHITE"
        case .pink:     return "PINK"
        }
    }

    var isNoise: Bool {
        self == .white || self == .pink
    }
}
