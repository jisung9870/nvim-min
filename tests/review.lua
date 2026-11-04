-- 리뷰 의견 메시지 형식과 extmark 추적 시험
--   nvim --headless -u NONE -l tests/review.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")))
vim.opt.runtimepath:prepend(root)
-- theme는 catppuccin이 필요하므로 시험에서는 토큰만 흉내 낸다
package.loaded.theme = {
  rebuild = function()
    return { warn = "#ffaa00", fg_dim = "#888888" }
  end,
}
local review = require("review")

local failures = 0
local function eq(name, got, want)
  if vim.inspect(got) == vim.inspect(want) then
    print("ok   " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n  got:  " .. vim.inspect(got) .. "\n  want: " .. vim.inspect(want))
  end
end

eq(
  "메시지 형식",
  review.format_message({
    { path = "lua/a.lua", first = 3, last = 3, code = { "local x = 1" }, text = "이름을 바꿔줘" },
    { path = "b.py", first = 10, last = 14, code = { "a", "b", "c", "d" }, text = "분리" },
  }),
  table.concat({
    "리뷰 의견 2건. 각 위치를 고쳐줘.",
    "",
    "1. lua/a.lua:3",
    "     local x = 1",
    "   의견: 이름을 바꿔줘",
    "2. b.py:10-14",
    "     a",
    "     b",
    "     c",
    "   의견: 분리",
  }, "\n")
)

-- extmark가 편집을 따라가는지 (vim.ui.input을 흉내 낸다)
vim.ui.input = function(_, cb)
  cb("의견")
end
local file = vim.fn.tempname() .. ".txt"
vim.fn.writefile({ "one", "two", "three" }, file)
vim.cmd.edit(file)
review.add(2, 2)
eq("미전송 의견 수", review.pending_count(), 1)
vim.api.nvim_buf_set_lines(0, 0, 0, false, { "new top" })
local ns = vim.api.nvim_create_namespace("review_comments")
local row = vim.api.nvim_buf_get_extmark_by_id(0, ns, review.comments[1].mark, {})[1]
eq("앞에 줄을 넣으면 의견이 따라간다 (0-based)", row, 2)
review.comments[1].sent = true
eq("전송 처리하면 미전송 수가 줄어든다", review.pending_count(), 0)
review.clear()
eq("지우면 비운다", #review.comments, 0)
vim.fn.delete(file)

if failures > 0 then
  print(failures .. " 실패")
  os.exit(1)
end
print("review: 통과")
