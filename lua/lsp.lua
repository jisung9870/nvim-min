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
  "jsonls",
  "terraformls",
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
  "json-lsp",
  "terraform-ls",
  "pyright",
  "ruff",
  "gopls",
  "bash-language-server",
  "marksman",
  -- 린터/포매터
  "yamllint",
  "actionlint",
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
        ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/"
          .. (vim.g.k8s_schema_version or "v1.33.1")
          .. "-standalone-strict/all.json"] = {
          "k8s/**/*.yaml",
          "manifests/**/*.yaml",
          "*.k8s.yaml",
        },
        ["https://json.schemastore.org/kustomization.json"] = "kustomization.{yml,yaml}",
        ["https://json.schemastore.org/chart.json"] = "Chart.{yml,yaml}",
        ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
        ["https://json.schemastore.org/github-action.json"] = ".github/actions/**/action.{yml,yaml}",
        ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
        ["https://json.schemastore.org/ansible-playbook.json"] = "playbooks/**/*.{yml,yaml}",
      },
    },
  },
})

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
})

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
