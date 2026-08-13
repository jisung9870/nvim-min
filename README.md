# nvim-min

`vim.pack` 기반 Neovim 설정. 기본 `nvim` 설정으로 바로 사용할 수 있다.

설치부터 구조, 기능 구성, 전체 키맵, 운영·복구, 릴리스 절차까지는
[상세 문서](docs/README.md)에서 확인할 수 있다. 사용자 영향 변경은
[Changelog](CHANGELOG.md)에 기록한다.

## 사전 설치: Neovim 0.12+

이 설정은 Neovim 0.12 이상이 필요하다. 아래에서 운영체제에 맞는 방법으로 Neovim을 먼저
설치하고, 마지막 명령에서 `NVIM v0.12` 이상이 출력되는지 확인한다. 다른 설치 방법은
[Neovim 공식 설치 문서](https://neovim.io/doc/install/)에서 확인할 수 있다.

### macOS

[Homebrew](https://brew.sh/)가 설치되어 있다는 전제에서 다음 명령을 실행한다.

```sh
brew update
brew install neovim
nvim --version | head -n 1
```

`xcode-select --install`에서 이미 설치되었다는 메시지가 나오면 그대로 다음 명령을 진행한다.

### WSL (Ubuntu)

Ubuntu 기본 저장소의 Neovim이 0.12보다 낮을 수 있으므로 공식 최신 Linux tarball을 설치한다.
다음 명령은 일반적인 x86_64 WSL 환경을 기준으로 한다.

```sh
sudo apt-get update
sudo apt-get install -y curl ca-certificates git build-essential

curl -fLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
hash -r
nvim --version | head -n 1
```

`/usr/local/bin/nvim`이 이미 있다는 오류가 나오면 기존 Neovim 설치를 먼저 확인한다. 기존
실행 파일을 자동으로 덮어쓰지는 않는다.

## nvim-min 설치

Neovim 준비가 끝났으면 설정을 설치한다.

```sh
curl -fsSL https://raw.githubusercontent.com/jisung9870/nvim-min/main/install.sh | sh
nvim
```

설치 스크립트는 `~/.config/nvim`이 이미 있으면 덮어쓰지 않고 중단한다. Git과 Neovim 0.12
이상을 확인하고 설정을 설치한 뒤, 고정된 플러그인과 사용 가능한 경우 Treesitter 파서까지
준비한다. 자세한 요구 사항과 수동 설치법은 [빠른 시작](docs/getting-started.md)을 참고한다.

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
  theme.lua           catppuccin + 하이라이트. 색은 시맨틱 토큰(M.tokens)으로만 나감
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

의존하는 대상은 **팔레트가 아니라 토큰**이다. `statusline.lua`에는 catppuccin
고유 색 이름(`mauve`, `peach`, `surface0` …)이 한 번도 나오지 않는다.
`theme.lua`의 `M.rebuild()` 매핑 한 곳만 팔레트를 알기 때문에, 테마를 갈아끼우는
비용은 그 매핑 하나다.

| | |
|---|---|
| `M.tokens` | 의미 이름 → 색. 항상 같은 테이블이라 캐싱해도 된다 |
| `M.rebuild()` | 현재 `background`에 맞춰 토큰을 다시 채우고 `M.tokens`를 반환 |

토큰은 `bg` `bar` `raised` `border` / `fg` `fg_muted` `fg_dim` `fg_on_accent` /
`accent` `accent_alt` / `ok` `info` `warn` `err` `hint` `modified` /
`git_*` / `mode_*` 로 나뉜다.

## 플러그인 18개

| 플러그인 | 역할 |
|---|---|
| catppuccin/nvim | 테마. `background`에 따라 mocha(dark) / latte(light) |
| nvim-treesitter (`main`) | 파서 설치. 하이라이트는 nvim 내장이 처리 |
| render-markdown.nvim | 제목·목록·체크박스·표·코드 블록을 Neovim 안에서 렌더링 |
| nvim-lspconfig | 서버 기본값(`lsp/*.lua`) 제공. 옛 `setup{}` API는 안 씀 |
| mason.nvim | LSP/린터/포매터 바이너리 설치 |
| blink.cmp | 자동완성 (릴리스 태그 = 미리 빌드된 Rust 바이너리) |
| conform.nvim | 포맷 |
| nvim-lint | LSP가 못 주는 진단만 (yamllint / actionlint / tflint / hadolint / sqlfluff) |
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

`lua_ls` `yamlls` `ansiblels` `jsonls` `terraformls` `taplo` `pyright` `ruff` `gopls`
`bashls` `marksman`

Markdown은 `marksman`이 문서 심볼, 링크 이동, 참조, 자동완성을 제공한다.

### Python 가상환경

pyright에 인터프리터를 알려주지 않으면 PATH의 python을 쓴다. 그러면 프로젝트
가상환경에만 있는 패키지가 전부 `could not be resolved`가 되고, 그 패키지에 대한
타입·자동완성·정의 이동이 통째로 죽는다. 그래서 붙을 때마다 인터프리터를 찾는다.

1. `VIRTUAL_ENV` 또는 `CONDA_PREFIX` — 셸에서 이미 활성화했으면 그게 의도다
2. 편집 중인 파일에서 위로 올라가며 만나는 첫 `.venv` 또는 `venv`

루트가 아니라 **파일 기준으로 올라간다**. 서비스마다 venv가 따로인 저장소도 맞는다.
둘 다 없으면 아무것도 넘기지 않고 pyright 기본 동작에 맡긴다. 지금 어떤 인터프리터를
쓰는지는 `:PythonEnv`로 확인한다.

### Go 빌드 태그

`//go:build integration`이 붙은 파일은 기본 빌드에서 빠지므로 gopls가
`No packages found for open file`로 그 파일을 통째로 포기한다. 태그 이름은
저장소마다 다르니 설정에 박지 않는다.

```lua
-- lua/local.lua
vim.g.go_build_tags = { "integration", "e2e" }
```

그 자리에서 바꾸려면 `:GoBuildTags integration,e2e`. 인자 없이 `:GoBuildTags`면
해제된다. 둘 다 gopls를 다시 띄운다.

Jenkinsfile에는 Groovy LSP를 붙이지 않는다 (JDK가 필요하다). 대신 **Jenkins 서버가
직접 검증**한다 — 아래 참고.

### Jenkinsfile 검증

저장하면 `Jenkinsfile`, `Jenkinsfile.*`, `*.jenkinsfile`을 Jenkins의
`pipeline-model-converter/validate`로 올려 문법 오류를 진단으로 받는다.
수동 실행은 `:JenkinsLint`.

자격증명은 환경변수를 먼저 보고, 없으면 `vim.g`를 본다.

| 환경변수 | `lua/local.lua` | 값 |
|---|---|---|
| `JENKINS_URL` | `vim.g.jenkins_url` | `https://jenkins.example.com` |
| `JENKINS_USER` | `vim.g.jenkins_user` | 계정 이름 |
| `JENKINS_TOKEN` | `vim.g.jenkins_token` | Jenkins API 토큰 |

셋 중 하나라도 비면 **조용히 비활성화**된다 (`macism`, `alloy`와 같은 규칙).
셸에서 주입하려면 `bb sec exec jenkins -- nvim`.

토큰은 curl의 `--variable` / `--expand-user`로 환경에서 읽는다. 명령줄 인자로
넘기지 않으므로 같은 머신의 `ps`에 노출되지 않는다.

네트워크를 타므로 **저장할 때만** 돈다. `InsertLeave`에서는 돌지 않는다.
서버에 닿지 못하면 조용히 넘어가지 않고 1번 줄에 경고 진단 하나를 남긴다.

### Ansible

`yamlls`가 YAML 구조를, `ansiblels`가 모듈 이름·파라미터·문서를 담당한다.
`ansiblels`가 `ansible-lint`를 직접 호출하므로 `nvim-lint` 쪽에는 Ansible 린터를
넣지 않았다 — `ansible-lint`는 yamllint 규칙을 이미 포함해서 넣으면 같은 진단이
두 번 뜬다.

`yaml.ansible`로 승격되는 조건은 둘 중 하나다.

| 경로 | |
|---|---|
| `playbooks/**/*.yml` | |
| `roles/*/{tasks,handlers,vars,defaults,meta}/*.yml` | |
| **내용** | 앞 40줄에 `hosts:`, `become:`, `gather_facts:`, `ansible.*.` 중 하나 |

내용 규칙은 경로 규칙에 진 다음에만 적용된다. 저장소 루트의 `site.yml`처럼 경로로는
알 수 없는 플레이북을 잡기 위한 것이고, K8s 매니페스트·docker-compose·Helm 템플릿·
GitHub Actions는 표식이 없어 그대로 자기 타입으로 남는다.

Ansible 스키마는 schemastore가 아니라 **ansible-lint가 배포하는 것**을 쓴다.
`json.schemastore.org/ansible-playbook.json`은 301 뒤 404라서, yamlls가 리다이렉트를
따라가지 않아 플레이북을 열 때마다 `Unable to load schema ... No content` 진단이 떴다.

### 데이터 형식

| 형식 | 하이라이트 | LSP | 포맷 | 린트 |
|---|---|---|---|---|
| YAML | ✓ | yamlls | prettier | yamllint |
| JSON / JSONC | ✓ | jsonls | prettier | (LSP) |
| TOML | ✓ | taplo | taplo | (LSP) |
| HCL / Terraform | ✓ | terraformls | terraform_fmt | tflint |
| Dockerfile | ✓ | — | — | hadolint |
| SQL | ✓ | — | 의도적 없음 | sqlfluff |
| CSV / TSV | ✓ | — | — | — |
| XML | ✓ | — | — | — |
| INI · `.env` | ✓ | — | — | — |

`.env`는 filetype이 `env`인데 같은 이름의 파서가 없다. key=value로 문법이 같은
`properties` 파서를 붙였다.

SQL 포맷을 비워 둔 건 의도다. `sqlfluff fix`는 쿼리를 크게 다시 쓰므로 저장할 때마다
돌리기엔 위험하다. 방언 기본값은 `ansi`이고 `lua/local.lua`의 `vim.g.sql_dialect`로
바꾼다. 저장소에 `.sqlfluff`가 있으면 그쪽이 이긴다.

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

`uf` 자동포맷(전역) · `uF` 자동포맷(버퍼) · `uw` wrap · `ul` 줄번호 · `ud` 진단 · `uh` inlay hint · `um` Markdown 렌더링 · `ub` light/dark 배경

## 유지보수

| 명령 | 동작 |
|---|---|
| `:PackUpdate` | 플러그인 업데이트. 확인 버퍼에서 `:w` 확정, `:q` 취소 |
| `:PackStatus` | 설치 목록 (네트워크 없이). `[[` `]]`로 이동, `gO`로 목차 |
| `:PackClean` | `plugins.lua`에서 빠진 플러그인 삭제 |
| `:TSUpdateAll` / `:TSSync` | 파서 업데이트 / 목록 전부 동기 설치 |
| `:LspInstallAll` | 이 설정이 쓰는 LSP·린터·포매터 전부 설치 |
| `:PythonEnv` | pyright가 쓰는 Python 인터프리터와 그 출처 확인 |
| `:GoBuildTags [태그]` | gopls 빌드 태그 설정 후 재시작 (인자 없으면 해제) |
| `:Mason` | mason UI |
| `:FormatToggle[!]` | 자동 포맷 토글 (`!`는 현재 버퍼만) |
| `:JenkinsLint` | 현재 파일을 Jenkins 서버로 검증 |

**업데이트가 뭔가 깨뜨렸을 때**

```sh
git checkout HEAD -- nvim-pack-lock.json   # 잠금 파일을 이전 리비전으로
```

되돌린 뒤 nvim에서 `:restart`, 그리고
`:lua vim.pack.update(nil, { offline = true, target = 'lockfile' })` → `:w`.

**새 머신에서**

```sh
curl -fsSL https://raw.githubusercontent.com/jisung9870/nvim-min/main/install.sh | sh
nvim                                      # lockfile 리비전 그대로 설치됨
```

Neovim 안에서:

```vim
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
| `terraform` | `terraform_fmt` 포맷 | 포맷 안 됨 |
| `ansible` | `ansiblels`가 모듈을 해석할 때 씀 | Ansible 진단 없음 |
| `gitui` 또는 `lazygit` | `<leader>gg` | 명령 못 찾음 |
| `bb` | `<leader>tp` tmux 세션 전환 | 명령 못 찾음 |
| `curl` | Jenkinsfile 검증 (macOS 기본 포함, 8.3+) | 조용히 비활성화 |

## 아직 안 옮긴 것

LazyVim 쪽에 있고 여기 없는 것들. 필요해지면 그때 옮긴다.

- **schema-companion** — K8s YAML 스키마를 파일 내용(`kind`/`apiVersion`)으로 자동 감지.
  지금은 `lsp.lua`에서 경로 규칙(`k8s/**`, `manifests/**`)으로만 붙인다
- **snacks explorer 커스텀 액션** — 파일 복제(`C`), 크기·수정시각 표시(`T`)
- **octo / gitlab / kubectl / csvview / gitgraph**
- **DAP, neotest** — 이걸 넣게 되면 lazy.nvim 전환 기준에 걸린다
- **AI 플러그인** (claudecode, copilot)

**안 옮기는 것으로 결정된 것** — 위 목록과 달리 대기 상태가 아니다.

- **workbench 모듈** (projects / worktrees / agents / binbox, 451줄).
  binbox-cli `docs/decision-log.md`의 "LazyVim Workbench UI retired"에서
  **대체 없이 폐기**로 결정됐다. 에디터는 프로젝트 picker만 갖고, 수명주기
  (agents / worktrees / schedulers)는 Orca가 단독으로 갖는다.
  `<leader>fp`(snacks project picker)가 남은 전부다.

## 다음 성능 레버

137ms 중 `init.lua` 소싱이 78ms, 나머지는 nvim 코어와 rtp 플러그인이다.
더 줄여야 하면 `git`·`terminal`·`editing`을 `UIEnter` 뒤로 미루면 약 25ms가 빠진다.
지금은 안 한다 — 체감 차이가 없고, 지연 로딩 배선이 이 설정의 목적(전부 파악 가능)과 상충한다.
