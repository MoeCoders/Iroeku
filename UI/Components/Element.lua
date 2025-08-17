local utils = require("UI.utils")

---@class Element 通用元素类
---@field id string 元素的唯一标识符
---@field x table 元素的x坐标及表示方式
---@field y table 元素的y坐标及表示方式
---@field visible boolean 元素的可见性
---@field width table 元素的宽度及表示方式
---@field height table 元素的高度及表示方式
---@field z_index number 元素的层级
---@field events table 元素的事件表
---@field children table 元素的子元素表
--- @field anchor string 元素的锚点
local Element = {}

---comment
---@param e table
---@return Element
function Element.new(e)
    local element = {
        id = e.id,
        visible = e.visible or true,
        width = e.width or { value = 1, unit = utils.SIZE_UNITS.PERCENT },
        height = e.height or { value = 1, unit = utils.SIZE_UNITS.PERCENT },
        z_index = e.z_index,
        events = e.events or {},
        children = e.children or {},
        draw = e.draw or nil,
        anchor = e.anchor or "top_left"
    }
    setmetatable(element, { __index = Element })
    return element
end

function Element:setDrawFunc(drawFunc)
    self.draw = drawFunc
end

function Element:remove()
    self = nil
end

---@param callback fun() 鼠标点击元素时触发的回调函数
function Element:setOnClick(callback)
    self.events.onClick = callback
end

---@param callback fun() 鼠标悬停在元素上时触发的回调函数
function Element:setOnHover(callback)
    self.events.onHover = callback
end

---@param callback fun() 元素被拖动时触发的回调函数
function Element:setOnDrag(callback)
    self.events.onDrag = callback
end

--@param callback fun() 开始拖动元素触发的回调函数
function Element:setOnDragStart(callback)
    self.events.onDragStart = callback
end

---@param callback fun() 元素被拖动结束时触发的回调函数
function Element:setOnDragEnd(callback)
    self.events.onDragEnd = callback
end

---@param visible boolean 元素的可见性
function Element:setVisible(visible)
    self.visible = visible
end

function Element:addChildren(...)
    for _, child in ipairs({ ... }) do
        table.insert(self.children, child)
    end
end

return Element
