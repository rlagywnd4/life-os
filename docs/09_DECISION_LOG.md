# Decision Log

이 문서는 LifeOS 구현 중 발생한 중요한 제품/기술 결정을 기록한다. 상위 제품 기준은 로컬 전용 `docs/LIFEOS_PRD.md`이며, PRD와 충돌하거나 PRD를 바꿔야 할 가능성이 있는 내용은 여기와 handoff 문서에 먼저 기록한다.

## 작성 규칙

- 기능 구현마다 반드시 작성하지 않아도 된다.
- 데이터 모델, UX 방향, 보안, AI 메모리, MVP 범위에 영향을 주는 결정만 기록한다.
- 결정과 단순 구현 메모를 섞지 않는다.
- PRD 본문은 Codex가 임의로 수정하지 않는다.
- 결정이 임시라면 되돌릴 조건을 함께 적는다.

## Template

```text
## YYYY-MM-DD - 결정 제목

Status: Accepted | Proposed | Superseded
Scope: Product | Engineering | Data | UX | Security | AI

Context:
- 왜 결정이 필요했는가.

Decision:
- 무엇을 결정했는가.

Rationale:
- 왜 이 선택을 했는가.

Alternatives:
- 검토했지만 선택하지 않은 방법.

Impact:
- 구현, UX, 데이터, 문서에 미치는 영향.

PRD Impact:
- PRD 반영 필요 여부.
```

## 2026-07-17 - 네이티브 AI는 V1 이후 생각 정리 기능으로 분리

Status: Accepted
Scope: Product / AI / UX

Context:

- LifeOS는 iPhone과 Mac에서 사용하는 개인 도구로 전환하며, 두 기기 간 데이터 동기화는 기존 Supabase를 계속 사용하기로 했다.
- 기기 내 AI는 개인 기록을 요약·분류하는 데 유용하지만, V1의 핵심 데이터 흐름과 UI 완성보다 먼저 구현하면 범위와 검증 부담이 커진다.

Decision:

- 네이티브 AI 기능은 V1에서 구현하지 않는다.
- V1 이후 첫 AI 후보는 사용자가 선택한 메모 또는 Inbox 항목을 요약하고, 주제·미해결 질문·Inbox/프로젝트/다음 행동 후보를 제안하는 "생각 정리" 기능이다.
- AI는 선택된 최소 범위의 데이터만 참조하며, 제안을 자동 저장·실행하지 않는다.
- 지원 기기에서는 기기 내 모델을 우선 검토하되, 사용 불가 기기에서도 V1 핵심 기능은 동일하게 사용할 수 있어야 한다.

Rationale:

- 데이터 동기화와 AI 추론을 분리하면 Supabase 기반의 V1을 단순하게 완성하면서, 나중에 AI 제공자나 모델을 바꿔도 핵심 데이터 구조를 흔들지 않는다.
- 개인 기록의 민감성을 고려하면 사용자가 선택한 정보만 AI에 전달하고 최종 반영을 직접 결정하는 흐름이 적합하다.

Alternatives:

- V1에 AI 채팅과 자동 분류를 함께 넣는 방식은 UI, 프롬프트, 오류 처리, 개인정보 동의 범위를 동시에 확장하므로 제외했다.
- 모든 Supabase 기록을 자동으로 모델에 제공하는 방식은 필요한 맥락 범위와 사용자 통제가 불명확해 제외했다.

Impact:

- V1에는 AI SDK, 모델 키, AI 전용 데이터 구조를 추가하지 않는다.
- 이후 AI 기능을 시작할 때 기기 지원 조건, 출력 품질, 외부 전송 여부, 사용자 승인 UX를 별도 검증한다.

PRD Impact:

- 없음. PRD의 AI 원칙과 충돌하지 않으며, 구현 순서와 범위를 구체화한 결정이다.

## 2026-07-17 - 검증 완료 작업은 한국어 Draft PR로 자동 게시

