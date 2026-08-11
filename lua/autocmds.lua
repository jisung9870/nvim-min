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
vim.filetype.add({
  extension = {
    alloy = "hcl", -- Grafana Alloy
    tf = "terraform",
    tfvars = "terraform-vars",
  },
  filename = {
    ["Jenkinsfile"] = "groovy",
    ["nginx.conf"] = "nginx",
    [".yamllint"] = "yaml",
  },
  pattern = {
    ["Jenkinsfile.*"] = "groovy",
    [".*%.jenkinsfile"] = "groovy",
    [".*/%.github/workflows/.*%.ya?ml"] = "yaml.ghaction",
    [".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
    [".*/nginx/.*%.conf"] = "nginx",
    [".*/templates/.*%.ya?ml"] = "helm",
  },
})
