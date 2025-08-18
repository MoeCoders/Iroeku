-- UI.lua
local conf = require("conf")
local RectLayout = require("UI.RectLayout")
local utils = require("UI.utils")
local bodyElement = require("UI.Layout.body")
local Element = require("UI.Components.Element")
-- 局部化常用函数和模块
local math_min = math.min
local math_floor = math.floor
local math_max = math.max
local graphics_getWidth = love.graphics.getWidth
local graphics_getHeight = love.graphics.getHeight
local graphics_push = love.graphics.push
local graphics_pop = love.graphics.pop
local graphics_translate = love.graphics.translate
local setmetatable = setmetatable
local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle
local print = print
local TablePool = require("UI.TablePool")
local stackPool = TablePool.new()
local listPool = TablePool.new()

-- 创建父元素代理元表
local ParentProxy = {}
ParentProxy.__index = function(t, k)
    return t._parent[k]
end

-- 创建或重用父元素代理对象
local function createOrReuseParentProxy(element, parent)
    if not element._parentProxy then
        element._parentProxy = setmetatable({ _parent = parent }, ParentProxy)
    else
        element._parentProxy._parent = parent
    end
    return element._parentProxy
end


-- UI 结构定义
local UI = {
    body = bodyElement,
}


-- 修改尺寸计算函数以处理内边距
local function calculateDimension(def, parentDim, parentPadding)
    parentPadding = parentPadding or 0
    if type(def) == "number" then
        return math.max(0, def - parentPadding * 2)
    end

    if type(def) == "table" then
        local value = def.value or 1
        local unit = def.unit or utils.SIZE_UNITS.PIXELS

        if unit == utils.SIZE_UNITS.PERCENT then
            return math.max(0, parentDim * value - parentPadding * 2)
        else
            return math.max(0, value - parentPadding * 2)
        end
    end

    return math.max(0, parentDim - parentPadding * 2)
end

-- 子节点位置计算逻辑
local function calculatePosition(child, parent)
    local padding = child.padding or 0
    local anchor = utils.ANCHOR_POINTS[child.anchor] or utils.ANCHOR_POINTS.top_left
    local defaultOffset = anchor

    -- 处理偏移量
    -- 预先获取父容器尺寸（避免多次访问）
    local pw, ph = parent._width, parent._height

    -- 内联转换逻辑：消除函数调用开销
    local function toAbsolute(val, size)
        return type(val) == "number" and val >= 0 and val <= 1 and val * size or (val or 0)
    end

    -- 处理默认偏移（单次属性访问）
    local dx, dy = defaultOffset.x, defaultOffset.y
    local defaultX = toAbsolute(dx, pw)
    local defaultY = toAbsolute(dy, ph)

    -- 处理子偏移（安全访问优化）
    local childOffset = child.offset
    local cx = childOffset and childOffset.x
    local cy = childOffset and childOffset.y

    -- 最终偏移计算（无分支计算）
    local offsetX = defaultX + toAbsolute(cx, pw)
    local offsetY = defaultY + toAbsolute(cy, ph)
    -- 计算基本位置（基于显示模式）
    local baseX, baseY = 0, 0

    if child.display_mode == utils.DISPLAY_MODES.RELATIVE then
        baseX = padding
        baseY = padding
    elseif child.display_mode == utils.DISPLAY_MODES.CENTER then
        baseX = (parent._width - child._width) / 2
        baseY = (parent._height - child._height) / 2
    elseif child.display_mode == utils.DISPLAY_MODES.TOP_LEFT then
        baseX = padding
        baseY = padding
    elseif child.display_mode == utils.DISPLAY_MODES.TOP_RIGHT then
        baseX = parent._width - child._width - padding
        baseY = padding
    elseif child.display_mode == utils.DISPLAY_MODES.TOP_CENTER then
        baseX = (parent._width - child._width) / 2
        baseY = padding
    elseif child.display_mode == utils.DISPLAY_MODES.BOTTOM_LEFT then
        baseX = padding
        baseY = parent._height - child._height - padding
    elseif child.display_mode == utils.DISPLAY_MODES.BOTTOM_RIGHT then
        baseX = parent._width - child._width - padding
        baseY = parent._height - child._height - padding
    elseif child.display_mode == utils.DISPLAY_MODES.BOTTOM_CENTER then
        baseX = (parent._width - child._width) / 2
        baseY = parent._height - child._height - padding
    elseif child.display_mode == utils.DISPLAY_MODES.LEFT_CENTER then
        baseX = padding
        baseY = (parent._height - child._height) / 2
    elseif child.display_mode == utils.DISPLAY_MODES.RIGHT_CENTER then
        baseX = parent._width - child._width - padding
        baseY = (parent._height - child._height) / 2
    elseif child.display_mode == utils.DISPLAY_MODES.FILL then
        baseX = padding
        baseY = padding
        -- 填充模式需要特殊处理尺寸
        child._width = math.max(0, parent._width - padding * 2)
        child._height = math.max(0, parent._height - padding * 2)
    elseif child.display_mode == utils.DISPLAY_MODES.ABSOLUTE then
        baseX = offsetX
        baseY = offsetY
        offsetX, offsetY = 0, 0 -- 绝对定位不使用额外偏移
    end

    -- 应用锚点偏移（基于元素自身尺寸）
    local anchorOffsetX = anchor.x * child._width
    local anchorOffsetY = anchor.y * child._height

    -- 最终位置计算
    return baseX + offsetX - anchorOffsetX, baseY + offsetY - anchorOffsetY
