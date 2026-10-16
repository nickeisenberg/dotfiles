local M = {}

M.config = {
  python = "python3",
  -- Delay before sending changes, so bursts of typing render once.
  debounce_ms = 30,
  -- Draw local images inline (kitty/ghostty, needs termguicolors).
  images = true,
}

local kitty = require("mark-tui.kitty")

local script = vim.fs.joinpath(
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))),
  "python",
  "mark_tui.py"
)

-- Open preview: source/preview buffers, socket, viewer job. Nil when closed;
-- every entry point checks is_open() first.
---@type table
local state = nil

local function is_open()
  return state ~= nil
end

local function send(full)
  if not state.client or not vim.api.nvim_buf_is_valid(state.src_buf) then
    return
  end

  local win = vim.fn.bufwinid(state.src_buf)
  local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win)[1] or 1

  if full then
    local name = vim.api.nvim_buf_get_name(state.src_buf)
    local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
    state.client:write(("D %d\n%s"):format(#dir, dir))
    local lines = vim.api.nvim_buf_get_lines(state.src_buf, 0, -1, false)
    local text = table.concat(lines, "\n")
    state.client:write(("T %d %d\n%s"):format(cursor, #text, text))
  else
    state.client:write(("C %d\n"):format(cursor))
  end
end

local function schedule_send(full)
  state.pending_full = state.pending_full or full
  state.timer:stop()
  state.timer:start(
    M.config.debounce_ms,
    0,
    vim.schedule_wrap(function()
      if not is_open() then
        return
      end
      local f = state.pending_full
      state.pending_full = false
      send(f)
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

-- Handle replies from the viewer:
--   L <topline> <cursor>\n               scroll position to match
--   I <id> <cols> <rows> <nbytes>\n<png>  image to upload to the terminal
local function read_replies(client)
  local pending = ""
  client:read_start(function(err, data)
    if err or not data then
      return
    end
    pending = pending .. data
    local latest, uploads = nil, {}
    while true do
      local nl = pending:find("\n", 1, true)
      if not nl then
        break
      end
      local header = pending:sub(1, nl - 1)
      local id, cols, rows, n = header:match("^I (%d+) (%d+) (%d+) (%d+)$")
      if id then
        n = tonumber(n)
        if #pending - nl < n then
          break
        end
        table.insert(uploads, {
          id = tonumber(id),
          cols = tonumber(cols),
          rows = tonumber(rows),
          png = pending:sub(nl + 1, nl + n),
        })
        pending = pending:sub(nl + n + 1)
      else
        local topline, cursor = header:match("^L (%d+) (%d+)$")
        if topline then
          latest = { tonumber(topline), tonumber(cursor) }
        end
        pending = pending:sub(nl + 1)
      end
    end
    if latest or #uploads > 0 then
      vim.schedule(function()
        if not is_open() then
          return
        end
        for _, img in ipairs(uploads) do
          kitty.render(img.id, img.png, img.rows, img.cols)
          state.images[img.id] = true
        end
        if latest then
          sync_source(latest[1], latest[2])
        end
      end)
    end
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
      send(true)
    end)
  end)
  return server
end

local function create_autocmds()
  local group = vim.api.nvim_create_augroup("mark_tui", { clear = true })

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

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = M.close,
  })
end

---Scroll the preview by `rows`, or to "top" / "bottom".
---@param rows integer|"top"|"bottom"
function M.scroll(rows)
  if is_open() and state.client then
    state.client:write(("S %s\n"):format(rows))
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

  local src_buf = vim.api.nvim_get_current_buf()
  local src_win = vim.api.nvim_get_current_win()
  local sock_path = vim.fn.tempname() .. ".sock"

  state = {
    src_buf = src_buf,
    sock_path = sock_path,
    timer = assert(vim.uv.new_timer()),
    pending_full = false,
    images = {}, -- ids uploaded to the host terminal
  }
  state.server = listen(sock_path)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    split = "right",
    win = -1,
  })
  state.buf, state.win = buf, win

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

  local cmd = { M.config.python, script, sock_path }
  if M.config.images and kitty.detect() then
    local reason = kitty.check()
    if reason then
      vim.notify("mark-tui: images disabled, " .. reason, vim.log.levels.WARN)
    else
      table.insert(cmd, "--images")
    end
  end

  vim.api.nvim_buf_call(buf, function()
    state.job = vim.fn.jobstart(cmd, {
      term = true,
      on_exit = function(_, code)
        vim.schedule(function()
          if code ~= 0 and is_open() and state.buf == buf then
            vim.notify(
              "mark-tui: viewer exited with code " .. code,
              vim.log.levels.ERROR
            )
          end
          if is_open() and state.buf == buf then
            M.close()
          end
        end)
      end,
    })
  end)

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

  pcall(vim.api.nvim_del_augroup_by_name, "mark_tui")
  s.timer:stop()
  s.timer:close()
  if s.client and not s.client:is_closing() then
    s.client:close()
  end
  if not s.server:is_closing() then
    s.server:close()
  end
  pcall(vim.fn.jobstop, s.job)
  for id in pairs(s.images) do
    pcall(kitty.delete, id)
  end
  if vim.api.nvim_buf_is_valid(s.buf) then
    vim.api.nvim_buf_delete(s.buf, { force = true })
  end
  os.remove(s.sock_path)
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("MarkTuiOpen", M.open, {
    desc = "Open live markdown preview in a right split",
  })
  vim.api.nvim_create_user_command("MarkTuiClose", M.close, {
    desc = "Close live markdown preview",
  })
end

return M
