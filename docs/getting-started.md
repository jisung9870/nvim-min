# 빠른 시작

## 목표와 완료 기준

nvim-min을 기본 Neovim 설정으로 설치해 별도 환경변수 없이 실행한다. 다음 조건을 모두
만족하면 설치가 완료된 것이다.

- `nvim`이 오류 없이 열린다.
- `:PackStatus`에 플러그인 목록이 나타난다.
- `:checkhealth`에서 필수 실행 파일 관련 차단 오류가 없다.
- 작업 언어의 파일에서 Treesitter 하이라이트와 LSP가 동작한다.

## 요구 사항

### 필수

| 항목 | 이유 | 확인 명령 |
|---|---|---|
| Neovim 0.12 계열 | `vim.pack`과 현재 Treesitter 구성을 사용 | `nvim --version` |
| Git | 저장소와 플러그인 설치 | `git --version` |
| C 컴파일러 | 일부 Treesitter 파서 컴파일 | `cc --version` |
| tree-sitter CLI | Treesitter 파서 설치 | `tree-sitter --version` |

현재 구성은 Neovim 0.12의 내장 파서 구성을 전제로 한다. 0.11 이하 호환성은 보장하지 않는다.

### 권장 또는 선택

| 항목 | 제공 기능 | 없을 때 |
|---|---|---|
| Nerd Font | 상태줄과 UI 아이콘 | 일부 문자가 네모로 표시됨 |
| `rg`, `fd` | 빠른 파일·본문 검색 | picker 성능 또는 기능이 제한될 수 있음 |
| `gitui` 또는 `lazygit` | `<leader>gg` Git UI | 해당 키 실행 실패 |
| `macism` (macOS) | 입력 모드 종료 시 한/영 전환 | 자동 전환만 비활성화 |
| `alloy` | Grafana Alloy 포맷 | Alloy 포맷만 비활성화 |
| `bb`와 tmux | `<leader>tp` 프로젝트 전환 | 해당 키 실행 실패 |
| Typora (macOS) | `<leader>mt` 외부 Markdown 열기 | 해당 앱 실행 실패 |

macOS에서 필요한 선택 도구의 예시는 다음과 같다.

```sh
brew install tree-sitter-cli ripgrep fd macism gitui
```

## 설치

기본 설치 위치는 `~/.config/nvim`이다. 자동 설치 스크립트는 기존 설정을 덮어쓰지 않으며,
대상 경로가 이미 있으면 안전하게 중단한다.

```sh
curl -fsSL https://raw.githubusercontent.com/jisung9870/nvim-min/main/install.sh | sh
nvim
```

스크립트는 Git과 Neovim 0.12 이상을 확인하고, `nvim-pack-lock.json`에 고정된 플러그인을
설치한다. `tree-sitter` CLI와 C 컴파일러가 있으면 파서 설치도 완료한다. 설정만 복사하고
초기 설치는 나중에 하려면 다음처럼 부트스트랩을 건너뛴다.

```sh
curl -fsSL https://raw.githubusercontent.com/jisung9870/nvim-min/main/install.sh \
  | sh -s -- --skip-bootstrap
```

수동 설치가 필요하면 다음 명령을 사용한다.

```sh
git clone https://github.com/jisung9870/nvim-min.git ~/.config/nvim
nvim
```

## 최초 구성

Neovim 안에서 다음 명령을 순서대로 실행한다.

```vim
:TSSync
:LspInstallAll
:checkhealth
```

- `:TSSync`는 구성에 선언된 Treesitter 파서를 설치하고 완료까지 기다린다.
- 설치 스크립트가 파서를 설치했다면 `:TSSync`를 다시 실행해도 안전하다.
- `:LspInstallAll`은 빠진 LSP·린터·포매터만 Mason으로 설치한다.
- `:checkhealth`는 Neovim과 플러그인의 실행 환경을 점검한다.

설치 상태는 `:PackStatus`, LSP 상태는 `:checkhealth vim.lsp`로 다시 확인할 수 있다.

## 기본 데이터 경로

별도 `NVIM_APPNAME`을 지정하지 않으므로 Neovim의 기본 경로를 사용한다.

| 종류 | 경로 |
|---|---|
| 설정 | `~/.config/nvim/` |
| 플러그인·Mason·파서 데이터 | `~/.local/share/nvim/` |
| 상태 | `~/.local/state/nvim/` |
| 캐시 | `~/.cache/nvim/` |

## 머신별 오버라이드

저장소에 포함하지 않을 로컬 설정은 `lua/local.lua`에 둔다. 파일은 `pcall`로 로드되므로 없어도
시작에 영향을 주지 않으며 `.gitignore` 대상이다.

```lua
-- ~/.config/nvim/lua/local.lua
vim.g.k8s_schema_version = "v1.33.1"
vim.opt.colorcolumn = "100"
```

`vim.g.k8s_schema_version`은 Kubernetes YAML 스키마 URL을 조정한다. 값을 바꾼 뒤 YAML 파일에서
LSP를 다시 시작해 적용 여부를 확인한다.

## 다음 문서

- 기능을 바꾸려면 [구조와 설계](architecture.md)와 [기능과 언어 구성](configuration.md)
- 사용법을 익히려면 [키맵](keymaps.md)
- 업데이트하려면 [운영과 유지보수](operations.md)
