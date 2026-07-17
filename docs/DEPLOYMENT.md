# Deployment

## Supabase

1. Supabase에서 새 프로젝트를 만든다.
2. Project Settings -> API에서 Project URL과 anon public key를 확인한다.
3. 로컬에서 `.env.local`에 값을 넣는다.
4. Supabase CLI를 사용한다면 `supabase link --project-ref <ref>` 후 `supabase db push`를 실행한다.
5. CLI가 없다면 SQL editor에서 `supabase/migrations/202607150001_initial_schema.sql`을 실행한다.
6. Authentication -> Providers에서 Email을 활성화한다.
7. Authentication -> URL Configuration에서 Site URL을 로컬과 Vercel URL로 설정한다.
8. Redirect URLs에 `/auth/callback`, `/reset-password` 주소를 추가한다.
9. Table Editor에서 RLS가 활성화되어 있는지 확인한다.
10. 테스트 사용자 2명을 만들고 `docs/SECURITY.md`의 교차 사용자 절차를 수행한다.

## GitHub

1. GitHub 저장소를 만든다.
2. `git remote add origin <repo-url>`을 실행한다.
3. `.env.local`과 비밀 키가 `.gitignore`에 포함되어 있는지 확인한다.
4. main 브랜치에 push한다.

### GitHub Actions 자동 배포

`.github/workflows/test-and-deploy.yml`은 `main` push에서 다음 순서로 프로덕션 변경을 검증하고 데이터베이스를 갱신한다.

1. 의존성 설치.
2. TypeScript 검사와 단위 테스트.
3. 애플리케이션 프로덕션 빌드.
4. Supabase 마이그레이션 dry-run.
5. Supabase 마이그레이션 적용.

Vercel Git Integration은 같은 `main` push를 자동으로 빌드한다. Vercel Project Settings의 Production Deployment Checks에 GitHub Actions 체크 `Test and migrate production database`를 필수로 등록한다. 그러면 Vercel은 빌드를 만들 수 있지만 이 체크가 통과하기 전에는 프로덕션 도메인으로 승격하지 않는다.

GitHub Actions 빌드가 실패하면 데이터베이스를 변경하지 않는다. 마이그레이션이 실패하면 Deployment Check가 실패하므로 새 Vercel 빌드는 프로덕션에 승격되지 않는다. 데이터베이스 적용 이후 Vercel 빌드가 실패할 가능성에 대비해 프로덕션 마이그레이션은 기존 앱과 호환되는 확장형 변경을 우선하고, 파괴적 변경은 여러 배포로 나눈다.

GitHub 저장소의 `Settings -> Secrets and variables -> Actions`에 다음 값을 등록한다.

Secrets:

- `SUPABASE_ACCESS_TOKEN`: Supabase account access token.
- `SUPABASE_DB_PASSWORD`: 프로덕션 프로젝트의 Postgres 비밀번호.

Variables:

- `SUPABASE_PROJECT_ID`: Supabase Dashboard URL의 project ref.

Supabase 비밀값은 저장소 파일, Vercel public 환경 변수, PR 본문에 넣지 않는다. CLI 버전은 워크플로에서 고정하고 의도적으로 갱신한다. Vercel 배포는 기존 Git Integration이 담당하므로 GitHub에 Vercel token, org ID, project ID를 중복 등록하지 않는다.

### 최초 마이그레이션 자동화 전 확인

기존 프로덕션 스키마를 Supabase SQL Editor에서 직접 적용했다면 실제 스키마와 `supabase_migrations.schema_migrations` 기록이 다를 수 있다. 자동화를 처음 실행하기 전에 로컬에서 프로덕션 프로젝트를 연결하고 상태를 비교한다.

```bash
supabase link --project-ref <project-ref>
supabase migration list
supabase db push --dry-run
```

이미 적용된 스키마인데 migration history에만 없는 버전이 있다면 실제 테이블, 타입, 함수와 정책이 해당 migration과 일치하는지 먼저 확인한다. 확인 없이 `migration repair`를 실행하지 않는다. 일치가 확인된 버전만 다음 형태로 기록을 복구한다.

