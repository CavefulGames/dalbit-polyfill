local string = require("./string")
local sub = string.sub
local len = string.len
local gsub = string.gsub
local split = string.split

return function(path: string): any
    local polyfill_path = gsub((debug :: any).getinfo(1, "S").source, "%.(lua[uac]?)$", "")
    local call_path = gsub((debug :: any).getinfo(2, "S").source, "%.(lua[uac]?)$", "")
    local require_prefix = sub(polyfill_path, -len("require") - 1, -len("require") - 1)
    local call_dir = sub(call_path:match("^(.*)" .. require_prefix) or "", 2)
    
    if sub(path, 1, 3) == "../" then
        local last_dir = call_dir:match("^(.*)" .. require_prefix) or ""
        if last_dir == "" then
            call_dir = ""
        else
            call_dir = sub(call_dir, 1, len(last_dir) - 1)
        end

        path = sub(path, 2)
    end

    if sub(path, 1, 2) == "./" then
        path = sub(path, 3)

        local splits = split(path, require_prefix)
        for i, v in pairs(splits) do
            call_dir = call_dir .. v .. (i == #splits and "" or require_prefix)
        end
    end

    return require(call_dir) :: any
end
