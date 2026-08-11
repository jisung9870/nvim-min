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

- `ansiblels`(Ansible)와 `taplo`(TOML) LSP.
- `hadolint`(Dockerfile)와 `sqlfluff`(SQL) 린트. SQL 방언 기본값은 `ansi`이고
  `vim.g.sql_dialect`로 바꾼다.
- CSV, TSV, XML, INI, properties, Helm, Go 템플릿, `go.work` treesitter 파서.
  `.env`는 같은 이름의 파서가 없어 `properties`를 연결했다.
- `roles/*/{handlers,vars,defaults,meta}`와 Ansible 표식이 있는 그 외 YAML의
  `yaml.ansible` 감지.
- Helm 차트 `templates/` 아래 `*.tpl` 감지.

### Changed

- Markdown 내부 렌더링에서 HTML과 LaTeX 변환을 비활성화해 원문 편집을 우선한다.
- `tflint`, `hadolint`, `sqlfluff`, `ansible-lint`를 `:LspInstallAll` 대상에 넣었다.
  `tflint`는 설정만 있고 설치되지 않아 지금까지 아무 진단도 내지 않았다.
- Ansible 스키마를 `ansible-lint` 배포본으로 교체했다.
- `yaml.ansible`에서 `yamllint`를 뺐다. `ansiblels`가 실행하는 `ansible-lint`가
  yamllint 규칙을 포함하므로 같은 진단이 두 번 떴을 것이다.
- 파일 타입 패턴에 우선순위를 명시했다. Neovim은 우선순위 0 이하 패턴을 확장자
  조회 뒤에 평가하므로 기본값으로는 `yml` 확장자 규칙이 먼저 이긴다.

### Deprecated

- 없음

### Removed

- 없음

### Fixed

- 플레이북을 열 때마다 뜨던 `Unable to load schema from
  'https://json.schemastore.org/ansible-playbook.json': No content.` 진단.
  해당 URL은 301 뒤 404이고 yamlls가 리다이렉트를 따라가지 않는다.
- Helm 차트의 `_helpers.tpl`이 `smarty`로 잡히던 문제.

### Security

- 없음

[Unreleased]: https://github.com/jisung9870/nvim-min/commits/nvim-min
