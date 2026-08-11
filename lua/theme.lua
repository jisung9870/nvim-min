-- ============================================================================
-- 테마: catppuccin mocha + 직접 손본 하이라이트
-- ============================================================================
-- 팔레트는 M.colors로 노출한다. statusline이 여기서 색을 읽어 간다.
-- ============================================================================

local icons = require("icons")

local M = {}

require("catppuccin").setup({
  flavour = "mocha",
  background = { light = "latte", dark = "mocha" },
  transparent_background = false,
  show_end_of_buffer = false,
  term_colors = true,
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
    keywords = { "italic" },
    functions = { "bold" },
    booleans = { "bold" },
    types = { "bold" },
  },
  color_overrides = {
    mocha = {
      base = "#1e1e2e",
      mantle = "#181825",
      crust = "#11111b",
    },
  },
  custom_highlights = function(c)
    return {
      -- 주석: 기본값보다 밝게 (야간 작업)
      Comment = { fg = "#9399b2", style = { "italic" } },

      LineNr = { fg = c.overlay0 },
      CursorLineNr = { fg = c.pink, style = { "bold" } },
      CursorLine = { bg = "#2a2b3c" },

      Search = { bg = c.surface2, fg = c.text, style = { "bold" } },
      IncSearch = { bg = c.pink, fg = c.base, style = { "bold" } },
      Visual = { bg = c.surface1, style = { "bold" } },

      -- 둥근 float 테두리 — NvChad 느낌의 핵심
      VertSplit = { fg = c.surface1 },
      WinSeparator = { fg = c.surface1 },
      FloatBorder = { fg = c.blue, bg = c.base },
      NormalFloat = { bg = c.base },

      Todo = { fg = c.yellow, bg = "NONE", style = { "bold", "italic" } },

      DiagnosticError = { fg = c.red },
      DiagnosticWarn = { fg = c.peach },
      DiagnosticInfo = { fg = c.sky },
      DiagnosticHint = { fg = c.teal },

      LspReferenceText = { bg = c.surface0 },
      LspReferenceRead = { bg = c.surface0 },
      LspReferenceWrite = { bg = c.surface0 },

      SnacksIndent = { fg = c.surface0 },
      SnacksIndentScope = { fg = c.surface2 },

      -- DevOps 파일 타입 강조
      ["@property.yaml"] = { fg = c.blue, style = { "bold" } },
      ["@type.hcl"] = { fg = c.mauve },
    }
  end,
  integrations = {
    blink_cmp = true,
    gitsigns = true,
    diffview = true,
    mason = true,
    markdown = true,
    mini = { enabled = true, indentscope_color = "" },
    native_lsp = {
      enabled = true,
      underlines = {
        errors = { "undercurl" },
        warnings = { "undercurl" },
        hints = { "undercurl" },
        information = { "undercurl" },
      },
    },
    snacks = { enabled = true },
    treesitter = true,
    which_key = true,
  },
})

vim.cmd.colorscheme("catppuccin")

M.colors = require("catppuccin.palettes").get_palette("mocha")
M.colors.base = "#1e1e2e"
M.colors.mantle = "#181825"
M.colors.crust = "#11111b"

-- 진단 표시 (nvim 0.11+ 형식)
vim.diagnostic.config({
  severity_sort = true,
  underline = { severity = vim.diagnostic.severity.ERROR },
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.diagnostics.error,
      [vim.diagnostic.severity.WARN] = icons.diagnostics.warn,
      [vim.diagnostic.severity.INFO] = icons.diagnostics.info,
      [vim.diagnostic.severity.HINT] = icons.diagnostics.hint,
    },
  },
  float = { border = "rounded", source = "if_many" },
})

-- 모든 float 창을 둥근 테두리로 (hover, signature 등)
vim.o.winborder = "rounded"

return M
