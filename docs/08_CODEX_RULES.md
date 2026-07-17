# Codex Rules

Codex는 LifeOS 구현 전에 현재 저장소를 먼저 분석한다.

## Pre-Implementation Checklist

- 기술 스택.
- 디렉터리 구조.
- 아키텍처.
- 코딩 스타일.
- 인증 방식.
- 데이터 저장 방식.
- 예외 처리.
- 테스트 패턴.
- UI 디자인 시스템.
- API 응답 규칙.
- 배포 환경.

## Implementation Rules

1. 기존 구조를 최대한 유지한다.
2. PRD 전체를 한 번에 구현하지 않는다.
3. 현재 지정된 MVP 범위만 구현한다.
4. [LIFEOS_PRD.md](./LIFEOS_PRD.md)를 상위 제품 기준으로 참고하되, Codex가 임의로 수정하지 않는다.
5. DB 마이그레이션과 롤백을 고려한다.
6. 민감 데이터가 로그에 노출되지 않게 한다.
7. 코드 수정 전 영향 범위를 설명한다.
8. 완료 후 변경 파일, 실행 방법, 테스트 결과, 남은 이슈를 정리한다.
9. 기존 기능을 깨뜨리지 않는 테스트를 작성한다.
10. UI는 기존 LifeOS 디자인 시스템을 따른다.
11. 미확정 항목은 결정 대기 항목으로 기록한다.
12. 구현 중 발견한 기존 구조 문제를 무단으로 대규모 리팩터링하지 않는다.

## Current Engineering Defaults

- Next.js App Router와 Server Actions를 우선 사용한다.
- Supabase RLS를 최종 데이터 격리 계층으로 둔다.
- 사용자 데이터 변경은 가능한 anon key + RLS + RPC/Server Action 흐름으로 처리한다.
- service role key는 import나 운영성 작업처럼 필요한 경우에만 로컬 스크립트에서 사용한다.

## Required Documentation After Feature Work

기능 구현이나 의미 있는 UX/데이터 변경 후 다음 문서를 갱신한다.

- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- 중요한 구현 또는 제품 결정이 있으면 `docs/09_DECISION_LOG.md`
- `docs/handoffs/YYYY-MM-DD-task-name.md`

handoff에는 작업 목표, 구현 내용, 변경 파일, 데이터 구조 변경, API 변경, 주요 결정, PRD와 달라진 점, 임시 구현과 기술 부채, 실제 사용 후 확인할 사항, 남은 문제, 다음 작업 후보, 실행 방법, 테스트 결과를 포함한다.

## GitHub Delivery Rules

LifeOS 작업은 코드와 문서가 로컬에만 남지 않도록 다음 규칙으로 마무리한다.

1. 작업 범위가 명확하고 테스트와 빌드 등 필요한 검증이 통과하면 Codex가 관련 파일만 명시적으로 스테이징한다.
2. 별도 재확인 없이 한국어 커밋 메시지로 커밋하고 현재 작업 브랜치에 push한다.
3. 같은 브랜치의 열린 PR이 있으면 그 PR을 갱신한다.
4. 열린 PR이 없으면 기본 브랜치를 대상으로 한국어 제목과 본문의 Draft PR을 생성한다.
5. PR 본문에는 작업 목표, 주요 변경 사항, 데이터/API 영향, 검증 결과, 배포 선행 조건, 남은 문제를 포함한다.
6. 사용자가 명시적으로 요청하지 않으면 PR을 자동 merge하거나 프로덕션 변경을 승인하지 않는다.
7. 관련 없는 변경, 실패한 검증, 인증 또는 권한 문제는 임의로 우회하지 않고 사용자에게 알린다.

이 규칙은 저장소 최상위 `AGENTS.md`에도 유지해 새 Codex 대화와 작업 환경에서 우선 적용되게 한다.
