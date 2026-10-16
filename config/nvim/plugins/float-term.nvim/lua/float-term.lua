local M = {}

local win_id = nil
local current_buf_idx = nil
local buf_ids = {}

local function window_is_open()
  return win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
end

local function window_config()
  local width = math.floor(vim.o.columns * 0.75)
  local height = math.floor(vim.o.lines * 0.75)

  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = string.format(" %d/%d ", current_buf_idx, #buf_ids),
    title_pos = "center",
  }
end

local function open_terminal()
  local bufnr = buf_ids[current_buf_idx]

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  win_id = vim.api.nvim_open_win(bufnr, true, window_config())

  vim.wo[win_id].wrap = false

  vim.cmd("startinsert")
end

local function close_terminal()
  if window_is_open() then
    vim.api.nvim_win_close(win_id, true)
  end

  win_id = nil
end

function M.new()
  close_terminal()

  local bufnr = vim.api.nvim_create_buf(false, true)

  local shell = vim.split(vim.o.shell, "%s+")

  vim.api.nvim_buf_call(bufnr, function()
    vim.fn.jobstart(shell, {
      term = true,
    })
  end)
  buf_ids[#buf_ids + 1] = bufnr
  current_buf_idx = #buf_ids

  open_terminal()
end

function M.toggle()
  if window_is_open() then
    close_terminal()
    return
  end

  if #buf_ids == 0 then
    M.new()
    return
  end

  open_terminal()
end

function M.next()
  if #buf_ids == 0 then
    M.new()
    return
  end

  current_buf_idx = (current_buf_idx % #buf_ids) + 1

  if window_is_open() then
    vim.api.nvim_win_set_buf(win_id, buf_ids[current_buf_idx])

    vim.api.nvim_win_set_config(win_id, window_config())
  else
    open_terminal()
  end

  vim.cmd("startinsert")
end

function M.prev()
  if #buf_ids == 0 then
    M.new()
    return
  end

  current_buf_idx = ((current_buf_idx - 2) % #buf_ids) + 1

  if window_is_open() then
    vim.api.nvim_win_set_buf(win_id, buf_ids[current_buf_idx])

    vim.api.nvim_win_set_config(win_id, window_config())
  else
    open_terminal()
  end

  vim.cmd("startinsert")
end

function M.kill()
  if #buf_ids == 0 then
    return
  end

  close_terminal()

  local bufnr = table.remove(buf_ids, current_buf_idx)

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, {
      force = true,
    })
  end

  if #buf_ids == 0 then
    current_buf_idx = nil
    return
  end

  if current_buf_idx > #buf_ids then
    current_buf_idx = #buf_ids
  end

  open_terminal()
end

function M.kill_all()
  close_terminal()

  for _, bufnr in ipairs(buf_ids) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, {
        force = true,
      })
    end
  end

  buf_ids = {}
  current_buf_idx = nil
end

return M
