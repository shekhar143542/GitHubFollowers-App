
import UIKit
import SwiftUI

enum AppTheme {

    // MARK: - Colors

    enum Colors {
        static let primary = UIColor.systemBlue
        static let background = UIColor.systemBackground
        static let secondaryBackground = UIColor.secondarySystemBackground
        static let text = UIColor.label
        static let secondaryText = UIColor.secondaryLabel
        static let separator = UIColor.separator

        // SwiftUI color versions
        static let primarySwiftUI = Color(uiColor: primary)
        static let backgroundSwiftUI = Color(uiColor: background)
        static let secondaryBackgroundSwiftUI = Color(uiColor: secondaryBackground)
        static let textSwiftUI = Color(uiColor: text)
        static let secondaryTextSwiftUI = Color(uiColor: secondaryText)
    }

    // MARK: - Fonts

    enum Fonts {
        // UIKit fonts
        static let title = UIFont.preferredFont(forTextStyle: .title2)
        static let headline = UIFont.preferredFont(forTextStyle: .headline)
        static let body = UIFont.preferredFont(forTextStyle: .body)
        static let caption = UIFont.preferredFont(forTextStyle: .caption1)

        // SwiftUI fonts
        static let titleSwiftUI = Font.title2
        static let headlineSwiftUI = Font.headline
        static let bodySwiftUI = Font.body
        static let captionSwiftUI = Font.caption
    }
}

