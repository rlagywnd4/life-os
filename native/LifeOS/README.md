# LifeOS Native

LifeOS의 iPhone·Mac 공용 SwiftUI 앱이다. 현재 범위는 기존 Supabase 계정으로 로그인하고 `UNREVIEWED` Inbox를 조회하는 것이다.

## 처음 실행하기

1. `Configuration/Secrets.xcconfig.example`을 `Configuration/Secrets.xcconfig`으로 복사한다.
2. 기존 Supabase 프로젝트의 URL과 publishable key를 입력한다. URL은 `https:/$()/프로젝트주소.supabase.co` 형태로 입력한다. Xcode 설정 파일에서 `$()`는 빈 문자열로 바뀌어 앱에는 정상적인 `https://` URL이 전달된다. 이 파일은 Git에 포함되지 않는다.
3. 프로젝트 디렉터리에서 `xcodegen generate`를 실행한다.
4. `LifeOS.xcodeproj`를 Xcode로 열어 `LifeOS` 스킴을 Mac 또는 iPhone 시뮬레이터에서 실행한다.

`Secrets.xcconfig`에 `LIFEOS_ACCOUNT_EMAIL`과 `LIFEOS_ACCOUNT_PASSWORD`도 입력하면 로그인 화면에 "내 계정으로 로그인" 버튼이 생긴다. 이 값은 개인 기기에 설치한 앱 안에는 포함되므로, 본인 전용 기기에서만 사용하고 파일을 절대 Git에 추가하지 않는다.

개인 Signing Team은 `project.yml`에 설정되어 있으므로 `xcodegen generate`를 다시 실행해도 유지된다. 새 Apple Developer 계정으로 소유권을 바꿀 때만 `DEVELOPMENT_TEAM` 값을 변경한다.

개인 iPhone에서 서명 오류가 발생하면 Xcode에 같은 Apple 계정이 로그인되어 있는지 확인한다. 앱 소유 계정을 바꾸거나 bundle identifier가 이미 사용 중일 때만 `project.yml`의 `DEVELOPMENT_TEAM`과 `PRODUCT_BUNDLE_IDENTIFIER`를 새 값으로 변경한다.

## 설계 원칙

- Supabase PostgreSQL이 원본 데이터다. SwiftData, iCloud, 오프라인 동기화는 V1 범위가 아니다.
- 앱에는 publishable key만 설정한다. service role key는 절대 넣지 않는다.
- 웹앱은 데이터 검증·긴급 접근·병행 사용을 위해 유지한다.
