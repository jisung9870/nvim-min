# nvim-min

`vim.pack` 기반 Neovim 설정. LazyVim을 대체한다.

```
NVIM_APPNAME=nvim-min nvim
```

기존 LazyVim(`~/.config/nvim`)은 그대로 남아 있고 서로 간섭하지 않는다.
플러그인/파서/mason 설치물도 `~/.local/share/nvim-min/`에 따로 들어간다.

설치부터 구조, 기능 구성, 전체 키맵, 운영·복구, 릴리스 절차까지는
[상세 문서](docs/README.md)에서 확인할 수 있다. 사용자 영향 변경은
[Changelog](CHANGELOG.md)에 기록한다.

## 왜 vim.pack인가

lazy.nvim이 기능은 전부 앞선다 (lazy-loading, `:Lazy` UI, 의존성 자동 해결).
vim.pack을 고른 이유는 기능이 아니라 **이해 가능성**이다. API가 이게 전부다.

| | |
|---|---|
| `vim.pack.add(specs, opts)` | 설치 + `:packadd` |
| `vim.pack.update(names)` | 업데이트 (확인 버퍼에서 `:w` 확정 / `:q` 취소) |
| `vim.pack.del(names)` | 디스크에서 삭제 |
| `vim.pack.get()` | 설치 목록 |

spec 필드도 4개다: `src`, `name`, `version`, `data`.

**lazy.nvim으로 되돌릴 기준** — 셋 중 하나라도 걸리면 옮긴다. 비용은 `lua/plugins.lua` 한 파일.

- `vim.pack.add()` 목록이 30줄을 넘을 때
- 시작이 150ms를 넘을 때
- nvim-dap + neotest급 스택이 필요해질 때

현재: 플러그인 18개 (같은 머신·같은 파일에서 기존 17개 구성은 137ms, LazyVim은 273–413ms).

## 구조

로딩 순서는 `init.lua`에 고정되어 있고, 이유가 있다.

```
init.lua              leader 설정 → 아래 순서대로 require
lua/
  options.lua         vim 옵션. 플러그인이 읽기 전에 확정해야 함
  plugins.lua         vim.pack.add() — 이후부터 require 가능
  icons.lua           Nerd Font 글리프 (\u{} 이스케이프로 고정)
  theme.lua           catppuccin + 하이라이트. 팔레트를 M.colors로 노출
  statusline.lua      직접 작성. theme의 팔레트를 씀
  treesitter.lua      파서 설치 + FileType에서 하이라이트/폴드/들여쓰기
  lsp.lua             vim.lsp.config / vim.lsp.enable + mason
  completion.lua      blink.cmp
  editing.lua         포맷 / 린트 / 괄호 / surround / 한영전환 / which-key
  markdown.lua        Markdown 내부 렌더링 + 체크박스·콜아웃 완성
  finder.lua          snacks picker·explorer + 검색 키맵
  git.lua             gitsigns + diffview
  terminal.lua        toggleterm + tmux navigator
  keymaps.lua         플러그인과 무관한 키맵
  autocmds.lua        autocmd + filetype 감지
  local.lua           머신별 오버라이드 (git 추적 안 함, 없어도 됨)
nvim-pack-lock.json   플러그인 리비전 잠금 — git으로 추적한다
```

`theme.lua`와 `statusline.lua`만 서로 의존하고, 나머지 모듈은 독립적이다.
하나를 지워도 다른 게 깨지지 않는다.

## 플러그인 18개

| 플러그인 | 역할 |
|---|---|
| catppuccin/nvim | 테마 (mocha) |
| nvim-treesitter (`main`) | 파서 설치. 하이라이트는 nvim 내장이 처리 |
| render-markdown.nvim | 제목·목록·체크박스·표·코드 블록을 Neovim 안에서 렌더링 |
| nvim-lspconfig | 서버 기본값(`lsp/*.lua`) 제공. 옛 `setup{}` API는 안 씀 |
| mason.nvim | LSP/린터/포매터 바이너리 설치 |
| blink.cmp | 자동완성 (릴리스 태그 = 미리 빌드된 Rust 바이너리) |
| conform.nvim | 포맷 |
| nvim-lint | LSP가 못 주는 진단만 (yamllint / actionlint / tflint) |
| snacks.nvim | picker, explorer, indent, notifier, input, bigfile |
| which-key.nvim | 키맵 발견성 |
| gitsigns.nvim | hunk 단위 git |
| diffview.nvim | 커밋/히스토리 diff |
| toggleterm.nvim | 터미널 |
| vim-tmux-navigator | nvim 창 ↔ tmux 패널 |
| mini.icons / mini.pairs / mini.surround | 아이콘 / 괄호 짝 / surround |
| im-select.nvim | 한영 자동 전환 (macOS, `macism` 필요) |

