# Changelog

nvim-min의 사용자 영향 변경을 이 문서에 기록한다. 아직 Git 태그로 배포된 버전이 없으므로
현재 변경은 모두 `Unreleased`에 속한다.

작성 규칙과 실제 릴리스 절차는 [릴리스 관리 가이드](docs/release-management.md)를 따른다.

## [Unreleased]

### Added

- `vim.pack` 기반의 독립 Neovim 구성과 플러그인 잠금 파일
- LSP, 자동완성, 포맷, 린트, Treesitter, 검색, Git, 터미널 기능
- Markdown 내부 렌더링과 marksman 기반 Markdown 언어 지원
- 설치, 구조, 구성, 키맵, 운영, 문제 해결, 릴리스 관리 문서

- Jenkinsfile 검증. 저장 시 `Jenkinsfile*`과 `*.jenkinsfile`을 Jenkins의
  `pipeline-model-converter/validate`로 보내 진단을 받는다. 수동 실행은 `:JenkinsLint`.
  자격증명(`JENKINS_URL` / `JENKINS_USER` / `JENKINS_TOKEN` 또는 대응하는 `vim.g`)이
  없으면 조용히 비활성화된다.

### Changed

- Markdown 내부 렌더링에서 HTML과 LaTeX 변환을 비활성화해 원문 편집을 우선한다.
- Jenkins 서버 린터를 비목표에서 제외했다. 새 플러그인 없이 `nvim-lint`를 재사용하고
  시작 시 비용이 없어 전환 기준에 걸리지 않는다.

### Deprecated

- 없음

### Removed

- 없음

### Fixed

- 없음

### Security

- Jenkins API 토큰을 curl `--variable` / `--expand-user`로 자식 프로세스 환경에서만
  읽는다. 명령줄 인자에 담기지 않으므로 `ps`에 노출되지 않는다.

[Unreleased]: https://github.com/jisung9870/nvim-min/commits/nvim-min
