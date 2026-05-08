import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

/// Represents the layout direction (LTR or RTL)
public enum LayoutDirection: Hashable {
    case ltr   // Left-to-Right
    case rtl   // Right-to-Left
    case auto  // Inherit from context
    
    /// Returns true if the direction is RTL
    public var isRTL: Bool {
        self == .rtl
    }

    /// Resolves the layout direction, using the fallback for `.auto`
    public func resolved(fallback: LayoutDirection) -> LayoutDirection {
        switch self {
        case .ltr: return .ltr
        case .rtl: return .rtl
        case .auto: return fallback == .auto ? .current : fallback
        }
    }

    /// Detects the current system layout direction
    public static var current: LayoutDirection {
        #if os(iOS) || os(tvOS)
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .rtl : .ltr
        #elseif os(macOS)
        return NSApp.userInterfaceLayoutDirection == .rightToLeft ? .rtl : .ltr
        #else
        return .ltr
        #endif
    }
    
    /// Detects layout direction from Locale
    public static func fromLocale(_ locale: Locale) -> LayoutDirection {
        let rtlLanguages = [
            "ar",  // Arabic
            "he",  // Hebrew
            "fa",  // Persian/Farsi
            "ps",  // Pashto
            "ur",  // Urdu
            "yi",  // Yiddish
            "ji",  // Yiddish (alternative)
            "iw",  // Hebrew (ISO)
            "ku",  // Kurdish
            "ckb", // Central Kurdish
            "dv",  // Dhivehi
        ]
        
        if let languageCode = locale.language.languageCode?.identifier {
            return rtlLanguages.contains(languageCode) ? .rtl : .ltr
        }
        
        return .ltr
    }
    
    /// Detects layout direction from language code
    public static func fromLanguageCode(_ code: String) -> LayoutDirection {
        let rtlLanguages = [
            "ar", "he", "fa", "ps", "ur", "yi", "ji", "iw", "ku", "ckb", "dv"
        ]
        return rtlLanguages.contains(code) ? .rtl : .ltr
    }
}
