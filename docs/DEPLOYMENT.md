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

## Vercel

1. Vercel에서 GitHub 저장소를 Import한다.
2. Framework가 Next.js로 인식되는지 확인한다.
3. 환경 변수 `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_SITE_URL`을 등록한다.
4. Build Command는 `pnpm build`, Install Command는 `pnpm install`을 사용한다.
5. 배포 후 프로덕션 URL을 확인한다.
6. Supabase Redirect URL에 Vercel URL 기반 callback/reset 주소를 추가한다.
7. Vercel에서 재배포한다.
8. 모바일 브라우저에서 랜딩, 로그인, 대시보드, Today 화면을 확인한다.

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