Status: Superseded
Scope: Engineering / Process

Context:

- 로컬 작업만 남으면 다른 대화나 나중 시점에 어떤 변경이 진행됐는지 추적하기 어렵다.
- 사용자는 기능 작업 완료 후 Codex가 매번 별도 확인을 기다리지 않고 커밋과 PR 게시까지 처리하기를 원한다.

Decision:

- 범위가 명확한 LifeOS 작업은 필요한 검증 후 Codex가 관련 파일만 커밋하고 원격 브랜치에 push한다.
- 기존 PR이 있으면 갱신하고, 없으면 기본 브랜치 대상 Draft PR을 만든다.
- 커밋 메시지, PR 제목과 본문은 한국어로 작성한다.
- 사용자가 명시적으로 요청하기 전에는 PR을 merge하지 않는다.

Rationale:

- Git 커밋과 PR을 작업 단위 기록으로 사용하면 변경 이력, 검증 결과, 배포 선행 조건을 GitHub에서 확인할 수 있다.
- Draft PR은 자동 게시와 사용자 최종 검토를 함께 지원한다.
- 최상위 `AGENTS.md`에 규칙을 두면 새 Codex 대화에서도 같은 운영 방식을 적용할 수 있다.

Alternatives:

- 작업마다 커밋과 PR 여부를 다시 묻는 방식은 기록 누락과 대화 간 운영 차이를 만들 수 있어 선택하지 않았다.
- 자동 merge는 프로덕션 배포와 DB 변경을 촉발할 수 있어 제외했다.

Impact:

- 향후 범위가 명확한 구현 작업은 검증 이후 기본적으로 GitHub Draft PR까지 게시된다.
- 관련 없는 변경이 섞였거나 인증·검증 문제가 있으면 자동 게시 대신 사용자 확인이 필요하다.

PRD Impact:

- 없음. Codex 작업 전달과 변경 추적 방식에 관한 운영 결정이다.

## 2026-07-17 - 기능 인수 확인 중심의 Git 컨벤션

Status: Accepted
Scope: Engineering / Process

Context:

- LifeOS는 현재 한 명이 사용하는 개인 서비스이며, 사용자는 코드 리뷰보다 구현된 기능을 직접 확인하고 병합 여부를 결정하기를 원한다.
- 모든 변경에 PR을 강제하면 단순 유지보수에도 불필요한 절차가 생기지만, 사용자 기능을 확인하기 전에 `main`에 반영하면 배포 기준이 흐려진다.
- 현재 웹앱은 Vercel Preview를 제공하고, 이후 Swift 앱에서도 테스트 빌드로 같은 인수 확인 흐름을 유지할 수 있어야 한다.

Decision:

- 사용자 기능과 위험도가 높은 변경은 기능 단위 PR로 만들고, 사용자가 Preview 또는 테스트 빌드에서 직접 확인한 뒤 요청하면 Squash merge한다.
- 단순 문서·포맷·내부 기록처럼 사용자 확인이 불필요한 작은 유지보수는 `main`에 직접 커밋할 수 있다.
- 브랜치와 커밋은 영문 Conventional Commit 형식을 사용하고, PR 제목과 본문은 한국어로 작성한다.
- `main`의 최종 Squash 커밋에는 PR 번호를 남기고, 병합한 작업 브랜치는 삭제한다.
- `main`에는 force push하지 않으며, 장애는 revert 또는 긴급 수정으로 복구한다.

Rationale:

- PR을 코드 검토 절차가 아니라 기능 인수 확인과 변경 기록으로 사용하면 한 명의 사용자도 배포 전 결과를 직접 판단할 수 있다.
- Preview와 테스트 빌드라는 결과물 중심 기준은 웹앱에서 Swift 앱으로 전환해도 유지된다.
- 직접 커밋 예외를 작은 유지보수로 제한하면 필요한 통제와 작업 속도를 함께 유지할 수 있다.

