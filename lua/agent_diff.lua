-- ============================================================================
-- AgentDiff: 에이전트 요청 한 건이 바꾼 내용만 보는 diff
-- ============================================================================
-- tmux 쪽(terminal-config)이 사용자가 요청을 보낸 순간의 작업 트리를 dangling 커밋으로
-- 만들고 에이전트 pane 옵션에 남긴다. 여기서는 그 커밋을 읽어 쓰기만 한다.
--   @agent_ui_snapshot       커밋 SHA (ref 없음)
--   @agent_ui_snapshot_root  git 최상위 경로
--   @agent_ui_snapshot_time  유닉스 초
--   @agent_ui_project        프로젝트 이름
--   @agent_ui_after          (선택) 에이전트가 멈춘 시점의 트리/커밋 SHA. 없으면 현재 작업 트리로 만든다
--
-- :AgentDiff        가장 최근 스냅샷과 "그 뒤의 트리"를 diffview로 열고, gitsigns 기준을
--                   그 스냅샷으로 바꾸고, 바뀐 hunk를 quickfix에 채운다.
--                   "그 뒤의 트리"는 @agent_ui_after, 없으면 임시 index로 만든 현재 작업 트리다.
--                   git diff <sha>는 index를 기준으로 비교해 요청 전부터 있던 untracked 파일이
--                   삭제로 나오고 새로 만든 파일이 빠지므로 쓰지 않는다.
-- :AgentDiff off    gitsigns 기준을 되돌리고 상태를 지운다.
-- ============================================================================

local M = {}

M.state = nil -- { sha, root, project, time }

local FIELDS =
  "#{pane_id}\t#{@agent_ui_snapshot}\t#{@agent_ui_snapshot_root}\t#{@agent_ui_snapshot_time}\t#{@agent_ui_project}\t#{@agent_ui_after}"

-- tmux list-panes 출력을 pane 목록으로 바꾼다. 스냅샷이 없는 pane은 버린다.
---@param text string
---@return { pane_id: string, sha: string, root: string, time: integer, project: string, after: string }[]
function M.parse_panes(text)
  local panes = {}
  for line in vim.gsplit(text or "", "\n", { plain = true }) do
    local pane_id, sha, root, time, project, after = unpack(vim.split(line, "\t", { plain = true }))
    if pane_id and sha and sha ~= "" and root and root ~= "" then
      panes[#panes + 1] = {
        pane_id = pane_id,
        sha = sha,
        root = root,
        time = tonumber(time) or 0,
        project = (project and project ~= "") and project or vim.fs.basename(root),
        after = after or "",
      }
    end
  end
  return panes
end

-- 현재 저장소(root)의 pane만 남기고 최신 스냅샷 순으로 정렬한다.
function M.candidates(panes, root)
  local list = vim.tbl_filter(function(pane)
    return pane.root == root
  end, panes)
  table.sort(list, function(a, b)
    return a.time > b.time
  end)
  return list
end

-- `git diff -U0` 출력에서 바뀐 hunk를 quickfix 항목으로 만든다.
---@param text string
---@return { filename: string, lnum: integer, text: string }[]
function M.parse_diff(text)
  local items, file = {}, nil
  for line in vim.gsplit(text or "", "\n", { plain = true }) do
    local path = line:match("^%+%+%+ b/(.+)$")
    if line:match("^diff %-%-git ") then
      file = nil -- 다음 +++ 줄이 오기 전까지 이전 파일 이름을 쓰지 않는다
    elseif path then
      file = path
    elseif line:match("^%+%+%+ /dev/null") then
      file = nil -- 삭제된 파일
    else
      local start, count = line:match("^@@ %-%d+,?%d* %+(%d+),?(%d*) @@")
      if start and file then
        count = count == "" and 1 or tonumber(count)
        local lnum = tonumber(start)
        items[#items + 1] = {
          filename = file,
          lnum = math.max(lnum, 1),
          text = count > 1 and ("%d줄 변경"):format(count) or (count == 0 and "줄 삭제" or "1줄 변경"),
        }
      end
    end
  end
  return items
end

function M.count_files(items)
  local seen, n = {}, 0
  for _, item in ipairs(items) do
    if not seen[item.filename] then
      seen[item.filename] = true
      n = n + 1
    end
  end
  return n
end

local function notify(message, level)
  vim.notify("AgentDiff: " .. message, level or vim.log.levels.INFO)
end

---@return vim.SystemCompleted?  실행하지 못했거나 시간이 지나면 nil
local function system(cmd, opts)
  local ok, res = pcall(function()
    return vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {})):wait(5000)
  end)
  if not ok or not res then
    return nil
  end
  return res
end

local function succeeded(res)
  return res ~= nil and res.code == 0
end

