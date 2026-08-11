-- ============================================================================
-- 자동완성 (blink.cmp)
-- ============================================================================
-- 릴리스 태그(v1.x)를 따라가므로 Rust 바이너리가 미리 빌드된 걸 받는다.
-- 소스 빌드가 필요 없다 (cargo 불필요).
--
-- 키: <C-space> 열기 / <Tab> 다음 / <S-Tab> 이전 / <CR> 확정 / <C-e> 닫기
-- ============================================================================

require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
  },

  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    accept = { auto_brackets = { enabled = true } },
    menu = {
      border = "rounded",
      draw = {
        treesitter = { "lsp" },
        columns = {
          { "kind_icon" },
          { "label", "label_description", gap = 1 },
          { "source_name" },
        },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      window = { border = "rounded" },
    },
    ghost_text = { enabled = false },
  },

  signature = {
    enabled = true,
    window = { border = "rounded" },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },

  cmdline = {
    enabled = true,
    completion = { menu = { auto_show = true } },
  },
})
