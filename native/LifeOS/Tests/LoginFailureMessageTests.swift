import Supabase
import XCTest
@testable import LifeOS

final class LoginFailureMessageTests: XCTestCase {
    func testExplainsInvalidCredentials() {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.supabase.co/auth/v1/token")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )!
        let error = AuthError.api(
            message: "Invalid login credentials",
            errorCode: .invalidCredentials,
            underlyingData: Data(),
            underlyingResponse: response
        )

        XCTAssertEqual(LoginFailureMessage.make(from: error), "이메일 또는 비밀번호가 맞지 않습니다.")
    }

    func testExplainsMissingInternetConnection() {
        let error = URLError(.notConnectedToInternet)

        XCTAssertEqual(LoginFailureMessage.make(from: error), "인터넷 연결을 확인한 뒤 다시 시도해 주세요.")
    }

    func testExplainsInvalidSupabaseKey() {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.supabase.co/auth/v1/token")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let error = AuthError.api(
            message: "Invalid API key",
            errorCode: .unknown,
            underlyingData: Data(),
            underlyingResponse: response
        )

        XCTAssertEqual(
            LoginFailureMessage.make(from: error),
            "Supabase publishable key가 현재 프로젝트와 맞지 않습니다. Secrets.xcconfig 설정을 확인해 주세요."
        )
    }
}
