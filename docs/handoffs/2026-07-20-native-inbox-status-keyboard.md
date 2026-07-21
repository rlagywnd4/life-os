# Native Inbox Status and Keyboard Handoff

## 작업 목표

네이티브 Inbox에서 항목 상태를 직접 선택해 저장하고, iPhone 입력 화면의 바깥을 누르면 키보드가 자연스럽게 내려가게 한다. 기존 프로젝트 전환이 프로젝트 탭까지 정상 반영되는지도 다시 확인한다.

## 구현한 내용

- Inbox 수정 화면의 상태 표시를 미검토·언젠가·보관·폐기 선택 메뉴로 변경했다.
- 제목·내용·카테고리·상태를 한 번의 Supabase update로 저장한다.
- `프로젝트 전환됨`은 사용자가 직접 지정하거나 다른 상태로 되돌리지 못하게 하고 기존 `convert_inbox_to_project` RPC만 만들 수 있게 유지했다.
- iOS 앱 창에 입력 필드 바깥 탭을 감지하는 제스처를 설치해 키보드를 내린다. 제스처는 입력 필드와 기존 버튼·메뉴 터치를 방해하지 않는다.
- 운영 Supabase의 임시 사용자와 Inbox로 프로젝트 전환을 실행하고, 반환된 Project ID, Inbox 상태, 연결 ID, 프로젝트 탭과 동일한 조회 결과를 검증한 뒤 임시 사용자를 삭제했다.

## 변경 파일

- `native/LifeOS/Sources/App/LifeOSRootView.swift`
- `native/LifeOS/Sources/Features/Inbox/InboxItem.swift`
- `native/LifeOS/Sources/Features/Inbox/InboxListView.swift`
- `native/LifeOS/Sources/Features/Inbox/InboxStore.swift`
- `native/LifeOS/Sources/Shared/KeyboardDismiss.swift`
- `native/LifeOS/Tests/InboxItemTests.swift`
- 생성된 Xcode 프로젝트와 구현 상태 문서

## 데이터 구조 변경

없음. 기존 `inbox_status` enum과 Inbox·Project 연결 구조를 그대로 사용한다.

## API 변경

없음. Inbox update 요청에 기존 `status` 컬럼을 함께 보내며, 프로젝트 전환은 기존 `convert_inbox_to_project` RPC를 사용한다.

## 주요 구현 결정과 이유

- 보관은 Inbox의 `ARCHIVED` 상태이고 프로젝트 생성과는 별개다.
- 프로젝트 전환은 Project 생성과 Inbox의 `CONVERTED_TO_PROJECT` 상태·`converted_project_id` 갱신을 트랜잭션으로 보장하는 RPC만 사용한다.
- 키보드 닫기는 iOS에만 적용한다. macOS에는 화면 키보드가 없고 기존 포커스 동작을 유지하는 편이 자연스럽다.

## 기존 PRD와 달라진 점

없음.

## 임시 구현과 기술 부채

- 키보드 닫기 동작은 앱 전체 iOS 창에 적용한 UIKit 제스처 기반이다. 향후 특정 화면에서 다른 포커스 정책이 필요하면 화면별 설정을 추가해야 한다.

## 실제 사용 후 확인해야 할 사항

- iPhone Inbox 수정 화면에서 상태 메뉴의 각 값을 선택하고 저장했을 때 목록 라벨이 바뀌는지 확인한다.
- 입력 중 목록, 빈 공간, 저장 버튼을 눌렀을 때 키보드가 내려가면서 원래 터치 동작도 실행되는지 확인한다.
- `프로젝트로 전환` 후 프로젝트 탭에서 활성 또는 대기 프로젝트로 표시되는지 확인한다.

## 남은 문제

- 컴파일·단위 테스트·운영 Supabase 전환 계약은 검증했으며, 실제 기기에서 상태 메뉴와 키보드의 촉감 확인이 남아 있다.

## 다음 작업 후보

1. 사용자의 iPhone 확인 결과에 따라 상태 메뉴 위치와 문구를 다듬는다.
2. Supabase 오류 코드를 프로젝트 활성 한도 등 원인별 한국어 안내로 세분화한다.
