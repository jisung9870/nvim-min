-- ============================================================================
-- 편집 보조: 포맷 / 린트 / 괄호 / surround / 한영 전환 / which-key
-- ============================================================================

-- 아이콘 (statusline, snacks picker가 함께 씀) ------------------------------
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

-- 괄호 자동 짝 --------------------------------------------------------------
require("mini.pairs").setup({
  modes = { insert = true, command = true, terminal = false },
})

-- surround: sa(추가) sd(삭제) sr(교체) -------------------------------------
require("mini.surround").setup()

-- 포맷 (conform) ------------------------------------------------------------
require("conform").setup({
  formatters_by_ft = {
    go = { "goimports", "gofumpt" },
    terraform = { "terraform_fmt" },
    tf = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
    hcl = { "alloy_space" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    lua = { "stylua" },
    toml = { "taplo" },
    python = { "ruff_organize_imports", "ruff_format" },
    -- SQL은 의도적으로 비워 둔다. sqlfluff fix는 쿼리를 크게 다시 쓰므로
    -- 저장할 때마다 돌리기엔 위험하다. 진단만 받고, 고칠 때는 직접 부른다.
    sql = {},
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = {}, -- 의도적 공백 보존 — 포맷 안 함
    ["_"] = { "trim_whitespace" },
  },

  formatters = {
    shfmt = { prepend_args = { "-i", "2", "-ci" } },
    prettier = {
      prepend_args = { "--tab-width", "2", "--no-semi", "--single-quote" },
    },
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

  format_on_save = function(bufnr)
    -- vim.b.autoformat = false 인 버퍼, 큰 파일은 건너뛴다
    if vim.b[bufnr].autoformat == false or vim.g.autoformat == false then
      return nil
    end
    local ok, stat = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
    if ok and stat and stat.size > 256 * 1024 then
      return nil
    end
    return { timeout_ms = 3000, lsp_format = "fallback" }
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

-- 린트 (nvim-lint) ----------------------------------------------------------
-- LSP가 진단을 못 주는 영역만 채운다.
-- shellcheck는 bashls가 알아서 물고 오므로 여기 없다 (중복 진단 방지).
local lint = require("lint")

-- yaml.ansible이 여기 없는 이유: ansiblels가 ansible-lint를 직접 돌리고,
-- ansible-lint는 yamllint 규칙을 이미 포함한다. 넣으면 같은 진단이 두 번 뜬다.
lint.linters_by_ft = {
  yaml = { "yamllint" },
  ["yaml.ghaction"] = { "actionlint" },
  terraform = { "tflint" },
  tf = { "tflint" },
  ["terraform-vars"] = { "tflint" },
  dockerfile = { "hadolint" },
  sql = { "sqlfluff" },
}

-- sqlfluff는 방언을 모르면 실행 자체가 실패한다. 저장소에 .sqlfluff가 있으면
-- 그쪽이 이기고, 없을 때 쓸 기본값만 여기서 준다.
--   lua/local.lua 에서:  vim.g.sql_dialect = "postgres"
lint.linters.sqlfluff = vim.tbl_deep_extend("force", lint.linters.sqlfluff, {
  args = {
    "lint",
    "--format=json",
    "--dialect",
    function()
      return vim.g.sql_dialect or "ansi"
    end,
    "-",
  },
})

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
  callback = function()
    lint.try_lint()
  end,
})

-- 한/영 자동 전환 (macOS: brew install macism) ------------------------------
if vim.fn.has("mac") == 1 and vim.fn.executable("macism") == 1 then
  require("im_select").setup({
    default_im_select = "com.apple.keylayout.ABC",
    default_command = "macism",
  })
end

-- which-key -----------------------------------------------------------------
local wk = require("which-key")
wk.setup({
  preset = "helix",
  win = { border = "rounded" },
})

wk.add({
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>f", group = "file/find" },
  { "<leader>g", group = "git" },
  { "<leader>gx", group = "conflict" },
  { "<leader>s", group = "search" },
  { "<leader>t", group = "terminal" },
  { "<leader>u", group = "ui/toggle" },
  { "<leader>x", group = "diagnostics" },
})
