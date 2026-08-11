-- ============================================================================
-- Markdown: Neovim 내부 렌더링
-- ============================================================================
-- 일반 모드에서는 제목, 목록, 체크박스, 표, 코드 블록을 보기 좋게 표시하고
-- 입력 모드에서는 원문 마크업을 그대로 보여 편집을 방해하지 않는다.
-- ============================================================================

local render = require("render-markdown")

render.setup({
  completions = {
    lsp = { enabled = true },
  },
  html = { enabled = false },
  latex = { enabled = false },
})

vim.keymap.set("n", "<leader>um", render.toggle, { desc = "Toggle Markdown rendering" })