```bash
supabase migration repair --status applied <migration-version>
```

초기 정합성을 맞춘 뒤에는 원격 SQL Editor나 Table Editor로 스키마를 직접 변경하지 않고 모든 변경을 `supabase/migrations` 파일과 `main` 배포 워크플로를 통해 적용한다.

### LifeOS 최초 원격 이력 복구

2026-07-17 최초 자동 배포에서 프로덕션 DB에는 `202607150001_initial_schema.sql`과 `202607150002_health_module.sql`의 테이블 및 RPC가 존재하지만 migration history에는 두 버전이 없음을 확인했다. `202607150003_life_context_seed_store.sql`의 테이블과 `202607160001_action_hierarchy.sql`의 `parent_action_id` 컬럼은 아직 존재하지 않았다.

이 상태에서만 GitHub의 `Actions -> Test and migrate -> Run workflow`에서 `repair_legacy_history`를 선택해 1회 실행한다. 워크플로는 검증된 `202607150001`, `202607150002`만 적용 완료로 기록한 뒤 dry-run과 `db push`를 실행한다. 그러면 `202607150003`과 `202607160001`은 일반 마이그레이션으로 실제 적용된다.

이 옵션은 기존 데이터베이스를 새로 만들거나 삭제하지 않고 migration history만 맞춘다. 다른 Supabase 프로젝트나 실제 스키마가 다른 환경에서는 선택하지 않는다. 최초 복구가 성공한 뒤에는 일반 `main` push 경로만 사용한다.

LifeOS 프로덕션은 2026-07-17에 이 복구를 완료했다. GitHub Actions 실행 `29583216409`에서 기존 2개 이력을 복구하고 `202607150003`, `202607160001`을 적용했으며, 일반 실행 `29583512241`에서 repair 단계를 건너뛰고 원격 DB가 최신 상태임을 재확인했다. 현재 프로덕션에서는 `repair_legacy_history`를 다시 선택하지 않는다.

## Vercel

1. Vercel에서 GitHub 저장소를 Import한다.
2. Framework가 Next.js로 인식되는지 확인한다.
3. 환경 변수 `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_SITE_URL`을 등록한다.
4. Build Command는 `pnpm build`, Install Command는 `pnpm install`을 사용한다.
5. 배포 후 프로덕션 URL을 확인한다.
6. Supabase Redirect URL에 Vercel URL 기반 callback/reset 주소를 추가한다.
7. Vercel에서 재배포한다.
8. 모바일 브라우저에서 랜딩, 로그인, 대시보드, Today 화면을 확인한다.

Vercel Git Integration이 branch push에서는 Preview, `main` push에서는 Production 빌드를 자동 생성한다. Production 환경 설정에서 `Test and migrate production database` GitHub Actions 체크를 Deployment Check로 추가해 마이그레이션 성공 전 자동 프로덕션 승격을 막는다. GitHub Actions는 Vercel CLI 배포를 별도로 실행하지 않으므로 중복 배포가 없다.

## 배포 후 검증

- 회원가입, 이메일 확인, 로그인, 로그아웃
- 비밀번호 재설정 메일 발송과 reset page 진입
- Inbox 생성
- 프로젝트 전환
- 프로젝트 상세에서 행동 추가
- 오늘 계획 저장과 행동 완료
- 다른 브라우저에서 로그인 후 동일 데이터 확인
- 테스트 사용자 B가 A 데이터를 볼 수 없는지 확인

## 비용 방지

- Vercel Usage와 Supabase Usage 화면을 주기적으로 확인한다.
- 결제 수단 등록 여부와 spend limit을 확인한다.
- 한도 초과 전 DB dump를 받아 둔다.
- 무료 한도 초과 시 기능이 제한되거나 프로젝트가 pause될 수 있음을 사용자 운영 메모에 기록한다.
- 이전이 필요하면 Supabase SQL dump와 GitHub 소스를 기준으로 새 호스팅에 복구한다.
