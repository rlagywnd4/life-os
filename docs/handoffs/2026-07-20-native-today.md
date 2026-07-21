# Native Today Handoff

## 작업 목표

웹 Today의 기본 흐름을 iPhone과 Mac 공용 SwiftUI 앱으로 이관한다.

## 구현한 내용

- iPhone 탭과 Mac 사이드바에 Today를 추가했다.
- 오늘 계획의 에너지, 모드, 메모, 휴식 이유를 `daily_plans`에 저장한다.
- 미완료 활동을 읽고 Today 또는 핵심 행동으로 추가하며 완료 처리할 수 있다.

## 변경 파일

- `native/LifeOS/Sources/App/LifeOSMainView.swift`
- `native/LifeOS/Sources/Features/Today/TodayStore.swift`
- `native/LifeOS/Sources/Features/Today/TodayView.swift`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-20-native-today.md`

## 데이터 구조 변경

없음.

## API 변경

없음. 기존 `daily_plans`, `action_items`, `add_core_action_to_today` RPC를 사용한다.

## 주요 구현 결정과 이유

- 웹과 같은 Supabase 데이터를 직접 사용해 iPhone·Mac·웹의 Today 상태를 공유한다.

## 기존 PRD와 달라진 점

없음.

## 임시 구현과 기술 부채

- Today에 추가된 행동 목록과 핵심 여부의 별도 표시는 다음 보강 작업으로 남아 있다.

## 실제 사용 후 확인해야 할 사항

- iPhone과 Mac에서 저장한 오늘 계획과 행동 완료가 웹에 즉시 보이는지 확인한다.

## 남은 문제

- 프로젝트·활동, 주간 리뷰, 건강 등 나머지 웹 기능 이관이 필요하다.

## 다음 작업 후보

1. Inbox CRUD와 검색을 구현한다.
2. 프로젝트와 계층형 활동을 구현한다.
