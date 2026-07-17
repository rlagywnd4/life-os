# 2026-07-16 Action Hierarchy

Date: 2026-07-16
Status: 구현 및 자동 검증 완료, 실제 사용자 환경 확인 필요

## 작업 목표

활동을 깊이 제한 없는 트리 구조로 세분화하고, 활동 편집과 부모 이동, 상위 경로, 하위 진행률, 수동 완료 제안을 제공한다.

## 구현한 내용

- 기존 `action_items`에 선택적인 부모 참조를 추가했다.
- 프로젝트 활동 목록을 들여쓰기 트리로 렌더링하고 각 부모 노드에 접기/펼치기 버튼을 추가했다.
- 활동 상세 라우트 `/projects/[id]/actions/[actionId]`를 추가했다.
- 상세 화면에서 제목, 내용, 예상 시간과 부모 활동을 수정할 수 있다.
- 활동을 최상위로 이동하거나 같은 프로젝트의 다른 활동 아래로 이동할 수 있다.
- 상세 화면에서 현재 활동을 부모로 하는 하위 활동을 바로 생성할 수 있다.
- 프로젝트와 모든 조상 활동을 현재 활동까지 breadcrumb로 표시한다.
- 각 부모 활동에 전체 후손의 완료 개수와 진행률을 표시한다.
- 모든 후손이 완료되면 부모를 자동 완료하지 않고 `완료하기` 액션을 제안한다.
- 계층 계산, 경로, 후손 탐색, 진행률과 폼 검증에 단위 테스트를 추가했다.
- SQL 정적 테스트에 자기 참조 키와 소유권·프로젝트·순환 검증 확인을 추가했다.

## 변경 파일

- `supabase/migrations/202607160001_action_hierarchy.sql`
- `src/types/database.ts`
- `src/lib/validation/schemas.ts`
- `src/lib/domain/action-tree.ts`
- `src/features/projects/actions.ts`
- `src/features/today/actions.ts`
- `src/components/action-tree.tsx`
- `src/app/(protected)/projects/[id]/page.tsx`
- `src/app/(protected)/projects/[id]/actions/[actionId]/page.tsx`
- `tests/unit/action-tree.test.ts`
- `tests/rls/rls-static.test.ts`
- `README.md`
- `docs/DATABASE.md`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-16-action-hierarchy.md`

## 데이터 구조 변경

- `action_items.parent_action_id uuid null`을 추가했다.
- `parent_action_id`는 `action_items.id`를 참조하고 부모 삭제 시 `null`이 되어 최상위로 이동한다.
- `(user_id, project_id, parent_action_id, created_at)` 인덱스를 추가했다.
- `validate_action_hierarchy` 트리거가 부모와 자식의 사용자/프로젝트 일치 및 순환 여부를 검사한다.
- 계층 깊이 또는 자식 수를 제한하는 컬럼이나 제약은 추가하지 않았다.

## API 변경

- `createActionItem` 서버 액션이 선택적인 `parentActionId`를 받는다.
- `updateActionItem` 서버 액션을 추가해 제목, 내용, 예상 시간과 부모를 함께 수정한다.
- `updateActionCompletion` 서버 액션을 추가해 사용자가 활동 완료 또는 완료 취소를 명시적으로 선택한다.
- 외부 HTTP API 변경은 없다.

## 주요 구현 결정과 이유

- 진행률은 전체 후손 중 `DONE` 상태인 활동 비율로 계산한다. 깊이가 달라도 같은 의미의 진행률을 유지하기 위해서다.
- 부모 후보 선택 UI에서는 현재 활동과 모든 후손을 제외하고, 데이터베이스에서도 재검증한다. UI 우회나 동시 변경에도 순환 구조가 저장되지 않게 하기 위해서다.
- 접기 상태는 브라우저 컴포넌트 상태로만 관리한다. 계층 데이터와 개인 보기 설정을 분리해 이번 범위를 작게 유지했다.
- 모든 후손 완료는 완료 제안 조건일 뿐 부모 상태 전환 조건이 아니다.

## 기존 PRD와 달라진 점

PRD의 Project, Task, 작은 행동 흐름을 계층형 활동으로 구체화했다. 기존 원칙과 충돌하지 않으며 `docs/LIFEOS_PRD.md`는 수정하지 않았다.

## 임시 구현과 기술 부채

- 프로젝트의 활동 전체를 조회하고 애플리케이션에서 트리와 진행률을 계산한다. 한 프로젝트의 활동 수가 매우 커지면 재귀 CTE, 집계 캐시 또는 페이지 분할을 검토한다.
- 접기/펼치기 상태는 화면 이동이나 새로고침 후 유지되지 않는다.
- 부모 이동은 선택 상자로 제공하며 드래그 앤 드롭은 이번 범위에서 제외했다.
- Today의 활동 선택 목록은 기존 평면 표현을 유지한다. 프로젝트 활동 목록과 상세 하위 목록에서 계층을 제공한다.

## 실제 사용 후 확인해야 할 사항

- 깊이가 4단계 이상일 때 모바일에서 들여쓰기와 가로 스크롤이 읽기 편한지 확인한다.
- 전체 후손 기준 진행률이 사용자가 기대한 의미와 맞는지 확인한다.
- 완료된 부모 아래에 새 하위 활동을 추가하는 흐름에 별도 경고가 필요한지 확인한다.
- 부모 선택 상자에서 경로 문자열이 긴 경우 선택하기 쉬운지 확인한다.
- Supabase 마이그레이션 적용 후 실제 계정으로 생성, 이동, 완료 제안 흐름을 확인한다.

## 남은 문제

- 현재 환경에서는 브라우저 확인을 위한 로컬 서버 실행 승인이 중단되어 인증된 실제 UI 흐름은 확인하지 못했다.
- 실제 Supabase 환경에 새 마이그레이션을 적용해야 한다.
- 실제 교차 사용자 및 교차 프로젝트 부모 지정 차단은 Supabase 통합 환경에서 추가 검증이 필요하다.

## 다음 작업 후보

1. Supabase 로컬 또는 테스트 프로젝트에서 마이그레이션과 계층 무결성 통합 테스트 추가.
2. 인증된 Playwright 시나리오로 하위 활동 생성, 부모 이동, 접기/펼치기와 완료 제안 검증.
3. 모바일 실제 사용 후 깊은 트리의 들여쓰기와 부모 선택 UI 개선.

## 실행 방법

```bash
supabase db push
pnpm dev
```

프로젝트 상세에서 최상위 활동을 만든 뒤 활동 제목을 눌러 상세 화면으로 이동한다. 상세 화면에서 하위 활동 추가와 부모 변경을 사용할 수 있다.

## 테스트 결과

- `pnpm test`: 통과. 3개 테스트 파일, 18개 테스트 통과.
- `pnpm exec tsc --noEmit`: 통과.
- `pnpm build`: 최초 샌드박스 실행은 Turbopack 포트 바인딩 권한 문제로 실패. 허용된 환경에서 재실행하여 통과했고 신규 동적 라우트 생성도 확인했다.
- `git diff --check`: 통과.
