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

- `<leader>ub` light/dark 배경 토글
- `theme.lua`의 시맨틱 토큰 레이어(`M.tokens`, `M.rebuild()`). 색을 쓰는 모듈은
  Catppuccin 고유 색 이름 대신 의미 이름만 사용한다.

### Changed

- Markdown 내부 렌더링에서 HTML과 LaTeX 변환을 비활성화해 원문 편집을 우선한다.
- `statusline.lua`가 Catppuccin 팔레트 대신 테마 토큰을 사용한다. 테마 교체 시
  변경 지점이 `theme.lua`의 매핑 한 곳으로 한정된다.

### Deprecated

- 없음

### Removed

- `theme.lua`의 `M.colors`. `M.tokens`로 대체됐다.

### Fixed

- `background=light`에서 테마가 Latte로 바뀌지 않던 문제. `flavour = "mocha"`가
  `background` 매핑을 무력화하고 있었다.
- 위 상황에서 상태줄만 Mocha 색으로 남던 문제. 팔레트를 `get_palette("mocha")`로
  고정해 읽고 있었다.
- `Comment`와 `CursorLine`이 Mocha 전용 하드코딩 색이라 Latte에서 대비가 무너지던 문제.

### Security

- 없음

[Unreleased]: https://github.com/jisung9870/nvim-min/commits/nvim-min
