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
| `ansiblels` | Ansible | 모듈·파라미터·문서; `ansible-lint`를 직접 호출 |
| `jsonls` | JSON | lspconfig 기본 설정 |
| `terraformls` | Terraform | Terraform 파일 타입 |
| `taplo` | TOML | 스키마 검증과 포맷 |
| `pyright` | Python 타입 | unused 진단은 Ruff와 중복되지 않게 비활성화 |
| `ruff` | Python 진단·수정 | Pyright와 역할 분리 |
| `gopls` | Go | gofumpt, staticcheck, hint 활성화 |
| `bashls` | shell, bash | shellcheck 연동은 서버 측 동작 사용 |
| `marksman` | Markdown | 문서 심볼, 링크, 참조, 완성 |

`:LspInstallAll`은 위 서버와 `yamllint`, `actionlint`, `ansible-lint`, `tflint`, `hadolint`,
`sqlfluff`, `shellcheck`, `shfmt`, `stylua`, `prettier`를 설치한다.

`terraform`, `ansible`, `goimports`, `gofumpt`, `alloy`는 Mason이 배포하지 않으므로 사용하는
언어에 맞게 시스템에 설치해야 한다.

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
| TOML | `taplo` | LSP와 같은 도구 |
| Python | Ruff import 정리, Ruff format | 순서대로 실행 |
| SQL | 없음 | 의도적 제외; `sqlfluff fix`는 쿼리를 크게 재작성한다 |
| JSON/YAML | `prettier` | 2칸, semicolon 없음, single quote 옵션 |
| Markdown | 없음 | 의도적인 공백 보존 |
| 기타 | trailing whitespace 제거 | 기본 처리 |

저장 시 포맷 제한 시간은 3초다. 256KiB를 초과하는 파일, 전역 또는 버퍼 자동 포맷을 끈
경우에는 저장 시 포맷하지 않는다. 수동 포맷은 `<leader>cf`다.

## 린트

| 파일 타입 | 린터 |
|---|---|
| YAML | `yamllint` |
| GitHub Actions YAML | `actionlint` |
| Terraform 계열 | `tflint` |
| Dockerfile | `hadolint` |
| SQL | `sqlfluff` |

린트는 `BufWritePost`, `BufReadPost`, `InsertLeave`에서 실행된다. LSP와 같은 진단을 중복 제공하는
린터는 추가하지 않는 것이 원칙이다.

Ansible YAML이 이 표에 없는 것은 이 원칙 때문이다. `ansiblels`가 `ansible-lint`를 직접
실행하고 `ansible-lint`는 yamllint 규칙을 포함하므로, `nvim-lint`에 다시 등록하면 동일한
진단이 두 번 표시된다.

`sqlfluff`는 방언 없이 실행되지 않는다. 저장소의 `.sqlfluff` 설정이 우선하며, 없을 때 사용할
기본값은 `ansi`다. `lua/local.lua`의 `vim.g.sql_dialect`로 변경한다.

## Treesitter 파서

추가 설치 대상은 Bash, CSV, diff, Dockerfile, Git commit/rebase, Go, go.mod, go.sum, go.work,
Go 템플릿, Groovy, HCL, Helm, INI, JSON, Make, Nginx, properties, Python, regex, SQL, Terraform,
TOML, TSV, XML, YAML이다. C, Lua, Markdown, Vim, Vimdoc, query는 Neovim 0.12 내장 파서를
전제로 한다.

`.env` 파일은 파일 타입이 `env`이지만 동일한 이름의 파서가 존재하지 않는다. 구문이 동일한
`properties` 파서를 `vim.treesitter.language.register`로 연결한다.

Helm 차트의 `templates/` 아래 YAML과 `.tpl` 파일은 `helm` 파서를 사용한다. 연결하지 않으면
`{{ }}` 구문이 YAML로 잘못 파싱된다.

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
| `playbooks/**/*.yml` | `yaml.ansible` |
| `roles/*/{tasks,handlers,vars,defaults,meta}/*.yml` | `yaml.ansible` |
| Ansible 표식이 있는 그 외 YAML | `yaml.ansible` |
| Nginx 경로의 `*.conf` | `nginx` |
| templates 경로의 YAML과 `*.tpl` | `helm` |

패턴에는 우선순위를 명시한다. Neovim은 패턴을 우선순위 내림차순으로 평가하되 우선순위가 0
이하인 패턴은 확장자 표를 조회한 뒤에 평가한다. 기본값을 사용하면 `yml` 확장자 규칙이 먼저
일치해 위 규칙에 도달하지 않는다. 경로 규칙은 10, 내용 기반 규칙은 1을 사용한다.

내용 기반 규칙은 앞 40줄에서 `hosts:`, `become:`, `gather_facts:`, `ansible.<컬렉션>.` 중
하나를 찾을 때만 `yaml.ansible`로 승격한다. 저장소 루트의 `site.yml`처럼 경로로 판별할 수 없는
플레이북을 위한 규칙이며, 해당하지 않으면 `nil`을 반환해 다음 규칙으로 넘어간다. Kubernetes
매니페스트, docker-compose, Helm 템플릿, GitHub Actions 파일은 이 표식이 없으므로 영향받지
않는다.

## 알려진 범위 밖 기능

- Jenkins 서버 린터
- 파일 내용 기반 Kubernetes 스키마 선택
- workbench 프로젝트·worktree·agent 통합
- octo, GitLab, kubectl, csvview, gitgraph
- DAP, neotest, AI 플러그인

이 목록은 결함이 아니라 현재 비목표다. 요구가 생기면 [구조와 설계](architecture.md)의 전환
기준과 시작 시간 영향을 먼저 평가한다.
