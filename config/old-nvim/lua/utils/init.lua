local M = {}

M.get_os_name = function()
    local os_name
    local separator = package.config:sub(1,1)
    if separator == "\\" then
        os_name = "Windows"

    else
        local handle = io.popen("uname -s")

        local result
        if handle ~= nil then
          result = handle:read("*a")
          handle:close()
        else
          return "OS not identified"
        end

        if result then
            os_name = result:gsub("\n", "")
        else
            os_name = "Unknown"
        end
    end
    return os_name
end

return M
