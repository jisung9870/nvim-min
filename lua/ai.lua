-- ============================================================================
-- AI 사이드바: Sidekick으로 Claude Code와 Codex CLI를 같은 UX로 제공한다.
-- Copilot 기반 Next Edit Suggestions는 사용하지 않고 CLI 패널만 활성화한다.
-- ============================================================================

require("sidekick").setup({
  nes = { enabled = false },
  copilot = { status = { enabled = false } },
  cli = {
    watch = true,
    win = {
      layout = "right",
      split = { width = 72, height = 0 },
      keys = {
        hide_ctrl_q = { "<c-q>", "hide", mode = { "n", "t" }, desc = "hide the AI panel" },
        stopinsert = false,
      },
    },
    mux = {
      enabled = vim.fn.executable("tmux") == 1,
      backend = "tmux",
      create = "terminal",
    },
    tools = {
      claude = {},
      codex = {},
    },
  },
})

local cli = require("sidekick.cli")
local map = vim.keymap.set

local tools = {
  { name = "claude", label = "Claude Code" },
  { name = "codex", label = "Codex" },
}

local function toggle(name)
  if vim.fn.executable(name) == 0 then
    vim.notify(name .. " CLI를 찾을 수 없습니다", vim.log.levels.WARN)
    return
  end
  cli.toggle({ name = name, focus = true })
end

local function select_tool()
  local installed = vim.tbl_filter(function(tool)
    return vim.fn.executable(tool.name) == 1
  end, tools)
  if #installed == 0 then
    vim.notify("Claude Code 또는 Codex CLI를 찾을 수 없습니다", vim.log.levels.WARN)
    return
  end
  vim.ui.select(installed, {
    prompt = "AI agent",
    format_item = function(tool)
      return tool.label
    end,
  }, function(tool)
    if tool then
      toggle(tool.name)
    end
  end)
end

local function send_context()
  local msg = "Current context:\n{this}"
  local diagnostics = vim.diagnostic.get(0)
  if #diagnostics > 0 then
    local lines = vim.tbl_map(function(item)
      return ("L%d: %s"):format(item.lnum + 1, item.message)
    end, diagnostics)
    msg = msg .. "\n\nDiagnostics:\n" .. table.concat(lines, "\n")
  end
  cli.send({ msg = msg })
end

map("n", "<leader>aa", select_tool, { desc = "Select AI agent" })
map({ "n", "x" }, "<leader>ac", function()
  toggle("claude")
end, { desc = "Toggle Claude Code" })
map({ "n", "x" }, "<leader>ax", function()
  toggle("codex")
end, { desc = "Toggle Codex" })
map("n", "<leader>af", function()
  cli.send({ msg = "{file}" })
end, { desc = "Send current file" })
map({ "n", "x" }, "<leader>at", send_context, { desc = "Send current context" })
map("x", "<leader>av", function()
  cli.send({ msg = "{selection}" })
end, { desc = "Send visual selection" })
map({ "n", "x" }, "<leader>ap", function()
  cli.prompt()
end, { desc = "Select AI prompt" })
map("n", "<leader>aq", function()
  cli.close()
end, { desc = "Detach AI agent" })
