import Foundation

enum Secrets {
    static let holidayApiKey: String = {
        guard let encoded = Bundle.main.object(forInfoDictionaryKey: "HOLIDAY_API_KEY_B64") as? String,
              !encoded.isEmpty,
              let decoded = decodeBase64URL(encoded) else {
            fatalError("HOLIDAY_API_KEY_B64 누락/디코딩 실패 — Secrets.xcconfig 확인")
        }
        return decoded
    }()

    private static func decodeBase64URL(_ s: String) -> String? {
        var b64 = s.replacingOccurrences(of: "-", with: "+")
                   .replacingOccurrences(of: "_", with: "/")
        let pad = (4 - b64.count % 4) % 4
        b64 += String(repeating: "=", count: pad)
        guard let data = Data(base64Encoded: b64) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
