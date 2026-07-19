import Foundation
import Supabase

enum SupabaseConfigurationError: LocalizedError {
    case missingValue(String)
    case invalidURL
    case truncatedURL

    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "\(key) 값이 비어 있습니다."
        case .invalidURL:
            return "Supabase URL 형식이 올바르지 않습니다."
        case .truncatedURL:
            return "Supabase URL이 https:까지만 읽혔습니다. Secrets.xcconfig의 URL을 https:/$()/프로젝트주소.supabase.co 형식으로 입력해 주세요."
        }
    }
}

enum SupabaseConfiguration {
    static func makeClient(bundle: Bundle = .main) throws -> SupabaseClient {
        let urlString = try requiredValue("SupabaseURL", bundle: bundle)
        let publishableKey = try requiredValue("SupabasePublishableKey", bundle: bundle)

        if urlString == "https:" {
            throw SupabaseConfigurationError.truncatedURL
        }

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