end

-- 更新updateChildren函数
local function updateChildren(root)
    local stack = stackPool:get()
    table.insert(stack, root)
    while #stack > 0 do
        local parent = table.remove(stack)
        if not parent.children then goto continue end
        for _, child in pairs(parent.children) do
            if not child.visible then goto child_continue end
            child.parent = createOrReuseParentProxy(child, parent)
            local padding = child.padding or 0
            local widthDef = child.width or { value = 1, unit = utils.SIZE_UNITS.PERCENT }
            local heightDef = child.height or { value = 1, unit = utils.SIZE_UNITS.PERCENT }
            child._width = calculateDimension(widthDef, parent._width, padding)
            child._height = calculateDimension(heightDef, parent._height, padding)
            if child.min_width then child._width = math_max(child._width, calculateDimension(child.min_width, parent._width)) end
            if child.max_width then child._width = math_min(child._width, calculateDimension(child.max_width, parent._width)) end
            if child.min_height then child._height = math_max(child._height, calculateDimension(child.min_height, parent._height)) end
            if child.max_height then child._height = math_min(child._height, calculateDimension(child.max_height, parent._height)) end
            child._x, child._y = calculatePosition(child, parent)
            if child.children then table.insert(stack, child) end
            ::child_continue::
        end
        ::continue::
    end
    stackPool:release(stack)
end

-- 尺寸计算函数
local function calculateDimension(def, parentDim)
    -- 如果def是数字，则将其视为像素值
    if type(def) == "number" then
        return def
    end

    -- 如果def是表，则按定义处理
    if type(def) == "table" then
        local value = def.value or 1
        local unit = def.unit or utils.SIZE_UNITS.PIXELS

        if unit == utils.SIZE_UNITS.PERCENT then
            return parentDim * value
        else -- PIXELS
            return value
        end
    end

    -- 默认情况
    return parentDim
end

-- 修复: 确保body尺寸正确更新
function UI:update(dt)
    local screenWidth = graphics_getWidth()
    local screenHeight = graphics_getHeight()
    -- Layout:clear()
    RectLayout.Layout:reset({ x = 0, y = 0, width = screenWidth, height = screenHeight }, nil)
    RectLayout.Layout:setSmallGridOptimization()
    RectLayout.Layout:optimizeMemory()
    -- 安全处理宽高比
    local aspectRatio = conf.aspectRatio or (16 / 9)
    if aspectRatio <= 0 then aspectRatio = 16 / 9 end

    -- 计算自适应尺寸 - 修复计算逻辑
    local bodyWidth, bodyHeight

    -- 根据屏幕宽高比计算body尺寸
    if screenWidth / screenHeight > aspectRatio then
        -- 屏幕更宽，高度受限
        bodyHeight = screenHeight
        bodyWidth = bodyHeight * aspectRatio
    else
        -- 屏幕更高，宽度受限
        bodyWidth = screenWidth
        bodyHeight = bodyWidth / aspectRatio
    end

    -- 更新body属性
    local body = self.body
    body._width = bodyWidth
    body._height = bodyHeight
    body._x = (screenWidth - bodyWidth) / 2
    body._y = (screenHeight - bodyHeight) / 2
    body._abs_x = body._x
    body._abs_y = body._y

    if utils.debug.enabled then
        print("[UI DEBUG] Body updated:")
        print(string.format("  Position: (%d, %d)", math_floor(body._x), math_floor(body._y)))
        print(string.format("  Absolute Position: (%d, %d)", math_floor(body._abs_x), math_floor(body._abs_y)))
        print(string.format("  Size: %d x %d", math_floor(body._width), math_floor(body._height)))
        print(string.format("  Screen: %d x %d", screenWidth, screenHeight))
        print(string.format("  Aspect Ratio: %.2f", aspectRatio))
    end

    -- 递归更新所有子节点
    updateChildren(body)

    -- 标记UI已更新
    self.needsRedraw = true
