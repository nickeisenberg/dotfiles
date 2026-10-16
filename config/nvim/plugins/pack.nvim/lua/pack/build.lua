-- Running a spec's `build` after its plugin is installed or updated.

local config = require("pack.config")
local registry = require("pack.registry")

local M = {}

function M.run(spec, path)
  local build = spec.build

  if type(build) == "string" and build:sub(1, 1) ~= ":" then
    config.notify("building " .. spec.name)
    vim.system({ vim.o.shell, "-c", build }, { cwd = path }, function(res)
      if res.code ~= 0 then
        vim.schedule(function()
          config.notify(
            ("build failed for %s:\n%s"):format(spec.name, res.stderr),
            vim.log.levels.ERROR
          )
        end)
      end
    end)
    return
  end

  -- Vim commands and functions rely on the plugin's code being loaded.
  vim.cmd.packadd(spec.name)
  local ok, err = pcall(function()
    if type(build) == "function" then
      build({ spec = spec, path = path })
    else
      vim.cmd(build:sub(2))
    end
  end)
  if not ok then
    config.notify(
      ("build failed for %s:\n%s"):format(spec.name, err),
      vim.log.levels.ERROR
    )
  end
end

---Must run before vim.pack.add() so builds run on first install.
function M.setup()
  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("pack_build", { clear = true }),
    callback = function(ev)
      local data = ev.data
      if data.kind ~= "install" and data.kind ~= "update" then
        return
      end
      local spec = registry.by_name[data.spec.name]
      if spec and spec.build then
        M.run(spec, data.path)
      end
    end,
  })
end

return M
