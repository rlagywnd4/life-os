import Foundation
import Supabase

enum SupabaseConfigurationError: LocalizedError {
    case missingValue(String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "\(key) 값이 비어 있습니다."
        case .invalidURL:
            return "Supabase URL 형식이 올바르지 않습니다."
        }
    }
}

enum SupabaseConfiguration {
    static func makeClient(bundle: Bundle = .main) throws -> SupabaseClient {
        let urlString = try requiredValue("SupabaseURL", bundle: bundle)
        let publishableKey = try requiredValue("SupabasePublishableKey", bundle: bundle)

        guard let url = URL(string: urlString) else {
            throw SupabaseConfigurationError.invalidURL
        }

        return SupabaseClient(supabaseURL: url, supabaseKey: publishableKey)
    }

    private static func requiredValue(_ key: String, bundle: Bundle) throws -> String {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            throw SupabaseConfigurationError.missingValue(key)
        }
        return value
    }
}
