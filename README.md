# LifeOS

LifeOS는 떠오른 생각을 Inbox에 안전하게 모아두고, 주간 리뷰에서 프로젝트로 고른 뒤, 오늘의 작은 행동으로 옮기는 개인용 인생 운영 웹앱입니다.

## 핵심 흐름

생각 기록 -> Inbox 검토 -> Project 전환 또는 Someday 보류 -> 작은 Action 분해 -> Today 계획 -> 결과 기록 -> Weekly Review.

## 기술 스택

- Next.js App Router, TypeScript, React
- Supabase Auth, PostgreSQL, Row Level Security
- Supabase SSR JavaScript client
- Tailwind CSS, React Hook Form/Zod 기반 검증 구조
- Vitest, React Testing Library, Playwright
- Vercel Hobby 배포 설정

## 주요 화면

- `/`: 간단한 랜딩 페이지
- `/login`, `/signup`, `/forgot-password`, `/reset-password`: 인증
- `/dashboard`: 빠른 Inbox, 오늘 상태, 프로젝트 요약
- `/inbox`: 검색, 필터, Someday 이동, 프로젝트 전환
- `/projects`, `/projects/[id]`: 프로젝트와 작은 행동
- `/today`: 에너지/모드/행동 선택
- `/weekly-review`, `/someday`, `/history`, `/settings`

## 로컬 실행

```bash
pnpm install
cp .env.example .env.local
pnpm dev
```

`.env.local`에는 Supabase 프로젝트 URL과 anon key를 넣습니다.

## Supabase 로컬 실행

Supabase CLI가 설치되어 있다면:

```bash
supabase start
supabase db reset
```

Cloud 프로젝트에는 `supabase db push` 또는 SQL editor로 `supabase/migrations` 파일을 적용합니다.

## 테스트

```bash
pnpm test
pnpm test:e2e
pnpm build
```

RLS 테스트는 현재 SQL 마이그레이션 정적 검증을 포함합니다. 실제 교차 사용자 차단은 Supabase 로컬 또는 Cloud 테스트 사용자를 만든 뒤 `docs/SECURITY.md` 절차로 검증합니다.

## 환경 변수

```text
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

현재 앱 코드는 service role key를 사용하지 않습니다.

## 보안 원칙

- 로그인 후 보호 화면 접근
- 서버와 브라우저 Supabase 클라이언트 분리
- 모든 사용자 데이터 테이블에 `user_id = auth.uid()` RLS
- Inbox -> Project, Today core action 추가는 PostgreSQL 함수로 원자 처리
- 날짜 계획은 `date`, 시각은 `timestamptz`

## 알려진 제한

- 설정 저장, 계정 삭제, Weekly Review 마법사의 완전한 중간 저장 UI는 다음 단계 과제입니다.
- E2E 인증 플로우는 Supabase 테스트 프로젝트가 필요합니다.
- Google 로그인과 오프라인 동기화는 초기 버전 범위에서 제외했습니다.

## 문서

- [Architecture](./docs/ARCHITECTURE.md)
- [Database](./docs/DATABASE.md)
- [Deployment](./docs/DEPLOYMENT.md)
- [Security](./docs/SECURITY.md)
- [Free Tier](./docs/FREE_TIER.md)
- [Decisions](./docs/DECISIONS.md)

## 검증 결과

초기 구현 후 `pnpm install`, `pnpm test`, `pnpm build`로 검증합니다. 결과는 작업 보고에 기록합니다.
