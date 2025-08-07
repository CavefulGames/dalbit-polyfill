local sub = string.sub
local len = string.len
local gsub = string.gsub

return function<T>(path: string): any
    local polyfill_path = (debug :: any).getinfo(1, "S").source
    local path_prefix = sub(polyfill_path, -len("require.luau") - 1, -len("require.luau") - 1)

    polyfill_path = gsub(polyfill_path, "/", path_prefix)

    --// advence @
    return require(sub(polyfill_path, 2)) :: any
end