local function git_root()
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  if dir == nil or dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.uv.cwd()
  end
  local res = system({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if not succeeded(res) then
    return nil
  end
  return vim.uv.fs_realpath(vim.trim(res.stdout))
end

local function list_panes(scope_flag)
  local cmd = { "tmux", "list-panes" }
  if scope_flag then
    cmd[#cmd + 1] = scope_flag
  end
  vim.list_extend(cmd, { "-F", FIELDS })
  local res = system(cmd)
  if not succeeded(res) then
    return {}
  end
  return M.parse_panes(res.stdout)
end

local function normalize_roots(panes)
  for _, pane in ipairs(panes) do
    pane.root = vim.uv.fs_realpath(pane.root) or pane.root
  end
  return panes
end

-- 비교할 "그 뒤의 트리". @agent_ui_after가 유효하면 그것을, 아니면 임시 index로 현재 작업 트리를 만든다.
-- 실제 index는 건드리지 않는다 (복사본에 git add -A).
---@return string? tree
local function after_tree(root, after)
  if after and after ~= "" then
    local res = system({ "git", "-C", root, "rev-parse", "--verify", "--quiet", after .. "^{tree}" })
    if succeeded(res) then
      return vim.trim(res.stdout)
    end
  end
  local index = system({ "git", "-C", root, "rev-parse", "--path-format=absolute", "--git-path", "index" })
  if not succeeded(index) then
    return nil
  end
  local tmp = vim.fn.tempname()
  -- index가 없으면(커밋 직후 등) 빈 복사본에서 시작한다
  -- 복사본의 mtime을 원본과 맞춘다. 새 mtime이면 git이 같은 초에 바뀐 파일(racy)을 놓칠 수 있다.
  local source = vim.trim(index.stdout)
  vim.uv.fs_copyfile(source, tmp)
  local stat = vim.uv.fs_stat(source)
  if stat then
    vim.uv.fs_utime(tmp, stat.atime.sec, stat.mtime.sec)
  end
  local env = { GIT_INDEX_FILE = tmp }
  local tree
  if succeeded(system({ "git", "-C", root, "add", "-A" }, { env = env })) then
    local written = system({ "git", "-C", root, "write-tree" }, { env = env })
    if succeeded(written) then
      tree = vim.trim(written.stdout)
    end
  end
  vim.fn.delete(tmp)
  return tree
end

local function activate(snapshot, root)
  local sha = snapshot.sha
  if not succeeded(system({ "git", "-C", root, "cat-file", "-e", sha .. "^{commit}" })) then
    return notify(
      "스냅샷 커밋을 찾을 수 없다 ("
        .. sha:sub(1, 8)
        .. "). 요청을 다시 보내면 새로 만들어진다.",
      vim.log.levels.WARN
    )
  end
  local tree = after_tree(root, snapshot.after)
  if not tree then
    return notify("비교할 작업 트리를 만들지 못했다.", vim.log.levels.ERROR)
  end

  -- 같은 기준(sha vs tree)으로 quickfix를 채운다. 새 파일은 추가된 파일 목록만 쓴다.
  local base = { "git", "-C", root, "-c", "core.quotePath=false", "diff", "--no-color", "--no-renames" }
  local modified = system(vim.list_extend(vim.deepcopy(base), { "--diff-filter=M", "-U0", sha, tree, "--" }))
  local items = succeeded(modified) and M.parse_diff(modified.stdout) or {}
  local added = system(vim.list_extend(vim.deepcopy(base), { "--diff-filter=A", "--name-only", sha, tree, "--" }))
  if succeeded(added) then
    for _, name in ipairs(vim.split(added.stdout, "\n", { trimempty = true })) do
      items[#items + 1] = { filename = name, lnum = 1, text = "새 파일" }
    end
  end

  M.state = { sha = sha, root = root, project = snapshot.project, time = snapshot.time }
  require("gitsigns").change_base(sha, true)

  local title = ("Agent · %s · %s"):format(snapshot.project, os.date("%H:%M", snapshot.time))
  for _, item in ipairs(items) do
    item.filename = vim.fs.joinpath(root, item.filename)
  end
  vim.fn.setqflist({}, " ", { title = title, items = items })

  -- Diffview도 같은 기준이다. 오른쪽은 이 트리의 스냅샷이므로 열고 난 뒤의 편집은 반영되지 않는다.
  vim.cmd("DiffviewOpen " .. sha .. ".." .. tree)
  vim.cmd.redrawstatus()
  notify(
    ("%s 이후 %d개 파일이 바뀌었다. 변경 위치는 quickfix에 있다."):format(
      os.date("%H:%M", snapshot.time),
      M.count_files(items)
    )
  )
end

function M.open()
  if vim.fn.executable("tmux") == 0 or (vim.env.TMUX or "") == "" then
    return notify("tmux 안에서만 쓸 수 있다.", vim.log.levels.WARN)
  end
  local root = git_root()
  if not root then
    return notify("현재 버퍼가 git 저장소 안에 없다.", vim.log.levels.WARN)
  end

  local list = M.candidates(normalize_roots(list_panes()), root)
  if #list == 0 then
    list = M.candidates(normalize_roots(list_panes("-s")), root)
  end
  if #list == 0 then
    return notify(
      "이 저장소의 에이전트 스냅샷이 없다. 에이전트에 요청을 보낸 뒤 다시 시도한다.",
      vim.log.levels.WARN
    )
  end
  if #list == 1 then
    return activate(list[1], root)
  end
  vim.ui.select(list, {
    prompt = "에이전트 스냅샷",
    format_item = function(pane)
      return ("%s  %s  %s"):format(os.date("%H:%M:%S", pane.time), pane.project, pane.pane_id)
    end,
  }, function(choice)
    if choice then
      activate(choice, root)
    end
  end)
end

function M.off()
  if not M.state then
    return notify("켜져 있지 않다.")
  end
  M.state = nil
  require("gitsigns").change_base(nil, true)
  pcall(vim.cmd, "DiffviewClose")
  vim.cmd.redrawstatus()
  notify("gitsigns 기준을 기본값으로 되돌렸다.")
end

function M.active()
  return M.state ~= nil
end

vim.api.nvim_create_user_command("AgentDiff", function(args)
  if args.args == "off" then
    M.off()
  else
    M.open()
  end
end, {
  nargs = "?",
  complete = function()
    return { "off" }
  end,
  desc = "에이전트 요청 한 건의 변경만 보기 (off: 해제)",
})

return M
