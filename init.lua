-- ============================================================================
-- nvim-min : vim.pack 기반 자기 소유 Neovim 설정
-- ============================================================================
-- 실행: NVIM_APPNAME=nvim-min nvim
--
-- 로딩 순서는 의도적으로 고정되어 있다.
--   options  → 플러그인이 읽는 vim.o 값을 먼저 확정
--   plugins  → vim.pack.add()로 설치 + rtp 등록 (이후 require 가능)
--   theme    → 팔레트/하이라이트 (statusline이 이 하이라이트를 씀)
--   나머지   → 기능별 모듈, 서로 의존하지 않음
-- ============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("options")
require("plugins")

require("theme")
require("statusline")
require("treesitter")
require("lsp")
require("completion")
require("editing")
require("finder")
require("git")
require("terminal")
require("keymaps")
require("autocmds")

-- 머신별 오버라이드 (git 추적 안 함)
pcall(require, "local")
