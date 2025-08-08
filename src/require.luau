local sub = string.sub
local len = string.len
local gsub = string.gsub
local match = string.match

local function dalbit_require(path: string)
    local polyfill_path = gsub((debug :: any).getinfo(1, "S").source, "%.(lua[uac]?)$", "")
    local call_path = gsub((debug :: any).getinfo(2, "S").source, "%.(lua[uac]?)$", "")
    local require_prefix = sub(polyfill_path, -len("require") - 1, -len("require") - 1)
    local call_dir = sub(match(call_path, "^(.*)" .. require_prefix) or "", 2)
    
    if sub(path, 1, 2) == "./" then
        path = sub(path, 3)
        call_dir = call_dir .. require_prefix .. path

        return require(call_dir) :: any
    end

    while sub(path, 1, 3) == "../" do
        local last_dir = match(call_dir, "^(.*)" .. require_prefix) or ""
        if last_dir == "" then
            call_dir = ""
        else
            call_dir = sub(call_dir, 1, len(last_dir) - 1)
        end

        path = sub(path, 4)
    end
    
    if call_dir == "" then
        call_dir = call_dir .. path
    else
        call_dir = call_dir .. require_prefix .. gsub(path, "/", require_prefix)
    end

    return require(call_dir) :: any
end

-- require("tests/import")
-- require("../tests/import")
-- print(dalbit_require("../tests/import")) --// tests/import

return dalbit_require
