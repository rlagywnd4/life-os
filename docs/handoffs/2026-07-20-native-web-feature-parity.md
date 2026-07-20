# Native Web Feature Parity Handoff

## 작업 목표

LifeOS 웹앱의 전체 사용자 경로를 기존 Supabase 인증·데이터·RLS를 유지한 iPhone·Mac 공용 SwiftUI 앱으로 전환한다.

## 구현한 내용

- 네이티브 홈에 대시보드 요약, 빠른 Inbox, 주요 화면 바로가기를 추가했다.
- Inbox 전체 목록·검색·카테고리 필터·CRUD·상태 변경과 `convert_inbox_to_project` RPC 전환을 구현했다.
- 프로젝트 상태별 목록과 활성 한도, 재귀 활동 트리, 활동 상세·경로·진행률·완료 제안·하위 활동 추가·안전한 부모 이동을 구현했다.
- Today의 에너지·모드·메모·휴식 이유, 권장 핵심 행동 범위, 오늘/핵심 추가와 완료 처리를 구현했다.
- Someday, 히스토리, 설정 조회와 주간 리뷰 요약·실제 임시 저장을 구현했다.
- 건강 체크인의 모든 웹 필드, 건강 프로필, 체중 목표 CRUD, 최근 체중, 운동 루틴, 14일 행동 유지율과 피드백을 구현했다.
- 로그인, 개인 계정 원클릭 로그인, 회원가입, 비밀번호 찾기와 앱 딥링크 기반 재설정을 구현했다.
- macOS 앱 빌드, iOS generic device 빌드, macOS 단위 테스트를 통과했다.
- 운영 Supabase에 임시 데이터를 생성하고 다시 삭제하는 통합 검증으로 인증, 전체 조회, Inbox CRUD·프로젝트 전환 RPC, 계층 활동, Today RPC, 활동 완료, Someday, 주간 리뷰, 체중 목표와 건강 체크인을 확인했다.
- 자동 서명된 iPhone 빌드를 연결된 iPhone 15 Pro에 설치·실행하고 프로세스가 정상 유지되는 것을 확인했다.

## 변경 파일

- `native/LifeOS/Sources/App/*`
- `native/LifeOS/Sources/Features/Auth/*`
- `native/LifeOS/Sources/Features/Dashboard/*`
- `native/LifeOS/Sources/Features/Health/*`
- `native/LifeOS/Sources/Features/Inbox/*`
- `native/LifeOS/Sources/Features/More/*`
- `native/LifeOS/Sources/Features/Projects/*`
- `native/LifeOS/Sources/Features/Today/*`
- `native/LifeOS/Sources/Resources/Info.plist`
- `native/LifeOS/Tests/*`
- 생성된 Xcode 프로젝트와 필수 운영 문서

## 데이터 구조 변경

없음. 기존 Supabase 테이블, enum, 제약 조건과 RLS를 그대로 사용한다.

## API 변경

없음. 네이티브 앱이 기존 Data API와 `convert_inbox_to_project`, `add_core_action_to_today` RPC를 직접 사용한다.

## 주요 구현 결정과 이유

- Supabase를 웹·Mac·iPhone의 단일 데이터 원본으로 유지해 별도 iCloud나 로컬 동기화 계층 없이 기기 간 데이터를 공유한다.
- iPhone은 홈·Inbox·프로젝트·더보기·건강 탭, Mac은 같은 기능을 사이드바에서 제공한다.
- 활동 계층 계산과 건강 리포트 계산은 웹의 규칙을 Swift로 동일하게 옮겼다.
- 인증 메일은 `lifeos://` 딥링크로 앱에 복귀한다.
- 웹에서 동작하지 않던 주간 리뷰 임시 저장은 네이티브에서 기존 `weekly_reviews` 테이블에 연결했다.

## 기존 PRD와 달라진 점

없음. AI는 합의한 대로 V1에서 제외했다.

## 임시 구현과 기술 부채

- 네이티브 앱은 온라인 Supabase 연결을 전제로 하며 오프라인 큐와 실시간 구독은 없다.
- 인증 딥링크는 개인용 custom URL scheme이다. 공개 배포 시 Universal Link 검토가 필요하다.
- 웹의 주간 리뷰 임시 저장 버튼은 여전히 서버 저장에 연결되지 않아 네이티브가 한 단계 앞선다.
- 개인 Signing Team과 자동 서명을 XcodeGen 원본에 기록해 프로젝트 재생성 후에도 유지한다. 앱 소유 계정을 바꿀 때만 Team ID를 변경해야 한다.

## 실제 사용 후 확인해야 할 사항

- Mac과 iPhone에서 같은 계정으로 주요 목록 수와 상태가 일치하는지 확인한다.
- 한 기기에서 Inbox, 프로젝트 활동, Today, 건강 체크인, 체중 목표, 주간 리뷰를 저장한 뒤 다른 기기에서 새로고침해 반영되는지 확인한다.
- Inbox→Project 전환과 활성 프로젝트 한도 오류가 의도한 한국어 안내로 보이는지 확인한다.
- 인증 메일 링크가 해당 기기의 LifeOS 앱을 열고 비밀번호 재설정 화면으로 이어지는지 확인한다.
- 작은 iPhone 화면에서 건강 설정 요일 버튼과 활동 계층 들여쓰기가 사용 가능한지 확인한다.

## 남은 문제

- 데이터 API와 RPC의 실제 사용자 계정 통합 검증 및 물리 iPhone 설치·실행은 완료했으며, 남은 범위는 사용자의 Mac·iPhone 화면별 조작과 기기 간 새로고침 확인이다.
- Supabase Auth Redirect URL 허용 목록에 네이티브 콜백 두 개를 등록해야 한다.

## 다음 작업 후보

1. 실제 Mac·iPhone 인수 확인에서 발견된 오류를 수정한다.
2. 검증 완료 후 전환 PR을 Ready for review로 바꾸고 병합한다.
3. V1 안정화 뒤 메뉴 막대 빠른 입력, 알림, 위젯과 AI 생각 정리를 별도 버전으로 계획한다.
