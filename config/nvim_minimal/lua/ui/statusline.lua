local pms = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
local dir = vim.api.nvim_get_hl(0, { name = "Directory", link = false })
local vis = vim.api.nvim_get_hl(0, { name = "Visual", link = false })

vim.api.nvim_set_hl(0, "StlMode", {
  fg = pms.fg,
  bg = vis.bg,
})

vim.api.nvim_set_hl(0, "StlGit", {
  fg = dir.fg,
  bg = pms.bg,
})

local modes = {
  n = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "V-LINE",
  ["\22"] = "V-BLOCK",
  c = "COMMAND",
  t = "TERMINAL",
  R = "REPLACE",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
}

-- Cache Git information by repository root.
local git_cache = {}

local function redraw()
  vim.schedule(function()
    vim.cmd("redrawstatus!")
  end)
end

local function update_buffer_info(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)

  -- Special/unnamed buffers don't need Git information.
  if path == "" or vim.bo[bufnr].buftype ~= "" then
    vim.b[bufnr].git_branch = nil
    vim.b[bufnr].rel_path = nil
    return
  end

  local cwd = vim.fs.dirname(path)

  if not cwd then
    return
  end

  -- Find the Git root without spawning a process.
  local git_dir = vim.fs.find(".git", {
    path = cwd,
    upward = true,
    type = "directory",
  })[1]

  if not git_dir then
    vim.b[bufnr].git_branch = nil
    vim.b[bufnr].rel_path = vim.fn.fnamemodify(path, ":~")
    redraw()
    return
  end

  local root = vim.fs.dirname(git_dir)

  vim.b[bufnr].rel_path = path:sub(#root + 2)

  -- We already know this repository's branch.
  if git_cache[root] then
    vim.b[bufnr].git_branch = git_cache[root]
    redraw()
    return
  end

  -- Branch lookup happens asynchronously.
  vim.system({ "git", "-C", root, "branch", "--show-current" }, { text = true }, function(result)
    if result.code ~= 0 then
      return
    end

    local branch = vim.trim(result.stdout)

    if branch == "" then
      return
    end

    git_cache[root] = branch

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.b[bufnr].git_branch = branch
        vim.cmd("redrawstatus!")
      end
    end)
  end)
end

function _G._statusline()
  local mode = modes[vim.fn.mode()] or vim.fn.mode():upper()

  local branch = ""
  if vim.b.git_branch then
    branch = "%#StlGit# " .. vim.b.git_branch .. " %*"
  end

  local path = vim.b.rel_path or "%f"

  local diag = ""
  local counts = vim.diagnostic.count(0) or {}

  local labels = {
    " ",
    " ",
    " ",
    " ",
  }

  local hls = {
    "DiagnosticError",
    "DiagnosticWarn",
    "DiagnosticInfo",
    "DiagnosticHint",
  }

  for i = 1, 4 do
    if counts[i] and counts[i] > 0 then
      diag = diag .. "%#" .. hls[i] .. "#" .. labels[i] .. counts[i] .. "%* "
    end
  end

  return "%#StlMode# " .. mode .. " %*" .. branch .. " " .. path .. "%=" .. diag .. vim.bo.filetype .. " %l:%c"
end

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    update_buffer_info(args.buf)
  end,
})

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = redraw,
})

vim.o.statusline = "%!v:lua._statusline()"
