-- ============================================================================
-- 터미널 + tmux
-- ============================================================================
-- Ctrl+h/j/k/l은 vim-tmux-navigator가 전담한다 (nvim 창 ↔ tmux 패널).
-- toggleterm에서 같은 키를 잡지 않는다 — 충돌 방지.
-- ============================================================================

require("toggleterm").setup({
  size = function(term)
    if term.direction == "horizontal" then
      return 15
    elseif term.direction == "vertical" then
      return math.floor(vim.o.columns * 0.4)
    end
  end,
  open_mapping = [[<C-\>]],
  hide_numbers = true,
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  terminal_mappings = true,
  persist_size = true,
  persist_mode = true,
  direction = "float",
  close_on_exit = true,
  shell = vim.o.shell,

  -- ESC는 toggleterm 버퍼에서만 terminal mode를 빠져나온다.
  -- 전역 매핑으로 하면 gitui / Claude Code 같은 TUI에서 ESC가 먹혀버린다.
  on_open = function(term)
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
      buffer = term.bufnr,
      desc = "Exit terminal mode",
    })
  end,

  float_opts = {
    border = "curved",
    width = function()
      return math.floor(vim.o.columns * 0.8)
    end,
    height = function()
      return math.floor(vim.o.lines * 0.8)
    end,
    winblend = 0,
  },
})

local map = vim.keymap.set
map({ "n", "t" }, "<C-\\>", "<cmd>ToggleTerm<cr>", { desc = "Toggle floating terminal" })
map("n", "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", { desc = "Horizontal terminal" })
map("n", "<leader>tv", "<cmd>ToggleTerm size=80 direction=vertical<cr>", { desc = "Vertical terminal" })
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Floating terminal" })

-- tmux 프로젝트 세션 전환기 (bb tm)
map("n", "<leader>tp", function()
  local Terminal = require("toggleterm.terminal").Terminal
  Terminal:new({
    cmd = "bb tm",
    direction = "float",
    close_on_exit = true,
    hidden = true,
    -- 전역 on_open(ESC 매핑)을 덮어써서 ESC가 내부 fzf로 전달되게 함
    on_open = function() end,
  }):toggle()
end, { desc = "Tmux project sessionizer" })

-- vim-tmux-navigator: 플러그인이 기본 매핑을 만들지 않도록 하고 직접 건다
vim.g.tmux_navigator_no_mappings = 1
map({ "n", "t" }, "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Go left (window/pane)" })
map({ "n", "t" }, "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Go down (window/pane)" })
map({ "n", "t" }, "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Go up (window/pane)" })
map({ "n", "t" }, "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Go right (window/pane)" })
