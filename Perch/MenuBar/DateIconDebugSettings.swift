#if DEBUG
import AppKit
import Combine
import Foundation

enum DateIconDebugFontWeight: String, CaseIterable, Identifiable {
    case regular
    case medium
    case semibold
    case bold
    case heavy

    var id: String {
        rawValue
    }

    var nsFontWeight: NSFont.Weight {
        switch self {
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        }
    }

    var displayTitle: String {
        switch self {
        case .regular:
            return "Regular"
        case .medium:
            return "Medium"
        case .semibold:
            return "Semibold"
        case .bold:
            return "Bold"
        case .heavy:
            return "Heavy"
        }
    }
}

@MainActor
final class DateIconDebugSettings: ObservableObject {
    @Published var isOverrideEnabled: Bool {
        didSet {
            onChange?()
        }
    }

    @Published var day: Int {
        didSet {
            guard !isApplyingDayClamp else {
                return
            }

            let clampedDay = Self.clamp(day: day)
            if day != clampedDay {
                isApplyingDayClamp = true
                day = clampedDay
                isApplyingDayClamp = false
                onChange?()
                return
            }

            onChange?()
        }
    }

    @Published var fontWeight: DateIconDebugFontWeight {
        didSet {
            onChange?()
        }
    }

    var onChange: (() -> Void)?
    private var isApplyingDayClamp = false

    var renderOptions: DateIconRenderOptions {
        DateIconRenderOptions(
            fontWeight: fontWeight.nsFontWeight,
            opticalYOffset: 0
        )
    }

    init(
        isOverrideEnabled: Bool = false,
        day: Int = Calendar.current.component(.day, from: Date()),
        fontWeight: DateIconDebugFontWeight = .semibold
    ) {
        self.isOverrideEnabled = isOverrideEnabled
        self.day = Self.clamp(day: day)
        self.fontWeight = fontWeight
    }

    private static func clamp(day: Int) -> Int {
        min(max(day, 1), 31)
    }
}
#endif