**플러그인 없이 쓰는 것** — nvim 내장으로 충분해서 뺐다.

- 주석 토글 → 내장 `gc` (0.10+)
- 폴딩 → `vim.treesitter.foldexpr()` (ufo 불필요)
- statusline → 직접 작성 (lualine 불필요)
- LSP 배선 → `vim.lsp.enable()` (0.11+)

## LSP

서버 목록은 실측 작업 스택 기준이다 (YAML > Jenkinsfile > Python > Terraform > SQL > Go).

`lua_ls` `yamlls` `jsonls` `terraformls` `pyright` `ruff` `gopls` `bashls` `marksman`

Markdown은 `marksman`이 문서 심볼, 링크 이동, 참조, 자동완성을 제공한다.

Jenkinsfile은 **treesitter 하이라이트만** 된다. Groovy LSP는 JDK가 필요한데
설치되어 있지 않다. Jenkins 서버 린터 연동은 아직 옮기지 않았다 (아래 "안 옮긴 것" 참고).

## 키맵

`<leader>` = `Space`. 전체 목록은 `<leader>sk`, 그룹 힌트는 leader를 누르면 뜬다.

### 이동·편집

| 키 | 동작 |
|---|---|
| `jk` | insert 모드 탈출 |
| `H` / `L` | 이전 / 다음 버퍼 |
| `<C-h/j/k/l>` | nvim 창 ↔ tmux 패널 이동 |
| `<A-j>` / `<A-k>` | 줄 이동 (visual도 됨) |
| `<` / `>` (visual) | 들여쓰기, 선택 유지 |
| `p` (visual) | 붙여넣기, 레지스터 안 덮어씀 |
| `sa` / `sd` / `sr` | surround 추가 / 삭제 / 교체 |
| `<C-s>` | 저장 |
| `<Esc>` | 검색 하이라이트 지우기 |

### 찾기 (`<leader>f`, `<leader>s`)

| 키 | 동작 |
|---|---|
| `<leader><space>` | 스마트 파일 찾기 |
| `<leader>ff` / `fr` / `fb` | 파일 / 최근 / 버퍼 |
| `<leader>fc` | 설정 파일 |
| `<leader>fp` | 프로젝트 |
| `<leader>e` | 파일 탐색기 |
| `<leader>sg` / `sw` | grep / 커서 아래 단어 grep |
| `<leader>sb` / `sk` / `sh` | 버퍼 내 검색 / 키맵 / 도움말 |
| `<leader>sr` | 마지막 picker 다시 열기 |

탐색기 안에서 `-` 가로 분할, `|` 세로 분할, `M` 최대화.
picker/grep은 `node_modules` `.terraform` `.terragrunt-cache` `vendor` `__pycache__` `.venv`를 제외한다.

### 코드 (`<leader>c`)

| 키 | 동작 |
|---|---|
| `gd` / `gr` / `gI` / `gy` | 정의 / 참조 / 구현 / 타입 정의 |
| `K` | hover |
| `<leader>cr` / `ca` | 이름 바꾸기 / code action |
| `<leader>cs` | 문서 심볼 |
| `<leader>cf` | 포맷 |
| `<leader>cd` | 현재 줄 진단 |
| `]d` `[d` / `]e` `[e` | 다음·이전 진단 / 에러 |
| `<leader>xx` / `xX` | 버퍼 / 워크스페이스 진단 목록 |

### Git (`<leader>g`)

| 키 | 동작 |
|---|---|
| `<leader>gg` | gitui (없으면 lazygit) |
| `]h` / `[h` | 다음 / 이전 hunk |
| `<leader>gs` / `gr` | hunk stage / reset (visual 선택 범위도 됨) |
| `<leader>gp` / `gb` | hunk 미리보기 / blame 토글 |
| `<leader>gd` / `gh` / `gH` | diffview 열기 / 파일 히스토리 / 브랜치 히스토리 |
| `<leader>gc` / `gt` | 커밋 로그 / status |
| `vih` `dih` | hunk 텍스트 오브젝트 |

### 터미널 (`<leader>t`)

