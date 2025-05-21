vim.o.termguicolors = true
vim.o.mouse = 'a'
vim.o.hlsearch = false
vim.o.background = "dark"

vim.o.shell = vim.o.shell .. " --login"

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- line numbers
vim.wo.nu = true
vim.wo.relativenumber = true

vim.o.foldmethod = "indent"
vim.o.foldlevelstart = 99

-- Toggel error messages in a floating window
vim.diagnostic.config({ virtual_text = false })

vim.diagnostic.config({
  virtual_text = false,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
  signs = true,
  underline = true,
  update_in_insert = true,
  severity_sort = false,
})


if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = '/mnt/c/Windows/System32/clip.exe',
      ['*'] = '/mnt/c/Windows/System32/clip.exe',
    },
    paste = {
      ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end

