-- A thin wrapper around vim.pack.
--
-- Each file in `lua/<import>/` (except init.lua) returns one spec or a list
-- of specs. A spec looks like:
--
--   {
--     "owner/repo",            -- or a git URL, `src = ...`, or a local path
--     name = "repo",           -- optional, defaults to the repo name
--     version = "main",        -- optional, passed through to vim.pack
--     dir = "picker.nvim",     -- local plugin; relative to `local_dir`
--     deps = { "owner/dep" },  -- specs added before this one
--     build = "make",          -- shell cmd, ":VimCmd", or function(plugin)
--     config = function() end, -- run after every plugin is added
--     enabled = false,         -- skip this spec
--   }

local M = {}

local defaults = {
  -- Lua module directory scanned for spec files.
  import = "plugins",
  -- Where relative `dir` paths of local plugins are resolved.
  local_dir = vim.fn.stdpath("config") .. "/plugins",
  -- Prefix for "owner/repo" shorthand.
  base_url = "https://github.com/",
}

M.config = vim.deepcopy(defaults)

---Resolved specs in load order.
M.plugins = {}

---Resolved specs by name.
M.by_name = {}

local function notify(msg, level)
  vim.notify("pack: " .. msg, level or vim.log.levels.INFO)
end

local function to_src(s)
  if s:match("^%a[%w+.-]*://") or s:match("^git@") then
    return s
  end
  return M.config.base_url .. s
end

local function normalize(raw)
  if type(raw) == "string" then
    raw = { raw }
  end
  local spec = vim.tbl_extend("force", {}, raw)

  -- Paths like "/abc", "~/abc" or "./abc" are shorthand for `dir`.
  if not spec.dir and type(spec[1]) == "string" and spec[1]:match("^[/~.]") then
    spec.dir = spec[1]
  end

  if spec.dir then
    local path = vim.fs.normalize(spec.dir)
    if path:sub(1, 1) ~= "/" then
      path = M.config.local_dir .. "/" .. path
    end
    spec.path = path
    spec.name = spec.name or vim.fs.basename(path)
  else
    local src = spec.src or spec[1]
    assert(type(src) == "string", "pack: spec has no source")
    spec.src = to_src(src)
    spec.name = spec.name or (spec.src:gsub("%.git$", "")):match("[^/]+$")
  end
  spec[1] = nil

  return spec
end

-- A table is a list of specs when its first item is a table, or when it is
-- a plain list of several strings. `{ "a/b", config = ... }` is one spec.
local function is_spec_list(raw)
  return type(raw) == "table"
    and (type(raw[1]) == "table" or (vim.islist(raw) and #raw > 1))
end

local function add(raw)
  if is_spec_list(raw) then
    for _, r in ipairs(raw) do
      add(r)
    end
    return
  end

  local spec = normalize(raw)
  if spec.enabled == false then
    return
  end

  for _, dep in ipairs(spec.deps or {}) do
    add(dep)
  end

  -- A plugin listed both as a dependency and on its own is merged.
  local existing = M.by_name[spec.name]
  if existing then
    for k, v in pairs(spec) do
      if existing[k] == nil then
        existing[k] = v
      end
    end
  else
    M.by_name[spec.name] = spec
    M.plugins[#M.plugins + 1] = spec
  end
end

local function spec_modules()
  local import = M.config.import
  local dir = vim.fn.stdpath("config") .. "/lua/" .. import:gsub("%.", "/")

  local mods = {}
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:match("%.lua$") and name ~= "init.lua" then
      mods[#mods + 1] = import .. "." .. name:gsub("%.lua$", "")
    end
  end
  table.sort(mods)

  return mods
end

local function run_build(spec, path)
  local build = spec.build

  if type(build) == "string" and build:sub(1, 1) ~= ":" then
    notify("building " .. spec.name)
    vim.system({ vim.o.shell, "-c", build }, { cwd = path }, function(res)
      if res.code ~= 0 then
        vim.schedule(function()
          notify(
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
    notify(
      ("build failed for %s:\n%s"):format(spec.name, err),
      vim.log.levels.ERROR
    )
  end
end

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

local function commit_message(path, sha)
  local res = vim
    .system({ "git", "-C", path, "log", "-1", "--format=%s (%cr)", sha })
    :wait()
  if res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout)
end

-- Add a "Message:" line under every "Revision...:" line of the vim.pack
-- confirmation buffer. Only `#` and `##` headers matter when it is written,
-- so the extra lines are safe.
local function add_commit_messages(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local out, path = {}, nil

  for _, line in ipairs(lines) do
    out[#out + 1] = line
    path = line:match("^Path:%s+(.+)$") or path

    local label, sha = line:match("^(Revision[^:]*:%s+)(%x+)")
    local msg = label and path and commit_message(path, sha)
    if msg then
      local suffix = label:match("^Revision([^:]*):")
      local width = "%-" .. #label .. "s"
      out[#out + 1] = width:format("Message" .. suffix .. ":") .. msg
    end
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false
end

local function pack_update(names, opts)
  -- With `force` there is no confirmation buffer to decorate.
  if not opts.force then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "nvim-pack",
      once = true,
      callback = function(ev)
        add_commit_messages(ev.buf)
      end,
    })
  end
  vim.pack.update(names, opts)
end

local function create_commands()
  vim.api.nvim_create_user_command("PackUpdate", function(o)
    pack_update(#o.fargs > 0 and o.fargs or nil, { force = o.bang })
  end, {
    nargs = "*",
    bang = true,
    complete = installed_names,
    desc = "Update plugins (! to skip confirmation)",
  })

  vim.api.nvim_create_user_command("PackStatus", function()
    pack_update(nil, { offline = true })
  end, { desc = "Show installed plugins without fetching" })

  vim.api.nvim_create_user_command("PackClean", function(o)
    local stale = vim
      .iter(vim.pack.get(nil, { info = false }))
      :filter(function(p)
        return not p.active
      end)
      :map(function(p)
        return p.spec.name
      end)
      :totable()

    if #stale == 0 then
      notify("nothing to clean")
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
    notify("removed " .. list)
  end, {
    bang = true,
    desc = "Delete plugins that are no longer in any spec",
  })
end

---@param opts? table
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  for _, mod in ipairs(spec_modules()) do
    local ok, ret = pcall(require, mod)
    if not ok then
      notify(("failed to load %s:\n%s"):format(mod, ret), vim.log.levels.ERROR)
    elseif type(ret) == "table" or type(ret) == "string" then
      add(ret)
    end
  end

  -- Must exist before vim.pack.add() so builds run on first install.
  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("pack_build", { clear = true }),
    callback = function(ev)
      local data = ev.data
      if data.kind ~= "install" and data.kind ~= "update" then
        return
      end
      local spec = M.by_name[data.spec.name]
      if spec and spec.build then
        run_build(spec, data.path)
      end
    end,
  })

  local remote = {}
  for _, spec in ipairs(M.plugins) do
    if spec.path then
      vim.opt.runtimepath:prepend(spec.path)
    else
      remote[#remote + 1] = {
        src = spec.src,
        name = spec.name,
        version = spec.version,
      }
    end
  end
  vim.pack.add(remote)

  for _, spec in ipairs(M.plugins) do
    if spec.config then
      local ok, err = xpcall(spec.config, debug.traceback, spec)
      if not ok then
        notify(
          ("config failed for %s:\n%s"):format(spec.name, err),
          vim.log.levels.ERROR
        )
      end
    end
  end

  create_commands()
end

return M
