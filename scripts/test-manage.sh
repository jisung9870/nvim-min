#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
export HOME="$work/home" XDG_CONFIG_HOME="$work/home/.config"
mkdir -p "$HOME" "$work/source/scripts" "$work/bin"
cp "$root/manage.sh" "$work/source/"
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
test "$(cat "$HOME/.tmux.conf")" = old-tmux
test "$(cat "$XDG_CONFIG_HOME"/nvim.backup.*/nvim/local.txt)" = keep
sh "$work/repo/manage.sh" install --skip-bootstrap
echo '# dirty' >> "$work/repo/manage.sh"
if sh "$work/repo/manage.sh" upgrade --skip-bootstrap; then exit 1; fi
git -C "$work/repo" restore manage.sh
echo '# upgraded' >> "$work/source/manage.sh"
git -C "$work/source" add .
git -C "$work/source" -c user.name=Test -c user.email=test@example.invalid commit -qm upgrade
sh "$work/repo/manage.sh" upgrade --skip-bootstrap
test "$(git -C "$work/source" rev-parse HEAD)" = "$(git -C "$work/repo" rev-parse HEAD)"
sh "$work/repo/manage.sh" uninstall
test ! -e "$XDG_CONFIG_HOME/nvim"
test "$(cat "$HOME/.tmux.conf")" = old-tmux
test -f "$work/repo/manage.sh"
sh "$work/repo/manage.sh" uninstall
echo foreign > "$HOME/.tmux.conf"
mkdir "$XDG_CONFIG_HOME/nvim"
sh "$work/repo/manage.sh" uninstall
test "$(cat "$HOME/.tmux.conf")" = foreign
test -d "$XDG_CONFIG_HOME/nvim"
echo 'nvim lifecycle tests passed'
