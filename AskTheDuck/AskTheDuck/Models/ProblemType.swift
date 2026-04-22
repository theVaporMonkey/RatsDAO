import SwiftUI

enum ProblemType: String, CaseIterable, Identifiable, Codable {
    case equipment = "Equipment"
    case chemistry = "Water Chemistry"
    case troubleshooting = "Troubleshooting"
    case leakOrStructure = "Leak / Structure"
    case automation = "Automation & Controls"
    case other = "Other"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .equipment: return "wrench.and.screwdriver.fill"
        case .chemistry: return "flask.fill"
        case .troubleshooting: return "stethoscope"
        case .leakOrStructure: return "drop.triangle.fill"
        case .automation: return "cpu.fill"
        case .other: return "questionmark.bubble.fill"
        }
    }

    var shortPrompt: String {
        switch self {
        case .equipment:
            return "You are helping diagnose pool equipment (pumps, filters, heaters, salt cells, cleaners)."
        case .chemistry:
            return "You are helping with pool water chemistry (chlorine, pH, alkalinity, calcium hardness, cyanuric acid, phosphates, algae)."
        case .troubleshooting:
            return "You are helping troubleshoot a general pool issue reported in the field."
        case .leakOrStructure:
            return "You are helping diagnose possible leaks, cracks, or structural damage to a pool or deck."
        case .automation:
            return "You are helping with pool automation systems (Pentair IntelliCenter, Hayward Omni, Jandy iAqualink, relays, actuators)."
        case .other:
            return "You are helping a Pool Duck technician with a general pool service question."
        }
    }
}
