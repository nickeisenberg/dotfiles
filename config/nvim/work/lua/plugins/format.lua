return {
  dir = "format.nvim",
  config = function()
    require("format").setup({
      formatters = {
        lua = {
          -- --stdin-filepath makes stylua look for stylua.toml from the
          -- file's directory; otherwise it looks from Neovim's working
          -- directory and falls back to tabs outside this config.
          {
            command = "stylua",
            args = function(bufname)
              return { "--stdin-filepath", bufname, "-" }
            end,
          },
        },
        tex = {
          { command = "tex-fmt", args = { "--stdin" } },
        },
        python = {
          -- Fixes first (unused imports, import order), then layout.
          {
            command = "ruff",
            args = function(bufname)
              return {
                "check",
                "--fix",
                "--exit-zero",
                "--stdin-filename",
                bufname,
                "-",
              }
            end,
          },
          {
            command = "ruff",
            args = function(bufname)
              return { "format", "--stdin-filename", bufname, "-" }
            end,
          },
        },
      },
    })
  end,
}
