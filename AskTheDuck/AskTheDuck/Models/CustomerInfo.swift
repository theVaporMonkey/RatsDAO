import Foundation

struct CustomerInfo: Codable, Hashable {
    var name: String
    var address: String
    var phone: String

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        phone.filter(\.isNumber).count >= 7
    }

    static let empty = CustomerInfo(name: "", address: "", phone: "")
}
