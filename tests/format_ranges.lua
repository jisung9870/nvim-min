-- hunk -> 포맷 range 계산 시험
--   nvim --headless -u NONE -l tests/format_ranges.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")))
vim.opt.runtimepath:prepend(root)
local formatting = require("formatting")

local failures = 0
local function eq(name, got, want)
  if vim.inspect(got) == vim.inspect(want) then
    print("ok   " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n  got:  " .. vim.inspect(got) .. "\n  want: " .. vim.inspect(want))
  end
end

-- {start_a, count_a, start_b, count_b}
eq("한 hunk", formatting.ranges_from_indices({ { 3, 1, 3, 1 } }), { { 3, 3 } })
eq("여러 줄 추가", formatting.ranges_from_indices({ { 2, 0, 3, 4 } }), { { 3, 6 } })
eq("삭제만 있으면 건너뜀", formatting.ranges_from_indices({ { 5, 2, 4, 0 } }), {})
eq("떨어진 hunk 둘", formatting.ranges_from_indices({ { 1, 1, 1, 1 }, { 9, 1, 9, 2 } }), { { 1, 1 }, { 9, 10 } })
eq("맞닿은 hunk는 합친다", formatting.ranges_from_indices({ { 1, 1, 1, 2 }, { 3, 1, 3, 1 } }), { { 1, 3 } })
eq(
  "너무 많으면 하나로",
  formatting.ranges_from_indices({ { 1, 1, 1, 1 }, { 5, 1, 5, 1 }, { 9, 1, 9, 1 } }, 2),
  { { 1, 9 } }
)

-- 실제 git 저장소: HEAD 대비 버퍼 내용
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local function git(...)
  local res = vim.system({ "git", "-C", dir, "-c", "user.name=t", "-c", "user.email=t@t", ... }, { text = true }):wait()
  assert(res.code == 0, res.stderr)
end
git("init", "-q")
local file = dir .. "/a.txt"
vim.fn.writefile({ "one", "two", "three", "four", "five" }, file)
git("add", ".")
git("commit", "-qm", "i")
eq("변경 없음", formatting.changed_ranges(file, { "one", "two", "three", "four", "five" }), {})
eq("두 번째 줄 수정", formatting.changed_ranges(file, { "one", "TWO", "three", "four", "five" }), { { 2, 2 } })
eq(
  "줄 삽입과 수정",
  formatting.changed_ranges(file, { "one", "two", "x", "y", "three", "four", "FIVE" }),
  { { 3, 4 }, { 7, 7 } }
)
eq("추적하지 않는 파일은 nil", formatting.changed_ranges(dir .. "/new.txt", { "a" }), nil)
vim.fn.delete(dir, "rf")

-- 범위에 걸린 hunk만 적용하면 줄이 사라지는 회귀: 포매터가 줄을 위로 옮기는 경우
local function indices(old, new)
  return vim.diff(table.concat(old, "\n") .. "\n", table.concat(new, "\n") .. "\n", { result_type = "indices" })
end
-- HEAD: import os / import sys, 사용자가 아래에 import abc를 추가 -> 포매터가 정렬하며 위로 옮긴다
local moved = indices({ "import os", "import sys", "import abc" }, { "import abc", "import os", "import sys" })
eq("줄이 범위 밖으로 옮겨지면 거부", formatting.hunks_within(moved, { { 3, 3 } }), false)
eq(
  "범위 안 변경만 있으면 허용",
  formatting.hunks_within(indices({ "a", "b  ", "c" }, { "a", "b", "c" }), { { 2, 2 } }),
  true
)
eq(
  "범위 밖 변경이 하나라도 있으면 거부",
  formatting.hunks_within(indices({ "a  ", "b", "c  " }, { "a", "b", "c" }), { { 3, 3 } }),
  false
)
eq(
  "범위 끝에 삽입은 허용",
  formatting.hunks_within(indices({ "a", "b" }, { "a", "b", "x" }), { { 2, 2 } }),
  true
)

-- 실제 버퍼에서: 줄을 정렬하는 가짜 포매터를 conform에 등록해 전체 경로를 검사한다
local conform_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", "conform.nvim")
if vim.fn.isdirectory(conform_dir) == 1 then
  vim.opt.runtimepath:append(conform_dir)
  formatting.setup()
  local conform = require("conform")
  conform.formatters.sorter = {
    format = function(_, _, lines, callback)
      local out = vim.deepcopy(lines)
      table.sort(out)
      callback(nil, out)
    end,
  }
  conform.formatters_by_ft.sorttest = { "sorter" }
  local repo = vim.fn.tempname()
  vim.fn.mkdir(repo, "p")
  local function run_git(...)
    local res = vim
      .system({ "git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", ... }, { text = true })
      :wait()
    assert(res.code == 0, res.stderr)
  end
  run_git("init", "-q")
  vim.fn.writefile({ "a", "c" }, repo .. "/f.sorttest")
  run_git("add", ".")
  run_git("commit", "-qm", "i")
  vim.cmd.edit(repo .. "/f.sorttest")
  vim.bo.filetype = "sorttest"
  vim.api.nvim_buf_set_lines(0, 2, 2, false, { "b" }) -- 정렬하면 b가 가운데로 간다
  formatting.format_buffer(0, { quiet = true })
  eq(
    "옮겨지는 포맷은 건너뛰어 줄을 잃지 않는다",
    vim.api.nvim_buf_get_lines(0, 0, -1, false),
    { "a", "c", "b" }
  )

  -- 변경 줄 안에서만 일어나는 포맷은 적용한다 (끝 공백 제거)
  vim.bo.filetype = "text"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "c", "b  " })
  formatting.format_buffer(0, { quiet = true })
  eq("바뀐 줄의 끝 공백만 제거", vim.api.nvim_buf_get_lines(0, 0, -1, false), { "a", "c", "b" })

  -- markdown은 포맷하지 않는다 (줄 끝 두 칸 = 줄바꿈)
  vim.bo.filetype = "markdown"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a  ", "b" })
  eq("markdown은 자동 포맷 대상이 아니다", formatting.should_format(0), false)
  formatting.format_buffer(0, { quiet = true })
  eq("markdown 줄 끝 공백 유지", vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], "a  ")
  vim.fn.delete(repo, "rf")
else
  print("skip conform 통합 시험 (conform.nvim 없음)")
end

if failures > 0 then
  print(failures .. " 실패")
  os.exit(1)
end
print("format_ranges: 통과")
