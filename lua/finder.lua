-- ============================================================================
-- 파일 탐색 / 검색 / UI 잡동사니 (snacks.nvim)
-- ============================================================================
-- snacks는 모듈 묶음이다. 여기서 켠 것만 동작한다 — 켜지 않은 모듈은
-- 로드되지 않으므로 "안 쓰는 기능이 뒤에서 도는" 상황이 없다.
-- ============================================================================

-- DevOps 작업에서 검색 결과를 오염시키는 디렉터리
local exclude = {
  ".git",
  "node_modules",
  ".terraform",
  ".terragrunt-cache",
  "vendor",
  "__pycache__",
  "*.pyc",
  ".venv",
}

-- 같은 디렉터리에 붙여넣어도 기존 파일을 덮어쓰지 않고 번호가 붙은 복제 이름을 만든다.
local function copy_target(from, dir)
  local name = vim.fs.basename(from)
  local stem, ext = name:match("^(.*)(%.[^.]*)$")
  if not stem or stem == "" then
    stem, ext = name, ""
  end

  local index = 1
  local target
  repeat
    index = index + 1
    target = vim.fs.joinpath(dir, ("%s-%d%s"):format(stem, index, ext))
  until not vim.uv.fs_stat(target)
  return target
end

local function explorer_paste(picker)
  local register = vim.v.register or "+"
  local files = vim.split(vim.fn.getreg(register) or "", "\n", { plain = true, trimempty = true })
  files = vim.tbl_filter(function(file)
    return vim.fn.filereadable(file) == 1
  end, files)

  if #files == 0 then
    Snacks.notify.warn(("The `%s` register does not contain any files"):format(register))
    return
  end

  local dir = picker:dir()
  for _, from in ipairs(files) do
    local target = vim.fs.joinpath(dir, vim.fs.basename(from))
    if vim.uv.fs_stat(target) then
      target = copy_target(from, dir)
    end
    Snacks.picker.util.copy_path(from, target)
  end

  local Tree = require("snacks.explorer.tree")
  Tree:refresh(dir)
  Tree:open(dir)
  require("snacks.explorer.actions").update(picker, { target = dir })
end

require("snacks").setup({
  -- 켠 모듈 --------------------------------------------------------------
  picker = {
    ui_select = true, -- vim.ui.select을 picker로 대체
    win = {
      input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } },
    },
    sources = {
      files = { exclude = exclude },
      grep = { exclude = exclude },
      explorer = {
        hidden = true,
        actions = { explorer_paste = explorer_paste },
        win = {
          list = {
            keys = {
              ["-"] = "edit_split",
              ["|"] = "edit_vsplit",
              ["M"] = "toggle_maximize",
            },
          },
        },
      },
    },
  },
  explorer = { replace_netrw = true },
  indent = { animate = { enabled = false } },
  input = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  words = { enabled = true },

  -- 끈 모듈 (기본값이 켜져 있는 것들을 명시적으로 끔) ----------------------
  dashboard = { enabled = false },
  scroll = { enabled = false }, -- 부드러운 스크롤 — tmux에서 잔상이 남아 끔
  statuscolumn = { enabled = false },
  zen = {
    enabled = true,
    toggles = { dim = false, git_signs = false, mini_diff_signs = false },
    show = { statusline = false, tabline = false },
    win = {
      width = 120,
      wo = { number = true, relativenumber = true, signcolumn = "yes" },
    },
  },

  styles = {
    notification = { wo = { wrap = true } },
  },
})

-- 키맵 ----------------------------------------------------------------------
local map = vim.keymap.set

-- 파일
map("n", "<leader><space>", function()
  Snacks.picker.smart()
end, { desc = "Smart find files" })
map("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Find files" })
map("n", "<leader>fr", function()
  Snacks.picker.recent()
end, { desc = "Recent files" })
map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>fc", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find config file" })
map("n", "<leader>fp", function()
  Snacks.picker.projects()
end, { desc = "Projects" })
map("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Explorer" })
map("n", "<leader>uz", function()
  Snacks.zen()
end, { desc = "Toggle focus mode" })

-- 검색
map("n", "<leader>sg", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
map("n", "<leader>sw", function()
  Snacks.picker.grep_word()
end, { desc = "Grep word under cursor" })
map("v", "<leader>sw", function()
  Snacks.picker.grep_word()
end, { desc = "Grep selection" })
map("n", "<leader>sb", function()
  Snacks.picker.lines()
end, { desc = "Search in buffer" })
map("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sh", function()
  Snacks.picker.help()
end, { desc = "Help pages" })
map("n", "<leader>sc", function()
  Snacks.picker.command_history()
end, { desc = "Command history" })
map("n", "<leader>sr", function()
  Snacks.picker.resume()
end, { desc = "Resume last picker" })
map("n", "<leader>sn", function()
  Snacks.picker.notifications()
end, { desc = "Notification history" })

-- 진단
map("n", "<leader>xx", function()
  Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer diagnostics" })
map("n", "<leader>xX", function()
  Snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics" })

-- 버퍼
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete other buffers" })

-- 이름 바꾸기 (LSP에 파일 이동을 알림)
map("n", "<leader>fR", function()
  Snacks.rename.rename_file()
end, { desc = "Rename file" })
