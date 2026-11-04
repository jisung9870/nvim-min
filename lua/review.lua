-- ============================================================================
-- 리뷰 의견: 코드 줄에 의견을 달아 두었다가 한 번에 에이전트에게 보낸다
-- ============================================================================
--   <leader>ar  현재 줄(normal)이나 선택 범위(visual)에 의견 추가
--   <leader>aR  보내지 않은 의견을 모두 활성 Sidekick CLI로 전송 (Enter는 누르지 않는다)
--   <leader>aC  의견 모두 지우기
-- 의견은 extmark로 저장해 편집해도 위치를 따라간다.
-- ============================================================================

local M = {}

local ns = vim.api.nvim_create_namespace("review_comments")

---@class review.Comment
---@field bufnr integer
---@field mark integer extmark id
---@field text string
---@field sent boolean

---@type review.Comment[]
M.comments = {}

local MAX_CODE_LINES = 3
local MAX_CODE_WIDTH = 200

-- 에이전트로 보낼 메시지를 만든다 (순수 함수).
---@param items { path: string, first: integer, last: integer, code: string[], text: string }[]
---@return string
function M.format_message(items)
  local out = { ("리뷰 의견 %d건. 각 위치를 고쳐줘."):format(#items), "" }
  for i, item in ipairs(items) do
    local range = item.first == item.last and tostring(item.first) or ("%d-%d"):format(item.first, item.last)
    out[#out + 1] = ("%d. %s:%s"):format(i, item.path, range)
    for n, line in ipairs(item.code) do
      if n > MAX_CODE_LINES then
        break
      end
      out[#out + 1] = "     " .. line:sub(1, MAX_CODE_WIDTH)
    end
    out[#out + 1] = "   의견: " .. item.text
  end
  return table.concat(out, "\n")
end

local function define_highlights()
  local t = require("theme").rebuild()
  vim.api.nvim_set_hl(0, "ReviewComment", { fg = t.warn, italic = true })
  vim.api.nvim_set_hl(0, "ReviewCommentSent", { fg = t.fg_dim, italic = true })
end

-- extmark의 현재 위치 (1-based, 양끝 포함). 지워진 의견은 nil.
local function position(comment)
  if not vim.api.nvim_buf_is_valid(comment.bufnr) then
    return nil
  end
  local mark = vim.api.nvim_buf_get_extmark_by_id(comment.bufnr, ns, comment.mark, { details = true })
  if #mark == 0 or mark[3].invalid then
    return nil
  end
  local first = mark[1] + 1
  local last = math.max((mark[3].end_row or mark[1]) + 1, first)
  return first, last
end

local function draw(comment, first, last)
  local line_count = vim.api.nvim_buf_line_count(comment.bufnr)
  last = math.min(last, line_count)
  vim.api.nvim_buf_set_extmark(comment.bufnr, ns, first - 1, 0, {
    id = comment.mark,
    end_row = last - 1,
    virt_text = { { "▍ " .. comment.text, comment.sent and "ReviewCommentSent" or "ReviewComment" } },
    virt_text_pos = "eol",
    invalidate = true,
    undo_restore = false,
  })
end

function M.pending_count()
  local n = 0
  for _, comment in ipairs(M.comments) do
    if not comment.sent and position(comment) then
      n = n + 1
    end
  end
  return n
end

---@param first integer
---@param last integer
function M.add(first, last)
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(bufnr) == "" or vim.bo[bufnr].buftype ~= "" then
    return vim.notify("파일 버퍼에서만 의견을 달 수 있다", vim.log.levels.WARN)
  end
  if first > last then
    first, last = last, first
  end
  vim.ui.input(
    { prompt = ("리뷰 의견 (%d%s): "):format(first, first == last and "" or ("-" .. last)) },
    function(text)
      if not text or vim.trim(text) == "" or not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local comment = { bufnr = bufnr, text = vim.trim(text), sent = false }
      comment.mark = vim.api.nvim_buf_set_extmark(bufnr, ns, first - 1, 0, { end_row = last - 1 })
      draw(comment, first, last)
      M.comments[#M.comments + 1] = comment
      vim.cmd.redrawstatus()
    end
  )
end

function M.send()
  local items, pending = {}, {}
  for _, comment in ipairs(M.comments) do
    local first, last = position(comment)
    if not comment.sent and first then
      local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(comment.bufnr), ":.")
      local code =
        vim.api.nvim_buf_get_lines(comment.bufnr, first - 1, math.min(last, first + MAX_CODE_LINES - 1), false)
      items[#items + 1] = { path = path, first = first, last = last, code = code, text = comment.text }
      pending[#pending + 1] = { comment = comment, first = first, last = last }
    end
  end
  if #items == 0 then
    return vim.notify("보낼 리뷰 의견이 없다", vim.log.levels.INFO)
  end

  -- text를 직접 주면 Sidekick이 {…} 치환을 하지 않아 코드의 중괄호가 그대로 간다
  local text = {}
  for _, line in ipairs(vim.split(M.format_message(items), "\n", { plain = true })) do
    text[#text + 1] = { { line } }
  end

  -- cli.send는 실제로 보냈는지 알려 주지 않는다. 세션이 선택될 때만 불리는 콜백에서 직접 보내고,
  -- 그때에만 sent로 표시한다 (세션 선택을 취소하면 의견은 그대로 남는다).
  require("sidekick.cli.state").with(function(state)
    if not (state and state.session and state.tool) then
      return
    end
    vim.schedule(function()
      local ok = pcall(function()
        state.session:send(state.tool:format(text) .. "\n")
      end)
      if not ok then
        return vim.notify("AI 세션에 보내지 못했다. 의견은 그대로 남아 있다.", vim.log.levels.WARN)
      end
      for _, p in ipairs(pending) do
        p.comment.sent = true
        draw(p.comment, p.first, p.last)
      end
      vim.cmd.redrawstatus()
      vim.notify(("리뷰 의견 %d건을 입력창에 넣었다. 확인한 뒤 Enter로 보내라."):format(#items))
    end)
  end, { attach = true, show = true, focus = false })
end

function M.clear()
  for _, comment in ipairs(M.comments) do
    if vim.api.nvim_buf_is_valid(comment.bufnr) then
      vim.api.nvim_buf_del_extmark(comment.bufnr, ns, comment.mark)
    end
  end
  M.comments = {}
  vim.cmd.redrawstatus()
end

define_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("review_hl", { clear = true }),
  callback = define_highlights,
})

vim.keymap.set("n", "<leader>ar", function()
  local line = vim.fn.line(".")
  M.add(line, line)
end, { desc = "Review comment (line)" })
vim.keymap.set("x", "<leader>ar", function()
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  vim.cmd("normal! \27")
  M.add(first, last)
end, { desc = "Review comment (selection)" })
vim.keymap.set("n", "<leader>aR", M.send, { desc = "Send review comments" })
vim.keymap.set("n", "<leader>aC", M.clear, { desc = "Clear review comments" })

return M
