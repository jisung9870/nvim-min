-- ============================================================================
-- Git: gitsigns (hunk 단위) + diffview (커밋/히스토리)
-- ============================================================================

local signs = require("icons").signs

require("gitsigns").setup({
  signs = {
    add = { text = signs.add },
    change = { text = signs.change },
    delete = { text = signs.delete },
    topdelete = { text = signs.topdelete },
    changedelete = { text = signs.changedelete },
    untracked = { text = signs.untracked },
  },
  current_line_blame = false, -- <leader>gb로 토글
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol",
    delay = 500,
  },
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- hunk 이동 (diff 모드에서는 vim 기본 ]c/[c로 폴백)
    map("n", "]h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, "Next hunk")
    map("n", "[h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, "Prev hunk")

    map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
    map("v", "<leader>gs", function()
      gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Stage selected hunk")
    map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
    map("v", "<leader>gr", function()
      gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Reset selected hunk")
    map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
    map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
    map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
    map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
    map("n", "<leader>gB", function()
      gs.blame_line({ full = true })
    end, "Blame line (full)")

    -- ih: hunk 텍스트 오브젝트 (vih, dih)
    map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
  end,
})

-- diffview -------------------------------------------------------------------
require("diffview").setup({
  enhanced_diff_hl = true,
  view = {
    default = { layout = "diff2_horizontal" },
    merge_tool = { layout = "diff3_horizontal" },
  },
  file_panel = {
    listing_style = "tree",
    win_config = { position = "left", width = 35 },
  },
})

local map = vim.keymap.set
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview: open" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview: file history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview: branch history" })
map("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Diffview: close" })

-- git 도구를 터미널로 띄우기 -------------------------------------------------
map("n", "<leader>gg", function()
  local cmd = vim.fn.executable("gitui") == 1 and "gitui" or "lazygit"
  Snacks.terminal(cmd, { win = { style = "terminal", border = "rounded" } })
end, { desc = "gitui / lazygit" })

-- 커밋/브랜치 picker
map("n", "<leader>gc", function()
  Snacks.picker.git_log()
end, { desc = "Git log" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Git log (this file)" })
map("n", "<leader>gt", function()
  Snacks.picker.git_status()
end, { desc = "Git status" })
