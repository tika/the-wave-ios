import SwiftUI

extension Font {
    static func authorVariable(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return .custom("AuthorVariable-Bold", size: size)
        case .medium:
            return .custom("AuthorVariable-Medium", size: size)
        case .light:
            return .custom("AuthorVariable-Light", size: size)
        default:
            return .custom("AuthorVariable-Regular", size: size)
        }
    }
    
    static func clashDisplayVariable(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return .custom("ClashDisplayVariable-Bold", size: size)
        case .semibold:
            return .custom("ClashDisplayVariable-Bold_semibold", size: size)
        case .medium:
            return .custom("ClashDisplayVariable-Bold_Medium", size: size)
        case .light:
            return .custom("ClashDisplayVariable-Bold_Light", size: size)
        default:
            return .custom("ClashDisplayVariable-Bold_Regular", size: size)
        }
    }
}
