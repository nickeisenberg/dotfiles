local M = {}

M.config = {
  python = "python3",
  -- Delay before sending changes, so bursts of typing render once.
  debounce_ms = 30,
}

local script = vim.fs.joinpath(
  vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))),
  "python",
  "mark_tui.py"
)

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

  vim.api.nvim_buf_call(buf, function()
    state.job = vim.fn.jobstart({ M.config.python, script, sock_path }, {
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

  vim.api.nvim_set_current_win(src_win)
  create_autocmds()
end

function M.close()
  if not is_open() then
    return
  end
  local s = state
  state = nil

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
