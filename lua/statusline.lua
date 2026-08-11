-- ============================================================================
-- statusline (직접 작성)
-- ============================================================================
--   NORMAL  main +2 ~1 -0   lua/plugins.lua           1  2   lua  62%  12:4
--  └──────┘└────────────┘ └──────────────┘         └────┘  └──┘└───┘└───┘
--   모드      git 상태        파일 경로              진단    ft  진행  위치
--
-- vim.o.statusline이 이 모듈의 render()를 매 리드로우마다 호출한다.
-- laststatus=3(전역)이라 창마다 그리지 않는다.
-- ============================================================================

local c = require("theme").colors
local icons = require("icons")

-- 하이라이트 정의 -----------------------------------------------------------
-- 모드 블록은 배경색으로 채우고, 나머지는 mantle 바탕에 글자색만 바꾼다.
local function hl(name, spec)
  vim.api.nvim_set_hl(0, name, spec)
end

local function define_highlights()
  local bg = c.mantle

  hl("StBase", { fg = c.text, bg = bg })
  hl("StDim", { fg = c.overlay1, bg = bg })
  hl("StPath", { fg = c.text, bg = bg })
  hl("StModified", { fg = c.peach, bg = bg })

  hl("StGitBranch", { fg = c.mauve, bg = bg, bold = true })
  hl("StGitAdd", { fg = c.green, bg = bg })
  hl("StGitChange", { fg = c.yellow, bg = bg })
  hl("StGitDelete", { fg = c.red, bg = bg })

  hl("StDiagError", { fg = c.red, bg = bg })
  hl("StDiagWarn", { fg = c.peach, bg = bg })
  hl("StDiagInfo", { fg = c.sky, bg = bg })
  hl("StDiagHint", { fg = c.teal, bg = bg })

  hl("StFiletype", { fg = c.blue, bg = bg, bold = true })
  hl("StProgress", { fg = c.subtext0, bg = c.surface0 })
  hl("StLocation", { fg = c.base, bg = c.blue, bold = true })

  -- 모드별 블록
  hl("StModeNormal", { fg = c.base, bg = c.blue, bold = true })
  hl("StModeInsert", { fg = c.base, bg = c.green, bold = true })
  hl("StModeVisual", { fg = c.base, bg = c.mauve, bold = true })
  hl("StModeReplace", { fg = c.base, bg = c.red, bold = true })
  hl("StModeCommand", { fg = c.base, bg = c.peach, bold = true })
  hl("StModeTerminal", { fg = c.base, bg = c.teal, bold = true })

  -- 상태줄 전체 바탕
  hl("StatusLine", { fg = c.text, bg = bg })
end

-- 모드 ----------------------------------------------------------------------
local modes = {
  ["n"] = { "NORMAL", "StModeNormal" },
  ["no"] = { "PENDING", "StModeNormal" },
  ["niI"] = { "NORMAL", "StModeNormal" },
  ["niR"] = { "NORMAL", "StModeNormal" },
  ["i"] = { "INSERT", "StModeInsert" },
  ["ic"] = { "INSERT", "StModeInsert" },
  ["ix"] = { "INSERT", "StModeInsert" },
  ["v"] = { "VISUAL", "StModeVisual" },
  ["vs"] = { "VISUAL", "StModeVisual" },
  ["V"] = { "V-LINE", "StModeVisual" },
  ["Vs"] = { "V-LINE", "StModeVisual" },
  ["\22"] = { "V-BLOCK", "StModeVisual" },
  ["\22s"] = { "V-BLOCK", "StModeVisual" },
  ["s"] = { "SELECT", "StModeVisual" },
  ["S"] = { "S-LINE", "StModeVisual" },
  ["\19"] = { "S-BLOCK", "StModeVisual" },
  ["R"] = { "REPLACE", "StModeReplace" },
  ["Rc"] = { "REPLACE", "StModeReplace" },
  ["Rv"] = { "V-REPLACE", "StModeReplace" },
  ["c"] = { "COMMAND", "StModeCommand" },
  ["cv"] = { "EX", "StModeCommand" },
  ["r"] = { "PROMPT", "StModeCommand" },
  ["rm"] = { "MORE", "StModeCommand" },
  ["r?"] = { "CONFIRM", "StModeCommand" },
  ["!"] = { "SHELL", "StModeTerminal" },
  ["t"] = { "TERMINAL", "StModeTerminal" },
  ["nt"] = { "TERMINAL", "StModeTerminal" },
}

