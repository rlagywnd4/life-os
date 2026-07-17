# 2026-07-17 GitHub Authentication Automation

Date: 2026-07-17
Status: 완료

## 작업 목표

GitHub CLI 사용자 토큰이 무효화되어도 LifeOS의 push와 PR 자동 게시가 중단되지 않도록, 저장소 전용의 최소 권한 인증 경로를 만든다.

## 구현한 내용

- `LifeOS Codex Automation` GitHub App을 만들고 `rlagywnd4/life-os` 한 저장소에만 설치했다.
- App에 코드와 Pull Request 읽기·쓰기만 부여하고 webhook과 전체 저장소 접근은 사용하지 않았다.
- App 비공개 키는 Mac 키체인에 저장하고 Downloads의 원본 PEM 파일은 삭제했다.
- Mac SSH 공개 키를 GitHub 계정에 등록했다.
- `scripts/github-app-token.mjs`가 키체인의 App 키로 짧은 수명의 설치 토큰을 자동 발급하도록 추가했다.
- `scripts/gh-lifeos`가 토큰을 노출하지 않고 `gh` 명령에 전달하도록 추가했다.

## 변경 파일

- `AGENTS.md`
- `scripts/github-app-token.mjs`
- `scripts/gh-lifeos`
- `docs/09_DECISION_LOG.md`
- `docs/10_CHANGELOG.md`
- `docs/11_IMPLEMENTATION_STATUS.md`
- `docs/12_GIT_CONVENTION.md`
- `docs/handoffs/2026-07-17-github-authentication-automation.md`

## 데이터 구조 변경

없음.

## API 변경

없음.

## 주요 구현 결정과 이유

- Git 전송과 GitHub API 인증을 분리했다. SSH는 push용, GitHub App 설치 토큰은 PR용으로 사용한다.
- 사용자 개인 토큰을 저장소·환경 파일에 저장하지 않고, App 비공개 키를 Mac 키체인에만 둔다.
- App을 한 저장소에만 설치해 다른 저장소에 접근하지 못하게 했다.

## 기존 PRD와 달라진 점

없음. 제품 요구사항이 아닌 개발 환경 인증 방식 변경이다.

## 임시 구현과 기술 부채

- 자동화는 이 Mac의 키체인과 로컬 Git 설정에 의존한다. 다른 Mac에서는 초기 설정이 한 번 필요하다.

## 실제 사용 후 확인해야 할 사항

- 다음 기능 작업에서 `scripts/gh-lifeos pr create`로 Ready for review PR이 생성되는지 확인한다.
- App 권한이 PR 병합과 상태 조회에 충분한지 첫 병합 요청 때 확인한다.

## 남은 문제

- GitHub App 비공개 키를 분실하면 App 설정에서 새 키를 발급하고 키체인을 갱신해야 한다.

## 다음 작업 후보

1. 새 Mac에서도 사용할 수 있는 비밀값 없는 초기 설정 안내 추가.
2. 필요하면 `main` 브랜치 보호 규칙과 Squash merge 기본값을 GitHub에서 확인.

## 실행 방법

```bash
scripts/gh-lifeos pr list
scripts/gh-lifeos pr create
```

## 테스트 결과

- GitHub App 설치와 저장소 제한을 GitHub 설정 화면에서 확인했다.
- SSH 공개 키 등록 후 `ssh -T git@github.com` 인증을 확인했다.
- App 토큰 발급 및 GitHub API 호출 검증은 로컬 App ID 설정 후 실행한다.
