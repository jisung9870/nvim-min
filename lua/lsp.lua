-- ============================================================================
-- LSP
-- ============================================================================
-- nvim 0.11+ 네이티브 API만 쓴다.
--   vim.lsp.config(name, opts)  설정 덮어쓰기
--   vim.lsp.enable({names})     해당 filetype에서 자동 시작
--
-- 서버 기본 설정(cmd, filetypes, root_markers)은 nvim-lspconfig가 제공하는
-- `lsp/<name>.lua` 파일에서 자동으로 읽힌다. lspconfig의 옛 setup{} API는
-- 쓰지 않는다.
--
-- 서버 바이너리는 mason으로 설치한다: `:Mason` 또는 `:LspInstallAll`
-- ============================================================================

require("mason").setup({
  ui = { border = "rounded" },
})

-- 실측 작업 스택 기준 서버 목록 --------------------------------------------
-- YAML > Jenkinsfile > Python > Terraform > SQL > Go
-- Groovy LSP는 JDK가 필요해서 뺐다 (Jenkinsfile은 treesitter 하이라이트만).
local servers = {
  "lua_ls",
  "yamlls",
  "ansiblels",
  "jsonls",
  "terraformls",
  "taplo", -- TOML
  "pyright",
  "ruff",
  "gopls",
  "bashls",
  "marksman",
}

-- mason 패키지 이름 (LSP 이름과 다름)
local mason_packages = {
  "lua-language-server",
  "yaml-language-server",
  "ansible-language-server",
  "json-lsp",
  "terraform-ls",
  "taplo",
  "pyright",
  "ruff",
  "gopls",
  "bash-language-server",
  "marksman",
  -- 린터/포매터
  "yamllint",
  "actionlint",
  "ansible-lint", -- ansiblels가 내부에서 호출한다
  "tflint",
  "hadolint",
  "sqlfluff",
  "shellcheck",
  "shfmt",
  "stylua",
  "prettier",
}

-- 이미 깔린 건 건너뛴다 (새 머신에서 여러 번 돌려도 안전)
vim.api.nvim_create_user_command("LspInstallAll", function()
  local registry = require("mason-registry")

  local missing = vim.tbl_filter(function(name)
    local ok, pkg = pcall(registry.get_package, name)
    return ok and not pkg:is_installed()
  end, mason_packages)

  if #missing == 0 then
    vim.notify("mason 패키지 " .. #mason_packages .. "개 전부 설치되어 있음", vim.log.levels.INFO)
    return
  end

  vim.notify("설치: " .. table.concat(missing, ", "), vim.log.levels.INFO)
  vim.cmd("MasonInstall " .. table.concat(missing, " "))
end, { desc = "이 설정이 쓰는 LSP/린터/포매터 설치 (없는 것만)" })

-- 서버별 커스텀 설정 --------------------------------------------------------

--- 클라이언트 하나에만 적용되는 설정 덮어쓰기.
---
--- 서버가 workspace/configuration으로 설정을 당겨갈 때 nvim은 `client.settings`를
--- 읽는다. `before_init`에서 `config.settings`를 새 테이블로 바꿔도 client.settings는
--- 원래 테이블을 계속 가리키므로 값이 서버에 도달하지 않는다.
--- 클라이언트마다 복사본을 만들어 고쳐야 다른 프로젝트로 값이 새지도 않는다.
local function override_settings(client, patch)
  client.settings = vim.tbl_deep_extend("force", vim.deepcopy(client.settings or {}), patch)
  client:notify("workspace/didChangeConfiguration", { settings = client.settings })
end

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false },
      diagnostics = { globals = { "vim" } },
      hint = { enable = true },
      telemetry = { enable = false },
    },
  },
})

-- ansible-lint가 배포하는 스키마. schemastore 쪽 ansible 항목은 없어졌다.
local ansible_schema = "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/"

