// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Composed",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "Composed",
            targets: ["Composed"]),
    ],
    dependencies: [
        .package(url: "https://github.com/shaps80/FlowLayout.git", .exact("1.0.7")),
        .package(url: "https://github.com/Quick/Quick.git", .exact("2.1.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .exact("8.0.2")),
    ],
    targets: [
        .target(
            name: "Composed",
            dependencies: ["FlowLayout"],
            path: "Sources"),
        .testTarget(
            name: "ComposedTests",
            dependencies: ["Composed", "Quick", "Nimble"],
            path: "Tests"),
    ]
)
