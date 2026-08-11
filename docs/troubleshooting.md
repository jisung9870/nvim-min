# 문제 해결

## 진단 순서

문제가 발생하면 설정 전체를 지우기 전에 다음 순서로 범위를 줄인다.

1. `NVIM_APPNAME=nvim-min nvim`으로 올바른 앱을 실행했는지 확인한다.
2. 오류 메시지와 `:messages`를 확인한다.
3. `:checkhealth`와 `:PackStatus`를 실행한다.
4. 문제가 특정 언어, 플러그인, 머신에만 있는지 구분한다.
5. 업데이트 직후라면 잠금 파일 변경을 확인한다.

## 시작 시 `vim.pack` 오류

가능한 원인은 Neovim 버전 불일치, Git 부재, 네트워크 실패, 손상된 플러그인 데이터다.

```sh
nvim --version
git --version
NVIM_APPNAME=nvim-min nvim --headless '+checkhealth' '+qa'
```

Neovim 0.12 계열인지 먼저 확인한다. 네트워크가 정상이고 잠금 파일이 신뢰 가능한 상태라면
[잠금 파일 롤백](operations.md#잠금-파일-롤백)을 우선 적용한다. 데이터 디렉터리 전체 삭제는
Mason과 파서 설치물까지 잃으므로 최후 수단이다.

## 플러그인이 설치되지 않음

1. `:PackStatus`에서 대상 플러그인의 상태와 이름을 확인한다.
2. `lua/plugins.lua` 선언과 `nvim-pack-lock.json` 항목을 비교한다.
3. Git으로 플러그인 원격 저장소에 접근 가능한지 확인한다.
4. 잠금 파일이 변경된 직후라면 이전 리비전으로 롤백한다.

`lua/plugins.lua`에서 제거한 플러그인이 남은 문제라면 `:PackClean`을 사용한다.

## Treesitter 하이라이트가 없음

```vim
:TSSync
:checkhealth nvim-treesitter
:set filetype?
```

- `tree-sitter` CLI와 C 컴파일러가 실행 가능한지 확인한다.
- `:set filetype?` 결과가 `lua/treesitter.lua`의 파서 이름과 매핑되는지 확인한다.
- Jenkinsfile, Helm, Ansible처럼 경로 규칙이 필요한 파일은 실제 경로가 규칙에 맞는지 확인한다.

## LSP가 연결되지 않음

```vim
:LspInstallAll
:checkhealth vim.lsp
:set filetype?
```

그 다음 서버 실행 파일이 Mason에 설치됐는지, 현재 파일이 서버의 root marker 안에 있는지
확인한다. Jenkinsfile은 현재 Groovy LSP를 제공하지 않고 Treesitter 하이라이트만 지원한다.

## 포맷 또는 린트가 동작하지 않음

- `<leader>uf`, `<leader>uF`로 자동 포맷이 꺼지지 않았는지 확인한다.
- 256KiB를 초과하는 파일은 저장 시 자동 포맷 대상이 아니다.
- Markdown은 의도적으로 포맷하지 않는다.
- `:ConformInfo`에서 포매터 실행 파일과 선택 결과를 확인한다.
- Terraform의 `tflint`, Go의 `goimports`·`gofumpt`, Alloy의 `alloy`는 별도 설치가 필요하다.

중복 진단이 보이면 LSP와 `nvim-lint`가 같은 검사를 동시에 제공하는지 확인하고 한쪽만 남긴다.

## Python import가 전부 미해결로 표시됨

- `:PythonEnv`로 Pyright가 사용하는 인터프리터를 확인한다. 가상환경을 찾지 못했다는
  경고가 나오면 그 경로에 `.venv` 또는 `venv`가 없는 것이다.
- 탐색 기준은 프로젝트 루트가 아니라 편집 중인 파일이며, 상위 디렉터리로 올라가면서
  찾는다. 편집 중인 파일이 가상환경 디렉터리보다 상위에 있으면 탐색되지 않는다.
- `.venv/bin/python`이 실제로 존재해야 한다. 디렉터리 이름만 있고 인터프리터가 없는
  경우는 후보에서 제외한다.
- 셸에서 다른 환경을 활성화한 상태라면 `VIRTUAL_ENV`가 우선한다. 의도한 환경이 아니면
  해당 환경을 비활성화한 뒤 Neovim을 다시 시작한다.
- 인터프리터는 클라이언트가 붙는 시점에 결정된다. 가상환경을 새로 만들었다면 해당
  버퍼를 다시 열어야 반영된다.

## Go 파일 하나가 통째로 인식되지 않음

`No packages found for open file`이 표시되면 해당 파일이 빌드 태그 때문에 기본 빌드에서
제외된 것이다.

- 파일 상단의 `//go:build` 제약을 확인하고 `:GoBuildTags <태그>`로 지정한다.
- 반복해서 사용하는 저장소라면 `lua/local.lua`에 `vim.g.go_build_tags`를 둔다.
- 태그를 지정해도 그대로면 파일이 모듈 밖에 있거나 `go.mod`가 없는 경우다.
- `:GoBuildTags`를 인자 없이 실행하면 해제되며, 두 경우 모두 gopls를 다시 시작한다.

## 아이콘이 네모로 표시됨

터미널 폰트를 Nerd Font 패치본으로 설정한다. `lua/icons.lua`는 글리프 손상을 막기 위해 Unicode
escape를 사용하지만, 폰트 자체가 없으면 렌더링할 수 없다.

## 검색이 느리거나 결과가 없음

- `rg`와 `fd`가 실행 가능한지 확인한다.
- `.git`, `node_modules`, `.terraform`, `.terragrunt-cache`, `vendor`, `.venv` 등은 의도적으로
  검색에서 제외한다.
- 제외 대상이 필요한 작업이면 `lua/finder.lua`의 `exclude` 정책을 변경하고 대규모 저장소에서
  성능을 다시 확인한다.

## tmux 이동 또는 TUI Escape가 이상함

- `<C-h/j/k/l>`은 `vim-tmux-navigator`가 Neovim 창과 tmux pane 이동을 함께 처리한다.
- toggleterm 버퍼의 `<Esc>`만 Terminal 모드를 종료한다.
- `bb tm` 전환기 안에서는 Escape를 내부 UI에 전달하기 위해 별도 on-open 동작을 사용한다.

tmux 밖에서 `<leader>tp`를 사용하거나 `bb`가 없으면 해당 전환기는 실행되지 않는다.

## 업데이트 직후 회귀

1. `git diff -- nvim-pack-lock.json`으로 바뀐 플러그인을 식별한다.
2. [운영 가이드](operations.md#잠금-파일-롤백)에 따라 잠금 파일을 되돌린다.
3. offline lockfile 적용 후 재시작한다.
4. 회귀가 사라지면 해당 플러그인과 리비전을 `CHANGELOG.md` 또는 이슈에 기록한다.
5. 설정 변경이 원인이면 마지막 정상 커밋과 현재 커밋을 같은 샘플 파일로 비교한다.

복구가 확인되기 전에는 새 잠금 파일을 릴리스하지 않는다.
