// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DailyVerseDependencies",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "Alamofire", targets: ["Alamofire"]),
        .library(name: "SwiftyJSON", targets: ["SwiftyJSON"]),
        .library(name: "SwiftDate", targets: ["SwiftDate"]),
        .library(name: "SnapKit", targets: ["SnapKit"]),
        .library(name: "MarqueeLabel", targets: ["MarqueeLabel"]),
        .library(name: "NotificationBannerSwift", targets: ["NotificationBannerSwift"]),
        .library(name: "DynamicBlurView", targets: ["DynamicBlurView"]),
        .library(name: "Spring", targets: ["Spring"]),
        .library(name: "MMMaterialDesignSpinner", targets: ["MMMaterialDesignSpinner"])
    ],
    targets: [
        .target(name: "Alamofire"),
        .target(name: "SwiftyJSON"),
        .target(
            name: "SwiftDate",
            resources: [
                .process("Formatters/RelativeFormatter/langs")
            ]
        ),
        .target(name: "SnapKit"),
        .target(name: "MarqueeLabel"),
        .target(
            name: "NotificationBannerSwift",
            dependencies: ["MarqueeLabel", "SnapKit"]
        ),
        .target(
            name: "DynamicBlurView",
            linkerSettings: [
                .linkedFramework("Accelerate")
            ]
        ),
        .target(
            name: "Spring",
            resources: [
                .process("LoadingView.xib")
            ]
        ),
        .target(
            name: "MMMaterialDesignSpinner",
            publicHeadersPath: "."
        )
    ],
    swiftLanguageVersions: [.v5]
)
