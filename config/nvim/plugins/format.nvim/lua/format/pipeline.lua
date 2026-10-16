-- Running a pipeline of external formatters over some text.

local config = require("format.config")

local M = {}

-- Commands already reported missing, so a missing tool warns once per
-- session instead of on every save.
local warned = {}

local function get_args(step, bufname)
  if type(step.args) == "function" then
    return step.args(bufname)
  end
  return step.args or {}
end

-- Every command must exist before any of them runs; a pipeline that stops
-- halfway would leave the text partly formatted.
local function check_commands(pipeline)
  for _, step in ipairs(pipeline) do
    if vim.fn.executable(step.command) ~= 1 then
      if not warned[step.command] then
        warned[step.command] = true
        config.notify(
          "formatter not found: " .. step.command,
          vim.log.levels.WARN
        )
      end
      return false
    end
  end
  return true
end

-- Run `pipeline` over `text`. `bufname` is passed to `args` functions so
-- tools can pick settings by path. Returns the formatted text, or nil when
-- a step is missing, fails or times out (the failure is reported).
---@param pipeline table[]
---@param text string
---@param bufname string
---@return string?
function M.run(pipeline, text, bufname)
  if not check_commands(pipeline) then
    return nil
  end

  for _, step in ipairs(pipeline) do
    local cmd = vim.list_extend({ step.command }, get_args(step, bufname))
    local result = vim
      .system(cmd, { stdin = text, text = true })
      :wait(config.options.timeout_ms)

    -- A killed process reports code 124. The result is nil instead when
    -- the command (a wrapper script, say) left a child holding its output
    -- open past the kill.
    if not result or (result.code == 124 and result.signal == 9) then
      config.notify(
        ("%s timed out after %d ms"):format(
          step.command,
          config.options.timeout_ms
        ),
        vim.log.levels.WARN
      )
      return nil
    end

    if result.code ~= 0 then
      local err = vim.trim(result.stderr or "")
      if err == "" then
        err = "exited with code " .. result.code
      end
      config.notify(step.command .. ": " .. err, vim.log.levels.WARN)
      return nil
    end

    -- Some tools print nothing when there is nothing to change; keep the
    -- current text rather than emptying the buffer.
    if result.stdout and result.stdout ~= "" then
      text = result.stdout
    end
  end

  return text
end

return M