Alternatives:

- 모든 변경에 PR을 강제하는 방식은 기록은 촘촘하지만 개인 프로젝트의 작은 유지보수에는 과도하다.
- 모든 변경을 `main`에 직접 반영하는 방식은 기능 확인과 배포 이력이 섞여 되돌리기와 추적이 어려워 제외했다.
- 모든 PR을 Draft로 게시하는 기존 방식은 완료된 기능에 사용자가 추가 상태 변경을 해야 하므로 대체했다.

Impact:

- 기능 PR은 Ready for review 상태로 사용자 확인용 결과물과 테스트 정보를 제공한다.
- 병합 전에는 최신 `main` 기준 검증을 다시 수행하고, 병합 뒤에는 배포 상태와 핵심 흐름을 확인한다.
- GitHub PR 템플릿을 사용해 사용자 확인 항목을 일관되게 기록한다.

PRD Impact:

- 없음. 제품 요구사항이 아닌 저장소 작업·배포 운영 방식이다.

## 2026-07-17 - 저장소 전용 GitHub App 인증 자동화

Status: Accepted
Scope: Engineering / Security / Process

Context:

- GitHub CLI의 사용자 토큰이 무효화되면 Codex가 push 이후 PR을 자동 게시할 수 없고, 사용자가 매번 재인증해야 한다.
- 개인 토큰을 저장소나 환경 파일에 장기 보관하는 방식은 유출 범위가 넓고 자동 갱신할 수 없다.

Decision:

- Git push는 계정에 등록한 Mac SSH 키를 사용한다.
- PR 생성·조회·병합은 `life-os` 저장소에만 설치한 `LifeOS Codex Automation` GitHub App의 설치 토큰을 사용한다.
- App 비공개 키는 Mac 키체인에만 보관하고, 저장소의 `scripts/gh-lifeos`는 필요할 때마다 짧은 수명의 토큰을 발급해 `gh`에 전달한다.
- App 권한은 코드와 Pull Request 읽기·쓰기로 제한하고, webhook과 전체 저장소 접근은 사용하지 않는다.

Rationale:

- SSH는 사용자 토큰 만료와 무관하게 Git 전송을 수행한다.
- App 설치 토큰은 짧게 유지되지만 비공개 키로 자동 발급되므로 사용자 재로그인 없이 GitHub API 작업을 수행할 수 있다.
- 키체인·저장소 제한·최소 권한 조합은 자동화와 키 유출 방지 사이의 균형을 맞춘다.

Alternatives:

- GitHub CLI OAuth 토큰을 다시 로그인해 사용하는 방식은 간단하지만 무효화 시 동일한 중단이 반복된다.
- 장기 개인 액세스 토큰을 환경 변수나 파일에 저장하는 방식은 갱신 부담과 노출 범위가 커 제외했다.

Impact:

- 이후 Codex는 `scripts/gh-lifeos`로 PR 자동화 작업을 수행한다.
- 새 Mac 또는 새 클론에는 GitHub App 키를 다시 키체인에 저장하고 로컬 App ID 설정을 해야 한다.

PRD Impact:

- 없음. 저장소 운영 인증 방식 변경이다.

## 2026-07-17 - 검증된 기존 스키마만 최초 migration history로 복구

Status: Accepted
Scope: Engineering / Data

Context:

- 최초 Supabase 자동 배포가 이미 존재하는 `inbox_category` 타입을 다시 만들려다 실패했다.
- 프로덕션 스키마 일부는 SQL Editor로 적용됐지만 `supabase_migrations.schema_migrations`에는 적용 이력이 없었다.
- 존재 여부가 확인되지 않은 migration까지 적용 완료로 기록하면 실제 스키마가 누락될 수 있다.

Decision:

