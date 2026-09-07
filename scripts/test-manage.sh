#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
export HOME="$work/home" XDG_CONFIG_HOME="$work/home/.config"
mkdir -p "$HOME" "$work/source/scripts" "$work/source/tmux" "$work/bin"
cp "$root/manage.sh" "$work/source/"
cp "$root/scripts/setup-tmux.sh" "$work/source/scripts/"
cp "$root/tmux/tmux.conf" "$work/source/tmux/"
# Never touch the user's running server.
printf '#!/bin/sh\nexit 1\n' > "$work/bin/tmux"
chmod +x "$work/bin/tmux"
export PATH="$work/bin:$PATH"
git -C "$work/source" init -q
git -C "$work/source" add .
git -C "$work/source" -c user.name=Test -c user.email=test@example.invalid commit -qm initial
git clone -q "$work/source" "$work/repo"
mkdir -p "$XDG_CONFIG_HOME/nvim"
echo keep > "$XDG_CONFIG_HOME/nvim/local.txt"
echo old-tmux > "$HOME/.tmux.conf"
sh "$work/repo/manage.sh" install --skip-bootstrap
test "$(readlink "$XDG_CONFIG_HOME/nvim")" = "$work/repo"
test "$(readlink "$HOME/.tmux.conf")" = "$work/repo/tmux/tmux.conf"
test "$(cat "$XDG_CONFIG_HOME"/nvim.backup.*/nvim/local.txt)" = keep
test "$(cat "$HOME"/.tmux.conf.backup.*/tmux.conf)" = old-tmux
sh "$work/repo/manage.sh" install --skip-bootstrap
echo dirty >> "$work/repo/tmux/tmux.conf"
if sh "$work/repo/manage.sh" upgrade --skip-bootstrap; then exit 1; fi
git -C "$work/repo" restore tmux/tmux.conf
echo '# upgraded' >> "$work/source/tmux/tmux.conf"
git -C "$work/source" add .
git -C "$work/source" -c user.name=Test -c user.email=test@example.invalid commit -qm upgrade
sh "$work/repo/manage.sh" upgrade --skip-bootstrap
test "$(git -C "$work/source" rev-parse HEAD)" = "$(git -C "$work/repo" rev-parse HEAD)"
sh "$work/repo/manage.sh" uninstall
test ! -e "$XDG_CONFIG_HOME/nvim"
test ! -L "$HOME/.tmux.conf"
test -f "$work/repo/tmux/tmux.conf"
sh "$work/repo/manage.sh" uninstall
echo foreign > "$HOME/.tmux.conf"
mkdir "$XDG_CONFIG_HOME/nvim"
sh "$work/repo/manage.sh" uninstall
test "$(cat "$HOME/.tmux.conf")" = foreign
test -d "$XDG_CONFIG_HOME/nvim"
echo 'nvim lifecycle tests passed'
