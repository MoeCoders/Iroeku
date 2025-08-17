local Animation = {
    _queue = {}
}

Animation._queue.__index = Animation._queue

function Animation._queue.new()
    local self = setmetatable({}, Animation._queue)
    self.data = {}
    self.front = 1
    self.reer = 0
    return self
end

function Animation._queue:enqueue(value)
    self.reer = self.reer + 1
    self.data[self.reer] = value
end

function Animation._queue:dequeue()
    if self:isEmpty() then
        return nil
    end
    local value = self.data[self.reer]
    self.data[self.reer] = nil
    self.front = self.front + 1
    return value
end

function Animation._queue:peek()
    if self:isEmpty() then return nil end
    return self.data[self.front]
end

function Animation._queue:size()
    return self.reer - self.front + 1
end

function Animation._queue:clear()
    self.data = {}
    self.front = 1
    self.reer = 0
end

function Animation._queue:isEmpty()
    return self.front > self.reer
end

Animation.queue = Animation._queue.new()

function Animation:play(dt)
    if self.queue:isEmpty() then
        return
    end
    while not self.queue:isEmpty() do
        local i = self.queue:dequeue()
        if type(i.play) == "function" then
            i:play(dt)
        end
    end
end

return Animation
