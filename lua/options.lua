-- ============================================================================
-- vim 옵션
-- ============================================================================

local opt = vim.opt

-- 편집 기본
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false
opt.confirm = true -- 저장 안 된 버퍼 닫을 때 물어봄
opt.virtualedit = "block"

-- 들여쓰기 (YAML/Terraform 기준 2칸)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shiftround = true

-- 검색
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- :s 미리보기

-- 창/스크롤
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.wrap = false
opt.linebreak = true

-- 완성/명령행
opt.pumheight = 15
opt.completeopt = "menu,menuone,noselect"
opt.cmdheight = 1
opt.showmode = false -- statusline이 모드를 표시함
opt.laststatus = 3 -- 전역 statusline

-- 시각 요소
opt.colorcolumn = "120"
opt.list = true
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }
opt.fillchars = {
  eob = " ",
  vert = "│",
  fold = " ",
  foldopen = "▾",
  foldclose = "▸", -- lua/icons.lua의 fold와 같은 값 (options는 icons보다 먼저 로드됨)
  foldsep = " ",
}

-- 폴딩 (treesitter.lua에서 foldexpr 지정)
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- 타이밍
opt.updatetime = 200
opt.timeoutlen = 300

-- 세션에 저장할 항목
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help" }

-- netrw 비활성화 (snacks explorer 사용)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
