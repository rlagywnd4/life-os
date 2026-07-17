# 2026-07-17 Git Convention

Date: 2026-07-17
Status: 완료

## 작업 목표

한 명이 사용하는 LifeOS에 맞춰, 구현된 기능을 사용자가 직접 확인한 뒤 `main`에 반영하면서도 단순 유지보수는 부담 없이 기록할 수 있는 Git 컨벤션을 만든다.

## 구현한 내용

- 기능·위험 변경은 최신 `main`에서 만든 영문 `codex/<type>-<short-description>` 브랜치와 기능 단위 PR로 관리하도록 정했다.
- 기능 PR은 Vercel Preview 또는 이후의 Swift 테스트 빌드에서 사용자가 직접 확인한 뒤 요청하면 Squash merge한다.
- 브랜치와 커밋은 영문 Conventional Commit, 사용자 확인용 PR 제목·본문은 한국어로 정했다.
- 단순 문서·포맷·내부 기록은 `main`에 직접 커밋할 수 있게 해 개인 프로젝트의 불필요한 절차를 줄였다.
- PR 템플릿에 사용자 변화, 직접 확인 방법, 검증 결과, 데이터·배포 영향, 제한 사항을 고정했다.
- force push 대신 revert 또는 긴급 수정으로 복구하고, 병합한 작업 브랜치를 삭제하도록 정했다.

## 변경 파일

- `AGENTS.md`
- `.github/pull_request_template.md`
- `docs/00_INDEX.md`
- `docs/08_CODEX_RULES.md`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/12_GIT_CONVENTION.md`
- `docs/handoffs/2026-07-17-git-convention.md`

## 데이터 구조 변경

없음.

## API 변경

없음.

## 주요 구현 결정과 이유

- PR은 코드 검토가 아니라 기능 인수 확인과 변경 기록에 사용한다. 사용자는 코드 대신 Preview 또는 테스트 빌드에서 결과를 확인한다.
- 모든 변경에 PR을 강제하지 않고, 사용자 확인이 필요 없는 작은 유지보수는 직접 커밋하도록 해 절차를 최소화했다.
- 웹의 Vercel Preview와 향후 Swift 테스트 빌드를 같은 "검증 가능한 결과물"로 정의해 플랫폼 전환에도 흐름을 유지한다.

## 기존 PRD와 달라진 점

없음. 제품 요구사항이 아닌 저장소 운영 방식 변경이다.

## 임시 구현과 기술 부채

- Swift 앱용 테스트 빌드 자동 배포는 아직 구현 전이다. 네이티브 앱을 시작할 때 TestFlight 또는 개발 빌드 배포 방식을 구체화한다.

## 실제 사용 후 확인해야 할 사항

- Vercel Preview 링크가 기능 PR에서 사용자가 직접 테스트하기에 충분한지 확인한다.
- PR 템플릿의 항목이 인수 확인에 과하지 않은지 실제 기능 작업 후 조정한다.

## 남은 문제

- Vercel Preview는 PR 전용 Supabase 데이터베이스를 제공하지 않는다. 데이터 구조 변경의 통합 검증 환경은 별도 과제다.

## 다음 작업 후보

1. 첫 SwiftUI 기능 PR에 맞는 테스트 빌드 배포 방식 선택.
2. 필요해지면 GitHub `main` 브랜치 보호 규칙과 병합 방식 설정 확인.

## 실행 방법

별도 실행 명령은 없다. 이후 LifeOS 작업부터 이 문서와 최상위 `AGENTS.md` 규칙을 따른다.

## 테스트 결과

- 문서와 PR 템플릿 변경이므로 `git diff --check` 및 Markdown 링크 확인을 실행한다.