vim.lsp.config("yamlls", {
  filetypes = { "yaml", "yaml.ansible", "yaml.ghaction", "helm" },
  settings = {
    yaml = {
      validate = true,
      hover = true,
      completion = true,
      keyOrdering = false, -- 키 정렬 강제 끄기 (K8s manifest에서 시끄러움)
      schemaStore = {
        enable = true,
        url = "https://www.schemastore.org/api/json/catalog.json",
      },
      schemas = {
        -- Kubernetes: kind/apiVersion 자동 감지 대신 경로 규칙으로 붙인다.
        -- (schema-companion 없이 가는 대신 명시적으로)
        ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/" .. (vim.g.k8s_schema_version or "v1.33.1") .. "-standalone-strict/all.json"] = {
          "k8s/**/*.yaml",
          "manifests/**/*.yaml",
          "*.k8s.yaml",
        },
        ["https://json.schemastore.org/kustomization.json"] = "kustomization.{yml,yaml}",
        ["https://json.schemastore.org/chart.json"] = "Chart.{yml,yaml}",
        ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
        ["https://json.schemastore.org/github-action.json"] = ".github/actions/**/action.{yml,yaml}",
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",

        -- Ansible 스키마는 ansible-lint가 배포하는 것을 쓴다.
        -- schemastore의 ansible-playbook.json은 301 뒤 404다. yamlls가
        -- 리다이렉트를 따라가지 않아 플레이북을 열 때마다
        -- "Unable to load schema ... No content" 진단이 떴다.
        [ansible_schema .. "playbook.json"] = {
          "playbooks/**/*.{yml,yaml}",
          "site.{yml,yaml}",
        },
        [ansible_schema .. "tasks.json"] = {
          "roles/*/tasks/*.{yml,yaml}",
          "roles/*/handlers/*.{yml,yaml}",
        },
      },
    },
  },
})

-- Ansible ---------------------------------------------------------------------
-- yamlls는 YAML 구조를, ansiblels는 모듈 이름·파라미터·문서를 담당한다.
-- ansiblels가 ansible-lint를 직접 호출하므로 nvim-lint 쪽에는 Ansible 린터를
-- 넣지 않는다 (같은 진단이 두 번 뜬다).
vim.lsp.config("ansiblels", {
  settings = {
    ansible = {
      validation = {
        enabled = true,
        lint = { enabled = true, path = "ansible-lint" },
      },
      -- 컨테이너 실행 환경은 쓰지 않는다. 로컬 ansible 설치를 그대로 본다.
      executionEnvironment = { enabled = false },
    },
  },
})

-- Python 인터프리터 탐지 ----------------------------------------------------
-- pyright는 pythonPath를 안 주면 PATH의 python을 쓴다. 그러면 프로젝트
-- 가상환경에만 있는 패키지가 전부 "could not be resolved"가 되고, 그 패키지에
-- 대한 타입·완성·정의 이동이 통째로 죽는다.
--
-- 우선순위:
--   1. VIRTUAL_ENV / CONDA_PREFIX — 셸에서 이미 활성화했으면 그게 의도다
--   2. 파일에서 위로 올라가며 만나는 첫 .venv 또는 venv
--      (루트가 아니라 파일 기준이라 서비스마다 venv가 따로인 저장소도 맞는다)
-- 둘 다 없으면 pythonPath를 넘기지 않고 pyright 기본 동작에 맡긴다.

local function nearest_venv(start)
  local found = vim.fs.find(function(name, dir)
    if name ~= ".venv" and name ~= "venv" then
      return false
    end
    return vim.uv.fs_stat(dir .. "/" .. name .. "/bin/python") ~= nil
  end, { path = start, upward = true, type = "directory", limit = 1 })
  return found[1]
end

local function python_interpreter(start)
  for _, prefix in ipairs({ vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX }) do
    if prefix and prefix ~= "" and vim.uv.fs_stat(prefix .. "/bin/python") then
      return prefix .. "/bin/python", "환경변수"
    end
  end
  if start == nil or start == "" then
    start = vim.api.nvim_buf_get_name(0)
  end
  if start == "" then
    start = vim.fn.getcwd()
  end
  local venv = nearest_venv(start)
  if venv then
    return venv .. "/bin/python", venv
  end
  return nil, nil
end

vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        -- ruff가 import 정리/린트를 담당하므로 중복 진단을 끈다
        diagnosticSeverityOverrides = {
          reportUnusedImport = "none",
          reportUnusedVariable = "none",
        },
      },
    },
  },
  on_init = function(client)
    local interpreter = python_interpreter(client.root_dir)
    if interpreter then
      override_settings(client, { python = { pythonPath = interpreter } })
    end
  end,
})

vim.api.nvim_create_user_command("PythonEnv", function()
  local interpreter, source = python_interpreter(nil)
  if not interpreter then
    vim.notify("가상환경을 찾지 못했다. pyright가 PATH의 python을 쓴다.", vim.log.levels.WARN)
    return
  end
  vim.notify(("pyright 인터프리터: %s\n출처: %s"):format(interpreter, source), vim.log.levels.INFO)
end, { desc = "pyright가 쓰는 Python 인터프리터 확인" })

-- Go 빌드 태그 --------------------------------------------------------------
-- `//go:build integration` 같은 태그가 붙은 파일은 기본 빌드에 들어가지 않아
-- gopls가 "No packages found for open file"로 통째로 포기한다. 태그는 저장소마다
-- 다르므로 값은 설정에 박지 않는다.
--
--   lua/local.lua 에서:  vim.g.go_build_tags = { "integration", "e2e" }
--   또는 그 자리에서:     :GoBuildTags integration,e2e
--
-- vim.g는 lsp.lua보다 늦게 로드되는 local.lua에서도 잡히도록 attach 시점에 읽는다.
local function go_build_flags()
  local tags = vim.g.go_build_tags
  if type(tags) == "table" then
    tags = table.concat(tags, ",")
  end
  if type(tags) ~= "string" or tags == "" then
    return nil
  end
  return { "-tags=" .. tags }
end

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      analyses = { unusedparams = true, shadow = true },
      hints = {
        parameterNames = true,
        assignVariableTypes = true,
        rangeVariableTypes = true,
      },
    },
  },
  on_init = function(client)
    local flags = go_build_flags()
    if flags then
      override_settings(client, { gopls = { buildFlags = flags } })
    end
  end,
})

vim.api.nvim_create_user_command("GoBuildTags", function(args)
  vim.g.go_build_tags = vim.trim(args.args)
  -- 이 빌드에는 :LspRestart가 없다. 클라이언트를 멈추고 버퍼를 다시 읽어
  -- vim.lsp.enable의 자동 시작을 태우는 게 확실한 경로다.
  local clients = vim.lsp.get_clients({ name = "gopls" })
  for _, client in ipairs(clients) do
    client:stop()
  end
  vim.defer_fn(function()
    vim.cmd("silent! edit")
    if args.args == "" then
      vim.notify("Go 빌드 태그 해제", vim.log.levels.INFO)
    else
      vim.notify("Go 빌드 태그: " .. args.args, vim.log.levels.INFO)
    end
  end, 300)
end, {
  nargs = "?",
  desc = "gopls 빌드 태그 설정 후 재시작 (인자 없으면 해제)",
})

vim.lsp.config("bashls", {
  filetypes = { "sh", "bash" },
})

vim.lsp.enable(servers)

-- 버퍼별 LSP 키맵 -----------------------------------------------------------
-- nvim 0.11 기본 매핑으로 이미 있는 것: grn(rename), gra(code action),
-- grr(references), gri(implementation), grt(type def), gO(symbols), K(hover),
-- <C-s>(signature, insert 모드). 여기서는 익숙한 별칭만 얹는다.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(ev)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    map("n", "gd", function()
      Snacks.picker.lsp_definitions()
    end, "Goto definition")
    map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
    map("n", "gr", function()
      Snacks.picker.lsp_references()
    end, "References")
    map("n", "gI", function()
      Snacks.picker.lsp_implementations()
    end, "Goto implementation")
    map("n", "gy", function()
      Snacks.picker.lsp_type_definitions()
    end, "Goto type definition")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>cs", function()
      Snacks.picker.lsp_symbols()
    end, "Document symbols")

    -- inlay hint 지원 서버에서만 토글 제공
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") then
      map("n", "<leader>uh", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = ev.buf })
      end, "Toggle inlay hints")
    end
  end,
})
