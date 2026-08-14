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
    alloy = { "alloy_space" },
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

-- Jenkins 선언형 파이프라인 (네트워크 린터) ---------------------------------
-- Jenkins의 pipeline-model-converter/validate에 파일을 올려 문법을 검사한다.
-- Groovy LSP는 JDK가 필요해서 안 쓰므로, Jenkinsfile 진단을 얻는 유일한 경로다.
-- 플러그인은 늘지 않고(nvim-lint 재사용) 시작 비용도 없다 — autocmd 하나다.
--
-- 자격증명은 환경변수를 먼저 보고, 없으면 vim.g를 본다:
--   JENKINS_URL   / vim.g.jenkins_url     예: https://jenkins.example.com
--   JENKINS_USER  / vim.g.jenkins_user
--   JENKINS_TOKEN / vim.g.jenkins_token   Jenkins API 토큰
-- vim.g 쪽은 git이 추적하지 않는 lua/local.lua에 둔다.
-- 셸에서 주입하려면 `bb sec exec jenkins -- nvim`.
-- 셋 중 하나라도 비면 조용히 비활성화된다 (macism / alloy와 같은 규칙).
--
-- 토큰은 curl --variable/--expand-user로 환경에서 읽는다. argv에 들어가지 않아
-- 같은 머신의 `ps`에 보이지 않는다.
--
-- 네트워크를 타므로 저장할 때만 돈다. InsertLeave에서는 돌지 않는다.

local function jenkins_credentials()
  local function value_of(env_name, global_name)
    local value = vim.env[env_name]
    if value == nil or value == "" then
      value = vim.g[global_name]
    end
    if type(value) == "string" and value ~= "" then
      return value
    end
  end

  local url = value_of("JENKINS_URL", "jenkins_url")
  local user = value_of("JENKINS_USER", "jenkins_user")
  local token = value_of("JENKINS_TOKEN", "jenkins_token")
  if not (url and user and token) then
    return nil
  end
  return { url = (url:gsub("/+$", "")), user = user, token = token }
end

-- 응답 형식:
--   Jenkinsfile successfully validated.
-- 또는
--   Errors encountered validating Jenkinsfile:
--   WorkflowScript: 12: Expected a step @ line 12, column 9.
--      echo
--      ^
local function parse_jenkins(output, bufnr)
  local diagnostics = {}
  if output == "" or output:find("successfully validated", 1, true) then
    return diagnostics
  end

  local last_line = math.max(vim.api.nvim_buf_line_count(bufnr) - 1, 0)
  local function add(lnum, col, message, severity)
    diagnostics[#diagnostics + 1] = {
      lnum = math.min(math.max(lnum, 0), last_line),
      col = math.max(col, 0),
      severity = severity or vim.diagnostic.severity.ERROR,
      source = "jenkins",
      message = message,
    }
  end

  local first_line
  for line in vim.gsplit(output, "\n", { plain = true }) do
    if not first_line and vim.trim(line) ~= "" then
      first_line = vim.trim(line)
    end
    local message, lnum, col = line:match("^WorkflowScript:%s*%d+:%s*(.-)%s*@ line (%d+), column (%d+)")
    if message then
      add(tonumber(lnum) - 1, tonumber(col) - 1, message)
    else
      -- `@ line ...` 꼬리가 없는 형태
      local plain_lnum, plain_message = line:match("^WorkflowScript:%s*(%d+):%s*(.+)$")
      if plain_lnum then
        add(tonumber(plain_lnum) - 1, 0, vim.trim(plain_message))
      end
    end
  end

  -- 성공도 아니고 해석도 안 됐다면 인증·URL·네트워크 쪽 문제일 가능성이 높다.
  -- 조용히 넘기면 설정이 틀린 걸 알 수 없으므로 한 줄만 올린다.
  if #diagnostics == 0 then
    local detail = (first_line or "빈 응답"):sub(1, 200)
    add(0, 0, "jenkins validate 응답을 해석하지 못했다: " .. detail, vim.diagnostic.severity.WARN)
  end
  return diagnostics
end

local function jenkins_linter(config)
  -- nvim-lint의 env는 자식 환경을 통째로 교체한다 (PATH만 자동으로 붙는다).
  -- 사내망에서 필요한 프록시 설정은 명시적으로 넘긴다.
  local env = { JENKINS_USER = config.user, JENKINS_TOKEN = config.token }
  for _, name in ipairs({ "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "no_proxy" }) do
    local value = vim.env[name]
    if value and value ~= "" then
      env[name] = value
    end
  end

  return {
    cmd = "curl",
    stdin = false,
    append_fname = false,
    ignore_exitcode = true,
    stream = "stdout",
    env = env,
    args = {
      "--silent",
      "--show-error",
      -- curl 자신의 오류(연결 실패, DNS, 타임아웃)도 stdout으로 보낸다.
      -- 그래야 응답 본문과 같은 스트림에서 파서가 보고 WARN을 올린다.
      "--stderr",
      "-",
      "--max-time",
      "10",
      "--variable",
      "%JENKINS_USER",
      "--variable",
      "%JENKINS_TOKEN",
      "--expand-user",
      "{{JENKINS_USER}}:{{JENKINS_TOKEN}}",
      "--form",
      function()
        return "jenkinsfile=<" .. vim.api.nvim_buf_get_name(0)
      end,
      config.url .. "/pipeline-model-converter/validate",
    },
    parser = parse_jenkins,
  }
end

local function lint_jenkinsfile(notify)
  local function complain(message)
    if notify then
      vim.notify(message, vim.log.levels.WARN)
    end
  end

  if vim.api.nvim_buf_get_name(0) == "" then
    return complain("이름 없는 버퍼는 검증할 수 없다")
  end
  if vim.fn.executable("curl") == 0 then
    return complain("curl을 찾지 못했다")
  end
  local config = jenkins_credentials()
  if not config then
    return complain("Jenkins 자격증명이 없다 (JENKINS_URL / JENKINS_USER / JENKINS_TOKEN)")
  end

  -- 자격증명은 실행 시점의 값이어야 하므로 정의를 매번 새로 만든다.
  lint.linters.jenkins = jenkins_linter(config)
  lint.try_lint("jenkins")
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("jenkins_lint", { clear = true }),
  pattern = { "Jenkinsfile", "Jenkinsfile.*", "*.Jenkinsfile", "*.jenkinsfile" },
  callback = function()
    lint_jenkinsfile(false)
  end,
})

vim.api.nvim_create_user_command("JenkinsLint", function()
  if vim.bo.modified then
    vim.notify("저장하지 않은 변경이 있다. 디스크 내용으로 검사한다.", vim.log.levels.WARN)
  end
  lint_jenkinsfile(true)
end, { desc = "현재 파일을 Jenkins 서버로 검증" })

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
  { "<leader>a", group = "ai" },
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>f", group = "file/find" },
  { "<leader>g", group = "git" },
  { "<leader>gx", group = "conflict" },
  { "<leader>q", group = "session/quit" },
  { "<leader>s", group = "search" },
  { "<leader>t", group = "terminal" },
  { "<leader>u", group = "ui/toggle" },
  { "<leader>x", group = "diagnostics" },
})
