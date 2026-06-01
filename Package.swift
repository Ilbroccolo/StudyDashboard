// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StudyDashboard",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swiftui-math.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "StudyDashboard",
            dependencies: [
                .product(name: "SwiftUIMath", package: "swiftui-math")
            ],
            path: ".",
            sources: ["Core", "Models", "ViewModels", "Views"]
        )
    ]
)
