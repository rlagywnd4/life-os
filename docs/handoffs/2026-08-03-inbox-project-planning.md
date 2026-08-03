# 2026-08-03 Inbox Project Planning

## 작업 목표

- Inbox를 빠른 수집·분류 공간으로 분리하고, 프로젝트 안에서 목표·계획·일정·실행·기록까지 이어지는 웹 흐름을 구현한다.

## 구현한 내용

- 미처리 Inbox 전용 목록, 빠른 입력, 수정, 보관, 삭제, 일반 일정 전환을 구현했다.
- Inbox 내용을 초기값으로 사용하는 5단계 프로젝트 생성 화면을 추가했다. 취소는 서버 요청을 만들지 않아 원본 Inbox를 보존하고, 초안 저장 또는 최종 생성은 DB RPC 하나에서 프로젝트·단계·첫 행동·Inbox 상태를 함께 기록한다.
- 프로젝트 목록 카드에 상태, 목표일, 현재 단계, 다음 행동, 마일스톤, 말단 활동 진행률과 계획 부족 배지를 표시한다.
- 상세 화면에 개요, 계획, 프로젝트 일정, 기록과 마일스톤 영역을 추가했다.
- 활동은 계층, 부모 이동, 상태·일정 수정, 완료, 형제 순서 이동, 접기/펼치기, 완료 표시 제어, 삭제 시 하위 재배치/함께 삭제를 지원한다.
- 일반 일정 CRUD와 프로젝트 활동을 함께 보는 날짜별 웹 캘린더를 추가했다.

## 변경 파일

- `supabase/migrations/202608030001_project_planning_enums.sql`, `202608030002_inbox_project_planning.sql`: 상태 확장, 계획·마일스톤·기록·일정 테이블, RLS, 검증 trigger, 원자적 생성 RPC를 추가한다.
- `src/features/inbox`, `src/features/projects`, `src/features/calendar`: 서버 액션과 재검증을 추가한다.
- `src/app/(protected)/inbox`, `projects`, `calendar`: 새 사용자 흐름과 화면을 구현한다.
- `src/lib/domain/project-planning.ts`: 진행률·추천·계획 부족 판단을 공통화한다.
- `tests/unit/project-planning.test.ts`, `tests/rls/rls-static.test.ts`: 핵심 도메인과 RLS migration 계약을 검증한다.

## 데이터 구조 및 API

- `projects`에 `goal`, `completion_criteria`, `next_action_id`, `archived_at`을 추가하고 기존 `reason`, `desired_outcome`을 backfill한다.
- `action_items`에 단계·순서·시작/마감/시간·종일·실제 소요·soft delete 필드를 추가한다.
- `project_milestones`, `project_records`, `calendar_events`를 추가한다.
- `create_project_plan`은 Inbox 전환을 포함한 생성 트랜잭션이며, `delete_action_item`은 하위 활동의 재배치 또는 함께 삭제를 처리한다.

## 주요 결정

- Inbox→프로젝트 변환은 물리 삭제가 아닌 `CONVERTED_TO_PROJECT` 상태와 연결 ID를 저장해 추적 가능하게 했다.
- 단계는 별도 엔티티가 아니라 `is_stage=true`인 최상위 활동으로 저장해 기존 무제한 활동 트리를 유지한다.
- 진행률은 말단 활동 기준이고, 활동이 없을 때만 마일스톤을 fallback으로 사용한다. 완료 프로젝트는 100%다.
- 다음 행동은 사용자 지정 값을 우선하고, 없을 때만 UI가 후보를 추천한다.

## PRD와의 차이

- PRD와 충돌하지 않는다. 반복 일정과 월/주간 캘린더는 이번 데이터 구조에는 포함하지 않았으며 별도 UX 결정을 남긴다.

## 임시 구현 및 기술 부채

- 프로젝트 생성 중 브라우저 탭을 닫는 경우의 자동 임시 저장은 구현하지 않았다. 사용자는 명시적인 “초안 저장”으로 안전하게 저장할 수 있다.
- 일반 일정은 날짜별 목록 UI이며 월/주간 그리드와 반복 일정은 후속 범위다.
- 이번 브랜치는 최신 `main`에서 분기했으며, 작업 트리에 있던 미추적 `native/` 폴더는 기존 사용자 작업으로 변경하지 않았다.

## 실제 사용 후 확인할 사항

- migration 적용 뒤 Inbox→초안/활성 프로젝트 전환이 RLS 계정에서 정상 작동하는지 확인한다.
- 긴 프로젝트 제목·트리 깊이·작은 모바일 화면에서 카드와 활동 조작이 자연스러운지 확인한다.
- 프로젝트 완료·보관과 Today 화면의 기존 활동 필터가 기대대로 동작하는지 확인한다.

## 남은 문제 및 다음 작업 후보

- 실제 Supabase migration 적용과 운영 통합/E2E는 아직 수행하지 않았다.
- 월/주간 캘린더, 반복 일정, 프로젝트 기록 메모 편집 UI, 네이티브 앱 동기화가 다음 후보이다.
