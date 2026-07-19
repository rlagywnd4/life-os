# LifeOS Native

LifeOS의 iPhone·Mac 공용 SwiftUI 앱이다. 현재 범위는 기존 Supabase 계정으로 로그인하고 `UNREVIEWED` Inbox를 조회하는 것이다.

## 처음 실행하기

1. `Configuration/Secrets.xcconfig.example`을 `Configuration/Secrets.xcconfig`으로 복사한다.
2. 기존 Supabase 프로젝트의 URL과 publishable key를 입력한다. URL은 `https:/$()/프로젝트주소.supabase.co` 형태로 입력한다. Xcode 설정 파일에서 `$()`는 빈 문자열로 바뀌어 앱에는 정상적인 `https://` URL이 전달된다. 이 파일은 Git에 포함되지 않는다.
3. 프로젝트 디렉터리에서 `xcodegen generate`를 실행한다.
4. `LifeOS.xcodeproj`를 Xcode로 열어 `LifeOS` 스킴을 Mac 또는 iPhone 시뮬레이터에서 실행한다.

개인 iPhone에서 실행하기 전에는 Xcode의 Signing & Capabilities에서 본인 Apple 개발 팀을 선택한다. bundle identifier가 이미 사용 중이면 `project.yml`의 `PRODUCT_BUNDLE_IDENTIFIER`를 본인 식별자로 변경한다.

## 설계 원칙

- Supabase PostgreSQL이 원본 데이터다. SwiftData, iCloud, 오프라인 동기화는 V1 범위가 아니다.
- 앱에는 publishable key만 설정한다. service role key는 절대 넣지 않는다.
- 웹앱은 데이터 검증·긴급 접근·병행 사용을 위해 유지한다.
