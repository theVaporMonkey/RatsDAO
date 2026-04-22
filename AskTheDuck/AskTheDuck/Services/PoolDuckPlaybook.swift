import Foundation

/// Loads the Pool Duck playbook that gets injected into every Claude
/// system prompt.
///
/// The playbook is an ordinary markdown file bundled inside the app at
/// `Resources/playbook.md`. Keeping it as data (not code) means ops /
/// legal can update the franchise-wide tech playbook without touching
/// Swift — they just regenerate the file (typically from the real FDD /
/// Franchise Operations Manual) and rebuild.
///
/// Future: swap `load()` for a remote-config fetch so the playbook can
/// be updated franchise-wide without a TestFlight push.
enum PoolDuckPlaybook {

    /// Short hint that's always audience-forward even if `playbook.md`
    /// is missing. Used as a last-resort fallback so Claude never
    /// accidentally starts talking to the homeowner.
    private static let audienceFallback = """
    AUDIENCE
    You are speaking to a Pool Duck field technician who is at the pool \
    right now. You are NOT speaking to the homeowner. Use trade language \
    (FC, TA, CYA, SWG, VS pump, DE grid, MPV, etc.) freely. Be direct, \
    pro-to-pro.
    """

    /// Returns the playbook text to splice into a system prompt.
    /// Prefers the bundled markdown file; falls back to a minimal
    /// audience directive if the file is missing.
    static func systemPromptFragment(bundle: Bundle = .main) -> String {
        guard let url = bundle.url(forResource: "playbook", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return audienceFallback
        }
        return stripHTMLComments(text)
    }

    /// The existing audience/playbook fallback — also used by
    /// `QuoteService` so extraction stays aimed at the tech, not the
    /// homeowner, even if the markdown file is missing.
    static var audience: String { audienceFallback }

    /// Removes `<!-- … -->` blocks so Claude doesn't spend tokens on the
    /// "this is a placeholder" disclaimer baked into the file.
    private static func stripHTMLComments(_ s: String) -> String {
        var result = s
        while let start = result.range(of: "<!--"),
              let end = result.range(of: "-->", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
