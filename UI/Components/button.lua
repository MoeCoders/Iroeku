-- button.lua
local utils = require("UI.utils")
local ObjectPool = require("UI.ObjectPool")

---@class Button
---@field id string

local Button = {}

local button_pool = ObjectPool.new(function()
    return setmetatable({}, { __index = Button })
end, function(btn)
    btn.id = nil
    btn.text = nil
    btn.visible = true
    btn.width = nil
    btn.height = nil
    btn.z_index = nil
    btn.events = {}
    btn.draw = nil
    btn.anchor = "center"
end)

---@param config table
function Button.new(config)
    local btn = button_pool:get()
    btn.id = config.id
    btn.text = config.text or "Button"
    btn.visible = config.visible ~= false
    btn.width = config.width or { value = 100, unit = utils.SIZE_UNITS.PIXELS }
    btn.height = config.height or { value = 50, unit = utils.SIZE_UNITS.PIXELS }
    btn.z_index = config.z_index or 1
    btn.events = config.events or {}
    btn.anchor = config.anchor or "center"
    btn.draw = function(self)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle("fill", 0, 0, self._width, self._height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(self.text, self._width / 2 - 20, self._height / 2 - 10)
    end
    return btn
end

function Button:remove()
    button_pool:release(self)
end

-- 添加事件方法类似Element

function Button:setOnClick(callback)
    self.events.onClick = callback
end

return Button
