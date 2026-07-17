# 2026-07-15 Click Interaction Feedback

## 작업 목표

클릭이 실제로 입력되었는지 사용자가 눈으로 구분할 수 있도록 버튼의 즉시 피드백과 서버 액션 제출 중 상태를 강화한다.

## 구현한 내용

- 전역 `.btn` 스타일에 눌림 효과, 그림자 변화, 터치 하이라이트 제거를 추가했다.
- 서버 액션 폼에서 사용할 `ActionButton` 클라이언트 컴포넌트를 추가했다.
- 주요 저장, 추가, 삭제, 상태 변경 버튼에 제출 중 스피너와 상태 문구를 표시했다.
- 로그인과 로그아웃 버튼에도 처리 중 상태와 스피너를 표시했다.

## 변경 파일

- `src/app/globals.css`
- `src/components/action-button.tsx`
- `src/components/auth-form.tsx`
- `src/components/logout-button.tsx`
- `src/components/quick-inbox-form.tsx`
- `src/app/(protected)/today/page.tsx`
- `src/app/(protected)/inbox/page.tsx`
- `src/app/(protected)/projects/[id]/page.tsx`
- `src/app/(protected)/health/page.tsx`
- `src/app/(protected)/health/settings/page.tsx`
- `src/app/(protected)/health/weight/page.tsx`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`

## 데이터 구조 변경

없음.

## API 변경

없음.

## 주요 구현 결정과 이유

- 전역 `.btn`에 `active` 상태를 추가해 모든 버튼과 버튼형 링크가 즉시 눌림 피드백을 갖도록 했다.
- 서버 액션 제출 중 상태는 `useFormStatus` 기반의 공용 `ActionButton`으로 처리해 개별 폼마다 중복 클라이언트 상태를 만들지 않았다.
- 버튼 단위 문구는 `저장 중`, `추가 중`, `삭제 중`처럼 사용자의 의도와 가까운 말로 지정했다.

## 기존 PRD와 달라진 점

PRD 변경 없음. LifeOS의 차분한 조작 경험을 보강하는 UX 개선이다.

## 임시 구현과 기술 부채

- 같은 폼 안에 여러 `ActionButton`이 있으면 해당 폼 제출 중 모든 액션 버튼이 pending 표시로 바뀐다. 어떤 버튼을 눌렀는지까지 개별 유지하려면 클릭된 submitter 추적이 추가로 필요하다.
- 필터 버튼처럼 GET 폼 또는 임시 저장 mock 버튼은 전역 눌림 피드백만 적용되어 있고 제출 중 상태는 없다.

## 실제 사용 후 확인해야 할 사항

- 모바일 터치에서 눌림 효과가 충분히 보이는지 확인한다.
- 서버 응답이 느린 환경에서 pending 문구가 너무 자주 깜박이지 않는지 확인한다.
- 여러 버튼이 있는 폼에서 모든 버튼이 pending으로 보이는 방식이 헷갈리지 않는지 확인한다.

## 남은 문제

- 실제 배포 환경에서 클릭 후 서버 액션 응답 시간과 체감 지연을 측정해야 한다.
- 필요하면 특정 액션 버튼만 pending으로 보이도록 개선한다.

## 다음 작업 후보

1. Playwright로 주요 폼 클릭 후 pending 상태를 확인하는 UI 테스트 추가.
2. 버튼별 clicked submitter를 추적해 다중 액션 폼의 피드백을 더 정밀하게 개선.
3. 느린 화면의 Supabase 쿼리 수와 Vercel Function 리전 지연 측정.

## 실행 방법

- `pnpm dev`
- 주요 화면에서 저장, 추가, 삭제, 상태 변경 버튼을 클릭한다.

## 테스트 결과

- `pnpm test`: 통과. 2개 test file, 13개 test 통과.
- `pnpm build`: 최초 샌드박스 실행은 Turbopack 내부 포트 바인딩 권한 문제로 실패. 권한 상승 후 재실행하여 통과.
