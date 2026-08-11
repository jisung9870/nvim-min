# 기능과 언어 구성

## 구성 요약

현재 잠금 파일에는 플러그인 18개가 기록되어 있다. 구성은 DevOps 작업의 YAML, Jenkinsfile,
Python, Terraform, SQL, Go 사용을 우선하며 Markdown 편집과 탐색·Git·터미널 기능을 포함한다.

## 플러그인

| 영역 | 플러그인 | 역할 |
|---|---|---|
| UI | `catppuccin/nvim` | Mocha 테마와 하이라이트 |
| 구문 | `nvim-treesitter` (`main`) | 파서 설치; 실행은 Neovim 내장 API 사용 |
| Markdown | `render-markdown.nvim` | 제목·목록·표·코드 블록 내부 렌더링 |
| LSP | `nvim-lspconfig`, `mason.nvim` | 서버 기본값과 실행 파일 설치 |
| 완성 | `blink.cmp` 1.x | LSP·경로·snippet·buffer 완성 |
| 품질 | `conform.nvim`, `nvim-lint` | 포맷과 비LSP 진단 |
| 탐색 | `snacks.nvim` | picker, explorer, 알림, 큰 파일 처리 |
| 발견성 | `which-key.nvim` | leader 그룹 표시 |
| Git | `gitsigns.nvim`, `diffview.nvim` | hunk와 diff/히스토리 |
| 터미널 | `toggleterm.nvim`, `vim-tmux-navigator` | 터미널과 tmux 이동 |
| 편집 | `mini.icons`, `mini.pairs`, `mini.surround` | 아이콘·괄호·surround |
| 입력기 | `im-select.nvim` | macOS 한/영 자동 전환 |

플러그인을 추가할 때는 `lua/plugins.lua`와 잠금 파일을 함께 변경하고, 해당 기능의 설정은 기존
책임에 맞는 모듈에 둔다. 단일 기능 때문에 새 공통 계층을 만들지 않는다.

Markdown 내부 렌더링은 제목, 목록, 체크박스, 표와 코드 블록을 대상으로 한다. HTML과 LaTeX
변환은 비활성화해 해당 구문을 원문 그대로 확인하고 편집할 수 있게 한다.

## LSP와 Mason

### 활성 LSP

| 서버 | 주 대상 | 비고 |
|---|---|---|
| `lua_ls` | Lua | Neovim 전역 `vim`, inlay hint |
| `yamlls` | YAML, Ansible, GitHub Actions, Helm | 경로 기반 스키마 연결 |
| `jsonls` | JSON | lspconfig 기본 설정 |
| `terraformls` | Terraform | Terraform 파일 타입 |
| `pyright` | Python 타입 | unused 진단은 Ruff와 중복되지 않게 비활성화; 가상환경 자동 감지 |
| `ruff` | Python 진단·수정 | Pyright와 역할 분리 |
| `gopls` | Go | gofumpt, staticcheck, hint 활성화; 빌드 태그 설정 가능 |
| `bashls` | shell, bash | shellcheck 연동은 서버 측 동작 사용 |
| `marksman` | Markdown | 문서 심볼, 링크, 참조, 완성 |

`:LspInstallAll`은 위 서버와 `yamllint`, `actionlint`, `shellcheck`, `shfmt`, `stylua`,
`prettier`를 설치한다. `tflint`, `terraform`, `goimports`, `gofumpt`, `alloy` 등은 Mason 목록에
없거나 별도 도구이므로 사용하는 언어에 맞게 시스템에 설치해야 한다.

### Python 가상환경

Pyright는 인터프리터 경로를 받지 못하면 `PATH`의 Python을 사용한다. 프로젝트 가상환경에만
설치된 패키지는 이 경우 전부 미해결 import가 되며 해당 패키지의 타입 추론, 자동완성, 정의
이동이 함께 동작하지 않는다. 클라이언트가 붙을 때마다 다음 순서로 인터프리터를 찾는다.

1. `VIRTUAL_ENV` 또는 `CONDA_PREFIX` 환경 변수
2. 편집 중인 파일에서 상위로 올라가며 처음 만나는 `.venv` 또는 `venv`

탐색 기준은 프로젝트 루트가 아니라 편집 중인 파일이다. 하나의 저장소 안에서 디렉터리마다
가상환경이 다른 구성도 각 파일에 맞는 인터프리터를 사용한다. 둘 다 없으면 경로를 넘기지
않고 Pyright 기본 동작을 유지한다.

