local sub = string.sub

return function(path)
    return require(sub((debug :: any).getinfo(2, "S").source, 2)) :: any
end
