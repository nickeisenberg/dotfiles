-- The :Pack* user commands.

local build = require("pack.build")
local config = require("pack.config")
local confirm = require("pack.confirm")
local registry = require("pack.registry")

local M = {}

local function installed_names(arglead)
  return vim
    .iter(vim.pack.get(nil, { info = false }))
    :map(function(p)
      return p.spec.name
    end)
    :filter(function(name)
      return vim.startswith(name, arglead)
    end)
    :totable()
end

local function buildable_names(arglead)
  return vim
    .iter(registry.plugins)
    :filter(function(spec)
      return spec.build and vim.startswith(spec.name, arglead)
    end)
    :map(function(spec)
      return spec.name
    end)
    :totable()
end

local function update(names, opts)
  -- With `force` there is no confirmation buffer to decorate.
  if not opts.force then
    confirm.decorate_next()
  end
  vim.pack.update(names, opts)
end

-- Stale means in no spec and not loaded. The spec check keeps a plugin
-- that just hasn't been loaded yet; the `active` check skips plugins other
-- code added this session, which vim.pack.del() refuses to remove.
local function clean(o)
  local stale = vim
    .iter(vim.pack.get(nil, { info = false }))
    :filter(function(p)
      return not registry.by_name[p.spec.name] and not p.active
    end)
    :map(function(p)
      return p.spec.name
    end)
    :totable()

  if #stale == 0 then
    config.notify("nothing to clean")
    return
  end

  local list = table.concat(stale, ", ")
  if not o.bang then
    local choice = vim.fn.confirm("Delete " .. list .. "?", "&Yes\n&No", 2)
    if choice ~= 1 then
      return
    end
  end

  vim.pack.del(stale)
  config.notify("removed " .. list)
end

function M.setup()
  vim.api.nvim_create_user_command("PackUpdate", function(o)
    update(#o.fargs > 0 and o.fargs or nil, { force = o.bang })
  end, {
    nargs = "*",
    bang = true,
    complete = installed_names,
    desc = "Update plugins (! to skip confirmation)",
  })

  vim.api.nvim_create_user_command("PackStatus", function()
    update(nil, { offline = true })
  end, { desc = "Show installed plugins without fetching" })

  vim.api.nvim_create_user_command("PackBuild", function(o)
    build.run_all(#o.fargs > 0 and o.fargs or nil)
  end, {
    nargs = "*",
    complete = buildable_names,
    desc = "Run plugin builds (all that have one by default)",
  })

  vim.api.nvim_create_user_command("PackClean", clean, {
    bang = true,
    desc = "Delete plugins that are no longer in any spec",
  })
end

return M
