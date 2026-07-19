# Native Inbox Read Handoff

## 작업 목표

iPhone과 Mac에서 공용으로 실행되는 LifeOS 네이티브 V1의 첫 세로 흐름을 만든다. 기존 Supabase 계정으로 로그인한 뒤, 웹에 이미 저장된 검토 전 Inbox를 읽는 범위로 제한한다.

## 구현한 내용

- `native/LifeOS`에 iOS 18·macOS 15 공용 SwiftUI 앱 프로젝트를 추가했다.
- 이메일·비밀번호로 기존 Supabase 계정에 로그인하고 로그아웃할 수 있다.
- 로그인한 사용자의 `inbox_items` 중 `UNREVIEWED` 항목을 최신순으로 읽고, 당겨서 새로고침하거나 앱이 다시 활성화될 때 갱신한다.
- Mac은 사이드바와 Inbox 상세 화면을, iPhone은 목록 중심 탐색을 제공한다.
- URL과 publishable key는 추적하지 않는 `Secrets.xcconfig`에 보관한다. 예제 파일과 실행 안내를 제공한다.
- `supabase-swift` 2.46.0과 잠금 파일을 고정했다. 생성된 Xcode 프로젝트도 함께 관리한다.

## 변경 파일

- `.gitignore`
- `native/LifeOS/project.yml`
- `native/LifeOS/LifeOS.xcodeproj/`
- `native/LifeOS/Configuration/`
- `native/LifeOS/Sources/`
- `native/LifeOS/Tests/InboxItemTests.swift`
- `native/LifeOS/README.md`
- `docs/ARCHITECTURE.md`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-18-native-inbox-read.md`

## 데이터 구조 변경

없음. 기존 `inbox_items` 테이블과 `UNREVIEWED` 상태를 읽기만 한다.

## API 변경

없음. 네이티브 앱은 기존 Supabase Auth와 Data API를 RLS 권한으로 직접 사용한다.

## 주요 구현 결정과 이유

- 하나의 SwiftUI 타깃으로 iPhone과 Mac의 모델·인증·Inbox 코드를 공유한다. 플랫폼별로는 탐색 구조만 다르게 했다.
- Supabase를 계속 단일 원본 데이터로 사용한다. 두 기기 사이에 별도 동기화나 데이터 가져오기를 만들 필요가 없다.
- URL과 publishable key는 로컬 `Secrets.xcconfig`로 분리한다. 공개 저장소와 PR 기록에 개인 연결 정보를 남기지 않기 위해서다.
- 앱에는 publishable key만 허용하며, service role key를 넣지 않는다. 기존 RLS가 각 사용자 데이터 접근을 제한한다.

## 기존 PRD와 달라진 점

없음. PRD는 수정하지 않았다. 이 작업은 네이티브 V1의 첫 구현 순서를 구체화한 것이다.

## 임시 구현과 기술 부채

- Inbox는 읽기 전용이며, 추가·수정·삭제·검색·실시간 갱신은 아직 없다.
- 회원가입과 비밀번호 재설정은 현재 웹에서 계속 처리한다.
- XcodeGen을 사용해 프로젝트를 재생성할 수 있다. 생성된 Xcode 프로젝트도 커밋했으므로 XcodeGen 없이 열 수 있지만, `project.yml` 변경 뒤에는 다시 생성해야 한다.

## 실제 사용 후 확인해야 할 사항

- 기존 Supabase URL과 publishable key를 로컬 설정에 넣은 뒤, 기존 계정으로 로그인되는지 확인한다.
- 웹에서 만든 검토 전 Inbox가 Mac과 iPhone 양쪽에 동일하게 보이는지 확인한다.
- Inbox 목록의 제목·설명·카테고리 표시 밀도가 두 기기에서 매일 사용하기 편한지 확인한다.

## 남은 문제

- 개인 Supabase 설정을 의도적으로 저장소에 넣지 않아 실제 계정 접속은 아직 검증하지 않았다.
- 실제 iPhone 실행에는 Xcode에서 Apple 개발 팀 서명이 필요하다.

## 후속 수정

- 2026-07-19: `Debug.xcconfig`과 `Release.xcconfig`에서 빈 기본값을 먼저 선언하고 마지막에 `Secrets.xcconfig`를 포함하도록 순서를 바꿨다. 이전 순서는 사용자가 입력한 URL과 키를 다시 빈값으로 덮어써 앱이 Supabase URL 설정 오류를 표시했다.
- 2026-07-19: Xcode의 xcconfig 문법이 `https://` 중 `//` 뒤를 주석으로 처리해 URL을 `https:`로 자르는 것을 확인했다. 예제와 안내를 `https:/$()/프로젝트주소.supabase.co` 형식으로 바꾸고, 앱에서 해당 오류를 구체적으로 안내한다.

## 다음 작업 후보

1. 실제 계정으로 Mac과 iPhone Inbox 읽기 흐름을 확인한다.
2. 네이티브 Inbox 추가·수정·삭제를 구현한다.
3. 필요한 경우 앱 활성화 갱신 외의 Supabase Realtime 구독을 검토한다.
