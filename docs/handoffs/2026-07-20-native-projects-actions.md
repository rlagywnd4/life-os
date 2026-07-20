# Native Projects and Actions Handoff

## 작업 목표

웹의 프로젝트와 계층형 활동 기본 흐름을 iPhone·Mac 공용 앱으로 이관한다.

## 구현한 내용

- 프로젝트를 상태별로 조회하고 상태를 변경한다.
- 프로젝트별 활동을 조회하고 추가·수정·완료/미완료 처리한다.
- 활동 편집에서 같은 프로젝트의 부모 활동을 선택한다.
- iPhone 탭과 Mac 사이드바에 프로젝트 화면을 추가했다.

## 변경 파일

- `native/LifeOS/Sources/App/LifeOSMainView.swift`
- `native/LifeOS/Sources/Features/Projects/ProjectModels.swift`
- `native/LifeOS/Sources/Features/Projects/ProjectsStore.swift`
- `native/LifeOS/Sources/Features/Projects/ProjectsView.swift`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-20-native-projects-actions.md`

## 데이터 구조 변경

없음.

## API 변경

없음. 기존 `projects`, `action_items` Data API와 RLS를 사용한다.

## 주요 구현 결정과 이유

- 웹과 같은 테이블을 직접 사용해 기기 간 상태를 공유한다.
- 활동 계층 검증은 기존 데이터베이스 트리거를 최종 기준으로 유지한다.

## 기존 PRD와 달라진 점

없음.

## 임시 구현과 기술 부채

- 네이티브 활동 목록은 1단계 들여쓰기이며, 재귀 트리 접기·펼치기와 하위 진행률은 보강이 필요하다.

## 실제 사용 후 확인해야 할 사항

- 실제 계정에서 부모 이동, 순환 오류 안내, 완료 상태가 웹과 동일하게 반영되는지 확인한다.

## 남은 문제

- Inbox 프로젝트 전환과 네이티브 트리 진행률 표시가 남아 있다.

## 다음 작업 후보

1. Inbox 프로젝트 전환 RPC를 연결한다.
2. Someday와 주간 리뷰를 이관한다.
