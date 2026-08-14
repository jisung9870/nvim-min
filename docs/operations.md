# 운영과 유지보수

## 운영 원칙

플러그인 업데이트와 설정 변경은 분리해서 검증한다. `nvim-pack-lock.json`은 재현 가능한 복구의
핵심이므로 플러그인 변경과 함께 커밋하고, 임의로 삭제하거나 무시하지 않는다.

## 일상 점검

| 대상 | 명령 | 정상 기준 |
|---|---|---|
| 플러그인 | `:PackStatus` | 선언된 플러그인이 목록에 있고 오류가 없음 |
| Neovim/플러그인 | `:checkhealth` | 필수 도구 관련 error 없음 |
| LSP | `:checkhealth vim.lsp` | 샘플 파일에서 기대 서버가 연결됨 |
| Treesitter | `:TSSync` | 선언된 파서 설치 완료 |
| Mason | `:Mason` | 필요한 패키지가 Installed 상태 |

## 사용자 명령 참조

| 명령 | 동작 | 확인 또는 주의사항 |
|---|---|---|
| `:PackStatus` | 네트워크 없이 설치 목록 확인 | `[[`, `]]`로 항목 이동 |
| `:PackUpdate` | 플러그인 업데이트 후보 계산 | 확인 버퍼에서 `:w` 확정, `:q` 취소 |
| `:PackClean` | 선언에서 빠진 플러그인 삭제 | 삭제 후보 확인 후 명시적으로 선택 |
| `:TSUpdateAll` | 설치된 Treesitter 파서 업데이트 | 완료 메시지와 대표 파일 확인 |
| `:TSSync` | 선언된 파서를 강제로 동기 설치 | 완료까지 기다리며 최대 10분 제한 |
| `:LspInstallAll` | 빠진 Mason 패키지 설치 | Mason 외부 도구는 별도 설치 |
| `:FormatToggle` | 전역 저장 시 포맷 토글 | 수동 `<leader>cf`에는 영향 없음 |
| `:FormatToggle!` | 현재 버퍼 저장 시 포맷 토글 | 버퍼를 닫으면 버퍼 상태 소멸 |
| `:SessionSave` | 현재 cwd의 창·탭·파일 버퍼 저장 | 파일 내용 자체는 먼저 저장해야 함 |
| `:SessionRestore` | 현재 cwd의 마지막 편집기 세션 복원 | 현재 창 레이아웃이 저장된 레이아웃으로 바뀜 |
| `:ProjectScratch` | 현재 cwd의 Markdown 메모 열기 | state 경로에 자동 저장되며 Git에는 포함되지 않음 |

## 플러그인 업데이트

1. 작업 트리가 깨끗한지 확인한다.

   ```sh
   git status --short
   ```

2. nvim-min에서 `:PackUpdate`를 실행한다.
3. 확인 버퍼의 변경 리비전을 검토한다.
4. `:w`로 확정하거나 `:q`로 취소한다.
5. Neovim을 다시 시작하고 아래 검증을 수행한다.
6. `nvim-pack-lock.json`과 `CHANGELOG.md`를 함께 커밋한다.

업데이트 후 최소 검증:

- 시작 오류가 없다.
- `:PackStatus`와 `:checkhealth`가 통과한다.
- 파일 picker와 grep이 열린다.
- 대표 언어 파일에서 Treesitter, LSP, completion, 저장 시 format/lint가 동작한다.
- Git 저장소에서 hunk 표시와 Diffview가 열린다.
- terminal을 열고 닫을 수 있다.

## 보안과 재현성

Neovim 플러그인은 편집기 프로세스 권한으로 코드를 실행한다. 업데이트 확인 버퍼와
`nvim-pack-lock.json` diff에서 예상한 저장소와 리비전만 바뀌었는지 검토한 뒤 확정한다.
잠금 파일은 버전 재현을 돕지만 플러그인 자체의 신뢰성을 보증하지는 않는다.

`lua/local.lua`가 Git에서 제외되어 있어도 API 토큰, SSH 키, 비밀번호를 직접 기록하지 않는다.
민감값이 필요한 로컬 확장은 환경 변수나 운영체제의 보안 저장소에서 읽고, 알림·로그·오류
메시지에 값이 출력되지 않는지 확인한다.

## Treesitter와 도구 업데이트

- `:TSUpdateAll`: 설치된 파서의 업데이트를 시작한다.
- `:TSSync`: 구성 목록 전체를 강제로 설치하고 완료까지 기다린다.
- `:LspInstallAll`: 빠진 Mason 패키지만 설치한다.
- `:Mason`: 설치·업데이트 상태를 대화형으로 확인한다.

파서나 LSP만 업데이트했더라도 대표 파일을 다시 열어 하이라이트, root 탐지, 진단을 확인한다.
플러그인 잠금 파일은 Mason 바이너리 버전까지 고정하지 않으므로 Mason 업데이트 결과는 별도다.

## 사용하지 않는 플러그인 정리

`lua/plugins.lua`에서 선언을 제거한 뒤 `:PackClean`을 실행한다. 삭제 후보가 표시되고 `삭제`를
선택한 경우에만 디스크에서 제거된다. 삭제 전에는 잠금 파일과 설정에서 참조가 모두 사라졌는지
확인한다.

## 잠금 파일 롤백

업데이트 직후 문제가 생겼고 설정 코드는 바뀌지 않았다면 잠금 파일부터 이전 상태로 되돌린다.

```sh
git restore --source=HEAD^ -- nvim-pack-lock.json
```

아직 커밋하지 않은 업데이트만 취소하려면 다음 명령을 사용한다.

```sh
git restore -- nvim-pack-lock.json
```

그 뒤 Neovim을 다시 시작하고 다음을 실행한다.

```vim
:lua vim.pack.update(nil, { offline = true, target = 'lockfile' })
```

확인 버퍼에서 `:w`로 적용한 뒤 다시 시작해 검증한다. 설정 코드도 함께 바뀌었다면 잠금 파일만
되돌리지 말고 해당 릴리스의 태그 또는 커밋 전체로 복구한다.

## 새 머신 복원

```sh
curl -fsSL https://raw.githubusercontent.com/jisung9870/nvim-min/main/install.sh | sh
nvim
```

Neovim 안에서 다음을 실행한다.

```vim
:TSSync
:LspInstallAll
:checkhealth
```

Mason이 관리하지 않는 `tflint`, `terraform`, `goimports`, `gofumpt`, `alloy`, `gitui` 같은
도구는 머신 패키지 관리자로 별도 설치한다. `lua/local.lua`도 새 머신 정책에 맞게 다시 만든다.

## 변경 전후 검증 체크리스트

- [ ] 변경 전 `nvim-pack-lock.json`과 시작 상태를 보존했다.
- [ ] `nvim`이 오류 없이 시작한다.
- [ ] `:checkhealth`의 신규 오류가 없다.
- [ ] 대표 파일에서 LSP, 포맷, 린트, Treesitter를 확인했다.
- [ ] picker, Git, terminal 핵심 경로를 확인했다.
- [ ] 사용자 영향 변경을 `CHANGELOG.md`의 `Unreleased`에 기록했다.
- [ ] 설정과 관련 문서를 함께 갱신했다.

릴리스 단위 검증과 태그 절차는 [릴리스 관리](release-management.md)를 따른다.