local function mode()
  local m = modes[vim.api.nvim_get_mode().mode] or { "UNKNOWN", "StModeNormal" }
  return ("%%#%s# %s %%#StBase#"):format(m[2], m[1])
end

-- git -----------------------------------------------------------------------
local function git()
  local dict = vim.b.gitsigns_status_dict
  if not dict or not dict.head or dict.head == "" then
    return ""
  end

  local parts = { ("%%#StGitBranch# %s %s"):format(icons.git.branch, dict.head) }
  local counts = {
    { dict.added, "StGitAdd", icons.git.added },
    { dict.changed, "StGitChange", icons.git.changed },
    { dict.removed, "StGitDelete", icons.git.removed },
  }
  for _, item in ipairs(counts) do
    local n = item[1]
    if n and n > 0 then
      parts[#parts + 1] = ("%%#%s# %s%d"):format(item[2], item[3], n)
    end
  end
  return table.concat(parts) .. "%#StBase# "
end

-- 파일 경로 -----------------------------------------------------------------
local function file()
  local name = vim.fn.expand("%:.")
  if name == "" then
    return "%#StDim# [No Name] "
  end
  -- 경로가 길면 앞쪽 디렉터리를 한 글자로 줄인다: lua/plugins/foo.lua → l/p/foo.lua
  if #name > 45 then
    name = vim.fn.pathshorten(name)
  end
  local out = ("%%#StPath# %s"):format(name)
  if vim.bo.modified then
    out = out .. "%#StModified# " .. icons.file.modified
  end
  if vim.bo.readonly or not vim.bo.modifiable then
    out = out .. "%#StDim# " .. icons.file.readonly
  end
  return out .. "%#StBase# "
end

-- 진단 ----------------------------------------------------------------------
local severity = {
  { vim.diagnostic.severity.ERROR, "StDiagError", icons.diagnostics.error },
  { vim.diagnostic.severity.WARN, "StDiagWarn", icons.diagnostics.warn },
  { vim.diagnostic.severity.INFO, "StDiagInfo", icons.diagnostics.info },
  { vim.diagnostic.severity.HINT, "StDiagHint", icons.diagnostics.hint },
}

local function diagnostics()
  local counts = vim.diagnostic.count(0)
  local parts = {}
  for _, item in ipairs(severity) do
    local n = counts[item[1]]
    if n and n > 0 then
      parts[#parts + 1] = ("%%#%s#%s%d"):format(item[2], item[3], n)
    end
  end
  if #parts == 0 then
    return ""
  end
  return table.concat(parts, " ") .. "%#StBase# "
end

-- LSP 클라이언트 ------------------------------------------------------------
local function lsp()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end
  local names = vim.tbl_map(function(client)
    return client.name
  end, clients)
  return ("%%#StDim# %s %s "):format(icons.lsp, table.concat(names, ","))
end

-- 파일 타입 -----------------------------------------------------------------
local function filetype()
  local ft = vim.bo.filetype
  if ft == "" then
    return ""
  end
  local ok, icons = pcall(require, "mini.icons")
  local icon = ""
  if ok then
    icon = icons.get("filetype", ft) .. " "
  end
  return ("%%#StFiletype# %s%s "):format(icon, ft)
end

-- 렌더 ----------------------------------------------------------------------
local M = {}

function M.render()
  return table.concat({
    mode(),
    git(),
    file(),
    "%=", -- 여기서 좌/우 분리
    diagnostics(),
    lsp(),
    filetype(),
    "%#StProgress# %P ",
    "%#StLocation# %l:%c ",
  })
end

define_highlights()
vim.o.statusline = "%!v:lua.require'statusline'.render()"

-- 컬러스킴이 바뀌면 하이라이트를 다시 잡는다
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("statusline_hl", { clear = true }),
  callback = define_highlights,
})

return M
