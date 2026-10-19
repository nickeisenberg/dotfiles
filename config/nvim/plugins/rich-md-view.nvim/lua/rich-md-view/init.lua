local M = {}

M.config = {
  -- Interpreter that runs the viewer. nil: the one in `venv` if it
  -- exists, else "python3".
  python = nil,
  -- The venv `build.run()` made. nil: its default location.
  venv = nil,
  -- Delay before sending changes, so bursts of typing render once.
  debounce_ms = 30,
  -- Draw local images inline (kitty/ghostty, needs termguicolors).
  images = true,
}

local images = require("rich-md-view.images")
local protocol = require("rich-md-view.protocol")

-- lua/rich-md-view/init.lua -> plugin root
local root = vim.fs.dirname(
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
)
-- Run from here, so `-m` finds the package without it being installed.
local python_dir = vim.fs.joinpath(root, "python")

-- The interpreter, and a hint for errors when it is the python3 fallback,
-- which likely lacks the dependencies.
---@return string, string?
local function python()
  if M.config.python then
    return M.config.python
  end
  local venv_python = require("rich-md-view.build").venv_python(M.config.venv)
  if vim.uv.fs_stat(venv_python) then
    return venv_python
  end
  local hint = "python3 was used, as there is no venv at "
    .. venv_python
    .. '; build it with `:lua require("rich-md-view.build").run()`'
  return "python3", hint
end

local function notify_error(msg, hint)
  if hint then
    msg = msg .. "\n" .. hint
  end
  vim.notify("rich-md-view: " .. msg, vim.log.levels.ERROR)
end

-- The last non-empty lines a terminal buffer shows, such as a traceback.
local function last_lines(buf, n)
  local lines = vim.tbl_filter(function(line)
    return vim.trim(line) ~= ""
  end, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  return table.concat(vim.list_slice(lines, math.max(1, #lines - n + 1)), "\n")
end

---@class RichMdView.State
---@field src_buf integer markdown buffer being previewed
---@field buf integer preview terminal buffer
---@field win integer preview window
---@field job integer viewer job
---@field sock_path string
---@field server uv.uv_pipe_t
---@field client? uv.uv_pipe_t the viewer, once it has connected
---@field timer uv.uv_timer_t debounces sends
---@field pending_text boolean whether the debounced send includes the text
---@field images RichMdView.Images

-- The open preview. Nil when closed; every entry point checks is_open()
-- first.
---@type RichMdView.State
local state = nil ---@diagnostic disable-line: assign-type-mismatch

local function is_open()
  return state ~= nil
end

local function can_send()
  return state.client ~= nil and vim.api.nvim_buf_is_valid(state.src_buf)
end

-- 1-based cursor line in the source window, 1 when it isn't shown.
local function source_cursor()
  local win = vim.fn.bufwinid(state.src_buf)
  return win ~= -1 and vim.api.nvim_win_get_cursor(win)[1] or 1
end

local function send_text()
  if not can_send() then
    return
  end
  local name = vim.api.nvim_buf_get_name(state.src_buf)
  local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local lines = vim.api.nvim_buf_get_lines(state.src_buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  state.client:write(protocol.text(source_cursor(), dir, text))
end

local function send_cursor()
  if can_send() then
    state.client:write(protocol.cursor(source_cursor()))
  end
end

-- Debounced send; the text goes along if any call in the burst asked.
---@param with_text boolean
local function schedule_send(with_text)
  state.pending_text = state.pending_text or with_text
  state.timer:stop()
  state.timer:start(
    M.config.debounce_ms,
    0,
    vim.schedule_wrap(function()
      if not is_open() then
        return
      end
      local text = state.pending_text
      state.pending_text = false
      if text then
        send_text()
      else
        send_cursor()
      end
    end)
  )
end

-- Scroll the source window to match the preview after it was scrolled.
local function sync_source(topline, cursor)
  local win = vim.fn.bufwinid(state.src_buf)
  if win == -1 then
    return
  end
  local last = vim.api.nvim_buf_line_count(state.src_buf)
  vim.api.nvim_win_call(win, function()
    vim.fn.winrestview({
      topline = math.min(topline, last),
      lnum = math.min(cursor, last),
      col = 0,
    })
  end)
end

-- Replies from the viewer, by kind; see python/richmdviewnvim/protocol.py.
---@type table<string, fun(msg: RichMdView.Message)>
local handlers = {
  L = function(msg)
    sync_source(tonumber(msg.args[1]), tonumber(msg.args[2]))
  end,
  I = function(msg)
    local id, cols, rows = unpack(vim.tbl_map(tonumber, msg.args))
    state.images:upload(id, msg.payload, rows, cols)
  end,
}

local function read_replies(client)
  local feed = protocol.decoder()
  client:read_start(function(err, data)
    if err or not data then
      return
    end
    local messages = feed(data)
    if #messages == 0 then
      return
    end
    vim.schedule(function()
      for _, msg in ipairs(messages) do
        if not is_open() then
          return
        end
        handlers[msg.kind](msg)
      end
    end)
  end)
end

local function listen(sock_path)
  local server = assert(vim.uv.new_pipe(false))
  assert(server:bind(sock_path))
  server:listen(1, function(err)
    if err or not is_open() then
      return
    end
    local client = assert(vim.uv.new_pipe(false))
    server:accept(client)
    vim.schedule(function()
      if not is_open() then
        client:close()
        return
      end
      state.client = client
      read_replies(client)
      send_text()
    end)
  end)
  return server
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("rich_md_view", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(ev)
      if ev.buf == state.src_buf then
        schedule_send(true)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    callback = function(ev)
      if ev.buf == state.src_buf then
        schedule_send(false)
      end
    end,
  })

  -- Follow whichever markdown buffer is focused.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      if ev.buf ~= state.src_buf and vim.bo[ev.buf].filetype == "markdown" then
        state.src_buf = ev.buf
        schedule_send(true)
      end
    end,
  })

  -- Closing the preview window (:q, <C-w>c) closes the preview.
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    buffer = state.buf,
    callback = vim.schedule_wrap(M.close),
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = M.close,
  })
