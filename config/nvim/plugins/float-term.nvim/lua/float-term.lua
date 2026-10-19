local M = {}

local win_id = nil
local current_buf_idx = nil
local buf_ids = {}

-- Forget terminals whose buffers are gone: deleted with :bd!, or closed
-- by Neovim when the shell exits. The current terminal stays current if
-- it survived.
local function prune()
  local current = buf_ids[current_buf_idx or 0]
  buf_ids = vim.tbl_filter(vim.api.nvim_buf_is_valid, buf_ids)

  if #buf_ids == 0 then
    current_buf_idx = nil
    return
  end

  local idx = vim.fn.index(buf_ids, current) + 1
  current_buf_idx = idx > 0 and idx or math.min(current_buf_idx, #buf_ids)
end

local function window_is_valid()
  return win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
end

-- Open in the current tab. A float left in another tab counts as hidden.
local function window_is_open()
  return window_is_valid()
    and vim.api.nvim_win_get_tabpage(win_id)
      == vim.api.nvim_get_current_tabpage()
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

local function close_terminal()
  if window_is_valid() then
    vim.api.nvim_win_close(win_id, true)
  end

  win_id = nil
end

local function open_terminal()
  local bufnr = buf_ids[current_buf_idx]

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Close the float if it was left open in another tab.
  close_terminal()

  win_id = vim.api.nvim_open_win(bufnr, true, window_config())

  vim.wo[win_id].wrap = false

  vim.cmd("startinsert")
end

function M.new()
  close_terminal()

  local bufnr = vim.api.nvim_create_buf(false, true)

  local shell = vim.split(vim.o.shell, "%s+")

  -- jobstart throws if the shell isn't executable.
  local ok, job_id
  vim.api.nvim_buf_call(bufnr, function()
    ok, job_id = pcall(vim.fn.jobstart, shell, {
      term = true,
    })
  end)

  if not ok or job_id <= 0 then
    vim.api.nvim_buf_delete(bufnr, {
      force = true,
    })
    vim.notify("Could not start shell: " .. vim.o.shell, vim.log.levels.ERROR)
    return
  end

  -- Neovim only closes a terminal itself when the shell exits with 0;
  -- close it on any exit so dead terminals leave the rotation.
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = bufnr,
    nested = true,
    callback = function()
      -- Scheduled: the buffer may already be mid-delete (kill, :bd!).
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_delete(bufnr, {
            force = true,
          })
        end
      end)
    end,
  })

  buf_ids[#buf_ids + 1] = bufnr
  current_buf_idx = #buf_ids

  open_terminal()
end

function M.toggle()
  prune()

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
  prune()

  if #buf_ids == 0 then
    M.new()
    return
  end

  current_buf_idx = (current_buf_idx % #buf_ids) + 1

  if window_is_open() then
    vim.api.nvim_win_set_buf(win_id, buf_ids[current_buf_idx])

    vim.api.nvim_win_set_config(win_id, window_config())

    vim.api.nvim_set_current_win(win_id)

    vim.cmd("startinsert")
  else
    open_terminal()
  end
end

function M.prev()
  prune()

  if #buf_ids == 0 then
    M.new()
    return
  end

  current_buf_idx = ((current_buf_idx - 2) % #buf_ids) + 1

  if window_is_open() then
    vim.api.nvim_win_set_buf(win_id, buf_ids[current_buf_idx])

    vim.api.nvim_win_set_config(win_id, window_config())

    vim.api.nvim_set_current_win(win_id)

    vim.cmd("startinsert")
  else
    open_terminal()
  end
end

function M.kill()
  prune()

  if #buf_ids == 0 then
    return
  end

  local was_open = window_is_open()

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

  if was_open then
    open_terminal()
  end
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

-- Keep the float centred when the editor is resized.
vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("FloatTerm", {}),
  callback = function()
    if window_is_valid() then
      vim.api.nvim_win_set_config(win_id, window_config())
    end
  end,
})

return M
