-- ============================================================================
-- autocmd / filetype 감지
-- ============================================================================

local function augroup(name)
  return vim.api.nvim_create_augroup("min_" .. name, { clear = true })
end

-- yank 하이라이트
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("yank_highlight"),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- 마지막 커서 위치 복원
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_position"),
  callback = function(ev)
    if vim.b[ev.buf].last_position_restored then
      return
    end
    vim.b[ev.buf].last_position_restored = true

    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 창 크기가 바뀌면 분할 비율 유지
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.api.nvim_set_current_tabpage(tab)
  end,
})

-- q로 닫는 버퍼들
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "qf",
    "man",
    "checkhealth",
    "lspinfo",
    "startuptime",
    "gitsigns-blame",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- 텍스트 파일은 wrap + spell
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("text_wrap"),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- 저장 시 없는 상위 디렉터리 자동 생성
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+://") then
      return
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- ============================================================================
-- filetype 감지 (LazyVim이 해주던 것들)
-- ============================================================================
-- 우선순위를 명시하는 이유: Neovim은 패턴을 우선순위 내림차순으로 보되,
-- 0 이하인 패턴은 확장자 표(`yml` → `yaml`)를 조회한 **뒤에** 본다. 기본값
-- 그대로 두면 확장자가 먼저 이겨서 아래 규칙이 영영 안 걸린다.
local PATH_RULE = 10 -- 경로로 확정되는 것
local CONTENT_RULE = 1 -- 내용을 봐야 아는 것. 경로 규칙에 진 다음에 온다.

local function by_path(filetype)
  return { filetype, { priority = PATH_RULE } }
end

local patterns = {
  ["Jenkinsfile.*"] = by_path("groovy"),
  [".*%.Jenkinsfile"] = by_path("groovy"),
  [".*%.jenkinsfile"] = by_path("groovy"),
  [".*/%.github/workflows/.*%.ya?ml"] = by_path("yaml.ghaction"),
  [".*/playbooks/.*%.ya?ml"] = by_path("yaml.ansible"),
  [".*/nginx/.*%.conf"] = by_path("nginx"),
  [".*/templates/.*%.ya?ml"] = by_path("helm"),
  -- 차트의 _helpers.tpl은 기본 감지가 smarty로 잡는다
  [".*/templates/.*%.tpl"] = by_path("helm"),
}

-- role 하위 디렉터리. Lua 패턴에는 (a|b) 교대가 없어서 하나씩 만든다.
for _, dir in ipairs({ "tasks", "handlers", "vars", "defaults", "meta" }) do
  patterns[".*/roles/.*/" .. dir .. "/.*%.ya?ml"] = by_path("yaml.ansible")
end

-- 경로 규칙에 안 걸리는 플레이북(예: 저장소 루트의 site.yml)을 내용으로 잡는다.
-- 앞부분만 훑고 Ansible 특유의 표식이 있을 때만 승격시킨다. nil을 돌려주면
-- 다음 규칙으로 넘어가므로 K8s 매니페스트, docker-compose, Helm 템플릿,
-- GitHub Actions는 그대로 자기 타입으로 남는다.
local function ansible_by_content(_, bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)) do
    if
      line:match("^%s*hosts:")
      or line:match("ansible%.[%w_]+%.")
      or line:match("^%s*become:%s")
      or line:match("^%s*gather_facts:%s")
    then
      return "yaml.ansible"
    end
  end
end

vim.filetype.add({
  extension = {
    alloy = "alloy", -- Grafana Alloy (HCL과 비슷하지만 별도 River 문법)
    tf = "terraform",
    tfvars = "terraform-vars",
  },
  filename = {
    ["Jenkinsfile"] = "groovy",
    ["nginx.conf"] = "nginx",
    [".yamllint"] = "yaml",
  },
  pattern = vim.tbl_extend("error", patterns, {
    [".*%.ya?ml"] = { ansible_by_content, { priority = CONTENT_RULE } },
  }),
})
