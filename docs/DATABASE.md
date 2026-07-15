# Database

## ERD

```mermaid
erDiagram
  auth_users ||--|| profiles : owns
  auth_users ||--o{ inbox_items : owns
  auth_users ||--o{ projects : owns
  projects ||--o{ action_items : has
  inbox_items ||--o| projects : converts_to
  auth_users ||--o{ daily_plans : owns
  daily_plans ||--o{ daily_plan_actions : has
  action_items ||--o{ daily_plan_actions : scheduled_as
  auth_users ||--o{ someday_items : owns
  auth_users ||--o{ weekly_reviews : owns
  weekly_reviews ||--o{ weekly_review_focus_projects : focuses
```

## 테이블

- `profiles`: 시간대, 주 시작 요일, 프로젝트/핵심 행동 제한.
- `inbox_items`: 제목만으로 생성 가능한 생각 기록.
- `projects`: ACTIVE, WAITING, PAUSED, COMPLETED, ABANDONED, ARCHIVED 상태.
- `action_items`: 프로젝트에 속한 작은 행동.
- `daily_plans`: 날짜별 에너지와 모드. `unique(user_id, plan_date)`.
- `daily_plan_actions`: 오늘 계획에 선택된 행동. `unique(daily_plan_id, action_item_id)`.
- `someday_items`: 나중에 볼 항목.
- `weekly_reviews`: 주간 회고.
- `weekly_review_focus_projects`: 회고에서 선택한 최대 3개 초점 프로젝트.
- `daily_check_ins`: 하루 한 번 상태 기록.

## 제약과 인덱스

모든 사용자 소유 테이블은 `user_id default auth.uid()`와 RLS 정책을 가진다. 조회 빈도가 높은 `(user_id, status)`, `(user_id, date)` 조합에 인덱스를 둔다.

## 상태 전환

앱 규칙은 `src/lib/domain/rules.ts`에 있으며, DB에서는 닫힌 프로젝트에 새 행동을 추가하지 못하도록 트리거가 막는다. 활성 프로젝트 한도와 핵심 행동 한도는 RPC에서 확인한다.

## Migration 관리

초기 스키마는 `supabase/migrations/202607150001_initial_schema.sql`에 있다.
