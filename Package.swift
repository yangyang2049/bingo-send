// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BingoSend",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "BingoSend", targets: ["BingoSend"])],
    targets: [
        .target(name: "BingoCore"),
        .executableTarget(name: "BingoSend", dependencies: ["BingoCore"]),
        .testTarget(name: "BingoCoreTests", dependencies: ["BingoCore"])
    ]
)
