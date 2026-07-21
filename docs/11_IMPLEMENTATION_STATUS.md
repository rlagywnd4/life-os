# Implementation Status

이 문서는 현재 LifeOS 구현 상태를 기능 단위로 요약한다. 자세한 제품 기준은 로컬 전용 `docs/LIFEOS_PRD.md`, 세부 변경 내역은 [10_CHANGELOG.md](./10_CHANGELOG.md), 작업별 인수인계는 [handoffs](./handoffs/)를 참고한다.

## 작성 규칙

- 기능 구현이나 의미 있는 UX/데이터 변경 후 갱신한다.
- "완료"는 실제 실행 또는 테스트 기준으로 확인된 범위만 표시한다.
- 임시 구현, 검증 부족, 사용자 사용 후 확인할 항목을 숨기지 않는다.
- PRD와 다르거나 아직 미정인 부분은 명시한다.

## Status Legend

- `Done`: 구현 및 기본 검증 완료.
- `Partial`: 사용할 수 있으나 범위 제한 또는 보강 필요.
- `Planned`: 아직 구현 전.
- `Blocked`: 사용자 결정, 외부 설정, 계정/키 등 선행 작업 필요.

## Current Summary

| Area                                      | Status  | Notes                                                                                                                                                                                                             |
| ----------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Product Constitution                      | Done    | PRD 원문과 Constitution v1 문서 구조가 저장소에 있음.                                                                                                                                                             |
| Auth                                      | Partial | 웹과 네이티브에 Supabase 로그인·회원가입·비밀번호 재설정 흐름이 있음. 네이티브 딥링크의 Supabase Redirect URL 등록과 실제 메일 확인이 남아 있음.                                                                  |
| Capture / Inbox                           | Partial | 웹과 네이티브에 빠른 등록, 전체 목록, 검색·카테고리 필터, CRUD, 상태 선택 메뉴, 트랜잭션 기반 Project 전환이 있고 운영 Supabase에서 Inbox 연결과 프로젝트 탭 조회까지 검증함. 물리 기기 UI 확인이 남아 있음.      |
| Projects                                  | Partial | 웹과 네이티브에 상태별 목록·상세, 깊이 제한 없는 활동 트리, 추가·수정·완료, 부모 이동, 경로·진행률·완료 제안이 있고 운영 Supabase 계약 검증을 통과함. 물리 기기 확인이 남아 있음.                                 |
| Today                                     | Partial | 웹과 네이티브에서 에너지·모드·메모·휴식 이유 저장, 미완료 활동 조회, 오늘/핵심 추가, 완료 처리를 사용할 수 있음. 실제 기기 사용 검증과 오늘 선택 결과 표시 보강이 남아 있음.                                      |
| Calendar                                  | Partial | 네이티브에서 월간·주간 보기, 활동 실행일·시간·마감일, 일반 일정 CRUD, 완료·드래그/날짜 재배치, Today 시간표와 계획량 안내를 구현하고 운영 DB 계약 검증을 통과함. 실제 iPhone·Mac 조작 검증과 웹 달력은 남아 있음. |
| Weekly Review                             | Partial | 네이티브에 검토할 Inbox·활성 프로젝트·최근 결과와 회고 임시 저장을 구현함. 웹의 임시 저장 버튼은 아직 DB에 연결되지 않음.                                                                                         |
| Health & Diet MVP                         | Partial | 네이티브에 전체 체크인, 프로필 설정, 체중 목표 CRUD, 최근 체중, 운동 루틴, 14일 리포트와 피드백이 있고 운영 Supabase 저장 계약을 검증함. 양 기기 UI 확인이 남아 있음.                                             |
| Native App V1                             | Partial | 모든 웹 사용자 경로의 SwiftUI·Supabase 흐름, iPhone·iPad·Mac 앱 아이콘 세트, 양 플랫폼 서명 빌드, 단위·운영 DB 검증, 물리 iPhone 설치·실행을 확인함. 사용자의 화면별 조작 확인이 남아 있음.                       |
| Deployment Automation                     | Partial | GitHub 비밀값 등록, 최초 history 복구, 실제 DB migration, Vercel Production 배포, repair 없는 일반 재실행을 완료함. Vercel Production Deployment Check 등록 여부 확인 필요.                                       |
| Codex Delivery Process                    | Done    | 기능 PR은 사용자가 Preview 또는 테스트 빌드로 확인한 뒤 병합하며, 영문 Conventional Commit·한국어 PR·Squash merge·안전한 복구와 SSH·GitHub App 인증 자동화를 적용함.                                              |
| AI Memory / Life Graph                    | Planned | `life_context_*` 저장 구조 초안은 있으나, AI 관계 추천/승인 흐름은 미구현. 네이티브 생각 정리 AI는 V1 이후 기능으로 분리했다.                                                                                     |
| Finance / Travel / Content / Relationship | Planned | 문서 기준만 있음.                                                                                                                                                                                                 |

## Next Recommended Work

1. iPhone과 Mac에서 월간·주간 달력의 드래그, 일정 편집, Today 반영을 직접 확인한다.
2. 확인된 UI 피드백을 반영한 뒤 달력 PR을 Ready for review로 전환한다.
3. 같은 실행일 기준을 사용하는 웹 달력을 구현한다.

## Recent Handoffs

- [2026-07-21 Native Calendar MVP](./handoffs/2026-07-21-native-calendar-mvp.md)
- [2026-07-21 Native App Icon](./handoffs/2026-07-21-native-app-icon.md)
- [2026-07-20 Native Inbox Status and Keyboard](./handoffs/2026-07-20-native-inbox-status-keyboard.md)
- [2026-07-20 Native Web Feature Parity](./handoffs/2026-07-20-native-web-feature-parity.md)
- [2026-07-18 Native Inbox Read](./handoffs/2026-07-18-native-inbox-read.md)
- [2026-07-17 Production Deployment Smoke Test](./handoffs/2026-07-17-production-deployment-smoke-test.md)
- [2026-07-17 Supabase Migration History Repair](./handoffs/2026-07-17-supabase-migration-history-repair.md)
- [2026-07-17 Korean PR Automation](./handoffs/2026-07-17-korean-pr-automation.md)
- [2026-07-17 Git Convention](./handoffs/2026-07-17-git-convention.md)
- [2026-07-17 GitHub Authentication Automation](./handoffs/2026-07-17-github-authentication-automation.md)
- [2026-07-17 Supabase Deploy Automation](./handoffs/2026-07-17-supabase-deploy-automation.md)
- [2026-07-16 Action Hierarchy](./handoffs/2026-07-16-action-hierarchy.md)
- [2026-07-15 Click Interaction Feedback](./handoffs/2026-07-15-click-interaction-feedback.md)
- [2026-07-15 Health & Diet Current Implementation](./handoffs/2026-07-15-health-diet-current-implementation.md)
