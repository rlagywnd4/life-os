# 2026-07-17 Supabase Deploy Automation

Date: 2026-07-17
Status: 구현 및 로컬 검증 완료, GitHub 설정과 최초 프로덕션 실행 확인 필요

## 작업 목표

`main`에 코드가 반영될 때 테스트된 애플리케이션과 Supabase 데이터베이스 마이그레이션을 올바른 순서로 자동 배포한다.

## 구현한 내용

- 기존 GitHub Actions 프로덕션 워크플로에 애플리케이션 빌드, Supabase CLI 설치, 프로젝트 연결, migration dry-run 및 적용 단계를 추가했다.
- 기존 Vercel Git 자동 배포는 유지하고 GitHub Actions 결과를 Production Deployment Check로 사용하도록 운영 절차를 정리했다.
- GitHub Actions에 필요한 Supabase secret과 variable 누락을 배포 전에 검사한다.
- 워크플로의 Supabase 구성과 build-migrate 순서를 정적 테스트로 고정했다.
- 최초 자동화 전에 원격 migration history를 확인하고 필요할 때 안전하게 정합성을 복구하는 절차를 문서화했다.

## 변경 파일

- `.github/workflows/test-and-deploy.yml`
- `tests/unit/deployment-workflow.test.ts`
- `docs/DEPLOYMENT.md`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/handoffs/2026-07-17-supabase-deploy-automation.md`

## 데이터 구조 변경

없음. 기존 `supabase/migrations` 파일을 원격 데이터베이스에 자동 적용하는 배포 흐름을 추가했다.

## API 변경

없음.

## 주요 구현 결정과 이유

- GitHub Actions build를 먼저 실행해 컴파일 실패 시 프로덕션 DB가 변경되지 않게 했다.
- Vercel Production Deployment Check가 Supabase migration 성공 전 새 빌드의 도메인 승격을 막도록 했다.
- `supabase db push --dry-run`을 먼저 실행해 pending migration과 history 불일치를 실제 적용 전에 확인한다.
- CLI를 `2.84.2`로 고정해 CI 실행 간 도구 변화로 인한 불확실성을 줄였다.
- GitHub Actions의 기존 production concurrency group을 유지해 migration 동시 실행을 피한다.

## 기존 PRD와 달라진 점

없음. 제품 요구사항이 아니라 배포 운영 개선이다.

## 임시 구현과 기술 부채

- DB migration 성공 후 Vercel build 실패까지 하나의 원자적 트랜잭션으로 묶을 수는 없다. migration은 이전 앱과 호환되게 작성해야 한다.
- PR에서 임시 Supabase 데이터베이스를 생성하는 preview migration 검증은 포함하지 않았다.
- CLI action은 major tag `supabase/setup-cli@v2`를 사용하며 CLI binary 버전만 정확히 고정했다.

## 실제 사용 후 확인해야 할 사항

- Repository Actions secrets와 variable이 정확히 등록됐는지 확인한다.
- 최초 `supabase migration list`에서 로컬 및 원격 migration history가 일치하는지 확인한다.
- main merge 후 Supabase migration 단계가 적용되고 Vercel Deployment Check 통과 후 프로덕션 도메인이 갱신되는지 확인한다.
- 배포 후 활동 트리에서 생성, 이동, 진행률과 완료 제안을 실제 계정으로 확인한다.

## 남은 문제

- GitHub에 `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `SUPABASE_PROJECT_ID`를 등록해야 한다.
- 기존 프로덕션 DB의 migration history 상태를 확인해야 한다.
- Vercel Production 환경에 `Test and migrate production database` Deployment Check를 등록해야 한다.

## 다음 작업 후보

1. GitHub production environment와 required reviewer로 프로덕션 DB 변경 승인 정책 추가.
2. PR 전용 Supabase Branching 또는 로컬 Docker 기반 migration 통합 테스트 추가.
3. 배포 후 smoke test와 실패 알림 추가.

## 실행 방법

GitHub repository Actions 설정에 다음 값을 등록한다.

- Secrets: `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`.
- Variable: `SUPABASE_PROJECT_ID`.

Vercel Project Settings의 Production Deployment Checks에서 GitHub Actions 체크 `Test and migrate production database`를 추가한다.

이후 PR을 `main`에 병합하면 `.github/workflows/test-and-deploy.yml`이 자동 실행된다. 수동 재실행은 Actions 화면의 `workflow_dispatch`를 사용한다.

## 테스트 결과

- `pnpm test`: 통과. 4개 테스트 파일, 21개 테스트 통과.
- `pnpm exec tsc --noEmit`: 통과.
- `pnpm build`: 통과. 활동 상세 동적 라우트를 포함한 21개 라우트 생성 확인.
- 변경된 workflow, 테스트, 운영 문서 대상 `prettier --check`: 통과.
- `git diff --check`: 통과.
