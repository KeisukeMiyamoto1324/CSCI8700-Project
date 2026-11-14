import Foundation
import Tokenizers
import MLXLMCommon

// ---------------------------------------------------------
// Adapt the local swift-transformers tokenizer without compiler plugins.
// No remote model identifier is used by this loader.
// ---------------------------------------------------------
struct LocalTokenizerLoader: MLXLMCommon.TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        let tokenizer = try await AutoTokenizer.from(modelFolder: directory)
        return LocalTokenizer(upstream: tokenizer)
    }
}

private struct LocalTokenizer: MLXLMCommon.Tokenizer {
    let upstream: any Tokenizers.Tokenizer
    var bosToken: String? { upstream.bosToken }
    var eosToken: String? { upstream.eosToken }
    var unknownToken: String? { upstream.unknownToken }

    func encode(text: String, addSpecialTokens: Bool) -> [Int] {
        return upstream.encode(text: text, addSpecialTokens: addSpecialTokens)
    }

    func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
        return upstream.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
    }

    func convertTokenToId(_ token: String) -> Int? { return upstream.convertTokenToId(token) }
    func convertIdToToken(_ id: Int) -> String? { return upstream.convertIdToToken(id) }

    func applyChatTemplate(
        messages: [[String: any Sendable]], tools: [[String: any Sendable]]?,
        additionalContext: [String: any Sendable]?
    ) throws -> [Int] {
        return try upstream.applyChatTemplate(messages: messages, tools: tools, additionalContext: additionalContext)
    }
}