- 프로덕션 API 스키마에서 테이블과 RPC 존재가 확인된 `202607150001`, `202607150002`만 기존 적용분으로 인정한다.
- 명시적인 수동 실행과 `repair_legacy_history` 입력이 있을 때만 두 버전의 migration history를 복구한다.
- 존재하지 않은 `202607150003`과 `202607160001`은 repair 대상에서 제외하고 일반 `db push`로 적용한다.

Rationale:

- 실제 스키마와 migration history를 분리해 확인하면 중복 DDL 실행과 미적용 스키마 은폐를 함께 막을 수 있다.
- 수동 boolean 입력은 특수한 최초 복구가 일반 `main` 배포마다 반복되는 것을 막는다.

Alternatives:

- 네 migration을 모두 적용 완료로 기록하는 방식은 아직 존재하지 않는 테이블과 컬럼을 누락시키므로 제외했다.
- 초기 migration을 모두 idempotent SQL로 다시 작성하는 방식은 이미 운영 중인 스키마 정의를 광범위하게 바꿔야 해 제외했다.

Impact:

- 최초 1회는 수동 workflow dispatch로 이력을 복구하고, 이후에는 기존 자동 배포 흐름을 그대로 사용한다.
- 다른 프로젝트에서는 스키마 확인 없이 이 옵션을 사용하면 안 된다.

PRD Impact:

- 없음. 기존 프로덕션 DB의 배포 이력을 안전하게 정합화하는 운영 결정이다.

## 2026-07-17 - DB 마이그레이션을 Vercel 프로덕션 승격 조건으로 사용

Status: Accepted
Scope: Engineering / Data / Security

Context:

- 계층형 활동 코드가 배포되기 전에 `parent_action_id` 데이터베이스 마이그레이션이 적용되어야 한다.
- 기존 Vercel Git 자동 배포는 유지하면서 Supabase 자동화와 앱 공개 순서를 보장해야 한다.
- 기존 GitHub Actions의 Vercel CLI 배포는 필요한 Vercel secrets가 등록되지 않아 첫 실행부터 실패했다.

Decision:

- 기존 `main` GitHub Actions 워크플로가 검사와 애플리케이션 빌드 후 Supabase migration dry-run과 적용을 수행한다.
- Vercel Git Integration은 빌드를 담당하고, GitHub Actions의 `Test and migrate production database` 체크를 Production Deployment Check로 등록해 migration 성공 전 프로덕션 승격을 막는다.
- Supabase account token과 DB 비밀번호는 GitHub Actions secrets, project ref는 variable로 관리한다.
- Supabase CLI 버전은 워크플로에 고정한다.

Rationale:

- 코드가 빌드되지 않으면 DB를 변경하지 않고, DB 변경이 실패하면 Vercel이 새 앱을 프로덕션 도메인에 노출하지 않는다.
- 하나의 concurrency group과 직렬 단계가 동시에 여러 프로덕션 마이그레이션을 실행하는 위험을 줄인다.
- 비밀값을 저장소 및 브라우저 환경에서 분리한다.
- Vercel CLI 인증값과 중복 프로덕션 배포를 제거하면서 기존 Preview 배포 흐름을 유지한다.

Alternatives:

- Vercel CLI로 다시 빌드·배포하는 방식은 Vercel secrets와 중복 빌드가 필요해 제외했다.
- Deployment Check 없이 Vercel과 Supabase를 독립 실행하는 방식은 실행 순서 경쟁 때문에 선택하지 않았다.

Impact:

