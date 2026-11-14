// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VoiceTypingModels",
    platforms: [.macOS(.v14)],
    products: [.library(name: "VoiceTypingModels", targets: ["VoiceTypingModels"])],
    dependencies: [
        .package(url: "https://github.com/Neywa-Labs/mlx-audio-swift.git", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm.git", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.33.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", from: "1.1.6"),
        .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.8.1")
    ],
    targets: [.target(name: "VoiceTypingModels", dependencies: [
        .product(name: "MLXAudioCore", package: "mlx-audio-swift"),
        .product(name: "MLXAudioVAD", package: "mlx-audio-swift"),
        .product(name: "MLXLLM", package: "mlx-swift-lm"),
        .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
        .product(name: "MLX", package: "mlx-swift"),
        .product(name: "MLXNN", package: "mlx-swift"),
        .product(name: "MLXFast", package: "mlx-swift"),
        .product(name: "MLXFFT", package: "mlx-swift"),
        .product(name: "Tokenizers", package: "swift-transformers"),
        .product(name: "HuggingFace", package: "swift-huggingface")
    ])]
)
