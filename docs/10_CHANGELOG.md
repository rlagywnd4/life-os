# Changelog

이 문서는 LifeOS 저장소의 사용자에게 의미 있는 변경을 시간순으로 기록한다. 세부 구현 의도와 이어받을 내용은 `docs/handoffs/`에 남기고, 제품/기술 결정은 `docs/09_DECISION_LOG.md`에 남긴다.

## 작성 규칙

- 기능, UX, 데이터 구조, 문서 운영 방식이 바뀌면 기록한다.
- 내부 리팩터링만 있고 사용자 영향이 없다면 짧게 기록하거나 handoff에만 남긴다.
- PRD 변경은 직접 기록하지 않고, 새 PRD 버전 반영 작업의 changelog로 기록한다.

## 2026-07-15

- 주요 클릭/저장 상호작용에 눌림 효과와 제출 중 상태 표시를 추가했다.
- LifeOS Constitution v1 문서 구조를 추가했다.
- PRD v0.1의 Mission, Vision, 원칙, 도메인, AI 메모리 모델, 로드맵을 저장소 문서로 분리했다.
- 개인 PRD와 사용자 seed를 로컬 전용 파일로 분리했다.
- `docs/09_DECISION_LOG.md`, `docs/11_IMPLEMENTATION_STATUS.md`, `docs/handoffs/README.md`를 추가해 구현 추적 구조를 정리했다.
