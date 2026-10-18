-- Signs for lines added, changed or removed against the git index (or a
-- revision), updated as you type; and actions to jump between those hunks,
-- preview, stage or reset them, diff the file and blame a line.

local actions = require("hunks.actions")
local buffer = require("hunks.buffer")
local config = require("hunks.config")
local git = require("hunks.git")
local signs = require("hunks.signs")

local M = {}

M.preview = actions.preview
M.reset = actions.reset
M.stage = actions.stage
M.undo_stage = actions.undo_stage
M.diffthis = actions.diffthis
M.blame = actions.blame

---@param count? integer defaults to the count typed before the mapping
function M.next(count)
  actions.nav(true, count)
end

---@param count? integer
function M.prev(count)
  actions.nav(false, count)
end

function M.toggle()
  buffer.toggle()
  vim.api.nvim_echo(
    { { "hunks: signs " .. (buffer.enabled and "on" or "off") } },
    false,
    {}
  )
end

function M.refresh()
  buffer.refresh(vim.api.nvim_get_current_buf(), true)
end

-- Compare every buffer against `name` from now on: "index", or a revision
-- such as HEAD or main~2. Without a name, show the current one.
---@param name? string
function M.base(name)
  if not name or name == "" then
    vim.api.nvim_echo(
      { { "hunks: the base is " .. config.options.base } },
      false,
      {}
    )
    return
  end
  local path = vim.api.nvim_buf_get_name(0)
  local root = path ~= "" and git.root(path)
  if name ~= "index" and root then
    if
      not git.run(
        root,
        { "rev-parse", "--verify", "--quiet", name .. "^{commit}" }
      )
    then
      config.warn("no such revision: " .. name)
      return
    end
  end
  config.options.base = name
  buffer.refresh_all(true)
  vim.api.nvim_echo({ { "hunks: the base is " .. name } }, false, {})
end

-- :Hunks subcommands; each gets the command's arguments after its name and
-- its range, or nil without one.
local commands = {
  toggle = M.toggle,
  refresh = M.refresh,
  next = function(args)
    M.next(tonumber(args[1]))
  end,
  prev = function(args)
    M.prev(tonumber(args[1]))
  end,
  preview = M.preview,
  reset = function(_, range)
    M.reset(range)
  end,
  stage = function(_, range)
    M.stage(range)
  end,
  undo_stage = M.undo_stage,
  diffthis = M.diffthis,
  blame = M.blame,
  base = function(args)
    M.base(args[1])
  end,
}

local function command(cmd)
  local name = cmd.fargs[1]
  local run = commands[name]
  if not run then
    local names = vim.tbl_keys(commands)
    table.sort(names)
    config.warn(
      ('unknown command "%s", try one of: %s'):format(
        name,
        table.concat(names, ", ")
      )
    )
    return
  end
  run(
    vim.list_slice(cmd.fargs, 2),
    cmd.range > 0 and { cmd.line1, cmd.line2 } or nil
  )
end

local function complete(lead, line)
  local choices
  if line:match("Hunks%s+base%s") then
    choices = { "index", "HEAD" }
  elseif line:match("Hunks%s+%S+%s") then
    return {}
  else
    choices = vim.tbl_keys(commands)
    table.sort(choices)
  end
  return vim.tbl_filter(function(c)
    return vim.startswith(c, lead)
  end, choices)
end

---@param opts? table see hunks.config.defaults
function M.setup(opts)
  config.setup(opts)
  signs.highlights()

  vim.api.nvim_create_user_command(
    "Hunks",
    command,
    { nargs = "+", range = true, complete = complete }
  )

  -- Clearing the group makes calling setup() again safe.
  local group = vim.api.nvim_create_augroup("hunks", { clear = true })
  local function on(event, callback, pattern)
    vim.api.nvim_create_autocmd(
      event,
      { group = group, pattern = pattern, callback = callback }
    )
  end

  on({ "BufReadPost", "BufWritePost", "BufFilePost" }, function(ev)
    buffer.refresh(ev.buf)
  end)
  on({ "FocusGained", "ShellCmdPost" }, git.forget_roots)
  -- CursorHold and FocusGained catch a `git add` or commit made in a shell.
  on({ "BufEnter", "FocusGained", "ShellCmdPost", "CursorHold" }, function(ev)
    buffer.refresh(ev.buf)
  end)
  on("User", function()
    buffer.refresh_all()
  end, "FugitiveChanged")
  on("BufWipeout", function(ev)
    buffer.detach(ev.buf)
  end)
  on("ColorScheme", signs.highlights)

  -- Buffers loaded before setup().
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      buffer.refresh(bufnr)
    end
  end
end

return M
