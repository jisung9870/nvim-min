#!/bin/sh
set -eu

backup=0
for arg in "$@"; do
  case "$arg" in
    --backup) backup=1 ;;
    -h|--help)
      echo 'Usage: setup-tmux.sh [--backup]'
      echo 'Link ~/.tmux.conf to this checkout. --backup preserves an existing target.'
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
source_file="$repo_dir/tmux/tmux.conf"
target="${HOME:?HOME must be set}/.tmux.conf"
test -f "$source_file"
if [ -L "$target" ] && [ "$(readlink "$target")" = "$source_file" ]; then
  echo "Already linked: $target"
  exit 0
fi

saved=''
if [ -e "$target" ] || [ -L "$target" ]; then
  if [ "$backup" -ne 1 ]; then
    echo "Existing configuration: $target. Use --backup to preserve it and switch." >&2
    exit 1
  fi
  saved=$(mktemp -d "$HOME/.tmux.conf.backup.XXXXXX")
  mv "$target" "$saved/tmux.conf"
  echo "Backup: $saved/tmux.conf"
fi
if ! ln -s "$source_file" "$target"; then
  if [ -n "$saved" ]; then mv "$saved/tmux.conf" "$target"; fi
  exit 1
fi
echo "Linked: $target -> $source_file"
echo 'For a running tmux server, apply with: tmux source-file ~/.tmux.conf'
