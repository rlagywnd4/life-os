# Supabase Migration History Repair Handoff

## 작업 목표

- 최초 프로덕션 마이그레이션 자동화 실패 원인을 확인하고 기존 DB를 보존하면서 배포 이력을 정합화한다.

## 구현한 내용

- GitHub Actions 수동 실행에 `repair_legacy_history` boolean 입력을 추가했다.
- 입력을 명시적으로 선택한 경우에만 검증된 `202607150001`, `202607150002`를 적용 완료로 기록한다.
- history 복구 후에도 dry-run과 일반 `db push` 순서를 유지한다.
- repair 대상과 실행 조건을 정적 테스트로 고정했다.
- Supabase CLI가 만드는 `supabase/.temp/`를 Git 추적에서 제외했다.

## 변경 파일

- `.github/workflows/test-and-deploy.yml`
- `.gitignore`
- `tests/unit/deployment-workflow.test.ts`
- `docs/DEPLOYMENT.md`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-17-supabase-migration-history-repair.md`

## 데이터 구조 변경

- 이 변경 자체는 테이블이나 데이터를 변경하지 않는다.
- 수동 복구 실행은 `supabase_migrations.schema_migrations`에 기존 적용분 2개를 기록한다.
- 이후 일반 migration 단계가 `202607150003_life_context_seed_store.sql`과 `202607160001_action_hierarchy.sql`을 적용한다.

## API 변경

- 없음.

## 주요 구현 결정과 이유

- 서비스 역할 키로 읽은 PostgREST OpenAPI 스키마에서 초기 스키마와 건강 모듈의 모든 테이블, 핵심 RPC가 존재함을 확인했다.
- `life_context_documents`, `life_context_entries`, `action_items.parent_action_id`는 없음을 확인했으므로 해당 migration은 repair하지 않는다.
- 최초 복구 전용 동작이 일반 배포에 섞이지 않도록 수동 입력 조건을 사용한다.

## 기존 PRD와 달라진 점

- 없음.

## 임시 구현과 기술 부채

- `repair_legacy_history`는 현재 LifeOS 프로덕션의 최초 1회 복구만 위한 운영 옵션이다.
- 복구 완료 후에도 사고 대응을 위해 옵션은 남기지만, 다른 프로젝트에서는 스키마 검증 없이 사용하면 안 된다.

## 실제 사용 후 확인해야 할 사항

- 수동 복구 실행 `29583216409`에서 `202607150003`, `202607160001`만 pending으로 표시되고 실제 적용됐다.
- DB 적용 후 `action_items.parent_action_id`가 UUID 컬럼으로 API 스키마에 노출됨을 확인했다.
- repair 옵션이 없는 일반 실행 `29583512241`에서 dry-run과 apply가 모두 `Remote database is up to date`로 성공했다.

## 남은 문제

- Vercel Production Deployment Check 등록 여부를 별도로 확인해야 한다.
- GitHub Actions의 `actions/checkout@v4`, `actions/setup-node@v4`가 Node.js 20 deprecation 경고를 출력한다. 현재 실행에는 영향이 없지만 공식 최신 major 검토가 필요하다.

## 다음 작업 후보

- Vercel Production Deployment Check가 `Test and migrate production database`를 실제 승격 조건으로 사용하는지 대시보드에서 확인한다.
- Supabase CLI와 GitHub 공식 Actions major 버전 갱신을 별도 작업으로 검토한다.
