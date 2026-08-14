-- ============================================================================
-- 키맵 (플러그인별 키맵은 각 모듈 안에 있다)
-- ============================================================================

local map = vim.keymap.set

-- nvim 0.11 기본 LSP 매핑(grn/gra/grr/gri/grt) 제거.
-- 이게 남아 있으면 `gr`(references)이 프리픽스가 되어 timeoutlen만큼 멈춘다.
-- 같은 기능은 lsp.lua에서 gd/gr/gI/gy, <leader>cr, <leader>ca로 제공한다.
for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
  pcall(vim.keymap.del, "n", lhs)
end

-- Insert 모드 탈출
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- 버퍼 이동: deployment.yaml → service.yaml → ingress.yaml 사이를 H/L로
map("n", "H", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- 들여쓰기 후 선택 유지 (YAML 블록 반복 조정)
map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

-- 검색 결과를 화면 중앙에
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- 라인 합치기 시 커서 위치 유지
map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- 비주얼 붙여넣기가 레지스터를 덮어쓰지 않게
map("v", "p", '"_dP', { desc = "Paste without overwriting register" })

-- 줄 이동
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- 창 분할
map("n", "<leader>-", "<C-w>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split window right" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })

-- 창 크기
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- 저장 / 종료
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- 하이라이트 지우기
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- 코드
map({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Prev diagnostic" })
map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })
map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev error" })

-- 토글
map("n", "<leader>uf", "<cmd>FormatToggle<cr>", { desc = "Toggle autoformat (global)" })
map("n", "<leader>uF", "<cmd>FormatToggle!<cr>", { desc = "Toggle autoformat (buffer)" })
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })
map("n", "<leader>ul", function()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = vim.wo.number
end, { desc = "Toggle line numbers" })
map("n", "<leader>ud", function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify("진단: " .. tostring(not enabled))
end, { desc = "Toggle diagnostics" })
local compact_diagnostics = vim.deepcopy(vim.diagnostic.config().virtual_text)
local diagnostic_lines = false
map("n", "<leader>uv", function()
  diagnostic_lines = not diagnostic_lines
  local virtual_lines = false
  local virtual_text = compact_diagnostics
  if diagnostic_lines then
    virtual_lines = { current_line = true }
    virtual_text = false
  end
  vim.diagnostic.config({
    virtual_lines = virtual_lines,
    virtual_text = virtual_text,
  })
  vim.notify("진단 상세 줄: " .. tostring(diagnostic_lines))
end, { desc = "Toggle diagnostic virtual lines" })
-- background를 바꾸면 nvim이 컬러스킴을 다시 읽고(:h 'background'),
-- theme이 latte/mocha 중 맞는 팔레트로 토큰을 다시 채운다.
map("n", "<leader>ub", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
  vim.notify("배경: " .. vim.o.background)
end, { desc = "Toggle light/dark background" })

-- 설정 관리
map("n", "<leader>cp", "<cmd>PackStatus<cr>", { desc = "Plugin status" })
map("n", "<leader>cu", "<cmd>PackUpdate<cr>", { desc = "Plugin update" })

-- markdown을 Typora로 (macOS)
map("n", "<leader>mt", function()
  if vim.fn.has("mac") == 0 then
    vim.notify("Typora keymap is macOS only", vim.log.levels.WARN)
    return
  end
  if vim.bo.filetype ~= "markdown" then
    vim.notify("Not a markdown file", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ "open", "-a", "Typora", vim.fn.expand("%:p") }, { detach = true })
end, { desc = "Open in Typora" })
