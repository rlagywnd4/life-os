# Native App Icon Handoff

## 작업 목표

사용자가 제공한 LifeOS 아이콘에서 바깥 흰 배경을 제거하고, iPhone·iPad·Mac 앱 아이콘으로 등록한다.

## 구현한 내용

- 흰 바깥 배경을 투명 처리하고, 파란색·민트색 둥근 사각형, 흰색 L, 초록색 잎을 보존했다.
- 홈 화면에서 아이콘이 작게 보이지 않도록 투명 여백을 잘라 1024×1024 원본으로 맞췄다.
- iPhone·iPad·Mac에서 필요한 모든 앱 아이콘 해상도를 `AppIcon.appiconset`에 추가했다.
- XcodeGen 프로젝트에 자산 카탈로그 리소스를 포함하고 macOS와 generic iOS 빌드를 통과했다.

## 변경 파일

- `native/LifeOS/Sources/Resources/Assets.xcassets/`
- `native/LifeOS/LifeOS.xcodeproj/project.pbxproj`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`

## 데이터 구조 변경

없음.

## API 변경

없음.

## 주요 구현 결정과 이유

- 아이콘 바깥의 흰 캔버스만 제거하고 로고 내부의 L·잎·그림자는 유지했다.
- iOS와 macOS가 각자 요구하는 크기의 PNG를 제공해 Xcode와 실제 기기에서 같은 아이콘을 사용한다.

## 기존 PRD와 달라진 점

없음.

## 임시 구현과 기술 부채

없음.

## 실제 사용 후 확인해야 할 사항

- iPhone과 Mac에서 이전 빌드를 삭제하지 않고 새 빌드를 실행한 뒤 홈 화면·Dock의 아이콘이 기대한 크기와 모양인지 확인한다.

## 남은 문제

없음. 앱 아이콘 자산과 양 플랫폼 빌드는 확인했다.

## 다음 작업 후보

1. 실제 기기에서 아이콘 표시를 확인하고, 필요하면 아이콘 내부 여백과 그림자 강도를 조정한다.
