# Native Inbox CRUD Handoff

## 작업 목표

네이티브 Inbox를 읽기 전용에서 웹과 같은 기본 관리 흐름으로 확장한다.

## 구현한 내용

- Inbox 추가·수정·삭제, 제목·내용 검색을 구현했다.
- 언젠가, 보관, 폐기 상태 전환을 추가했다.
- Mac과 iPhone이 같은 SwiftUI 편집 화면과 Supabase CRUD 요청을 사용한다.

## 변경 파일

- `native/LifeOS/Sources/Features/Inbox/InboxItem.swift`
- `native/LifeOS/Sources/Features/Inbox/InboxListView.swift`
- `native/LifeOS/Sources/Features/Inbox/InboxStore.swift`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-20-native-inbox-crud.md`

## 데이터 구조 변경

없음.

## API 변경

없음. 기존 `inbox_items` RLS와 Data API를 사용한다.

## 주요 구현 결정과 이유

- 검색은 먼저 로컬에 읽은 목록에서 수행해 개인 데이터 규모에서 즉시 반응하도록 했다.
- 실제 삭제에는 확인 대화상자를 둔다.

## 기존 PRD와 달라진 점

없음.

## 임시 구현과 기술 부채

- 프로젝트 전환 입력 흐름은 프로젝트 기능 이관에서 RPC와 함께 구현한다.

## 실제 사용 후 확인해야 할 사항

- iPhone과 Mac에서 추가·수정·삭제한 항목이 웹에 동일하게 반영되는지 확인한다.

## 남은 문제

- 프로젝트 전환과 상태별 필터가 남아 있다.

## 다음 작업 후보

1. 프로젝트와 계층형 활동을 구현한다.
2. Inbox 프로젝트 전환을 연결한다.
