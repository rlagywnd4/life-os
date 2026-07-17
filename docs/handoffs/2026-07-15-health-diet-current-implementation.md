# Health & Diet Current Implementation

Date: 2026-07-15
Status: Documentation only

## 작업 목표

현재 저장소에 이미 구현된 Health & Diet 기능을 PRD 기준으로 인수인계 가능하게 정리한다. 이번 작업은 기능 코드를 수정하지 않고, 현재 구현 범위와 남은 확인 항목을 기록한다.

## 구현한 내용

이번 handoff 작성 시점에 확인한 구현은 다음과 같다.

- `/health`: 오늘 건강 체크인 화면.
- `/health/settings`: 다이어트 프로필과 건강 설정.
- `/health/weight`: 현재/목표/최근 체중, 단계별 목표 체중 관리.
- `/health/workout`: 주말 운동 A/B 루틴과 최소 버전.
- `/health/report`: 최근 행동 유지율과 간단 피드백.

## 변경 파일

이번 handoff 작업에서 기능 코드는 변경하지 않았다.

문서/운영 구조 변경:

- `docs/LIFEOS_PRD.md`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/README.md`
- `docs/handoffs/2026-07-15-health-diet-current-implementation.md`

## 데이터 구조 변경

이번 handoff 작업 자체는 데이터 구조를 변경하지 않았다.

현재 Health & Diet 구현이 사용하는 주요 테이블:

- `health_profiles`
- `health_weight_goals`
- `health_check_ins`

현재 장기 컨텍스트 저장을 위해 별도 변경으로 준비된 테이블:

- `life_context_documents`
- `life_context_entries`

## API 변경

이번 handoff 작업 자체는 API를 변경하지 않았다.

현재 Health & Diet 기능은 Next.js Server Action을 통해 저장한다.

- `saveHealthProfile`
- `saveHealthCheckIn`
- `saveHealthGoal`
- `deleteHealthGoal`

## 주요 구현 결정과 이유

- Health와 Diet는 현재 별도 완전 분리 모듈이 아니라 `/health` 하위 흐름으로 묶여 있다.
- 체중은 단일 수치보다 최근 흐름과 단계 목표로 다룬다.
- 운동은 전체 루틴과 최소 버전을 함께 보여준다.
- 체크인은 수면, 컨디션, 스트레스, 저에너지 모드를 함께 기록해 체중/운동만으로 판단하지 않도록 한다.
- 기록이 없는 날을 실패로 계산하지 않는 문구가 리포트에 포함되어 있다.

## 기존 PRD와 달라진 점

- PRD의 Phase 1 범위 중 간단 식사 기록은 아직 독립 기능으로 구현되어 있지 않다. 현재는 체크인 안의 `계획 밖 간식`, `저녁 과식`, `자유식`, `음주` 같은 플래그로 다룬다.
- PRD의 "AI 체크인용 데이터 조회"는 데이터와 피드백 함수의 기초는 있으나, 실제 외부 AI 연동이나 승인 흐름은 구현되어 있지 않다.
- PRD의 Life Graph 관계 후보와 사용자 승인 흐름은 아직 Health 화면에 연결되어 있지 않다.

## 임시 구현과 기술 부채

- 계획된 간식 알림은 mock 단계이며 실제 푸시 알림은 없다.
- 활동 수준은 단일 선택값이라 평일/주말 차이를 충분히 표현하지 못할 수 있다.
- 식사 기록이 체크인 플래그 중심이라 사진/텍스트/간단 선택 입력 요구사항을 아직 완전히 충족하지 않는다.
- 리포트 피드백은 로컬 규칙 기반 문구이며 AI 요약은 아니다.
- 실제 Supabase 환경에서 인증/RLS/저장 흐름을 사용자가 직접 검증해야 한다.

## 실제 사용 후 확인해야 할 사항

- 프로필 등록 시 입력 항목이 부담스럽지 않은지.
- 현재 체중과 목표 체중을 동시에 입력하는 방식이 압박감을 만들지 않는지.
- 활동 수준 단일 선택이 실제 생활을 표현하기에 충분한지.
- 매일 체크인이 귀찮지 않은지.
- 체크인 후 오늘 무엇을 하면 되는지 더 선명해지는지.
- 저에너지 모드와 최소 운동 문구가 실제로 부담을 줄이는지.
- 식사 기록을 현재 플래그 방식으로 충분히 쓸 수 있는지.

## 남은 문제

- 사용자의 실제 사용 피드백이 아직 반영되지 않았다.
- Health/Diet를 하나로 유지할지, Diet를 별도 모듈로 분리할지 결정이 필요하다.
- 민감 건강 데이터 export/delete UI는 아직 명확히 연결되어 있지 않다.
- PRD 원문과 현재 구현 상태를 계속 비교하는 운영 루틴이 필요하다.

## 다음 작업 후보

1. 사용자가 `/health/settings`에서 프로필을 직접 등록하고 피드백을 남긴다.
2. 체크인 흐름을 하루 이상 실제로 사용해본다.
3. 사용 피드백을 기준으로 작은 UX 수정과 제품 방향 변경을 분리한다.
4. 식사 기록을 독립 기능으로 만들지, 체크인 플래그를 보강할지 결정한다.

## 실행 방법

```bash
pnpm dev
```

브라우저에서 `/health`, `/health/settings`, `/health/weight`, `/health/workout`, `/health/report`를 확인한다.

## 테스트 결과

```bash
pnpm test
```

2026-07-15 기준 단위 테스트 2개 파일, 13개 테스트가 통과했다.
