-- ============================================================================
-- 포맷 설정 (conform) — 에디터와 scripts/format-changed.lua가 함께 쓴다
-- ============================================================================
-- 저장할 때 git HEAD 대비 바뀐 줄만 포맷한다. 에이전트(Claude Code/Codex)가
-- 고친 파일을 저장해도 손대지 않은 줄까지 다시 쓰이지 않게 하려는 것이다.
--   - range 포맷을 지원하는 포매터(ruff_format, prettier, stylua)는 hunk마다 range로 부른다.
--   - trim_whitespace는 바뀐 줄의 끝 공백만 직접 지운다.
--   - range를 못 쓰는 그 밖의 포매터(shfmt, YAML prettier)는 결과를 직접 계산해, 결과의 모든 변경이
--     바뀐 줄 안에 있을 때만 적용하고 아니면 건너뛴다.
--   - 파일 단위로만 맞출 수 있는 포매터(taplo, gofumpt, terraform_fmt ...)는 파일 전체를 포맷한다.
--   - git 추적 밖의 파일(새 파일)은 파일 전체를 포맷한다.
-- 이 모듈은 LSP·treesitter·다른 플러그인에 의존하지 않는다 (conform만 필요).
-- ============================================================================

local M = {}

-- 파일 전체를 포맷하는 포매터. 이 밖의 포매터 중 range_args가 있으면 range로 부르고,
-- 없으면(shfmt, YAML prettier) 결과가 바뀐 줄 안에 모두 들어올 때만 적용한다.
-- 줄을 범위 밖으로 옮기거나 imports를 추가·삭제하는 포매터는 일부 hunk만 적용하면
-- 줄이 사라지므로 전체를 돌려야 한다.
M.whole_file = {
  -- 범위 밖으로 줄을 옮기는 포매터는 일부 hunk만 적용하면 줄이 사라진다
  ruff_organize_imports = true,
  terraform_fmt = true,
  gofumpt = true,
  goimports = true,
  taplo = true,
  alloy_space = true,
}

-- hunk가 이보다 많으면 첫 줄~끝 줄을 range 하나로 합친다 (포매터 프로세스 수 제한)
M.max_ranges = 30
M.max_bytes = 256 * 1024
-- 포맷하지 않는 filetype. conform은 빈 표를 "설정 없음"으로 보고 `_`(trim_whitespace)를
-- 적용하므로 여기서 직접 막는다 (markdown은 줄 끝 두 칸이 줄바꿈이다).
M.skip_filetypes = { markdown = true, sql = true }
M.timeout_ms = 3000

