-- 한 파일에서 git HEAD 대비 바뀐 줄만 포맷해 저장한다 (에이전트 PostToolUse 훅용).
--
--   nvim --headless -u NONE -l scripts/format-changed.lua <파일>
--
-- 전체 설정·LSP·treesitter는 로드하지 않고 conform만 쓴다. 항상 종료 코드 0이며
-- 문제가 있으면 stderr에 한 줄만 남긴다. 내용이 바뀐 경우에만 파일을 쓴다.

local function note(message)
  io.stderr:write("format-changed: " .. message .. "\n")
end

local function read_bytes(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local data = file:read("*a")
  file:close()
  return data
end

local DEADLINE_MS = 8000

local function main(path)
  if not path or path == "" then
    return note("파일 경로 인자가 필요하다")
  end
  path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(path) == 0 then
    return note("읽을 수 없는 파일: " .. path)
  end

  -- 처음 읽은 디스크 내용. 쓰기 직전에 같은지 확인해 에이전트의 재편집을 덮어쓰지 않는다.
  local original = read_bytes(path)
  if not original then
    return note("읽을 수 없는 파일: " .. path)
  end

  -- 이 스크립트 위치에서 저장소 경로를 구해 lua/formatting.lua를 찾는다
  local script = debug.getinfo(1, "S").source:sub(2)
  local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(script, ":p")))
  vim.opt.runtimepath:prepend(root)

  local conform_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", "conform.nvim")
  if vim.fn.isdirectory(conform_dir) == 0 then
    return note("conform.nvim이 설치돼 있지 않다: " .. conform_dir)
  end
  vim.opt.runtimepath:append(conform_dir)

  -- mason이 깔아 둔 포매터(prettier, ruff, stylua ...)를 찾도록 PATH에 더한다
  local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
  vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")

  -- 묻지 않고 조용히 동작하게 한다
  vim.o.swapfile = false
  vim.o.confirm = false
  vim.o.more = false
  vim.o.shortmess = vim.o.shortmess .. "FWIcCsS"

  local formatting = require("formatting")
  -- git 밖의 파일(설정 파일 등)은 건드리지 않는다. 저장소 안의 새 파일만 전체를 포맷한다.
  if not formatting.in_git_repo(path) then
    return note("git 저장소 밖의 파일이라 건너뛴다: " .. path)
  end
  formatting.setup()

  vim.cmd.edit({ args = { path }, mods = { silent = true } })
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].fixendofline = false -- 끝 줄바꿈이 없던 파일은 없는 채로 둔다
  -- -u NONE에서는 filetype 감지가 꺼져 있으므로 직접 판별한다
  vim.bo[bufnr].filetype = vim.filetype.match({ buf = bufnr, filename = path }) or ""
  if vim.bo[bufnr].filetype == "" then
    return note("파일 종류를 알 수 없어 건너뛴다: " .. path)
  end
  if not formatting.should_format(bufnr) then
    return
  end

  formatting.format_buffer(bufnr, { quiet = true })
  if vim.bo[bufnr].modified then
    if read_bytes(path) ~= original then
      return note("포맷하는 사이 파일이 바뀌어 쓰지 않는다: " .. path)
    end
    vim.cmd("silent noautocmd write")
  end
end

-- 전체 기한: 넘기면 아무것도 쓰지 않고 끝낸다 (쓰기는 순간적이라 기한 중간에 끊기지 않는다)
vim.defer_fn(function()
  note(("%d초를 넘겨 포기한다"):format(DEADLINE_MS / 1000))
  os.exit(0)
end, DEADLINE_MS)

local ok, err = pcall(main, arg[1])
if not ok then
  note(tostring(err))
end
vim.cmd("silent! qall!")
os.exit(0)
