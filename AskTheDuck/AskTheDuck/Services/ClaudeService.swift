import Foundation
import UIKit

/// Thin wrapper around the Anthropic Messages API.
///
/// In production the API key should live behind a proxy owned by Pool Duck
/// (e.g. a small serverless endpoint) so that the secret never ships inside
/// the iOS binary. For development, the app reads `CLAUDE_API_KEY` from the
/// app's Info.plist (set via a `.xcconfig` that is NOT committed).
actor ClaudeService {
    struct Configuration {
        var endpoint: URL
        var model: String
        var apiKey: String
        var anthropicVersion: String

        static func fromBundle() -> Configuration {
            let info = Bundle.main.infoDictionary ?? [:]
            let key = (info["CLAUDE_API_KEY"] as? String) ?? ""
            let model = (info["CLAUDE_MODEL"] as? String) ?? "claude-sonnet-4-6"
            let endpoint = URL(string: (info["CLAUDE_ENDPOINT"] as? String)
                ?? "https://api.anthropic.com/v1/messages")!
            return Configuration(
                endpoint: endpoint,
                model: model,
                apiKey: key,
                anthropicVersion: "2023-06-01"
            )
        }
    }

    enum ClaudeError: LocalizedError {
        case missingKey
        case badStatus(Int, String)
        case decoding

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "Claude API key is missing. Add CLAUDE_API_KEY to the app configuration."
            case .badStatus(let code, let body):
                return "Claude returned HTTP \(code): \(body)"
            case .decoding:
                return "Could not decode Claude's response."
            }
        }
    }

    private let config: Configuration
    private let urlSession: URLSession

    init(config: Configuration = .fromBundle(), urlSession: URLSession = .shared) {
        self.config = config
        self.urlSession = urlSession
    }

    /// Sends a technician message (with optional photos) to Claude and returns
    /// the assistant's text reply. Uses the Messages API with the image
    /// content block for multimodal support.
    func ask(
        problem: ProblemType,
        history: [ChatMessage],
        newMessage: ChatMessage
    ) async throws -> String {
        guard !config.apiKey.isEmpty else { throw ClaudeError.missingKey }

        let system = Self.systemPrompt(for: problem)
        let messages = Self.encodeMessages(history: history + [newMessage])

        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(config.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 1500,
            "system": system,
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClaudeError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            throw ClaudeError.badStatus(http.statusCode, snippet)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]]
        else { throw ClaudeError.decoding }

        let text = content.compactMap { block -> String? in
            guard (block["type"] as? String) == "text" else { return nil }
            return block["text"] as? String
        }.joined(separator: "\n\n")

        return text.isEmpty ? "(No response)" : text
    }

    // MARK: - Prompt construction

    static func systemPrompt(for problem: ProblemType) -> String {
        """
        You are "Ask the Duck," the in-field AI assistant for Pool Duck \
        technicians and franchisees. Speak plainly, like a seasoned pool pro \
        talking to a teammate on a job site. Be concise, step-by-step, and \
        safety-conscious. Never guess when chemistry dosing is involved — \
        ask for the missing reading (pH, FC, TA, CH, CYA, pool volume) \
        before recommending amounts.

        Context for this question: \(problem.shortPrompt)

        Response format:
        1. **Likely cause** — one short paragraph.
        2. **Check these next** — bulleted diagnostic steps.
        3. **Fix** — numbered action items the tech can do on site.
        4. **Escalate if** — when to call the franchise owner or office.
        """
    }

    private static func encodeMessages(history: [ChatMessage]) -> [[String: Any]] {
        history.compactMap { message -> [String: Any]? in
            let role: String
            switch message.role {
            case .technician: role = "user"
            case .duck: role = "assistant"
            case .system: return nil
            }

            var contentBlocks: [[String: Any]] = []
            for attachment in message.attachments where attachment.kind == .image || attachment.kind == .video {
                let base64 = attachment.jpegData.base64EncodedString()
                contentBlocks.append([
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": base64
                    ]
                ])
            }
            if !message.text.isEmpty {
                contentBlocks.append(["type": "text", "text": message.text])
            }
            if contentBlocks.isEmpty { return nil }
            return ["role": role, "content": contentBlocks]
        }
    }
}
