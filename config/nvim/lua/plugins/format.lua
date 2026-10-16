return {
  dir = "format.nvim",
  config = function()
    require("format").setup({
      formatters = {
        lua = {
          { command = "stylua", args = { "-" } },
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
