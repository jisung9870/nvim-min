-- ============================================================================
-- 테마: catppuccin + 시맨틱 토큰
-- ============================================================================
-- 색을 쓰는 쪽(statusline 등)은 catppuccin 고유 이름(mauve / peach / surface0 …)을
-- 모른다. 아래 M.rebuild()의 매핑 한 곳만 팔레트를 안다. 테마를 갈아끼우면
-- 고칠 곳도 이 파일 하나다.
--
--   M.tokens      의미 이름 → 색. 항상 같은 테이블이라 캐싱해도 된다.
--   M.rebuild()   현재 background에 맞춰 토큰을 다시 채우고 M.tokens를 돌려준다.
--
-- 플레이버는 vim.o.background에서 파생된다. background를 바꾸면 nvim이
-- 컬러스킴을 다시 읽고(:h 'background'), ColorScheme에서 rebuild()가 돈다.
-- ============================================================================

local icons = require("icons")

local M = {}

M.tokens = {}

-- 기본 팔레트에서 바꾼 값. setup()과 rebuild()가 같은 표를 본다.
local color_overrides = {
  mocha = {
    base = "#1e1e2e",
    mantle = "#181825",
    crust = "#11111b",
  },
}

local function flavour()
  return vim.o.background == "light" and "latte" or "mocha"
end

-- 팔레트에 없는 중간 톤을 만든다 (CursorLine 등). alpha는 fg 쪽 비중.
local function blend(fg, bg, alpha)
  local function channel(offset)
    local f = tonumber(fg:sub(offset, offset + 1), 16)
    local b = tonumber(bg:sub(offset, offset + 1), 16)
    return math.floor(f * alpha + b * (1 - alpha) + 0.5)
  end
  return ("#%02x%02x%02x"):format(channel(2), channel(4), channel(6))
end

require("catppuccin").setup({
  flavour = "auto", -- background에서 결정 (light → latte, dark → mocha)
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
  color_overrides = color_overrides,
  custom_highlights = function(c)
    return {
      -- 주석: 기본값보다 밝게 (야간 작업)
      Comment = { fg = c.overlay2, style = { "italic" } },

      LineNr = { fg = c.overlay0 },
      CursorLineNr = { fg = c.pink, style = { "bold" } },
      CursorLine = { bg = blend(c.surface0, c.base, 0.55) },

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

--- 현재 background에 맞는 팔레트를 읽어 시맨틱 토큰을 갱신한다.
--- M.tokens 테이블을 제자리에서 고치므로 한 번 잡아둔 참조도 계속 유효하다.
function M.rebuild()
  -- get_palette는 위에서 넘긴 color_overrides를 이미 반영해서 돌려준다.
  local c = require("catppuccin.palettes").get_palette(flavour())
  local t = M.tokens

  -- 표면
  t.bg = c.base
  t.bar = c.mantle -- statusline 바탕
  t.raised = c.surface0 -- 바 위에 한 단계 올라온 블록
  t.border = c.surface1

  -- 글자
  t.fg = c.text
  t.fg_muted = c.subtext0
  t.fg_dim = c.overlay1
  t.fg_on_accent = c.base -- 강조색 배경 위에 얹는 글자

  -- 강조
  -- binbox-cli TUI는 다른 보라 계열(#5B50D6 / #A78BFA)을 쓴다. 그쪽은 대비비가
  -- 측정·문서화되어 있어 억지로 맞추지 않았다. 맞출 일이 생기면 아래 두 줄이
  -- 유일한 변경 지점이다.
  t.accent = c.blue
  t.accent_alt = c.mauve

  -- 상태
  t.ok = c.green
  t.info = c.sky
  t.warn = c.peach
  t.err = c.red
  t.hint = c.teal
  t.modified = c.peach

  -- git
  t.git_branch = c.mauve
  t.git_added = c.green
  t.git_changed = c.yellow
  t.git_removed = c.red

  -- 모드
  t.mode_normal = c.blue
  t.mode_insert = c.green
  t.mode_visual = c.mauve
  t.mode_replace = c.red
  t.mode_command = c.peach
  t.mode_terminal = c.teal

  return t
end

M.rebuild()

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