- GitHub에 `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `SUPABASE_PROJECT_ID`를 등록하고 Vercel에서 GitHub Actions Deployment Check를 선택해야 안전한 프로덕션 승격이 동작한다.
- 기존 원격 DB를 수동 SQL로 구성했다면 최초 실행 전에 migration history 정합성을 확인해야 한다.
- DB 적용 후 Vercel 빌드 실패는 완전히 원자적으로 되돌릴 수 없으므로 프로덕션 migration은 이전 앱과 호환되게 작성한다.

PRD Impact:

- 없음. 배포 안정성과 비밀값 운영 방식에 관한 구현 결정이다.

## 2026-07-16 - 활동 계층을 자기 참조 구조로 관리

Status: Accepted
Scope: Product / Data / UX

Context:

- 활동을 필요한 만큼 더 작은 활동으로 나누고, 생성 후에도 다른 부모 아래로 옮길 수 있어야 한다.
- 계층형 데이터의 진행률과 부모 완료 상태를 어떤 기준으로 계산할지 정해야 한다.

Decision:

- 기존 `action_items`에 nullable 자기 참조 키 `parent_action_id`를 추가한다.
- 부모는 같은 사용자와 같은 프로젝트에 속한 활동만 허용하며 자기 자신 또는 자신의 후손 아래로 이동하는 순환 관계는 데이터베이스 트리거로 거부한다.
- 부모 활동의 완료 개수와 진행률은 직계 자식만이 아니라 전체 후손 활동을 기준으로 계산하고 `DONE` 상태만 완료로 센다.
- 전체 후손이 완료되어도 부모 상태는 변경하지 않고 사용자에게 별도 완료 액션을 제안한다.

Rationale:

- 자기 참조 모델은 별도 관계 테이블 없이 한 활동당 하나의 부모라는 요구를 직접 표현하고 깊이를 고정하지 않는다.
- 전체 후손 기준 진행률은 여러 단계로 세분화된 활동에서도 실제 남은 작업을 일관되게 보여준다.
- 명시적인 완료 액션은 하위 활동의 완료와 상위 목표의 달성을 같은 의미로 단정하지 않는다.

Alternatives:

- 고정된 2~3단계 컬럼 구조는 깊이 제한 요구와 맞지 않아 제외했다.
- 모든 하위 활동 완료 시 부모를 자동 완료하는 방식은 사용자의 최종 판단을 건너뛰므로 제외했다.
- 직계 자식만 진행률에 포함하는 방식은 더 깊은 활동의 상태를 숨길 수 있어 제외했다.

Impact:

- 모든 환경에 `202607160001_action_hierarchy.sql` 마이그레이션을 적용해야 한다.
- 프로젝트 상세 화면이 평면 미완료/완료 목록에서 하나의 계층 트리로 바뀐다.
- 트리 전체를 조회해 클라이언트에서 진행률을 계산하므로 활동 수가 크게 늘면 집계 쿼리 또는 서버 계산을 검토한다.

PRD Impact:

- 기존 PRD의 Project/Task 및 작은 행동 개념을 구체화하며 충돌은 없다. PRD 원문은 수정하지 않았다.

## 2026-07-15 - Constitution v1 문서 구조 채택

Status: Accepted
Scope: Product / Engineering

Context:

- `LifeOS_PRD_v0.1.md`를 구현의 상위 기준으로 사용하면서, 실제 구현 기록과 제품 개념 문서를 분리할 필요가 생겼다.

Decision:

- PRD 원문은 `docs/LIFEOS_PRD.md`에 보관한다.
- 구현 변경 기록은 `docs/10_CHANGELOG.md`, 현재 상태는 `docs/11_IMPLEMENTATION_STATUS.md`, 작업별 인수인계는 `docs/handoffs/`에 기록한다.
- 제품/기술 결정은 이 문서에 기록한다.

Rationale:

- 기능 구현 중 PRD를 직접 수정하면 개념 변경과 코드 변경의 경계가 흐려진다.
- 작은 기능 단위로 구현하고 실제 사용 피드백을 별도 반영하는 운영 방식에 맞춘다.

Impact:

- 앞으로 기능 구현 작업은 changelog, implementation status, handoff 갱신을 완료 조건에 포함한다.

PRD Impact:

- 없음. PRD 원문은 그대로 기준 문서로 둔다.
