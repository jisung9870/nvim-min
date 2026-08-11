-- ============================================================================
-- 플러그인 목록 (vim.pack)
-- ============================================================================
-- vim.pack API는 이게 전부다:
--   vim.pack.add(specs, opts)  설치 + packadd
--   vim.pack.update(names)     업데이트 (확인 버퍼 → :w 확정 / :q 취소)
--   vim.pack.del(names)        디스크에서 삭제
--   vim.pack.get()             설치된 목록
--
-- 설치 위치: ~/.local/share/nvim-min/site/pack/core/opt/
-- 잠금 파일: ./nvim-pack-lock.json  (git 추적함 — 다른 머신에서 동일 리비전 재현)
--
-- lazy-loading은 없다. init.lua 소싱 중에는 `load=false`(= :packadd!)라
-- plugin/ 스크립트가 startup 정규 시점에 한 번에 소싱된다.
--
-- 전환 기준 (메모): 아래 목록이 30줄을 넘거나, 시작이 150ms를 넘거나,
-- nvim-dap+neotest급 스택이 필요해지면 lazy.nvim으로 옮긴다.
-- 비용은 이 파일 하나.
-- ============================================================================

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("catppuccin/nvim"), name = "catppuccin" },
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("mason-org/mason.nvim") },
  { src = gh("Saghen/blink.cmp"), version = vim.version.range("1") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("mfussenegger/nvim-lint") },
  { src = gh("folke/snacks.nvim") },
  { src = gh("folke/which-key.nvim") },
  { src = gh("lewis6991/gitsigns.nvim") },
  { src = gh("sindrets/diffview.nvim") },
  { src = gh("akinsho/toggleterm.nvim") },
  { src = gh("christoomey/vim-tmux-navigator") },
  { src = gh("echasnovski/mini.icons") },
  { src = gh("echasnovski/mini.pairs") },
  { src = gh("echasnovski/mini.surround") },
  { src = gh("keaising/im-select.nvim") },
}, { confirm = false })

-- 업데이트/정리용 단축 명령
vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, { desc = "플러그인 업데이트 (확인 버퍼에서 :w 확정)" })

vim.api.nvim_create_user_command("PackStatus", function()
  vim.pack.update(nil, { offline = true })
end, { desc = "설치된 플러그인 목록 (네트워크 없이)" })

vim.api.nvim_create_user_command("PackClean", function()
  local stale = vim.iter(vim.pack.get())
    :filter(function(p)
      return not p.active
    end)
    :map(function(p)
      return p.spec.name
    end)
    :totable()
  if #stale == 0 then
    vim.notify("정리할 플러그인 없음", vim.log.levels.INFO)
    return
  end
  vim.ui.select({ "삭제", "취소" }, { prompt = "삭제: " .. table.concat(stale, ", ") }, function(choice)
    if choice == "삭제" then
      vim.pack.del(stale)
    end
  end)
end, { desc = "목록에서 빠진 플러그인 삭제" })
