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
| Capture / Inbox                           | Partial | 빠른 등록, 미처리 전용 목록, 검색·카테고리 필터, 수정·보관·삭제·일정 전환과 트랜잭션 기반 프로젝트 전환을 구현함. 운영 Supabase migration 적용과 실제 사용자 흐름 확인이 남음. |
| Projects                                  | Partial | 목표·완료 기준·기간·초안·단계·다음 행동·말단 활동 진행률·마일스톤·기록·계층 활동과 프로젝트 일정 화면을 구현함. 운영 DB 적용 및 실제 사용자 흐름 확인이 남음.              |
| Calendar                                  | Partial | 일반 일정 CRUD와 프로젝트 활동 일정 목록을 웹에 추가함. 월/주간 시각화, 반복 일정과 운영 DB 검증은 후속 작업임.                                                           |
| Today                                     | Partial | 에너지/모드/핵심 행동 선택 흐름 있음. 주요 액션은 클릭/제출 중 피드백을 표시함.                                                                                             |
| Weekly Review                             | Partial | 주간 리뷰 기본 흐름 있음.                                                                                                                                                   |
| Health & Diet MVP                         | Partial | 프로필, 체크인, 체중 목표, 운동/리포트 화면 기본 구현 있음. 저장/삭제 액션은 클릭/제출 중 피드백을 표시함. 실제 사용 피드백 필요.                                           |
| Native App V1                             | Planned | iPhone·Mac 공용 SwiftUI 앱으로 전환을 계획함. Supabase를 원본 데이터 및 동기화 계층으로 유지하며, 첫 범위는 양 기기의 Inbox 기본 흐름이다.                                  |
| Deployment Automation                     | Partial | GitHub 비밀값 등록, 최초 history 복구, 실제 DB migration, Vercel Production 배포, repair 없는 일반 재실행을 완료함. Vercel Production Deployment Check 등록 여부 확인 필요. |
| Codex Delivery Process                    | Done    | 기능 PR은 사용자가 Preview 또는 테스트 빌드로 확인한 뒤 병합하며, 영문 Conventional Commit·한국어 PR·Squash merge·안전한 복구와 SSH·GitHub App 인증 자동화를 적용함.  |
| AI Memory / Life Graph                    | Planned | `life_context_*` 저장 구조 초안은 있으나, AI 관계 추천/승인 흐름은 미구현. 네이티브 생각 정리 AI는 V1 이후 기능으로 분리했다.                                              |
| Finance / Travel / Content / Relationship | Planned | 문서 기준만 있음.                                                                                                                                                           |

## Next Recommended Work

1. 운영 Supabase에 2026-08-03 프로젝트 계획 migration을 적용하고 Inbox→프로젝트→일정→완료 흐름을 실제 계정으로 확인한다.
2. 웹 캘린더의 월/주간 보기와 반복 일정 정책을 결정한다.
3. 네이티브 앱에 프로젝트 계획 데이터 모델과 화면을 동기화한다.

## Recent Handoffs

- [2026-08-03 Inbox Project Planning](./handoffs/2026-08-03-inbox-project-planning.md)

- [2026-07-17 Production Deployment Smoke Test](./handoffs/2026-07-17-production-deployment-smoke-test.md)
- [2026-07-17 Supabase Migration History Repair](./handoffs/2026-07-17-supabase-migration-history-repair.md)
- [2026-07-17 Korean PR Automation](./handoffs/2026-07-17-korean-pr-automation.md)
- [2026-07-17 Git Convention](./handoffs/2026-07-17-git-convention.md)
- [2026-07-17 GitHub Authentication Automation](./handoffs/2026-07-17-github-authentication-automation.md)
- [2026-07-17 Supabase Deploy Automation](./handoffs/2026-07-17-supabase-deploy-automation.md)
- [2026-07-16 Action Hierarchy](./handoffs/2026-07-16-action-hierarchy.md)
- [2026-07-15 Click Interaction Feedback](./handoffs/2026-07-15-click-interaction-feedback.md)
- [2026-07-15 Health & Diet Current Implementation](./handoffs/2026-07-15-health-diet-current-implementation.md)
