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
