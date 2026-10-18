-- Directories as buffers you edit to change the file system, like oil.nvim:
-- rename by editing a name, delete a line to delete, add one to create,
-- dd here and p in another directory to move, yy and p to copy. :w shows
-- what will happen and asks first. The design (a hidden number per line)
-- comes from mini.files.

local config = require("files.config")
local fs = require("files.fs")
local git = require("files.git")
local preview = require("files.preview")
local sync = require("files.sync")
local view = require("files.view")

local M = {}

local function full(path)
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  return path == "/" and path or (path:gsub("/$", ""))
end

-- Show `dir` in the current window, with the cursor on `focus` (a name).
---@param dir? string defaults to the current file's directory, or in a
--- directory buffer, its parent
---@param focus? string
function M.open(dir, focus)
  if not dir then
    local name = vim.api.nvim_buf_get_name(0)
    local current = view.dir(0)
    if current then
      dir, focus = vim.fs.dirname(current), vim.fs.basename(current)
    elseif name ~= "" and vim.bo.buftype == "" then
      dir, focus = vim.fs.dirname(full(name)), vim.fs.basename(name)
    else
      dir = vim.fn.getcwd()
    end
  end
  dir = full(dir)
  if not fs.is_dir(dir) then
    config.notify(dir .. " is not a directory", vim.log.levels.ERROR)
    return
  end
  -- Where <C-c> goes back to.
  if not view.dir(0) then
    vim.w.files_return = vim.api.nvim_get_current_buf()
  end
  vim.cmd.edit(vim.fn.fnameescape(view.name(dir)))
  if focus then
    view.render(0, focus)
  end
end

-- Open the entry under the cursor here, or after `split` ("vsplit",
-- "split", "tab").
local function select(split)
  local line = vim.api.nvim_get_current_line()
  local entry = view.parse(line)
  local path = view.path_at(line)
  if not path then
    if entry then
      config.notify("save your changes first", vim.log.levels.WARN)
    end
    return
  end
  -- From ../, land on the directory we came from.
  local focus = entry.parent and vim.fs.basename(view.dir(0)) or nil
  if split then
    vim.cmd(split == "tab" and "tabnew" or split)
  end
  if fs.is_dir(path) then
    M.open(path, focus)
  else
    vim.cmd.edit(vim.fn.fnameescape(vim.fn.fnamemodify(path, ":.")))
  end
end

M.actions = {
  select = function()
    select()
  end,
  select_vsplit = function()
    select("vsplit")
  end,
  select_split = function()
    select("split")
  end,
  select_tab = function()
    select("tab")
  end,
  preview = preview.toggle,
  close = function()
    local back = vim.w.files_return
    if back and vim.api.nvim_buf_is_valid(back) then
      vim.api.nvim_win_set_buf(0, back)
    else
      config.notify("no buffer to go back to", vim.log.levels.WARN)
    end
  end,
  parent = function()
    if view.dir(0) ~= "/" then
      M.open()
    end
  end,
  cwd = function()
    M.open(vim.fn.getcwd())
  end,
  toggle_hidden = function()
    config.options.show_hidden = not config.options.show_hidden
    M.refresh_all()
  end,
  refresh = function()
    if vim.bo.modified then
      config.notify("unsaved changes; :e! drops them", vim.log.levels.WARN)
      return
    end
    view.render(0)
    git.update(0)
  end,
}

-- Re-read every directory buffer without unsaved changes.
function M.refresh_all()
  for _, bufnr in ipairs(view.list()) do
    if not vim.bo[bufnr].modified then
      view.render(bufnr)
      git.update(bufnr)
    end
  end
end

-- Read a files:// buffer: :edit, and :e! to drop changes.
local function read(bufnr)
  local keymaps = {}
  for lhs, name in pairs(config.options.keymaps) do
    if name then
      keymaps[lhs] = M.actions[name]
    end
  end
  view.init(bufnr, keymaps)
  local ok, err = view.render(bufnr)
  if not ok then
    config.notify(err, vim.log.levels.ERROR)
    return
  end
  git.update(bufnr)
end

-- Save, then show the parent in windows of a directory that is gone.
local function save()
  for _, g in ipairs(sync.save()) do
    local parent = vim.fs.dirname(g.dir)
    while not fs.is_dir(parent) do
      parent = vim.fs.dirname(parent)
    end
    for _, win in ipairs(vim.fn.win_findbuf(g.bufnr)) do
      vim.api.nvim_win_call(win, function()
        M.open(parent)
      end)
    end
    view.forget(g.bufnr)
    pcall(vim.api.nvim_buf_delete, g.bufnr, { force = true })
  end
end

-- `nvim .` and `:e somedir` open a directory buffer instead.
local function hijack(ev)
  local name = vim.api.nvim_buf_get_name(ev.buf)
  if
    vim.bo[ev.buf].buftype ~= ""
    or name == ""
    or view.dir(ev.buf)
    or not fs.is_dir(name)
  then
    return
  end
  vim.schedule(function()
    if vim.api.nvim_get_current_buf() ~= ev.buf then
      return
    end
    M.open(name)
    pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
  end)
end

---@param opts? table see files.config.defaults
function M.setup(opts)
  config.setup(opts)

  -- Netrw would take directories first.
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  vim.api.nvim_set_hl(
    0,
    "FilesDirectory",
    { link = "Directory", default = true }
  )
  vim.api.nvim_set_hl(0, "FilesGitStaged", { link = "Added", default = true })
  vim.api.nvim_set_hl(
    0,
    "FilesGitUnstaged",
    { link = "Changed", default = true }
  )
  vim.api.nvim_set_hl(
    0,
    "FilesGitUntracked",
    { link = "Comment", default = true }
  )
  vim.api.nvim_set_hl(
    0,
    "FilesGitConflict",
    { link = "DiagnosticError", default = true }
  )

  vim.api.nvim_create_user_command("Files", function(cmd)
    M.open(cmd.args ~= "" and cmd.args or nil)
  end, { nargs = "?", complete = "dir" })

  local group = vim.api.nvim_create_augroup("files", { clear = true })
  local function on(event, pattern, callback)
    vim.api.nvim_create_autocmd(
      event,
      { group = group, pattern = pattern, callback = callback }
    )
  end
  local files = view.scheme .. "*"
  on("BufReadCmd", files, function(ev)
    read(ev.buf)
  end)
  on("BufWriteCmd", files, save)
  on("BufWinEnter", files, function()
    view.set_window(0, config.options.git)
  end)
  -- Coming back to an unchanged directory shows what is there now.
  on("BufEnter", files, function(ev)
    if view.state(ev.buf) and not vim.bo[ev.buf].modified then
      view.render(ev.buf)
      git.update(ev.buf)
    end
    preview.update()
  end)
  on("CursorMoved", files, preview.update)
  on("BufEnter", "*", preview.on_buf_enter)
  on("WinClosed", "*", function(ev)
    preview.on_win_closed(tonumber(ev.match))
  end)
  on(
    { "CursorMoved", "CursorMovedI", "InsertEnter" },
    files,
    view.constrain_cursor
  )
  on("BufWipeout", files, function(ev)
    view.forget(ev.buf)
  end)
  on("BufEnter", "*", hijack)
end

return M
