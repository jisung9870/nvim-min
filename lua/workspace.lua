-- ============================================================================
-- 프로젝트별 Neovim 상태: 세션과 스크래치 메모
-- bb tm은 tmux 프로젝트 수명주기를 맡고, 이 모듈은 현재 cwd의 편집기 상태만 보존한다.
-- ============================================================================

local M = {}
local session_active = vim.fn.argc() == 0
local mark_scratch

local function cwd()
  return vim.fs.normalize(vim.fn.getcwd())
end

local function state_dir(name)
  local dir = vim.fs.joinpath(vim.fn.stdpath("state"), name)
  vim.fn.mkdir(dir, "p")
  return dir
end

local function project_id(root)
  return vim.fn.sha256(root):sub(1, 16)
end

function M.session_path(root)
  root = root or cwd()
  return vim.fs.joinpath(state_dir("sessions"), project_id(root) .. ".vim")
end

function M.scratch_path(root)
  root = root or cwd()
  local name = vim.fs.basename(root):gsub("[^%w._-]", "-")
  return vim.fs.joinpath(state_dir("scratch"), name .. "-" .. project_id(root) .. ".md")
end

local function file_buffers()
  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
  end, vim.api.nvim_list_bufs())
end

function M.save(opts)
  opts = opts or {}
  if #file_buffers() == 0 then
    if not opts.quiet then
      vim.notify("저장할 파일 세션이 없습니다", vim.log.levels.WARN)
    end
    return false
  end

  local path = M.session_path()
  local ok, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(path))
  if not ok then
    if not opts.quiet then
      vim.notify("세션 저장 실패: " .. tostring(err), vim.log.levels.ERROR)
    end
    return false
  end
  if not opts.quiet then
    vim.notify("프로젝트 세션 저장됨")
  end
  session_active = true
  return true
end

function M.restore(opts)
  opts = opts or {}
  local path = M.session_path()
  if vim.fn.filereadable(path) == 0 then
    if not opts.quiet then
      vim.notify("저장된 프로젝트 세션이 없습니다", vim.log.levels.WARN)
    end
    return false
  end

  local ok, err = pcall(vim.cmd, "silent source " .. vim.fn.fnameescape(path))
  if not ok then
    if not opts.quiet then
      vim.notify("세션 복원 실패: " .. tostring(err), vim.log.levels.ERROR)
    end
    return false
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    mark_scratch(buf)
  end
  if not opts.quiet then
    vim.notify("프로젝트 세션 복원됨")
  end
  session_active = true
  return true
end

function M.scratch()
  local root = cwd()
  local path = M.scratch_path(root)
  local fresh = vim.fn.filereadable(path) == 0

  vim.cmd.edit(vim.fn.fnameescape(path))
  if fresh then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# " .. vim.fs.basename(root) .. " scratch", "" })
    vim.cmd("silent write")
  end
  -- macOS에서는 /var 경로가 버퍼 이름에서 /private/var로 정규화될 수 있다.
  vim.b.project_scratch = vim.api.nvim_buf_get_name(0)
end

local function save_scratch(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local path = vim.b[buf].project_scratch
  if type(path) ~= "string" or vim.api.nvim_buf_get_name(buf) ~= path or not vim.bo[buf].modified then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent write")
  end)
end

mark_scratch = function(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local scratch_dir = state_dir("scratch")
  local dir = vim.uv.fs_realpath(scratch_dir) or vim.fs.normalize(scratch_dir)
  if name ~= "" and vim.fs.dirname(name) == dir then
    vim.b[buf].project_scratch = name
  end
end

vim.api.nvim_create_user_command("SessionSave", M.save, { desc = "현재 프로젝트 Neovim 세션 저장" })
vim.api.nvim_create_user_command("SessionRestore", M.restore, { desc = "현재 프로젝트 Neovim 세션 복원" })
vim.api.nvim_create_user_command(
  "ProjectScratch",
  M.scratch,
  { desc = "현재 프로젝트 스크래치 메모 열기" }
)

local map = vim.keymap.set
map("n", "<leader>qs", M.save, { desc = "Save project session" })
map("n", "<leader>qr", M.restore, { desc = "Restore project session" })
map("n", "<leader>.", M.scratch, { desc = "Project scratch" })

local group = vim.api.nvim_create_augroup("project_state", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function(args)
    mark_scratch(args.buf)
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    local empty = vim.fn.argc() == 0
      and vim.api.nvim_buf_get_name(0) == ""
      and vim.bo.buftype == ""
      and not vim.bo.modified
    if session_active and empty then
      M.restore({ quiet = true })
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  group = group,
  callback = function(args)
    save_scratch(args.buf)
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      save_scratch(buf)
    end
    if session_active then
      M.save({ quiet = true })
    end
  end,
})

return M
