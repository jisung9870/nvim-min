# 빠른 시작

## 목표와 완료 기준

기존 `~/.config/nvim`을 건드리지 않고 nvim-min을 별도 앱으로 실행한다. 다음 조건을 모두
만족하면 설치가 완료된 것이다.

- `NVIM_APPNAME=nvim-min nvim`이 오류 없이 열린다.
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

기본 설치 위치는 `~/.config/nvim-min`이다.

```sh
git clone https://github.com/jisung9870/nvim-min.git ~/.config/nvim-min
NVIM_APPNAME=nvim-min nvim
```

첫 실행에서는 `vim.pack`이 `nvim-pack-lock.json`에 고정된 리비전으로 플러그인을 설치한다.
파서는 백그라운드 설치될 수 있으므로 설치 메시지가 끝나기 전에 종료하지 않는다.

## 최초 구성

Neovim 안에서 다음 명령을 순서대로 실행한다.

```vim
:TSSync
:LspInstallAll
:checkhealth
```

- `:TSSync`는 구성에 선언된 Treesitter 파서를 설치하고 완료까지 기다린다.
- `:LspInstallAll`은 빠진 LSP·린터·포매터만 Mason으로 설치한다.
- `:checkhealth`는 Neovim과 플러그인의 실행 환경을 점검한다.

설치 상태는 `:PackStatus`, LSP 상태는 `:checkhealth vim.lsp`로 다시 확인할 수 있다.

## 기존 Neovim과의 분리

`NVIM_APPNAME=nvim-min`을 사용하면 기본 설정과 주요 데이터 경로가 분리된다.

| 종류 | nvim-min 경로 |
|---|---|
| 설정 | `~/.config/nvim-min/` |
| 플러그인·Mason·파서 데이터 | `~/.local/share/nvim-min/` |
| 상태 | `~/.local/state/nvim-min/` |
| 캐시 | `~/.cache/nvim-min/` |

셸 별칭이 필요하면 셸 설정에 다음과 같이 추가한다.

```sh
alias nvim-min='NVIM_APPNAME=nvim-min nvim'
```

## 머신별 오버라이드

저장소에 포함하지 않을 로컬 설정은 `lua/local.lua`에 둔다. 파일은 `pcall`로 로드되므로 없어도
시작에 영향을 주지 않으며 `.gitignore` 대상이다.

```lua
-- ~/.config/nvim-min/lua/local.lua
vim.g.k8s_schema_version = "v1.33.1"
vim.opt.colorcolumn = "100"
```

`vim.g.k8s_schema_version`은 Kubernetes YAML 스키마 URL을 조정한다. 값을 바꾼 뒤 YAML 파일에서
LSP를 다시 시작해 적용 여부를 확인한다.

## 다음 문서

- 기능을 바꾸려면 [구조와 설계](architecture.md)와 [기능과 언어 구성](configuration.md)
- 사용법을 익히려면 [키맵](keymaps.md)
- 업데이트하려면 [운영과 유지보수](operations.md)
