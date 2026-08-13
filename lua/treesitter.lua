-- ============================================================================
-- treesitter (nvim-treesitter `main` 브랜치)
-- ============================================================================
-- main 브랜치는 예전 `configs.setup{}` 거대 테이블을 버렸다. 이제는
--   1) 파서를 설치하고           → require('nvim-treesitter').install()
--   2) 버퍼마다 켠다             → vim.treesitter.start()
-- 두 단계가 전부다. 하이라이트/폴드/들여쓰기는 nvim 내장 기능이 처리한다.
-- ============================================================================

local ts = require("nvim-treesitter")

ts.setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

-- 실사용 언어. nvim 0.12는 c/lua/markdown/vim/vimdoc/query 파서를 내장하고 있다.
local parsers = {
  "bash",
  "csv", -- 리포트/추출 데이터
  "diff",
  "dockerfile",
  "gitcommit",
  "git_rebase",
  "go",
  "gomod",
  "gosum",
  "gotmpl", -- Go 템플릿
  "gowork",
  "groovy", -- Jenkinsfile
  "hcl", -- 일반 HCL. Alloy는 전용 syntax/alloy.vim을 사용한다.
  "helm", -- Helm 차트 템플릿 ({{ }}를 YAML로 오파싱하지 않게)
  "ini", -- dosini (awscli config, systemd unit 등)
  "json",
  "make",
  "nginx",
  "properties", -- .env, *.properties
  "python",
  "regex",
  "sql",
  "terraform",
  "toml",
  "tsv",
  "xml",
  "yaml",
}

-- `.env`는 filetype이 `env`인데 같은 이름의 파서는 없다. 문법이 key=value로
-- 같으므로 properties 파서를 붙인다. 이게 없으면 하이라이트가 아예 없다.
vim.treesitter.language.register("properties", "env")

-- 없는 파서만 설치 (매 시작마다 네트워크를 때리지 않게)
local installed = ts.get_installed("parsers")
local missing = vim.tbl_filter(function(lang)
  return not vim.tbl_contains(installed, lang)
end, parsers)

if #missing > 0 then
  vim.notify("treesitter 파서 설치: " .. table.concat(missing, ", "), vim.log.levels.INFO)
  ts.install(missing) -- 비동기. 편집을 막지 않는다.
end

-- 파일을 열 때 하이라이트/폴드/들여쓰기 켜기
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or not vim.treesitter.language.add(lang) then
      return
    end

    vim.treesitter.start(ev.buf, lang)

    -- 폴드: treesitter 기반 (기존 ufo 대체)
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

    -- 들여쓰기: 파서가 indents.scm을 제공할 때만
    if vim.treesitter.query.get(lang, "indents") then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- 파서 업데이트
vim.api.nvim_create_user_command("TSUpdateAll", function()
  ts.update(nil, { summary = true })
end, { desc = "treesitter 파서 전체 업데이트" })

-- 목록의 파서를 전부 설치하고 끝날 때까지 기다린다 (headless/새 머신 세팅용)
vim.api.nvim_create_user_command("TSSync", function()
  ts.install(parsers, { force = true }):wait(600000)
end, { desc = "treesitter 파서 동기 설치" })