| 키 | 동작 |
|---|---|
| `<C-\>` | 플로팅 터미널 토글 |
| `<leader>th` / `tv` / `tf` | 가로 / 세로 / 플로팅 |
| `<leader>tp` | tmux 세션 전환기 (`bb tm`) |

`<Esc>`로 터미널 모드를 빠져나오는 건 toggleterm 버퍼에만 걸려 있다.
gitui나 Claude Code처럼 ESC를 직접 받아야 하는 TUI는 영향받지 않는다.

### 토글 (`<leader>u`)

`uf` 자동포맷(전역) · `uF` 자동포맷(버퍼) · `uw` wrap · `ul` 줄번호 · `ud` 진단 · `uh` inlay hint · `um` Markdown 렌더링

## 유지보수

| 명령 | 동작 |
|---|---|
| `:PackUpdate` | 플러그인 업데이트. 확인 버퍼에서 `:w` 확정, `:q` 취소 |
| `:PackStatus` | 설치 목록 (네트워크 없이). `[[` `]]`로 이동, `gO`로 목차 |
| `:PackClean` | `plugins.lua`에서 빠진 플러그인 삭제 |
| `:TSUpdateAll` / `:TSSync` | 파서 업데이트 / 목록 전부 동기 설치 |
| `:LspInstallAll` | 이 설정이 쓰는 LSP·린터·포매터 전부 설치 |
| `:Mason` | mason UI |
| `:FormatToggle[!]` | 자동 포맷 토글 (`!`는 현재 버퍼만) |

**업데이트가 뭔가 깨뜨렸을 때**

```sh
git checkout HEAD -- nvim-pack-lock.json   # 잠금 파일을 이전 리비전으로
```

되돌린 뒤 nvim에서 `:restart`, 그리고
`:lua vim.pack.update(nil, { offline = true, target = 'lockfile' })` → `:w`.

**새 머신에서**

```sh
git clone <repo> ~/.config/nvim-min       # 또는 심링크
NVIM_APPNAME=nvim-min nvim                 # lockfile 리비전 그대로 설치됨
:TSSync
:LspInstallAll
```

## 필요한 외부 도구

| 도구 | 용도 | 없으면 |
|---|---|---|
| `git` | vim.pack 자체 | 동작 안 함 |
| `tree-sitter` CLI | 파서 컴파일 (`brew install tree-sitter-cli`) | 파서 설치 실패 |
| C 컴파일러 | 파서 컴파일 | 파서 설치 실패 |
| Nerd Font | 아이콘 | 네모칸으로 보임 |
| `rg`, `fd` | picker/grep | picker가 느려짐 |
| `macism` | 한영 자동 전환 (`brew install macism`) | 조용히 비활성화 |
| `alloy` | Grafana Alloy 포맷 | 조용히 비활성화 |
| `gitui` 또는 `lazygit` | `<leader>gg` | 명령 못 찾음 |
| `bb` | `<leader>tp` tmux 세션 전환 | 명령 못 찾음 |

## 아직 안 옮긴 것

LazyVim 쪽에 있고 여기 없는 것들. 필요해지면 그때 옮긴다.

- **Jenkins 서버 린터** (`lua/jenkins.lua`) — Jenkinsfile이 2위 작업량인데 지금은 하이라이트만 됨
- **schema-companion** — K8s YAML 스키마를 파일 내용(`kind`/`apiVersion`)으로 자동 감지.
  지금은 `lsp.lua`에서 경로 규칙(`k8s/**`, `manifests/**`)으로만 붙인다
- **workbench 모듈** (projects / worktrees / agents / binbox, 451줄) — `<leader>fp`는
  snacks 기본 project picker로 대체해둠
- **snacks explorer 커스텀 액션** — 파일 복제(`C`), 크기·수정시각 표시(`T`)
- **octo / gitlab / kubectl / csvview / gitgraph**
- **DAP, neotest** — 이걸 넣게 되면 lazy.nvim 전환 기준에 걸린다
- **AI 플러그인** (claudecode, copilot)

## 다음 성능 레버

137ms 중 `init.lua` 소싱이 78ms, 나머지는 nvim 코어와 rtp 플러그인이다.
더 줄여야 하면 `git`·`terminal`·`editing`을 `UIEnter` 뒤로 미루면 약 25ms가 빠진다.
지금은 안 한다 — 체감 차이가 없고, 지연 로딩 배선이 이 설정의 목적(전부 파악 가능)과 상충한다.