-- vim.diff(result_type = "indices") 결과를 새 쪽 줄 range 목록 {first, last}로 바꾼다.
-- 줄이 지워지기만 한 hunk(count_b == 0)는 포맷할 줄이 없어 건너뛴다.
---@param indices integer[][] { {start_a, count_a, start_b, count_b}, ... }
---@param max_ranges? integer
---@return integer[][]
function M.ranges_from_indices(indices, max_ranges)
  local ranges = {}
  for _, hunk in ipairs(indices) do
    local start_b, count_b = hunk[3], hunk[4]
    if count_b > 0 then
      local first, last = start_b, start_b + count_b - 1
      local prev = ranges[#ranges]
      if prev and first <= prev[2] + 1 then
        prev[2] = math.max(prev[2], last)
      else
        ranges[#ranges + 1] = { first, last }
      end
    end
  end
  if #ranges > (max_ranges or M.max_ranges) then
    ranges = { { ranges[1][1], ranges[#ranges][2] } }
  end
  return ranges
end

local function git_head_text(path)
  if vim.fn.executable("git") == 0 then
    return nil
  end
  local dir, name = vim.fs.dirname(path), vim.fs.basename(path)
  local ok, res = pcall(function()
    return vim.system({ "git", "-C", dir, "show", "HEAD:./" .. name }, { text = true }):wait(2000)
  end)
  if not ok or res.code ~= 0 then
    return nil
  end
  return res.stdout
end

-- 파일이 git 작업 트리 안에 있는지 (추적 여부와 무관)
---@param path string
---@return boolean
function M.in_git_repo(path)
  if vim.fn.executable("git") == 0 then
    return false
  end
  local ok, res = pcall(function()
    return vim
      .system({ "git", "-C", vim.fs.dirname(path), "rev-parse", "--is-inside-work-tree" }, { text = true })
      :wait(2000)
  end)
  return ok and res.code == 0 and vim.trim(res.stdout) == "true"
end

-- HEAD 대비 바뀐 줄 range. nil이면 비교할 수 없는 파일(새 파일, git 밖)이라는 뜻이다.
-- 디스크가 아니라 버퍼 내용을 비교하므로 저장 전 편집도 정확히 반영된다.
---@param path string
---@param lines string[]
---@return integer[][]|nil
function M.changed_ranges(path, lines)
  if path == "" then
    return nil
  end
  local head = git_head_text(path)
  if not head then
    return nil
  end
  local current = #lines > 0 and (table.concat(lines, "\n") .. "\n") or ""
  local indices = vim.diff(head, current, { result_type = "indices" })
  return M.ranges_from_indices(indices)
end

---@param bufnr integer
---@return boolean
function M.should_format(bufnr)
  if M.skip_filetypes[vim.bo[bufnr].filetype] then
    return false
  end
  if vim.b[bufnr].autoformat == false or vim.g.autoformat == false then
    return false
  end
  if vim.bo[bufnr].buftype ~= "" then
    return false
  end
  local ok, stat = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
  if ok and stat and stat.size > M.max_bytes then
    return false
  end
  return true
end

-- 포맷 결과(new)의 모든 변경이 바뀐 줄 range 안에 있는지 검사한다. 범위 밖 줄을 건드리거나
-- 줄을 범위 밖으로 옮기는 포매터를 걸러 낸다. indices는 old 기준 vim.diff 결과다.
---@param indices integer[][]
---@param ranges integer[][]
---@return boolean
function M.hunks_within(indices, ranges)
  for _, hunk in ipairs(indices) do
    local a_start, a_count = hunk[1], hunk[2]
    local ok = false
    for _, range in ipairs(ranges) do
      local first, last = range[1], range[2]
      if a_count == 0 then
        -- a_start 줄 뒤에 끼워 넣는다. 삽입 지점이 range의 경계 안이어야 한다.
        ok = a_start >= first - 1 and a_start <= last
      else
        ok = a_start >= first and a_start + a_count - 1 <= last
      end
      if ok then
        break
      end
    end
    if not ok then
      return false
    end
  end
  return true
end

local function trim_changed_lines(bufnr, ranges, edited)
  local changed = false
  for _, range in ipairs(ranges) do
    local lines = vim.api.nvim_buf_get_lines(bufnr, range[1] - 1, range[2], false)
    for i, line in ipairs(lines) do
      local trimmed = line:gsub("%s+$", "")
      if trimmed ~= line then
        if edited or changed then
          pcall(vim.cmd, "undojoin")
        end
        vim.api.nvim_buf_set_lines(bufnr, range[1] - 2 + i, range[1] - 1 + i, false, { trimmed })
        changed = true
      end
    end
  end
  return changed
end

-- range를 못 쓰는 포매터: 전체 결과를 계산해 모든 변경이 ranges 안일 때만 적용한다.
---@return boolean applied
local function format_if_contained(bufnr, name, ranges, edited, quiet)
  local conform = require("conform")
  local old = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local formatters = conform.resolve_formatters({ name }, bufnr, false, false)
  if #formatters == 0 then
    return false
  end
  local err, output = require("conform.runner").format_lines_sync(
    bufnr,
    formatters,
    M.timeout_ms,
    nil,
    old,
    { exclusive = true, dry_run = true, undojoin = false }
  )
  if err or not output then
    if not quiet and err then
      vim.notify(("%s: %s"):format(name, err.message or "포맷 실패"), vim.log.levels.WARN)
    end
    return false
  end
  local indices =
    vim.diff(table.concat(old, "\n") .. "\n", table.concat(output, "\n") .. "\n", { result_type = "indices" })
  if #indices == 0 then
    return false
  end
  if not M.hunks_within(indices, ranges) then
    return false
  end
  -- 아래 hunk부터 적용해야 위쪽 줄 번호가 유효하다
  for i = #indices, 1, -1 do
    local a_start, a_count, b_start, b_count = unpack(indices[i])
    local replacement = vim.list_slice(output, b_start, b_start + b_count - 1)
    if edited or i < #indices then
      pcall(vim.cmd, "undojoin")
    end
    if a_count == 0 then
      vim.api.nvim_buf_set_lines(bufnr, a_start, a_start, false, replacement)
    else
      vim.api.nvim_buf_set_lines(bufnr, a_start - 1, a_start - 1 + a_count, false, replacement)
    end
  end
  return true
end

-- 끝 줄바꿈이 없는 파일에 포매터를 거치면 끝에 빈 줄이 하나 붙는다. 원래 상태로 되돌린다.
local function restore_noeol(bufnr, had_noeol, original_last)
  if not had_noeol then
    return
  end
  local count = vim.api.nvim_buf_line_count(bufnr)
  if count > 1 and original_last ~= "" and vim.api.nvim_buf_get_lines(bufnr, count - 1, count, false)[1] == "" then
    pcall(vim.cmd, "undojoin")
    vim.api.nvim_buf_set_lines(bufnr, count - 1, count, false, {})
  end
end

local function has_range_args(name, bufnr)
  local config = require("conform").get_formatter_config(name, bufnr)
  return config ~= nil and config.range_args ~= nil and config.range_args ~= false
end

-- 버퍼를 바뀐 줄만 포맷한다. 오류는 conform이 알린다 (quiet면 알리지 않는다).
---@param bufnr integer
---@param opts? { quiet?: boolean }
function M.format_buffer(bufnr, opts)
  opts = opts or {}
  if M.skip_filetypes[vim.bo[bufnr].filetype] then
    return
  end
  local conform = require("conform")
  local had_noeol = not vim.bo[bufnr].eol
  local original_last = vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)[1] or ""
  local base = { bufnr = bufnr, async = false, timeout_ms = M.timeout_ms, quiet = opts.quiet, lsp_format = "never" }

  local names = {}
  for _, info in ipairs(conform.list_formatters_to_run(bufnr)) do
    if info.available then
      names[#names + 1] = info.name
    end
  end
  if #names == 0 then
    -- 포매터가 없으면 기존처럼 LSP 포맷으로 넘어간다 (포매터가 비어 있는 ft 한정)
    conform.format(vim.tbl_extend("force", base, { lsp_format = "fallback" }))
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local function ranges_now()
    return M.changed_ranges(path, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end

  if ranges_now() == nil then
    -- 비교 대상이 없는 파일(새 파일, git 밖)은 전체를 포맷한다
    conform.format(vim.tbl_extend("force", base, { formatters = names }))
    restore_noeol(bufnr, had_noeol, original_last)
    return
  end

  -- 포매터를 하나씩 돌린다. 앞 포매터가 줄 수를 바꾸면 range의 줄 번호가 어긋나므로
  -- 포매터마다 range를 새로 구한다.
  local edited = false
  for _, name in ipairs(names) do
    if M.whole_file[name] then
      conform.format(vim.tbl_extend("force", base, { formatters = { name }, undojoin = edited }))
      edited = true
    else
      local ranges = ranges_now() or {}
      if name == "trim_whitespace" then
        edited = trim_changed_lines(bufnr, ranges, edited) or edited
      elseif not has_range_args(name, bufnr) then
        edited = format_if_contained(bufnr, name, ranges, edited, opts.quiet) or edited
      else
        -- 아래 hunk부터 처리해야 위쪽 hunk의 줄 번호가 유효하다
        for i = #ranges, 1, -1 do
          local first = ranges[i][1]
          local last = math.min(ranges[i][2], vim.api.nvim_buf_line_count(bufnr))
          if first <= last then
            local last_line = vim.api.nvim_buf_get_lines(bufnr, last - 1, last, false)[1] or ""
            conform.format(vim.tbl_extend("force", base, {
              formatters = { name },
              range = { start = { first, 0 }, ["end"] = { last, #last_line } },
              undojoin = edited,
            }))
            edited = true
          end
        end
      end
    end
  end
  restore_noeol(bufnr, had_noeol, original_last)
end

-- conform 설정. 에디터와 헤드리스 스크립트가 공유한다.
function M.setup()
  local prettier_args = { "--config-precedence", "prefer-file", "--tab-width", "2", "--no-semi", "--single-quote" }
  require("conform").setup({
    formatters_by_ft = {
      go = { "goimports", "gofumpt" },
      terraform = { "terraform_fmt" },
      tf = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
      alloy = { "alloy_space" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      lua = { "stylua" },
      toml = { "taplo" },
      python = { "ruff_organize_imports", "ruff_format" },
      -- SQL은 의도적으로 비워 둔다. sqlfluff fix는 쿼리를 크게 다시 쓰므로
      -- 저장할 때마다 돌리기엔 위험하다. 진단만 받고, 고칠 때는 직접 부른다.
      sql = {}, -- 실제 차단은 M.skip_filetypes (빈 표는 `_`로 넘어간다)
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier_yaml" },
      markdown = {}, -- 의도적 공백 보존 — 포맷 안 함
      ["_"] = { "trim_whitespace" },
    },

    formatters = {
      -- .editorconfig가 있으면 스타일 플래그를 주지 않아 shfmt가 그 설정을 따른다
      shfmt = {
        prepend_args = function(_, ctx)
          local has_editorconfig = vim.fs.find(".editorconfig", { path = ctx.dirname, upward = true })[1] ~= nil
          return has_editorconfig and {} or { "-i", "2", "-ci" }
        end,
      },
      -- prefer-file: 프로젝트의 prettier 설정 파일이 있으면 아래 기본값은 무시된다
      prettier = { prepend_args = prettier_args },
      -- prettier의 YAML range 포맷은 range를 무시하고 파일 전체를 다시 쓴다. range_args를
      -- 꺼서 conform이 전체를 돌린 뒤 바뀐 줄 안의 변경만 적용하게 한다.
      prettier_yaml = { inherit = "prettier", prepend_args = prettier_args, range_args = false },
      -- Grafana Alloy: alloy fmt이 탭을 쓰므로 스페이스로 편다
      alloy_space = {
        command = "sh",
        args = { "-c", "alloy fmt - | expand -t 2" },
        stdin = true,
        condition = function()
          return vim.fn.executable("alloy") == 1
        end,
      },
    },
  })
end

-- 에디터 전용: 저장 시 자동 포맷과 :FormatToggle
function M.attach()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("format_changed_on_save", { clear = true }),
    callback = function(ev)
      if M.should_format(ev.buf) then
        M.format_buffer(ev.buf)
      end
    end,
  })

  vim.api.nvim_create_user_command("FormatToggle", function(args)
    if args.bang then
      vim.b.autoformat = vim.b.autoformat == false
      vim.notify("버퍼 자동 포맷: " .. tostring(vim.b.autoformat ~= false))
    else
      vim.g.autoformat = vim.g.autoformat == false
      vim.notify("전역 자동 포맷: " .. tostring(vim.g.autoformat ~= false))
    end
  end, { bang = true, desc = "자동 포맷 토글 (!는 현재 버퍼만)" })
end

return M
