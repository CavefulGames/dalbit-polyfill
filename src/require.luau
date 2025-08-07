local sub = string.sub
local gsub = string.gsub

return function(path)
    gsub(path, "@self", "./")
    return require(sub((debug :: any).getinfo(2, "S").source, 2)) :: any
end