end

---Scroll the preview by `rows`, or to "top" / "bottom".
---@param rows integer|"top"|"bottom"
function M.scroll(rows)
  if is_open() and state.client then
    state.client:write(protocol.scroll(rows))
  end
end

-- The viewer draws on the alternate screen, so the terminal buffer has no
-- scrollback of its own; scrolling keys in the preview go to the viewer.
local function set_keymaps(buf)
  local function page(frac)
    return function()
      local height = vim.api.nvim_win_get_height(0)
      M.scroll(math.floor(height * frac) * vim.v.count1)
    end
  end
  local function rows(n)
    return function()
      M.scroll(n * vim.v.count1)
    end
  end

  local maps = {
    j = rows(1),
    k = rows(-1),
    ["<Down>"] = rows(1),
    ["<Up>"] = rows(-1),
    ["<C-e>"] = rows(1),
    ["<C-y>"] = rows(-1),
    ["<ScrollWheelDown>"] = rows(3),
    ["<ScrollWheelUp>"] = rows(-3),
    ["<C-d>"] = page(0.5),
    ["<C-u>"] = page(-0.5),
    ["<C-f>"] = page(1),
    ["<C-b>"] = page(-1),
    gg = function()
      M.scroll("top")
    end,
    G = function()
      M.scroll("bottom")
    end,
  }
  for lhs, rhs in pairs(maps) do
    vim.keymap.set("n", lhs, rhs, {
      buffer = buf,
      desc = "Markdown preview: Scroll",
    })
  end

  vim.keymap.set("n", "q", M.close, {
    buffer = buf,
    desc = "Markdown preview: Close",
  })
end

function M.open()
  if is_open() then
    return
  end

  local py, hint = python()
  if vim.fn.executable(py) == 0 then
    notify_error(("python `%s` is not executable"):format(py), hint)
    return
  end

  local src_buf = vim.api.nvim_get_current_buf()
  local src_win = vim.api.nvim_get_current_win()
  local sock_path = vim.fn.tempname() .. ".sock"
  -- Listening before the viewer starts; nothing connects until open()
  -- returns, and by then state is set.
  local server = listen(sock_path)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    split = "right",
    win = -1,
  })

  for opt, val in pairs({
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    statuscolumn = "",
    cursorline = false,
    spell = false,
  }) do
    vim.wo[win][opt] = val
  end

  local cmd = { py, "-m", "richmdviewnvim", sock_path }
  if M.config.images and images.available() then
    table.insert(cmd, "--images")
  end

  local job = vim.api.nvim_buf_call(buf, function()
    return vim.fn.jobstart(cmd, {
      term = true,
      cwd = python_dir,
      on_exit = function(_, code)
        vim.schedule(function()
          if not is_open() or state.buf ~= buf then
            return
          end
          if code ~= 0 then
            -- The preview, and the error in it, is about to go away.
            notify_error(
              ("viewer exited with code %d:\n%s"):format(
                code,
                last_lines(buf, 10)
              ),
              hint
            )
          end
          M.close()
        end)
      end,
    })
  end)

  state = {
    src_buf = src_buf,
    buf = buf,
    win = win,
    job = job,
    sock_path = sock_path,
    server = server,
    timer = assert(vim.uv.new_timer()),
    pending_text = false,
    images = images.new(),
  }

  set_keymaps(buf)
  vim.api.nvim_set_current_win(src_win)
  create_autocmds()
end

function M.close()
  if not is_open() then
    return
  end
  local s = state
  state = nil ---@diagnostic disable-line: cast-local-type

  pcall(vim.api.nvim_del_augroup_by_name, "rich_md_view")
  s.timer:stop()
  s.timer:close()
  if s.client and not s.client:is_closing() then
    s.client:close()
  end
  if not s.server:is_closing() then
    s.server:close()
  end
  pcall(vim.fn.jobstop, s.job)
  s.images:clear()
  if vim.api.nvim_buf_is_valid(s.buf) then
    vim.api.nvim_buf_delete(s.buf, { force = true })
  end
  os.remove(s.sock_path)
end

function M.toggle()
  if is_open() then
    M.close()
  else
    M.open()
  end
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("RichMdViewOpen", M.open, {
    desc = "Open live markdown preview in a right split",
  })
  vim.api.nvim_create_user_command("RichMdViewClose", M.close, {
    desc = "Close live markdown preview",
  })
  vim.api.nvim_create_user_command("RichMdViewToggle", M.toggle, {
    desc = "Toggle live markdown preview",
  })
end

return M
