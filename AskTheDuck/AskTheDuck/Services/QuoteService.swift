import Foundation

/// Generates a first-draft `Quote` from the chat transcript by asking
/// Claude to extract parts, labor hours, and notes in structured JSON.
/// The tech then edits the result in `QuoteView`.
actor QuoteService {
    struct ExtractedLineItem: Codable {
        let description: String
        let partNumber: String?
        let quantity: Double?
        let unitCost: Double?
    }

    struct Extraction: Codable {
        let lineItems: [ExtractedLineItem]
        let laborHours: Double?
        let notes: String?
        let localMarketNote: String?
        let suggestedMarkupPercent: Double?
    }

    enum QuoteError: LocalizedError {
        case missingKey
        case badStatus(Int, String)
        case decoding(String)

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "Claude API key is missing."
            case .badStatus(let c, let b):
                return "Claude returned HTTP \(c): \(b)"
            case .decoding(let s):
                return "Couldn't parse Claude's quote response: \(s)"
            }
        }
    }

    private let config: ClaudeService.Configuration
    private let urlSession: URLSession

    init(
        config: ClaudeService.Configuration = .fromBundle(),
        urlSession: URLSession = .shared
    ) {
        self.config = config
        self.urlSession = urlSession
    }

    /// Returns a draft quote. Caller persists + edits.
    func draft(
        from record: ServiceRecord,
        existingQuote: Quote? = nil,
        technicianId: String,
        technicianName: String
    ) async throws -> Quote {
        let extraction = try await extract(from: record)

        var items = extraction.lineItems.map { item in
            QuoteLineItem(
                description: item.description,
                partNumber: item.partNumber,
                quantity: item.quantity ?? 1,
                unitCost: item.unitCost ?? 0
            )
        }
        if items.isEmpty {
            items = [
                QuoteLineItem(
                    description: "Diagnostic / part TBD",
                    partNumber: nil,
                    quantity: 1,
                    unitCost: 0
                )
            ]
        }

        let markup = extraction.suggestedMarkupPercent
            .map { max(0, min(200, $0)) } ?? 100

        return Quote(
            id: existingQuote?.id ?? UUID(),
            createdAt: existingQuote?.createdAt ?? Date(),
            technicianId: technicianId,
            technicianName: technicianName,
            customer: record.customer,
            problem: record.problem,
            serviceRecordID: record.id,
            lineItems: items,
            laborHours: extraction.laborHours ?? 1,
            laborRate: existingQuote?.laborRate ?? 125,
            markupPercent: markup,
            localMarketNote: extraction.localMarketNote ?? "",
            notes: extraction.notes ?? "",
            status: .draft
        )
    }

    // MARK: - Internal

    private func extract(from record: ServiceRecord) async throws -> Extraction {
        guard !config.apiKey.isEmpty else { throw QuoteError.missingKey }

        let transcript = record.transcript.map {
            "\($0.role.rawValue.uppercased()): \($0.text)"
        }.joined(separator: "\n\n")

        let system = """
        You extract structured repair-quote data for Pool Duck technicians.
        \(PoolDuckPlaybook.audience)

        The tech has been diagnosing:
        - Customer: \(record.customer.name)
        - Address: \(record.customer.address)
        - Problem type: \(record.problem.rawValue)

        From the chat transcript, identify:
        - Parts the tech is likely to replace (description, part number if
          mentioned, quantity, estimated unit cost at dealer wholesale).
        - Estimated labor hours.
        - A suggested markup percentage. Pool Duck's default is 100% on
          parts. Only recommend a lower markup (e.g. 60–90%) if the
          transcript explicitly mentions local pricing pressure or the
          customer pushing back on cost. Never recommend above 100%.
        - A brief local-market note if relevant.
        - Notes the tech should include on the quote.

        Respond with ONLY a valid JSON object of this exact shape:
        {
          "lineItems": [
            {"description": "...", "partNumber": "...", "quantity": 1, "unitCost": 0.0}
          ],
          "laborHours": 1.0,
          "notes": "...",
          "localMarketNote": "...",
          "suggestedMarkupPercent": 100
        }
        If you cannot determine a value, omit the key (except lineItems,
        which must be an array — empty if unknown). Do not wrap in code
        fences or include any prose.
        """

        let user: [String: Any] = [
            "role": "user",
            "content": [["type": "text", "text": "Transcript:\n\n\(transcript)"]]
        ]

        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(config.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 1200,
            "system": system,
            "messages": [user]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuoteError.decoding("no http response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw QuoteError.badStatus(http.statusCode, body)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let text = content.compactMap({ $0["text"] as? String }).first
        else { throw QuoteError.decoding("no content.text in response") }

        let clean = stripFences(text)
        guard let jsonData = clean.data(using: .utf8) else {
            throw QuoteError.decoding("non-utf8 payload")
        }
        do {
            return try JSONDecoder().decode(Extraction.self, from: jsonData)
        } catch {
            throw QuoteError.decoding(error.localizedDescription + " // \(clean.prefix(300))")
        }
    }

    private func stripFences(_ text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            // drop opening fence (optionally with a language tag)
            if let newlineIndex = trimmed.firstIndex(of: "\n") {
                trimmed = String(trimmed[trimmed.index(after: newlineIndex)...])
            }
            if trimmed.hasSuffix("```") {
                trimmed = String(trimmed.dropLast(3))
            }
        }
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
