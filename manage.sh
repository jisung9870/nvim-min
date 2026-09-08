#!/bin/sh
# Manage this checkout's Neovim configuration, preserving user data.
set -eu
repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
action=${1:-help}
[ "$#" -eq 0 ] || shift
bootstrap=1
for arg in "$@"; do
  case "$arg" in
    --skip-bootstrap) bootstrap=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

owned() {
  [ -d "$target" ] && [ "$(CDPATH='' cd -- "$target" && pwd -P)" = "$repo" ]
}
apply_config() {
  if [ "$bootstrap" -eq 1 ]; then
    command -v git >/dev/null 2>&1
    command -v nvim >/dev/null 2>&1
    nvim --version | awk 'NR == 1 { split($2, v, "."); sub(/^v/, "", v[1]); exit !(v[1] > 0 || v[2] >= 12) }'
  fi
  if ! owned; then
    mkdir -p "$(dirname -- "$target")"
    if [ -e "$target" ] || [ -L "$target" ]; then
      saved=$(mktemp -d "${target}.backup.XXXXXX")
      mv "$target" "$saved/nvim"
      echo "Neovim backup: $saved/nvim"
    fi
    if ! ln -s "$repo" "$target"; then
      if [ -n "${saved:-}" ]; then mv "$saved/nvim" "$target"; fi
      exit 1
    fi
  fi
  if [ "$bootstrap" -eq 1 ]; then
    unset NVIM_APPNAME
    nvim --headless '+lua dofile(vim.fn.stdpath("config") .. "/scripts/sync-plugins.lua")' '+qa'
    if command -v tree-sitter >/dev/null 2>&1 && command -v cc >/dev/null 2>&1; then
      nvim --headless '+TSSync' '+qa'
    fi
    nvim --headless '+lua if vim.v.errmsg ~= "" then vim.cmd("cquit") end' '+qa'
  fi
  echo 'Applied nvim-min. Restart Neovim to load changes.'
}

case "$action" in
  install) apply_config ;;
  upgrade)
    if ! owned; then echo 'Run manage.sh install first.' >&2; exit 1; fi
    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
      echo 'Checkout has local changes; preserve or commit them before upgrading.' >&2
      exit 1
    fi
    previous=$(git -C "$repo" rev-parse HEAD)
    git -C "$repo" pull --ff-only
    echo "Previous revision: $previous"
    # Reload the entrypoint so updates to the installer are applied as well.
    if [ "$bootstrap" -eq 0 ]; then exec sh "$repo/manage.sh" install --skip-bootstrap; fi
    exec sh "$repo/manage.sh" install
    ;;
  uninstall)
    # Only detach configuration belonging to this checkout.
    if owned; then
      if [ -L "$target" ]; then
        unlink "$target"
      else
        saved=$(mktemp -d "${target}.uninstalled.XXXXXX")
        mv "$target" "$saved/nvim"
        echo "Checkout preserved: $saved/nvim"
      fi
    fi
    echo 'Uninstalled configuration. Backups, plugins, sessions, local files and Neovim binary are preserved.'
    ;;
  help|-h|--help)
    echo 'Usage: sh manage.sh install|upgrade|uninstall [--skip-bootstrap]'
    echo 'install: back up old Neovim configuration, link this checkout, bootstrap plugins/parsers'
    echo 'upgrade: fast-forward a clean checkout, then apply it'
    echo 'uninstall: detach owned configuration, preserving all user data'
    ;;
  *) echo "Unknown action: $action" >&2; exit 2 ;;
esac
