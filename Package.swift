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
        .package(url: "https://github.com/Quick/Quick.git", from: "2.1.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.2"),
    ],
    targets: [
        .target(
            name: "Composed",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "ComposedTests",
            dependencies: ["Composed", "Quick", "Nimble"],
            path: "Tests"),
    ]
)
