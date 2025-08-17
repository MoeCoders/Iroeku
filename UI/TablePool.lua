-- TablePool.lua
local TablePool = {}
TablePool.__index = TablePool

function TablePool.new()
    local self = setmetatable({}, TablePool)
    self.pool = {}
    return self
end

function TablePool:get()
    if #self.pool > 0 then
        return table.remove(self.pool)
    end
    return {}
end

function TablePool:release(t)
    for k in pairs(t) do
        t[k] = nil
    end
    table.insert(self.pool, t)
end

function TablePool:clear()
    self.pool = {}
end

return TablePool