설정은 클라이언트별 복사본에 적용하므로 한 프로젝트의 인터프리터가 다른 프로젝트로
전파되지 않는다. 현재 사용 중인 인터프리터와 그 출처는 `:PythonEnv`로 확인한다.

### Go 빌드 태그

`//go:build` 제약이 붙은 파일은 기본 빌드 대상이 아니므로 gopls가 해당 파일을 패키지에서
제외하고 `No packages found for open file`을 보고한다. 태그 이름은 저장소마다 다르므로
설정 파일에 고정하지 않는다.

```lua
-- lua/local.lua
vim.g.go_build_tags = { "integration", "e2e" }
```

문자열(`"integration,e2e"`)도 허용한다. 세션 중에는 `:GoBuildTags integration,e2e`로 지정하고
인자 없이 실행하면 해제한다. 두 방법 모두 gopls를 다시 시작한다.

### YAML 스키마

Kubernetes 스키마는 다음 경로 패턴에만 연결된다.

- `k8s/**/*.yaml`
- `manifests/**/*.yaml`
- `*.k8s.yaml`

기본 스키마 버전은 코드에 고정되어 있고 `lua/local.lua`의
`vim.g.k8s_schema_version`으로 덮어쓸 수 있다. 파일 내용의 `kind`나 `apiVersion`만으로
스키마를 자동 선택하지는 않는다.

## 포맷

| 파일 타입 | 포매터 | 동작 |
|---|---|---|
| Go | `goimports`, `gofumpt` | 순서대로 실행 |
| Terraform | `terraform_fmt` | `terraform`, `tf`, `terraform-vars` |
| HCL/Alloy | `alloy fmt` 후 공백 변환 | `alloy`가 있을 때만 |
| shell | `shfmt` | 2칸 들여쓰기 |
| Lua | `stylua` | 저장소의 `stylua.toml` 사용 |
| Python | Ruff import 정리, Ruff format | 순서대로 실행 |
| JSON/YAML | `prettier` | 2칸, semicolon 없음, single quote 옵션 |
| Markdown | 없음 | 의도적인 공백 보존 |
| 기타 | trailing whitespace 제거 | 기본 처리 |

저장 시 포맷 제한 시간은 3초다. 256KiB를 초과하는 파일, 전역 또는 버퍼 자동 포맷을 끈
경우에는 저장 시 포맷하지 않는다. 수동 포맷은 `<leader>cf`다.

## 린트

| 파일 타입 | 린터 |
|---|---|
| YAML, Ansible YAML | `yamllint` |
| GitHub Actions YAML | `actionlint` |
| Terraform 계열 | `tflint` |

린트는 `BufWritePost`, `BufReadPost`, `InsertLeave`에서 실행된다. LSP와 같은 진단을 중복 제공하는
린터는 추가하지 않는 것이 원칙이다.

## Treesitter 파서

추가 설치 대상은 Bash, diff, Dockerfile, Git commit/rebase, Go, Groovy, HCL, JSON, Make,
Nginx, Python, regex, SQL, Terraform, TOML, YAML이다. C, Lua, Markdown, Vim, Vimdoc, query는
Neovim 0.12 내장 파서를 전제로 한다.

새 언어를 추가할 때는 다음을 함께 확인한다.

1. `lua/treesitter.lua`의 parser 목록
2. `lua/lsp.lua`의 서버와 Mason 패키지
3. `lua/editing.lua`의 formatter와 linter
4. 필요한 `vim.filetype.add()` 규칙
5. `:TSSync`, `:LspInstallAll`, 실제 샘플 파일의 동작

## 파일 타입 규칙

| 패턴 | 파일 타입 |
|---|---|
| `*.alloy` | `hcl` |
| `*.tf` | `terraform` |
| `*.tfvars` | `terraform-vars` |
| `Jenkinsfile*`, `*.jenkinsfile` | `groovy` |
| GitHub workflow YAML | `yaml.ghaction` |
| Ansible playbook/role task YAML | `yaml.ansible` |
| Nginx 경로의 `*.conf` | `nginx` |
| templates 경로의 YAML | `helm` |

## 알려진 범위 밖 기능

- Jenkins 서버 린터
- 파일 내용 기반 Kubernetes 스키마 선택
- workbench 프로젝트·worktree·agent 통합
- octo, GitLab, kubectl, csvview, gitgraph
- DAP, neotest, AI 플러그인

이 목록은 결함이 아니라 현재 비목표다. 요구가 생기면 [구조와 설계](architecture.md)의 전환
기준과 시작 시간 영향을 먼저 평가한다.
