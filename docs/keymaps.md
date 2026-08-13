# 키맵

`<leader>`는 `Space`, `<localleader>`는 `\\`다. `<leader>sk`에서 현재 적용된 전체 키맵을
검색할 수 있고 leader를 누르면 which-key 그룹이 표시된다.

## 기본 편집과 창

| 키 | 모드 | 동작 |
|---|---|---|
| `jk` | Insert | Normal 모드로 나가기 |
| `H` / `L` | Normal | 이전 / 다음 버퍼 |
| `<A-j>` / `<A-k>` | Normal, Visual | 줄 또는 선택 영역 아래 / 위로 이동 |
| `<` / `>` | Visual | 들여쓰기 후 선택 유지 |
| `p` | Visual | 기본 레지스터를 덮지 않고 붙여넣기 |
| `n` / `N` | Normal | 다음 / 이전 검색 결과를 화면 중앙에 표시 |
| `J` | Normal | 커서 위치를 유지하며 줄 합치기 |
| `<C-s>` | Insert, Select, Normal | 저장 후 Normal 모드 |
| `<Esc>` | Normal | 검색 하이라이트 지우기 |
| `<leader>qq` | Normal | 모든 창 종료 |
| `<leader>-` / `<leader>\|` | Normal | 아래 / 오른쪽으로 창 분할 |
| `<leader>wd` | Normal | 현재 창 닫기 |
| `<C-Up/Down>` | Normal | 창 높이 조절 |
| `<C-Left/Right>` | Normal | 창 너비 조절 |
| `sa` / `sd` / `sr` | Normal, Visual | surround 추가 / 삭제 / 교체 |
| `gc` | Normal, Visual | Neovim 내장 주석 토글 |

## 파일과 검색

| 키 | 동작 |
|---|---|
| `<leader><space>` | 스마트 파일 찾기 |
| `<leader>ff` / `fr` / `fb` | 파일 / 최근 파일 / 버퍼 |
| `<leader>fc` / `fp` | 설정 파일 / 프로젝트 찾기 |
| `<leader>e` | 파일 탐색기 |
| `<leader>fR` | 파일 이름 변경 후 LSP에 알림 |
| `<leader>sg` / `sw` | grep / 커서 단어 또는 선택 영역 grep |
| `<leader>sb` | 현재 버퍼 줄 검색 |
| `<leader>sk` / `sh` | 키맵 / 도움말 검색 |
| `<leader>sc` / `sr` / `sn` | 명령 기록 / 마지막 picker / 알림 기록 |
| `<leader>bd` / `bo` | 현재 버퍼 / 나머지 버퍼 삭제 |

Explorer 목록에서는 `-`가 가로 분할, `|`가 세로 분할, `M`이 최대화 토글이다. `y`로 파일을
복사하고 `p`로 붙여넣으며, 이름이 겹치면 `-2`, `-3` 접미사를 자동으로 붙인다. 파일과 grep은
`.git`, `node_modules`, `.terraform`, `.terragrunt-cache`, `vendor`, `__pycache__`, `.venv` 등을
제외한다.

## 코드와 진단

LSP가 현재 버퍼에 연결된 경우에만 LSP 키가 활성화된다.

| 키 | 동작 |
|---|---|
| `gd` / `gD` | 정의 / 선언 |
| `gr` / `gI` / `gy` | 참조 / 구현 / 타입 정의 |
| `K` | hover 문서 |
| `<leader>cr` / `ca` | 이름 변경 / code action |
| `<leader>cs` | 문서 심볼 |
| `<leader>cf` | 수동 포맷 |
| `<leader>cd` | 현재 줄 진단 |
| `]d` / `[d` | 다음 / 이전 진단 |
| `]e` / `[e` | 다음 / 이전 오류 |
| `<leader>xx` / `xX` | 버퍼 / 워크스페이스 진단 목록 |
| `<leader>uh` | 해당 서버가 지원할 때 inlay hint 토글 |

Neovim 0.11 기본 `grn`, `gra`, `grr`, `gri`, `grt` 매핑은 `gr` prefix 지연을 막기 위해 제거한다.
동일 기능은 위 키맵으로 제공한다.

## Git

| 키 | 동작 |
|---|---|
| `]h` / `[h` | 다음 / 이전 hunk |
| `<leader>gs` / `gr` | hunk stage / reset; Visual 범위 지원 |
| `<leader>gS` / `gR` | 버퍼 전체 stage / reset |
| `<leader>gp` | hunk 미리보기 |
| `<leader>gb` / `gB` | 줄 blame 토글 / 전체 blame |
| `vih`, `dih` | hunk 선택 / 삭제 |
| `<leader>gd` / `gq` | Diffview 열기 / 닫기 |
| `<leader>gh` / `gH` | 현재 파일 / 브랜치 히스토리 |
| `<leader>gg` | `gitui`, 없으면 `lazygit` |
| `<leader>gc` / `gf` / `gt` | Git 로그 / 현재 파일 로그 / 상태 |

`<leader>gr`은 Git 버퍼에서는 hunk reset, LSP 문맥의 `gr`은 reference다. leader 유무가 다르다.

## 터미널과 tmux

| 키 | 모드 | 동작 |
|---|---|---|
| `<C-\\>` | Normal, Terminal | 기본 floating terminal 토글 |
| `<leader>th` / `tv` / `tf` | Normal | 가로 / 세로 / floating terminal |
| `<leader>tp` | Normal | `bb tm` 프로젝트 세션 전환기 |
| `<C-h/j/k/l>` | Normal, Terminal | Neovim 창과 tmux pane 사이 이동 |
| `<Esc>` | toggleterm Terminal | Terminal 모드 나가기 |

`<Esc>` Terminal 매핑은 toggleterm 버퍼에만 적용한다. gitui 같은 TUI가 Escape 입력을 받아야
하는 경우를 보호하기 위한 경계다.

## 토글과 관리

| 키 | 동작 |
|---|---|
| `<leader>uf` / `uF` | 전역 / 현재 버퍼 자동 포맷 토글 |
| `<leader>uw` | 줄바꿈 토글 |
| `<leader>ul` | 줄 번호와 상대 줄 번호 토글 |
| `<leader>ud` | 진단 표시 토글 |
| `<leader>um` | Markdown 내부 렌더링 토글 |
| `<leader>ub` | light/dark 배경 토글; 테마와 상태줄이 함께 전환된다 |
| `<leader>cp` / `cu` | 플러그인 상태 / 업데이트 |
| `<leader>mt` | macOS에서 현재 Markdown을 Typora로 열기 |

## 자동완성

| 키 | 동작 |
|---|---|
| `<C-Space>` | 완성 메뉴 열기 |
| `<Tab>` / `<S-Tab>` | 다음 / 이전 항목 또는 snippet 이동 |
| `<CR>` | 선택 항목 적용; 없으면 기본 Enter |
| `<C-e>` | 메뉴 닫기 |
