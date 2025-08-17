-- ObjectPool.lua
local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool.new(createFunc, resetFunc)
    local self = setmetatable({}, ObjectPool)
    self.pool = {}
    self.createFunc = createFunc
    self.resetFunc = resetFunc or function() end
    return self
end

function ObjectPool:get()
    if #self.pool > 0 then
        local obj = table.remove(self.pool)
        self.resetFunc(obj)
        return obj
    end
    return self.createFunc()
end

function ObjectPool:release(obj)
    self.resetFunc(obj)
    table.insert(self.pool, obj)
end

function ObjectPool:clear()
    self.pool = {}
end

return ObjectPool