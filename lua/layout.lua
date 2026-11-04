-- ============================================================================
-- 화면 너비에 맞춘 배치: Sidekick 패널 너비, Diffview 레이아웃, 리사이즈 처리
-- ============================================================================

local M = {}

M.sidekick = { ratio = 0.4, min = 50, max = 72 }
-- columns가 이 값보다 작으면 diff를 세로(위아래)로 놓는다 / 파일 패널을 닫은 채 연다
M.diffview = { vertical_below = 140, panel_closed_below = 100 }

-- Sidekick 패널 너비: 화면의 40%, 50~72칸
---@param columns integer
---@return integer
function M.sidekick_width(columns)
  local width = math.floor(columns * M.sidekick.ratio)
  return math.max(M.sidekick.min, math.min(M.sidekick.max, width))
end

---@param columns integer
---@return { layout: "diff2_horizontal"|"diff2_vertical", panel_open: boolean }
function M.diffview_layout(columns)
  return {
    layout = columns < M.diffview.vertical_below and "diff2_vertical" or "diff2_horizontal",
    panel_open = columns >= M.diffview.panel_closed_below,
  }
end

-- 열려 있는 Sidekick 창과 다음에 열 창의 너비를 현재 화면에 맞춘다.
function M.update_sidekick_width()
  local width = M.sidekick_width(vim.o.columns)
  local ok, config = pcall(require, "sidekick.config")
  if ok and config.cli and config.cli.win and config.cli.win.split then
    config.cli.win.split.width = width
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[win].sidekick_cli then
      pcall(vim.api.nvim_win_set_width, win, width)
    end
  end
end

-- 모든 탭의 창을 균등하게 맞추되 winfixwidth 창(diffview 파일 패널, sidekick)은
-- 너비를 유지한다.
function M.equalize()
  local current = vim.api.nvim_get_current_tabpage()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local fixed = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.wo[win].winfixwidth then
        fixed[win] = vim.api.nvim_win_get_width(win)
      end
    end
    vim.api.nvim_set_current_tabpage(tab)
    vim.cmd("wincmd =")
    for win, width in pairs(fixed) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_set_width, win, width)
      end
    end
  end
  vim.api.nvim_set_current_tabpage(current)
end

return M