end

-- 递归绘制子节点
local function drawChildren(root)
    local stack = stackPool:get()
    table.insert(stack, {node = root, state = 1})
    while #stack > 0 do
        local entry = stack[#stack]
        local parent = entry.node
        if entry.state == 1 then
            graphics_push()
            graphics_translate(parent._x, parent._y)
            if type(parent.draw) == "function" then
                parent:draw()
                RectLayout.Layout:addRectShape(parent, parent._abs_x, parent._abs_y, parent._abs_x + parent._width, parent._abs_y + parent._height)
            end
            if utils.debug.enabled and utils.debug.anchors then
                set_color(1, 1, 0, 1)
                love.graphics.circle("fill", 0, 0, 3)
                set_color(1, 1, 1, 1)
            end
            entry.childrenList = listPool:get()
            for _, child in pairs(parent.children) do
                table_insert(entry.childrenList, child)
            end
            table_sort(entry.childrenList, function(a, b) return (a.z_index or 0) < (b.z_index or 0) end)
            entry.index = 1
            entry.state = 2
        elseif entry.state == 2 then
            if entry.index > #entry.childrenList then
                graphics_pop()
                listPool:release(entry.childrenList)
                entry.childrenList = nil
                table.remove(stack)
                goto continue
            end
            local child = entry.childrenList[entry.index]
            entry.index = entry.index + 1
            if child.visible then
                child._abs_x = child._x + child.parent._abs_x
                child._abs_y = child._y + child.parent._abs_y
                table.insert(stack, {node = child, state = 1})
            end
        end
        ::continue::
    end
    stackPool:release(stack)
end

-- 主绘制函数
function UI:draw()
    if self.body and self.body.visible ~= false then
        RectLayout.Layout:clear()
        -- 绘制调试网格
        if utils.debug.enabled and utils.debug.grid then
            set_color(0.3, 0.3, 0.3, 0.5)
            for i = 0, love.graphics.getWidth(), 20 do
                love.graphics.line(i, 0, i, love.graphics.getHeight())
            end
            for i = 0, love.graphics.getHeight(), 20 do
                love.graphics.line(0, i, love.graphics.getWidth(), i)
            end
            set_color(1, 1, 1, 1)
        end

        -- 绘制body轮廓
        if utils.debug.enabled and utils.debug.outlines then
            set_color(1, 0, 0, 1)
            rectangle("line", self.body._x, self.body._y, self.body._width, self.body._height)
            set_color(1, 1, 1, 1)
        end

        -- 绘制UI元素
        drawChildren(self.body)

        -- 标记UI已绘制
        self.needsRedraw = false
    end
end

-- 调试控制函数
function UI:toggleDebug()
    self.debug.enabled = not self.debug.enabled
    print("[UI DEBUG] Debug mode", self.debug.enabled and "enabled" or "disabled")
end

function UI:setDebugOption(option, value)
    if self.debug[option] ~= nil then
        self.debug[option] = value
        print("[UI DEBUG] Set", option, "to", value)
    else
        print("[UI WARNING] Invalid debug option:", option)
    end
end

-- 添加UI元素函数
function UI:addElement(parentId, element)
    local function findParent(node, id)
        if node.id == id then
            return node
        end

        if node.children then
            for _, child in pairs(node.children) do
                local found = findParent(child, id)
                if found then return found end
            end
        end
        return nil
    end

    local parent = findParent(self.body, parentId)
    if parent then
        if not parent.children then
            parent.children = {}
        end

        local newElement = Element.new(element)
        parent.children[newElement.id] = newElement
        newElement.parent = createOrReuseParentProxy(newElement, parent)

        print("[UI INFO] Added element:", element.id, "to parent:", parentId)

        -- 标记UI需要更新
        self.needsUpdate = true

        return element.id
    else
        print("[UI ERROR] Parent not found:", parentId)
    end
    return false
end

-- 移除UI元素函数
function UI:removeElement(elementId)
    local function removeFromParent(node, id)
        if node.children then
            for key, child in pairs(node.children) do
                if child.id == id then
                    local element = node.children[key]
                    node.children[key] = nil
                    if element.remove then
                        element:remove()
                    end
                    print("[UI INFO] Removed element:", id)
                    return true
                end
                if removeFromParent(child, id) then
                    return true
                end
            end
        end
        return false
    end

    local success = removeFromParent(self.body, elementId)
    if not success then
        print("[UI WARNING] Element not found for removal:", elementId)
    else
        -- 标记UI需要更新
        self.needsUpdate = true
    end
    return success
end

-- 查找UI元素函数
function UI:findElement(elementId)
    local function search(node, id)
        if node.id == id then
            return node
        end

        if node.children then
            for _, child in pairs(node.children) do
                local found = search(child, id)
                if found then return found end
            end
        end
        return nil
    end

    local element = search(self.body, elementId)
    if not element then
        print("[UI DEBUG] Element not found:", elementId)
    end
    return element
end

-- 显示/隐藏元素函数
function UI:setElementVisibility(elementId, visible)
    local element = self:findElement(elementId)
    if element then
        element.visible = visible
        if utils.debug.enabled then
            print("[UI DEBUG] Set visibility for", elementId, "to", visible)
        end
        -- 标记UI需要更新
        self.needsUpdate = true

        return true
    end
    print("[UI WARNING] Element not found for visibility change:", elementId)
    return false
end

-- 更新元素尺寸定义
function UI:updateElementSize(elementId, widthDef, heightDef)
    local element = self:findElement(elementId)
    if element then
        if widthDef then
            element.width = widthDef
        end
        if heightDef then
            element.height = heightDef
        end
        print("[UI DEBUG] Updated size for element:", elementId)

        -- 标记UI需要更新
        self.needsUpdate = true

        return true
    end
    return false
end

-- 设置元素位置
function UI:setElementPosition(elementId, displayMode, anchor, offsetX, offsetY)
    local element = self:findElement(elementId)
    if element then
        element.display_mode = displayMode or element.display_mode
        element.anchor = anchor or element.anchor
        element.offset = element.offset or {}
        element.offset.x = offsetX or element.offset.x
        element.offset.y = offsetY or element.offset.y
        print("[UI DEBUG] Updated position for element:", elementId)

        -- 标记UI需要更新
        self.needsUpdate = true

        return true
    end
    return false
end

-- 获取元素位置和尺寸
function UI:getElementRect(elementId)
    local element = self:findElement(elementId)
    if element then
        return {
            x = element._x,
            y = element._y,
            width = element._width,
            height = element._height
        }
    end
    return nil
end

-- 设置元素绘制函数
function UI:setElementDrawFunc(elementId, drawFunc)
    local element = self:findElement(elementId)
    if element then
        element.draw = drawFunc
        print("[UI DEBUG] Set draw function for element:", elementId)
        return true
    end
    return false
end

-- 设置元素Z索引
function UI:setElementZIndex(elementId, zIndex)
    local element = self:findElement(elementId)
    if element then
        element.z_index = zIndex
        print("[UI DEBUG] Set z-index for element:", elementId, "to", zIndex)
        return true
    end
    return false
end

-- 打印UI结构
function UI:printStructure()
    local function printNode(node, indent)
        indent = indent or 0
        local spaces = string.rep("  ", indent)
        print(string.format("%s[%s] %s (z:%d, %sx%s, pos:%d,%d, vis:%s)",
            spaces, node.id, node.display_mode or "none",
            node.z_index or 0, node._width, node._height,
            node._x or 0, node._y or 0,
            tostring(node.visible ~= false)))

        if node.children then
            for _, child in pairs(node.children) do
                printNode(child, indent + 1)
            end
        end
    end

    print("[UI STRUCTURE]")
    printNode(self.body)
end

-- 确保在游戏循环中调用UI更新
function UI:checkForUpdates(dt)
    if self.needsUpdate then
        self:update(dt)
        self.needsUpdate = false
        return true
    end
    return false
end

-- 初始化UI
function UI:init()
    if jit then
        ---@diagnostic disable-next-line: undefined-field
        jit.opt.start("hotloop=10", "hotexit=5")
        jit.on()
    end
    self.needsUpdate = true
    self:update()
end

-- 初始化UI
UI:init()

return UI
