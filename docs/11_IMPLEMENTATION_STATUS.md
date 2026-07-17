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

| Area                                      | Status  | Notes                                                                                                                                                                       |
| ----------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Product Constitution                      | Done    | PRD 원문과 Constitution v1 문서 구조가 저장소에 있음.                                                                                                                       |
| Auth                                      | Partial | Supabase Auth 기반 로그인/회원가입/비밀번호 재설정 흐름 있음. 실제 환경 검증은 Supabase 설정 필요.                                                                          |
| Capture / Inbox                           | Partial | 빠른 Inbox 등록, 검색/필터, Project/Someday 전환 흐름 있음. 주요 액션은 클릭/제출 중 피드백을 표시함.                                                                       |
| Projects                                  | Partial | 프로젝트와 계층형 활동 관리 흐름 있음. 활동 트리, 상세 편집, 부모 이동, 하위 진행률과 수동 완료 제안을 프로덕션 임시 계정으로 검증함. 실제 사용자 피드백 필요.              |
| Today                                     | Partial | 에너지/모드/핵심 행동 선택 흐름 있음. 주요 액션은 클릭/제출 중 피드백을 표시함.                                                                                             |
| Weekly Review                             | Partial | 주간 리뷰 기본 흐름 있음.                                                                                                                                                   |
| Health & Diet MVP                         | Partial | 프로필, 체크인, 체중 목표, 운동/리포트 화면 기본 구현 있음. 저장/삭제 액션은 클릭/제출 중 피드백을 표시함. 실제 사용 피드백 필요.                                           |
| Native App V1                             | Planned | iPhone·Mac 공용 SwiftUI 앱으로 전환을 계획함. Supabase를 원본 데이터 및 동기화 계층으로 유지하며, 첫 범위는 양 기기의 Inbox 기본 흐름이다.                                  |
| Deployment Automation                     | Partial | GitHub 비밀값 등록, 최초 history 복구, 실제 DB migration, Vercel Production 배포, repair 없는 일반 재실행을 완료함. Vercel Production Deployment Check 등록 여부 확인 필요. |
| Codex Delivery Process                    | Done    | 기능 PR은 사용자가 Preview 또는 테스트 빌드로 확인한 뒤 병합하며, 영문 Conventional Commit·한국어 PR·Squash merge·안전한 복구와 SSH·GitHub App 인증 자동화를 적용함.  |
| AI Memory / Life Graph                    | Planned | `life_context_*` 저장 구조 초안은 있으나, AI 관계 추천/승인 흐름은 미구현. 네이티브 생각 정리 AI는 V1 이후 기능으로 분리했다.                                              |
| Finance / Travel / Content / Relationship | Planned | 문서 기준만 있음.                                                                                                                                                           |

## Next Recommended Work

1. iPhone·Mac 공용 SwiftUI 프로젝트의 V1 범위와 기존 Supabase 직접 연동 방식을 구체화.
2. 양 기기에서 Inbox 조회·추가·수정·삭제 흐름을 구현.
3. V1 사용 후 AI 생각 정리 기능의 실제 입력 범위와 승인 UX를 검토.

## Recent Handoffs

- [2026-07-17 Production Deployment Smoke Test](./handoffs/2026-07-17-production-deployment-smoke-test.md)
- [2026-07-17 Supabase Migration History Repair](./handoffs/2026-07-17-supabase-migration-history-repair.md)
- [2026-07-17 Korean PR Automation](./handoffs/2026-07-17-korean-pr-automation.md)
- [2026-07-17 Git Convention](./handoffs/2026-07-17-git-convention.md)
- [2026-07-17 GitHub Authentication Automation](./handoffs/2026-07-17-github-authentication-automation.md)
- [2026-07-17 Supabase Deploy Automation](./handoffs/2026-07-17-supabase-deploy-automation.md)
- [2026-07-16 Action Hierarchy](./handoffs/2026-07-16-action-hierarchy.md)
- [2026-07-15 Click Interaction Feedback](./handoffs/2026-07-15-click-interaction-feedback.md)
- [2026-07-15 Health & Diet Current Implementation](./handoffs/2026-07-15-health-diet-current-implementation.md)
