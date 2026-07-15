# Free Tier

무료 플랜 수치와 정책은 바뀔 수 있으므로 앱 코드에 하드코딩하지 않는다. 배포 전에 각 서비스의 공식 가격 페이지를 다시 확인한다.

## 사용 서비스

- Vercel Hobby: Next.js 웹 앱 호스팅
- Supabase Free: PostgreSQL, Auth, Storage 미사용
- GitHub Free: 소스 저장소와 Vercel 연동

## 무료 범위를 초과할 수 있는 조건

- Vercel 빌드/대역폭/함수 실행량 증가
- Supabase DB 용량, Auth 사용자 수, API 요청량 증가
- 장기간 미사용에 따른 Supabase 프로젝트 일시 정지

## 비활성 프로젝트 일시 정지

Supabase Free 프로젝트는 비활성 시 pause될 수 있다. 개인용 앱은 주기적으로 접속하거나 중요한 데이터는 export한다.

## 백업 제약

무료 플랜의 자동 백업 보장 범위는 제한적일 수 있다. 중요한 기록은 정기적으로 SQL dump 또는 CSV export를 수행한다.

## 유료 전환 지점

- 매일 장시간 사용자가 늘어나는 경우
- DB 크기가 무료 한도에 가까운 경우
- 자동 백업과 복구 보장이 필요한 경우
- 더 많은 배포 팀 권한이 필요한 경우

## 대체 후보

- Netlify, Cloudflare Pages
- Neon, Turso, Railway free allowance
- 자체 호스팅 PostgreSQL
