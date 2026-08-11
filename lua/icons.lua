-- ============================================================================
-- 아이콘
-- ============================================================================
-- Nerd Font 글리프는 사설 영역(PUA) 코드포인트라 편집기/도구를 거치면서
-- 조용히 날아가는 일이 있다. 그래서 문자를 직접 넣지 않고 \u{...} 로 박는다.
-- 코드포인트는 https://www.nerdfonts.com/cheat-sheet 에서 확인.
--
-- 필요 폰트: Nerd Font 패치본 (예: JetBrainsMono Nerd Font)
-- ============================================================================

return {
  diagnostics = {
    error = "\u{f057}", -- nf-fa-times_circle
    warn = "\u{f071}", -- nf-fa-warning
    info = "\u{f05a}", -- nf-fa-info_circle
    hint = "\u{f0eb}", -- nf-fa-lightbulb_o
  },

  git = {
    branch = "\u{e0a0}", -- powerline branch
    added = "+",
    changed = "~",
    removed = "-",
  },

  -- gitsigns 사인 컬럼 (일반 유니코드 — 폰트 없어도 깨지지 않음)
  signs = {
    add = "▎",
    change = "▎",
    delete = "▁",
    topdelete = "▔",
    changedelete = "▎",
    untracked = "▎",
  },

  file = {
    modified = "●",
    readonly = "\u{f023}", -- nf-fa-lock
  },

  lsp = "\u{f085}", -- nf-fa-cogs

  fold = {
    open = "▾",
    close = "▸",
  },
}
