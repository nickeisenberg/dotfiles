-- LSP configuration for the Lua language server.
--
-- Neovim 0.11+ uses `vim.lsp.enable()` which automatically picks up files
-- inside the `lsp/` folder. This file is returned as a Lua table and Neovim
-- passes it straight to the LSP client.
--
-- Requirements: lua-language-server must be on your $PATH.
--   brew install lua-language-server

-- Neovim's runtime plus every plugin on disk, so `require("<plugin>")`
-- resolves for go-to-definition and hover. Remote plugins live where
-- vim.pack installs them; local ones live in the config's plugins/ dir.
-- Only each plugin's lua/ dir is added, which skips tests and fixtures.
local library = { vim.env.VIMRUNTIME }
for _, pattern in ipairs({
  vim.fn.stdpath("data") .. "/site/pack/core/opt/*/lua",
  vim.fn.stdpath("config") .. "/plugins/*/lua",
}) do
  vim.list_extend(library, vim.fn.glob(pattern, false, true))
end

return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      -- Neovim embeds LuaJIT, not vanilla Lua 5.1.
      runtime = {
        version = "LuaJIT",
        -- Resolve require("x") only from the start of a library or
        -- workspace root, the way Neovim does. Without this, lua_ls
        -- matches any file whose path ends in x.lua, so
        -- require("format") could land on snacks/picker/format.lua.
        -- The lua/ patterns cover the workspace and $VIMRUNTIME; the
        -- bare ones cover the plugin lua/ dirs above.
        path = { "lua/?.lua", "lua/?/init.lua", "?.lua", "?/init.lua" },
        pathStrict = true,
      },
      workspace = {
        -- Don't prompt about third-party libraries.
        checkThirdParty = false,
        library = library,
      },
    },
  },
}
