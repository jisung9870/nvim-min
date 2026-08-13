#!/bin/sh

set -eu

# This configuration intentionally owns Neovim's default app paths.
unset NVIM_APPNAME

repo_url=${NVIM_MIN_REPO_URL:-https://github.com/jisung9870/nvim-min.git}
config_root=${XDG_CONFIG_HOME:-"$HOME/.config"}
install_dir=${NVIM_MIN_INSTALL_DIR:-"$config_root/nvim"}
bootstrap=1

usage() {
  cat <<'EOF'
Usage: install.sh [--skip-bootstrap]

Installs nvim-min as the default Neovim configuration in ~/.config/nvim.

Options:
  --skip-bootstrap  Install the configuration without downloading plugins/parsers
  -h, --help        Show this help

Environment overrides (mainly for testing or custom XDG layouts):
  NVIM_MIN_REPO_URL    Git repository to clone
  NVIM_MIN_INSTALL_DIR Configuration destination
EOF
}

for arg in "$@"; do
  case $arg in
    --skip-bootstrap) bootstrap=0 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

require_command git
require_command nvim

nvim_version=$(nvim --version | sed -n '1s/^NVIM v\([0-9][0-9.]*\).*$/\1/p')
nvim_major=$(printf '%s' "$nvim_version" | cut -d. -f1)
nvim_minor=$(printf '%s' "$nvim_version" | cut -d. -f2)
if [ -z "$nvim_version" ]; then
  printf 'Error: could not determine the Neovim version.\n' >&2
  exit 1
fi
if [ "$nvim_major" -eq 0 ] && [ "$nvim_minor" -lt 12 ]; then
  printf 'Error: Neovim 0.12 or newer is required (found: %s).\n' "${nvim_version:-unknown}" >&2
  exit 1
fi

if [ -e "$install_dir" ]; then
  cat >&2 <<EOF
Error: $install_dir already exists; nothing was overwritten.
Move or remove that directory after preserving anything you need, then run this installer again.
EOF
  exit 1
fi

if [ "$bootstrap" -eq 1 ] && [ "$install_dir" != "$config_root/nvim" ]; then
  cat >&2 <<EOF
Error: automatic bootstrap requires the default path: $config_root/nvim
Use --skip-bootstrap with NVIM_MIN_INSTALL_DIR, or set XDG_CONFIG_HOME instead.
EOF
  exit 1
fi

mkdir -p "$(dirname "$install_dir")"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/nvim-min.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

printf 'Cloning nvim-min into %s ...\n' "$install_dir"
git clone --depth 1 "$repo_url" "$work_dir/repo"
mv "$work_dir/repo" "$install_dir"

if [ "$bootstrap" -eq 1 ]; then
  printf 'Installing pinned plugins ...\n'
  nvim --headless '+qa'

  if command -v tree-sitter >/dev/null 2>&1 && command -v cc >/dev/null 2>&1; then
    printf 'Installing Treesitter parsers ...\n'
    nvim --headless '+TSSync' '+qa'
  else
    printf '%s\n' 'Warning: skipped Treesitter parsers (tree-sitter CLI and a C compiler are required).' >&2
  fi
fi

cat <<EOF

nvim-min is installed as the default Neovim configuration.
Start it with:

  nvim

Optional next step inside Neovim:

  :LspInstallAll

Configuration: $install_dir
EOF
