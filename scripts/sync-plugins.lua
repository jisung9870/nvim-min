-- Apply committed pins without creating whitespace-only lockfile changes.
local path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
local original = vim.fn.readfile(path, "b")
local ok, err = pcall(vim.pack.update, nil, { target = "lockfile", force = true })
if not ok then
  print(err)
  vim.cmd("cquit")
end
local updated = vim.fn.readfile(path, "b")
if vim.deep_equal(vim.json.decode(table.concat(original, "\n")), vim.json.decode(table.concat(updated, "\n"))) then
  vim.fn.writefile(original, path, "b")
end
