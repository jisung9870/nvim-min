-- AgentDiff의 tmux 출력 파싱, 후보 선택, diff 해석 시험
--   nvim --headless -u NONE -l tests/agent_diff.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")))
vim.opt.runtimepath:prepend(root)
local agent = require("agent_diff")

local failures = 0
local function eq(name, got, want)
  if vim.inspect(got) == vim.inspect(want) then
    print("ok   " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n  got:  " .. vim.inspect(got) .. "\n  want: " .. vim.inspect(want))
  end
end

local panes = agent.parse_panes(table.concat({
  "%1\tabc123\t/repo\t1700000100\tweb\t",
  "%2\t\t\t\t", -- 스냅샷 없는 pane
  "%3\tdef456\t/repo\t1700000500\tweb\tfeedbeef",
  "%4\t999999\t/other\t1700000900\tapi",
  "",
}, "\n"))
eq("스냅샷 없는 pane은 버린다", #panes, 3)
eq("after 필드", panes[2].after, "feedbeef")
eq(
  "필드 해석",
  panes[1],
  { pane_id = "%1", sha = "abc123", root = "/repo", time = 1700000100, project = "web", after = "" }
)

local list = agent.candidates(panes, "/repo")
eq(
  "같은 저장소만, 최신순",
  vim.tbl_map(function(p)
    return p.pane_id
  end, list),
  { "%3", "%1" }
)
eq("일치하는 저장소가 없으면 빈 목록", agent.candidates(panes, "/nowhere"), {})

local diff = table.concat({
  "diff --git a/a.lua b/a.lua",
  "--- a/a.lua",
  "+++ b/a.lua",
  "@@ -3 +3 @@ foo",
  "-x",
  "+y",
  "@@ -10,2 +10,4 @@",
  "@@ -20,3 +23,0 @@",
  "diff --git a/old.lua b/old.lua",
  "--- a/old.lua",
  "+++ /dev/null",
  "@@ -1,2 +0,0 @@",
  "diff --git a/b.py b/b.py",
  "--- a/b.py",
  "+++ b/b.py",
  "@@ -1,0 +2,3 @@",
  "diff --git a/c.txt b/c.txt",
  "Binary files a/c.txt and b/c.txt differ",
  "@@ -1 +1 @@", -- +++ 줄이 없으면 앞 파일(b.py)로 잘못 붙으면 안 된다
}, "\n")
local items = agent.parse_diff(diff)
eq("hunk 수 (+++ 없는 hunk는 이전 파일에 붙이지 않는다)", #items, 4)
eq("첫 hunk", { items[1].filename, items[1].lnum }, { "a.lua", 3 })
eq("삭제 hunk는 최소 1줄", { items[3].filename, items[3].lnum }, { "a.lua", 23 })
eq("추가 hunk", { items[4].filename, items[4].lnum }, { "b.py", 2 })
eq("파일 수", agent.count_files(items), 2)

if failures > 0 then
  print(failures .. " 실패")
  os.exit(1)
end
print("agent_diff: 통과")
