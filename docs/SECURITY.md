# Security

## 위협 모델

가장 중요한 위험은 사용자가 브라우저 요청을 조작해 다른 사용자의 데이터를 조회, 수정, 삭제하는 것이다. LifeOS는 프론트엔드 필터링을 신뢰하지 않고 PostgreSQL RLS를 최종 방어선으로 둔다.

## RLS 정책

모든 사용자 소유 테이블은 다음 원칙의 SELECT, INSERT, UPDATE, DELETE 정책을 가진다.

```sql
user_id = auth.uid()
```

`profiles`는 `id = auth.uid()`를 사용한다.

## 키 관리

브라우저에는 `NEXT_PUBLIC_SUPABASE_ANON_KEY`만 노출한다. `SUPABASE_SERVICE_ROLE_KEY`는 현재 사용하지 않는다. 계정 삭제 같은 서버 전용 작업을 추가할 때만 서버 코드에서 제한적으로 사용하고 이유를 이 문서에 기록한다.

로컬 seed import 스크립트는 service role key를 사용할 수 있다. 이 스크립트는 서버 런타임이나 브라우저 번들에서 호출하지 않는다.

## 민감 Seed 관리

사용자 seed는 `seed/` 하위 로컬 파일에만 둔다. 체중, 의료, 정신 건강, 관계 갈등, 재정, 회사 내부 정보, 위치 기록처럼 민감한 데이터는 Git 추적 대상이 아니다.

## 세션 처리

`@supabase/ssr`의 브라우저/서버 클라이언트를 분리했다. middleware에서 쿠키 세션을 갱신하고 보호 경로 접근을 제어한다.

## 계정 삭제

사용자 삭제 시 `auth.users`를 기준으로 `on delete cascade`가 사용자 데이터를 제거한다. UI 활성화 전에는 service role 사용 범위, 확인 문구, 감사 로그 필요 여부를 검토한다.

## 교차 사용자 검증 절차

1. 테스트 사용자 A, B를 만든다.
2. A로 로그인해 Inbox와 Project를 만든다.
3. B로 로그인해 목록에서 A 데이터가 보이지 않는지 확인한다.
4. B 세션으로 A row id를 직접 사용해 update/delete 요청을 보낸다.
5. 요청이 실패하거나 영향 row가 0인지 확인한다.
6. 동일 절차를 `action_items`, `daily_plans`, `weekly_reviews`에 반복한다.

자동 테스트는 `tests/rls/rls-static.test.ts`가 RLS 활성화와 정책 존재를 정적으로 확인한다.
