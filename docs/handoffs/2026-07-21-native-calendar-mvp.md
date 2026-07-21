# Native Calendar MVP

Date: 2026-07-21
Status: Implemented and production contract verified, device verification pending

## 작업 목표

실제로 실행하기로 결정한 활동과 일반 일정을 iPhone·Mac에서 날짜와 시간에 배치하고 Today까지 연결한다.

## 구현한 내용

- 월간·주간 달력과 날짜별 활동·일정·마감 표시.
- 일반 일정 추가·수정·삭제와 일반·약속·여행·마일스톤 구분.
- 프로젝트 활동의 실행일, 선택적 시작 시간, 마감일, 예상 시간 편집.
- 달력 드래그와 별도 이동 화면을 통한 활동 재배치 및 선택적 이유 기록.
- 달력에서 활동 완료·미완료 전환.
- Today의 시간표, 시간 미정 활동, 일반 일정, 내일로 이동.
- 오늘 가능한 시간과 계획된 예상 시간 비교 안내.

## 변경 파일

- `native/LifeOS/Sources/Features/Calendar/*`
- `native/LifeOS/Sources/Features/Projects/*`
- `native/LifeOS/Sources/Features/Today/*`
- `native/LifeOS/Sources/App/LifeOSMainView.swift`
- `native/LifeOS/Sources/Features/More/MoreView.swift`
- `supabase/migrations/202607210001_native_calendar_mvp.sql`
- 관련 타입, 테스트, 구현 문서.

## 데이터 구조 변경

- `action_items`: `scheduled_time`, `due_date` 추가. 기존 `scheduled_date`는 실행일로 유지.
- `daily_plans`: `available_minutes` 추가.
- `calendar_events`: 사용자 소유 일반 일정.
- `action_schedule_changes`: 활동 재배치 이력.
- 신규 테이블에 사용자 소유 RLS 정책과 날짜 조회 인덱스를 적용.

## API 변경

- `reschedule_action`: 활동 실행일·시간, Today 연결, 이동 기록을 원자적으로 갱신.
- `add_core_action_to_today`: 실행일 변경 기록도 남기도록 확장.

## 주요 구현 결정과 이유

- 활동 실행일은 `action_items.scheduled_date`를 단일 기준으로 사용한다.
- 일반 일정은 활동 완료와 프로젝트 진행률 의미가 없으므로 별도 테이블에 저장한다.
- 이동은 실패 처리하지 않고 이유를 선택적으로 기록한다.

## 기존 PRD와 달라진 점

- 충돌은 없다. PRD의 Today 필수 정보와 Plan 경험을 네이티브 달력으로 구체화했다.

## 임시 구현과 기술 부채

- 반복 일정, 외부 캘린더, 알림, AI 자동 배치는 제외했다.
- 월간·주간 조회는 개인용 초기 규모를 전제로 전체 활동과 일정을 읽는다. 데이터가 커지면 기간 쿼리로 바꿔야 한다.
- 활동의 드래그는 날짜 이동만 지원하며 시간축 안에서의 정밀한 시간 드래그는 지원하지 않는다.

## 실제 사용 후 확인해야 할 사항

- 작은 iPhone 화면에서 월간 셀과 항목 목록이 읽기 쉬운지.
- Mac과 iPhone 사이에 일정 생성·활동 이동·완료가 일관되게 반영되는지.
- 하루 가능 시간 입력과 과부하 문구가 부담을 줄이는지.

## 남은 문제

- 실제 기기에서 드래그 앤 드롭과 일정 편집을 아직 조작 검증하지 않았다.
- 웹 달력은 아직 구현하지 않았다.

## 다음 작업 후보

- 실제 iPhone·Mac UI 확인 후 레이아웃 보정.
- 웹 달력 구현.
- 반복 일정 편집 정책 설계.

## 실행 방법

`native/LifeOS/LifeOS.xcodeproj`의 LifeOS scheme을 선택해 Mac 또는 연결된 iPhone에서 실행한다. 새 화면은 iPhone의 `달력` 탭과 Mac 사이드바의 `달력`에서 연다.

## 테스트 결과

- Vitest: 4개 파일, 22개 테스트 통과.
- Next.js production build 통과.
- Mac LifeOS scheme 단위 테스트 통과.
- generic iOS 대상 서명 없는 빌드 통과.
- GitHub Actions 실행 `29873362311`에서 테스트·빌드·migration dry-run·운영 적용 통과.
- 운영 Supabase 임시 사용자로 프로젝트·활동·일정 생성, 일정 조회, 활동 재배치, 시간 미정 전환, 마감일 유지, 재배치 이력 기록을 확인하고 테스트 사용자를 삭제함.
