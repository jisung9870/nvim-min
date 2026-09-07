# tmux 관리

tmux 설정을 설치하거나 기존 lazyvim-config 연결을 교체할 때 이 절차를 사용한다.
설정 원본은 [tmux/tmux.conf](../tmux/tmux.conf)이며 `~/.tmux.conf`는 그 파일을 가리킨다.
tmux와 Neovim은 같은 저장소에서 관리하되 각각 별도 프로세스로 실행된다.

## 연결과 적용

대상은 macOS 또는 WSL/Linux의 사용자 환경이다. nvim-min 체크아웃과 tmux가 필요하다.
아래 명령은 기본 Neovim 설정 경로를 기준으로 하며, 사용자 계정으로 어느 디렉터리에서든
실행할 수 있다. 다른 위치에 설치했다면 스크립트 경로를 해당 체크아웃으로 바꾼다.

```sh
sh ~/.config/nvim/scripts/setup-tmux.sh --backup
readlink ~/.tmux.conf
```

이미 같은 파일에 연결되어 있으면 아무것도 바꾸지 않는다. 기존 파일이나 링크는 출력된
`~/.tmux.conf.backup.XXXXXX/tmux.conf`에 보관한다. `--backup` 없이 실행하면 기존 대상이
있을 때 중단한다. Neovim 설정과 TPM 플러그인 디렉터리는 변경하지 않는다.

새 머신에서는 `install.sh --with-tmux`로 Neovim 설치와 설정 연결을 함께 수행할 수 있다.
기존 tmux 설정이 있으면 tmux 연결 단계에서 중단하며, 이미 복제한 Neovim 설정은 남는다.
이 경우 위 스크립트를 `--backup`으로 실행하면 연결을 마칠 수 있다.

실행 중인 tmux에는 다음 명령으로 적용한다. 서버가 없으면 다음 `tmux` 실행 때 읽힌다.
기존 세션은 유지되며 키와 상태줄 설정이 즉시 반영된다.

```sh
tmux source-file ~/.tmux.conf
tmux show-options -gv mouse
tmux list-keys -T prefix r
```

사용자가 적용 직후 확인한다. 오류 없이 읽히고 `mouse`가 `on`, `prefix r`이
`~/.tmux.conf` 재로드로 표시되면 정상이다. 이후에는 `Ctrl-b r`로 다시 읽을 수 있다.
원본은 Git으로 갱신하고 머신별 변경은 `~/.tmux.conf.local`에 둔다. 이 파일은 마지막에 읽힌다.

## 플러그인

기존 `~/.tmux/plugins`를 그대로 사용한다. 새 머신에서 TPM이 없다면 다음처럼 설치한다.

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux
```

tmux 안에서 `Ctrl-b I`(대문자 I)로 선언된 플러그인을 설치하고 `Ctrl-b r`로 다시 읽는다.
테마는 Catppuccin이며 `bb tm` 프로젝트 전환은 `Ctrl-b f`이다.

[plugins.lock](../tmux/plugins.lock)은 기존 저장소에서 가져온 과거 설치 커밋 참고 자료다.
연결 스크립트나 TPM이 이 파일의 커밋을 자동 강제하지 않는다. 실제 설치 대상은
`tmux.conf`의 `@plugin` 선언이며 Catppuccin은 선언에 있는 태그를 사용한다.
따라서 이 파일만으로 새 머신의 플러그인 버전이 완전히 재현되지는 않는다.

## 실패 시 복구

TPM 실행 파일이 없다는 오류는 위 플러그인 설치 절차로 해결한다. 설정 구문 오류나
키 동작 회귀가 있으면 사용자가 즉시 이전 설정으로 되돌린다. 아래 백업 경로는
연결 스크립트가 출력한 실제 경로로 바꾼다. 먼저 `readlink ~/.tmux.conf`가 nvim-min의
`tmux/tmux.conf`인지 확인한 뒤 실행한다.

```sh
unlink ~/.tmux.conf
mv ~/.tmux.conf.backup.XXXXXX/tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

옛 링크를 복구하려면 그 링크가 가리키는 저장소도 남아 있어야 한다. 이전 설정을 읽어도
새로 추가된 옵션이나 키는 남을 수 있으므로 문제가 지속되면 작업을 저장하고 별도 tmux
서버에서 확인한다. 실행 중인 작업이 있는 서버를 복구 목적으로 종료하지 않는다.
