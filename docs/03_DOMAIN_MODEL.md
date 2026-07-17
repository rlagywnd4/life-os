# Domain Model

## Life Graph

Life Graph는 LifeOS의 핵심 모델이다. 기록은 독립적인 row가 아니라 목표, 상태, 행동, 회고, 프로젝트와 연결되는 노드다.

초기 노드 후보:

- Goal
- Value
- Domain
- Project
- Task
- Habit
- Event
- Decision
- Reflection
- Metric
- Condition
- Emotion
- Energy
- Person
- Place
- Content
- Expense
- Health Record
- Learning Record

초기 관계 후보:

- `supports`
- `conflicts_with`
- `caused_by`
- `affected_by`
- `belongs_to`
- `depends_on`
- `blocked_by`
- `motivated_by`
- `learned_from`
- `related_to`
- `next_step_of`
- `replaced_by`
- `derived_from`

AI가 만든 관계는 사용자 확인 전까지 추론 상태로 저장한다.

## Domains

Constitution v1의 도메인은 다음과 같다.

- Vision
- Career
- Project
- Health
- Diet
- Finance
- Relationship
- Reflection
- Content
- Travel
- Learning
- Bucket List

## Current MVP Mapping

현재 저장소의 구현 범위:

- Today: `/today`
- Capture/Inbox: `/dashboard`, `/inbox`
- Project: `/projects`, `/projects/[id]`
- Review: `/weekly-review`, `/history`
- Health & Diet: `/health`, `/health/settings`, `/health/weight`, `/health/workout`, `/health/report`
- Someday: `/someday`

## Health & Diet MVP

구현 기준:

- 다이어트 프로필 등록 및 수정.
- 체중 목표와 단계 관리.
- 일일 건강 체크인.
- 걸음 수, 수면, 컨디션, 스트레스, 운동 완료 형태 기록.
- 저에너지 모드와 최소 행동을 실패가 아닌 계획 조정으로 표시.
- 주간/최근 요약에서 하나의 조정 포인트를 제안.

제외:

- 정교한 칼로리 자동 계산.
- 의료 진단.
- 웨어러블 실시간 동기화.
- 소셜 경쟁.
