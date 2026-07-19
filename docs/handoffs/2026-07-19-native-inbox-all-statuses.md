# Native Inbox All Statuses Handoff

## 작업 목표

로그인에는 성공했지만 네이티브 Inbox가 비어 보이는 원인을 확인하고, 기존 웹과 같은 Inbox 기록 범위를 표시한다.

## 구현한 내용

- 네이티브 Inbox 조회에서 `UNREVIEWED` 상태 제한을 제거했다.
- 미검토, 프로젝트 전환, 언젠가, 폐기, 보관을 포함한 모든 Inbox 항목을 최신순으로 표시한다.
- 각 항목에 카테고리와 상태 한글 라벨을 함께 표시한다.
- 모델 라벨 단위 테스트를 보강했다.

## 변경 파일

- `native/LifeOS/Sources/Features/Inbox/InboxStore.swift`
- `native/LifeOS/Sources/Features/Inbox/InboxItem.swift`
- `native/LifeOS/Sources/Features/Inbox/InboxListView.swift`
- `native/LifeOS/Tests/InboxItemTests.swift`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-19-native-inbox-all-statuses.md`

## 데이터 구조 변경

없음.

## API 변경

없음. 기존 `inbox_items` select 요청의 상태 필터만 제거했다.

## 주요 구현 결정과 이유

- 웹 Inbox와 범위를 일치시키기 위해 모든 상태를 표시한다.
- 상태별 선택은 이후 검색·필터 기능과 함께 제공한다. 지금은 기존 기록이 사라진 것처럼 보이지 않는 것이 우선이다.

## 기존 PRD와 달라진 점

없음.

## 임시 구현과 기술 부채

- 상태·카테고리 필터와 검색은 아직 없다.
- Inbox는 읽기 전용이다.

## 실제 사용 후 확인해야 할 사항

- 웹 Inbox에 보이는 기존 항목이 Mac과 iPhone에서 같은 순서와 상태로 보이는지 확인한다.
- 상태 라벨이 개인적인 기록 회고에 충분한지 확인한다.

## 남은 문제

- 없음. 첫 네이티브 읽기 범위와 웹의 불일치를 수정했다.

## 다음 작업 후보

1. 네이티브 Inbox 추가·수정·삭제를 구현한다.
2. 상태·카테고리 필터와 검색을 추가한다.
3. 앱 활성화 갱신 외에 Realtime 구독 필요성을 검토한다.
