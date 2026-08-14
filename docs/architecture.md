# 구조와 설계

## 핵심 결정

nvim-min은 기능 수보다 이해 가능성과 재현성을 우선한다. 모든 플러그인을 `vim.pack`으로 명시해
시작 시 로드하고, `nvim-pack-lock.json`으로 정확한 리비전을 고정한다. 기본 Neovim 설정
경로에 설치해 별도 환경변수 없이 실행한다.

## 설계 목표

- 한 파일이 한 기능 영역을 소유하도록 한다.
- 로딩 순서와 모듈 간 의존성을 작게 유지한다.
- Neovim 내장 기능으로 충분한 영역은 별도 플러그인을 추가하지 않는다.
- 새 머신에서 잠금 파일 기준으로 같은 플러그인 리비전을 복원한다.
- 머신별 차이는 추적하지 않는 `lua/local.lua`로 격리한다.

## 비목표

- 대규모 플러그인 배포판과 같은 기능 범위
- 모든 플러그인의 지연 로딩
- DAP·neotest의 기본 포함
- 내용 기반 Kubernetes 스키마 자동 감지

Jenkins 서버 린터는 이전까지 비목표였으나 구현으로 전환했다. 판단 근거는 이 문서의
전환 기준이다. 새 플러그인이 없고(`nvim-lint` 재사용) 시작 시 등록하는 것은 autocmd
하나뿐이라 `vim.pack.add()` 목록과 시작 시간에 영향이 없다. 반대로 Jenkinsfile은
작업량 2위인데 Groovy LSP를 쓸 수 없어 진단 경로가 아예 없었다.

## 시작 흐름

```text
nvim
  -> init.lua: leader 설정
  -> options.lua: 플러그인이 읽을 전역 옵션 확정
  -> plugins.lua: 설치, 잠금 리비전 확인, runtimepath 등록
  -> theme.lua -> statusline.lua
  -> treesitter/lsp/completion/editing/markdown/finder/git/terminal/ai/workspace
  -> keymaps.lua -> autocmds.lua
  -> local.lua: 선택적 머신 오버라이드
```

`theme.lua`가 색을 노출하고 `statusline.lua`가 이를 사용하는 의존성은 의도적이다.
다만 노출 대상은 팔레트가 아니라 **시맨틱 토큰**(`M.tokens`)이다. `statusline.lua`는
`mauve`, `peach`, `surface0` 같은 Catppuccin 고유 이름을 알지 못하고 `accent`,
`warn`, `bar` 같은 의미 이름만 사용한다. 팔레트를 아는 곳은 `theme.lua`의
`M.rebuild()` 매핑 한 곳뿐이므로 테마 교체 비용이 그 매핑으로 한정된다.

플레이버는 `vim.o.background`에서 파생된다. `background`가 바뀌면 Neovim이 컬러스킴을
다시 읽고(`:h 'background'`), `ColorScheme`에서 `M.rebuild()`가 실행되어 상태줄
하이라이트가 같은 플레이버(latte 또는 mocha)로 따라간다.

그 외 기능 모듈은 서로의 내부 구현을 직접 참조하지 않는 것을 원칙으로 한다.

## 파일별 책임

| 경로 | 책임 | 변경 시 확인 |
|---|---|---|
| `init.lua` | 로딩 순서, leader | 시작 오류와 순서 의존성 |
| `lua/options.lua` | 전역 편집·UI 옵션 | 기존 파일의 들여쓰기·표시 변화 |
| `lua/plugins.lua` | 플러그인 선언과 관리 명령 | 잠금 파일, 시작 시간, 플러그인 수 |
| `lua/icons.lua` | Nerd Font·상태 아이콘 | 폰트가 없는 환경의 표시 |
| `lua/theme.lua` | Catppuccin, 시맨틱 토큰, 진단 UI | light/dark 양쪽의 상태줄 색상과 float 가독성 |
| `lua/tabline.lua` | 상단 파일 버퍼 목록과 클릭 전환 | 활성·수정 버퍼 표시와 긴 목록 |
| `lua/statusline.lua` | 모드·Git·진단·LSP 상태 | 좁은 창과 비Git 버퍼 |
| `lua/treesitter.lua` | 파서 설치·하이라이트·폴드·들여쓰기 | 신규 언어 파서와 쿼리 존재 여부 |
| `lua/lsp.lua` | Mason 패키지와 LSP 설정 | 서버 이름, 실행 파일, root 탐지 |
| `lua/completion.lua` | blink.cmp | insert·cmdline 키 충돌 |
| `lua/editing.lua` | 포맷·린트(Jenkins 검증 포함)·pairs·surround·입력기 | 저장 지연, 진단 중복, 자격증명 없는 환경 |
| `lua/markdown.lua` | Markdown 렌더링 | insert 모드 원문 편집 |
| `lua/finder.lua` | picker·explorer·진단 목록 | 제외 경로와 대규모 저장소 성능 |
| `lua/git.lua` | hunk·diff·Git UI | Git 저장소 밖의 동작 |
| `lua/terminal.lua` | toggleterm·tmux 이동 | TUI의 Escape 키와 tmux 충돌 |
| `lua/ai.lua` | Sidekick CLI 패널·문맥 전달 | Claude/Codex 감지, 패널 키, tmux 유무 |
| `lua/workspace.lua` | cwd별 편집기 세션과 스크래치 메모 | 명시적 파일 시작, 자동 저장, cwd 격리 |
| `lua/keymaps.lua` | 공통 키맵 | 플러그인/Neovim 기본 키 충돌 |
| `lua/autocmds.lua` | 자동 명령과 파일 타입 | 이벤트 중복과 버퍼 로컬 상태 |
| `lua/local.lua` | 로컬 전용 오버라이드 | Git에 포함되지 않는지 확인 |

## 플러그인 수명 주기

```text
plugins.lua 선언
  -> vim.pack.add()
  -> nvim-pack-lock.json 리비전 사용
  -> runtimepath 등록
  -> 각 기능 모듈의 require/setup
```

플러그인 선언을 제거해도 디스크 데이터가 즉시 삭제되지는 않는다. `:PackClean`이 비활성
플러그인을 계산하고 사용자 선택 뒤 삭제한다. 업데이트와 정리 절차는
[운영과 유지보수](operations.md)를 따른다.

## 내장 기능 우선 경계

| 기능 | 구현 |
|---|---|
| 주석 토글 | Neovim 내장 `gc` |
| 폴딩 | `vim.treesitter.foldexpr()` |
| LSP 연결 | `vim.lsp.config()`와 `vim.lsp.enable()` |
| 상태줄 | 프로젝트 Lua 코드 |
| 플러그인 관리 | `vim.pack` |

다음 조건 중 하나가 실제로 발생하면 lazy.nvim 전환을 재검토한다.

- `vim.pack.add()` 목록이 30줄을 초과한다.
- 동일한 측정 환경에서 시작 시간이 150ms를 지속적으로 초과한다.
- nvim-dap와 neotest 수준의 스택이 기본 요구사항이 된다.

수치는 현재 설계의 재검토 기준이지 모든 머신에 대한 성능 보장이 아니다. 측정할 때는 같은
Neovim 버전, 잠금 파일, 머신, 시작 파일을 사용하고 여러 번 측정한다.
