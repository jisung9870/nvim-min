-- 화면 너비별 배치 결정 시험
--   nvim --headless -u NONE -l tests/layout.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")))
vim.opt.runtimepath:prepend(root)
local layout = require("layout")

local failures = 0
local function eq(name, got, want)
  if vim.inspect(got) == vim.inspect(want) then
    print("ok   " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n  got:  " .. vim.inspect(got) .. "\n  want: " .. vim.inspect(want))
  end
end

eq("좁은 화면은 최소 50", layout.sidekick_width(100), 50)
eq("120칸은 40%인 48이 아니라 최소 50", layout.sidekick_width(120), 50)
eq("150칸은 40%인 60", layout.sidekick_width(150), 60)
eq("200칸은 최대 72", layout.sidekick_width(200), 72)
eq("180칸은 정확히 72", layout.sidekick_width(180), 72)

eq("넓으면 가로 + 패널 열림", layout.diffview_layout(160), { layout = "diff2_horizontal", panel_open = true })
eq("140칸은 가로", layout.diffview_layout(140), { layout = "diff2_horizontal", panel_open = true })
eq("139칸은 세로 + 패널 열림", layout.diffview_layout(139), { layout = "diff2_vertical", panel_open = true })
eq("100칸은 패널 열림", layout.diffview_layout(100), { layout = "diff2_vertical", panel_open = true })
eq("99칸은 세로 + 패널 닫힘", layout.diffview_layout(99), { layout = "diff2_vertical", panel_open = false })

-- winfixwidth 창은 equalize 뒤에도 너비를 유지한다
vim.o.columns = 160
vim.cmd("vsplit | vsplit")
local fixed = vim.api.nvim_get_current_win()
vim.wo[fixed].winfixwidth = true
vim.api.nvim_win_set_width(fixed, 30)
layout.equalize()
eq("winfixwidth 창 너비 유지", vim.api.nvim_win_get_width(fixed), 30)

if failures > 0 then
  print(failures .. " 실패")
  os.exit(1)
end
print("layout: 통과")
