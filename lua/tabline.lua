-- ==========================================================================
-- 상단 파일 버퍼 바
-- ==========================================================================

local theme = require("theme")

local function hl(name, spec)
  vim.api.nvim_set_hl(0, name, spec)
end

local function define_highlights()
  local t = theme.rebuild and theme.rebuild()
    or {
      fg_on_accent = theme.colors.base,
      accent = theme.colors.blue,
      fg_muted = theme.colors.subtext0,
      fg_dim = theme.colors.overlay1,
      bar = theme.colors.mantle,
    }
  hl("TbActive", { fg = t.fg_on_accent, bg = t.accent, bold = true })
  hl("TbInactive", { fg = t.fg_muted, bg = t.bar })
  hl("TbFill", { fg = t.fg_dim, bg = t.bar })
end

local function listed_buffers()
  return vim.tbl_filter(function(buf)
    return vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
  end, vim.api.nvim_list_bufs())
end

local function label(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  name = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")
  return name:gsub("%%", "%%%%")
end

local M = {}

function M.click(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_set_current_buf(buf)
  end
end

function M.render()
  local current = vim.api.nvim_get_current_buf()
  local parts = {}

  for _, buf in ipairs(listed_buffers()) do
    local active = buf == current
    local group = active and "TbActive" or "TbInactive"
    local modified = vim.bo[buf].modified and " ●" or ""
    parts[#parts + 1] = ("%%#%s#%%%d@v:lua.require'tabline'.click@ %s%s %%T"):format(group, buf, label(buf), modified)
  end

  parts[#parts + 1] = "%#TbFill#%="
  return table.concat(parts)
end

define_highlights()
vim.o.showtabline = 2
vim.o.tabline = "%!v:lua.require'tabline'.render()"

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("tabline_hl", { clear = true }),
  callback = define_highlights,
})

return M
