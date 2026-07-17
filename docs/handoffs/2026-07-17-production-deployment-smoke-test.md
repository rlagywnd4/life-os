# Production Deployment Smoke Test Handoff

## 작업 목표

- 활동 계층 기능과 Supabase 자동화가 실제 프로덕션에서 동작하는지 배포 후 검증한다.
- 운영 검증에서 발견한 부모 활동 수정 폼의 표시 문제를 수정한다.

## 구현한 내용

- PR #1과 PR #2를 순서대로 병합했다.
- Supabase의 기존 migration history를 검증된 2개 버전만 복구하고 남은 2개 migration을 적용했다.
- repair 옵션이 없는 일반 워크플로를 재실행해 원격 DB가 최신 상태임을 확인했다.
- 활동 수정 폼을 `action.updated_at` 기준으로 다시 생성해 저장 직후 필드가 서버의 최신 값을 표시하도록 했다.

## 변경 파일

- `src/app/(protected)/projects/[id]/actions/[actionId]/page.tsx`
- `docs/DEPLOYMENT.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-17-supabase-migration-history-repair.md`
- `docs/handoffs/2026-07-17-production-deployment-smoke-test.md`

## 데이터 구조 변경

- `202607150003_life_context_seed_store.sql` 적용 완료.
- `202607160001_action_hierarchy.sql` 적용 완료.
- API 스키마에서 `life_context_documents`, `life_context_entries`와 UUID 형식의 `action_items.parent_action_id`를 확인했다.

## API 변경

- 없음.

## 주요 구현 결정과 이유

- 프로덕션 기능 검증은 별도 임시 Supabase 사용자로 수행해 기존 사용자 데이터와 분리했다.
- 테스트 완료 후 임시 사용자를 Admin API로 삭제해 연결된 프로젝트, Inbox, 활동 데이터를 cascade 정리했다.
- 부모 변경 후 breadcrumb는 즉시 갱신되지만 uncontrolled select가 이전 default를 표시하는 현상은 form key를 최신 `updated_at`으로 바꿔 해결했다.

## 기존 PRD와 달라진 점

- 없음.

## 임시 구현과 기술 부채

- Vercel의 고유 deployment URL은 Vercel 로그인을 요구하지만 저장소에 등록된 production alias `https://life-os-one-peach.vercel.app`은 정상 공개된다.
- Vercel Production Deployment Check 등록 여부는 Vercel 계정 대시보드에서 추가 확인이 필요하다.
- GitHub Actions가 Node.js 20 deprecation 경고를 표시한다.

## 실제 사용 후 확인한 사항

- 공개 랜딩 화면 정상 응답.
- 비로그인 `/projects` 접근 시 `/login?next=%2Fprojects`로 보호됨.
- 임시 계정 로그인과 Inbox에서 활성 프로젝트 전환 성공.
- 최상위 활동과 하위 활동 생성 성공.
- 활동 상세의 프로젝트 → 상위 → 현재 활동 경로 표시 성공.
- 자식 완료 후 부모 진행률 `1/1`, `100%`와 수동 완료 제안 표시 성공.
- 부모 활동이 자동 완료되지 않음.
- 프로젝트 활동 트리 접기와 펼치기 성공.
- 하위 활동을 최상위로 이동하고 다시 부모 아래로 이동하는 데이터 저장 성공.
- 임시 사용자와 연결 데이터를 삭제 완료.

## 배포 및 검증 기록

- 최초 기능 병합: PR #1, merge commit `902ed14013ed695dade4f2fcda2ec3d19f3b5807`.
- migration history 복구: PR #2, merge commit `17f00680cbd9a3a74e5aadc74f36847c941b3fed`.
- 이력 복구와 실제 migration 적용: GitHub Actions `29583216409` 성공.
- repair 없는 일반 재실행: GitHub Actions `29583512241` 성공, 원격 DB 최신 상태 확인.
- Vercel Production deployment `5489707526` 성공.
- 프로덕션 URL: `https://life-os-one-peach.vercel.app`.

## 남은 문제

- 부모 수정 폼 동기화 수정이 배포된 뒤 같은 왕복 이동을 한 번 더 확인해야 한다.
- Vercel Production Deployment Check가 DB migration 성공 전에 alias 승격을 막는지 확인해야 한다.

## 다음 작업 후보

- Vercel 대시보드에서 `Test and migrate production database` 체크를 Production Deployment Check로 등록 또는 확인한다.
- GitHub Actions Node runtime 경고를 해소하기 위해 공식 Actions major 업데이트를 검토한다.
