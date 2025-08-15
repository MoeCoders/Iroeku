local conf = require("conf")
local display = require("display")

-- 局部化常用函数和模块
local math_min = math.min
local math_floor = math.floor
local math_max = math.max
local graphics_getWidth = love.graphics.getWidth
local graphics_getHeight = love.graphics.getHeight
local graphics_push = love.graphics.push
local graphics_pop = love.graphics.pop
local graphics_translate = love.graphics.translate
local graphics_draw = love.graphics.draw
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle
local print = print

-- 创建父元素代理元表
local ParentProxy = {}
ParentProxy.__index = function(t, k)
    return t._parent[k]
end

-- 创建父元素代理对象
local function createParentProxy(parent)
    return setmetatable({ _parent = parent }, ParentProxy)
end

-- UI 结构定义
local UI = {
    body = {
        id = "body",
        _x = 0,
        _y = 0,
        _width = 0,
        _height = 0,
        children = {}
    },
    -- 调试配置
    debug = {
        enabled = conf.debug or false, -- 是否启用调试
        grid = true,                   -- 是否显示网格
        outlines = true,               -- 是否显示轮廓
        positions = true,              -- 是否显示位置信息
        sizes = true,                  -- 是否显示尺寸信息
        anchors = true,                -- 是否显示锚点
    },

    -- 支持的新显示模式
    DISPLAY_MODES = {
        RELATIVE = "relative",           -- 相对位置 (默认)
        CENTER = "center",               -- 居中
        TOP_LEFT = "top_left",           -- 左上角
        TOP_RIGHT = "top_right",         -- 右上角
        TOP_CENTER = "top_center",       -- 顶部居中
        BOTTOM_LEFT = "bottom_left",     -- 左下角
        BOTTOM_RIGHT = "bottom_right",   -- 右下角
        BOTTOM_CENTER = "bottom_center", -- 底部居中
        LEFT_CENTER = "left_center",     -- 左侧居中
        RIGHT_CENTER = "right_center",   -- 右侧居中
        FILL = "fill",                   -- 填充父容器
        ABSOLUTE = "absolute"            -- 绝对定位 (相对于屏幕)
    },

    -- 支持的尺寸单位
    SIZE_UNITS = {
        PIXELS = "pixels",   -- 像素值
        PERCENT = "percent", -- 百分比
        ASPECT = "aspect"    -- 保持宽高比
    }
}

-- 资源预加载
display.logoImage = display.logoImage or love.graphics.newImage("resources/logo.jpg")
display.backgroundImage = display.backgroundImage or love.graphics.newImage("resources/bg.png")

-- 背景绘制函数
local function drawBackground(self)
    if not display.backgroundImage then return end

    -- 计算缩放比例以适应节点尺寸
    local scaleX = self._width / display.backgroundImage:getWidth()
    local scaleY = self._height / display.backgroundImage:getHeight()

    -- 绘制背景图并缩放以适应节点
    set_color(1, 1, 1, 1)
    graphics_draw(display.backgroundImage, 0, 0, 0, scaleX, scaleY)

    -- 调试: 绘制轮廓
    if UI.debug.enabled and UI.debug.outlines then
        set_color(1, 0, 0, 1)
        rectangle("line", 0, 0, self._width, self._height)
        set_color(1, 1, 1, 1)
    end
end

-- 主菜单绘制函数
local function drawMainMenu(self)
    set_color(1, 1, 1, 0.7)
    rectangle("fill", 0, 0, self._width, self._height)

    -- 调试: 显示位置和尺寸信息
    if UI.debug.enabled then
        if UI.debug.positions or UI.debug.sizes then
            set_color(0, 0, 0, 1)
            local text = "Left Panel"
            if UI.debug.sizes then
                text = text .. string.format("\nSize: %d x %d", math_floor(self._width), math_floor(self._height))
            end
            if UI.debug.positions then
                text = text .. string.format("\nPos: (%d, %d)", math_floor(self._x), math_floor(self._y))
            end
            if UI.debug.anchors then
                text = text .. string.format("\nAnchor: %s", self.anchor or "none")
            end
            love.graphics.print(text, 10, 10)
            set_color(1, 1, 1, 1)
        end

        if UI.debug.outlines then
            set_color(0, 1, 0, 1)
            rectangle("line", 0, 0, self._width, self._height)
            set_color(1, 1, 1, 1)
        end
    end
end

-- 初始化UI结构
UI.body.children.background = {
    id = "background",
    z_index = 1,
    is_display = true,
    width = { value = 1, unit = UI.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = UI.SIZE_UNITS.PERCENT },
    display_mode = UI.DISPLAY_MODES.FILL,
    anchor = "top_left",
    children = nil,
    draw = drawBackground
}

UI.body.children.main_menu = {
    id = "main_menu",
    z_index = 2,
    is_display = true,
    width = { value = 1, unit = UI.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = UI.SIZE_UNITS.PERCENT },
    display_mode = UI.DISPLAY_MODES.FILL,
    anchor = "top_left",
    children = {
        left = {
            id = "left",
            z_index = 1,
            is_display = true,
            width = { value = 0.3, unit = UI.SIZE_UNITS.PERCENT },
            height = { value = 1, unit = UI.SIZE_UNITS.PERCENT },
            display_mode = UI.DISPLAY_MODES.RELATIVE,
            anchor = "top_left",
            offset = { x = 0, y = 0 },
            children = nil,
            draw = drawMainMenu
        },
        right = {
            id = "right",
            z_index = 2,
            is_display = true,
            width = { value = 0.7, unit = UI.SIZE_UNITS.PERCENT },
            height = { value = 1, unit = UI.SIZE_UNITS.PERCENT },
            display_mode = UI.DISPLAY_MODES.RELATIVE,
            anchor = "top_right",
            offset = { x = 1, y = 0 }, -- 从父节点宽度的30%处开始
            children = nil,
            draw = function(self)
                set_color(0.9, 0.9, 1, 0.5)
                rectangle("fill", 0, 0, self._width, self._height)

                -- 调试: 显示位置和尺寸信息
                if UI.debug.enabled then
                    if UI.debug.positions or UI.debug.sizes then
                        set_color(0, 0, 0, 1)
                        local text = "Right Panel"
                        if UI.debug.sizes then
                            text = text ..
                                string.format("\nSize: %d x %d", math_floor(self._width), math_floor(self._height))
                        end
                        if UI.debug.positions then
                            text = text .. string.format("\nPos: (%d, %d)", math_floor(self._x), math_floor(self._y))
                        end
                        if UI.debug.anchors then
                            text = text .. string.format("\nAnchor: %s", self.anchor or "none")
                        end
                        love.graphics.print(text, 10, 10)
                        set_color(0.9, 0.9, 1, 1)
                    end

                    if UI.debug.outlines then
                        set_color(0, 0, 1, 1)
                        rectangle("line", 0, 0, self._width, self._height)
                        set_color(0.9, 0.9, 1, 1)
                    end
                end
            end
        }
    },
    draw = nil
}

-- 尺寸计算函数
local function calculateDimension(def, parentDim)
    -- 如果def是数字，则将其视为像素值
    if type(def) == "number" then
        return def
    end

    -- 如果def是表，则按定义处理
    if type(def) == "table" then
        local value = def.value or 1
        local unit = def.unit or UI.SIZE_UNITS.PIXELS

        if unit == UI.SIZE_UNITS.PERCENT then
            return parentDim * value
        else -- PIXELS
            return value
        end
    end

    -- 默认情况
    return parentDim
end

-- 递归更新子节点尺寸信息 - 修复尺寸更新问题
local function updateChildren(parent)
    if not parent or not parent.children then return end

    -- 先更新所有子节点的尺寸
    for _, child in pairs(parent.children) do
        if not child.is_display then goto continue end

        -- 设置/更新父代理
        if not child.parent then
            child.parent = createParentProxy(parent)
        else
            child.parent._parent = parent
        end

        -- 处理尺寸定义 - 保留原始定义
        local widthDef = child.width or { value = 1, unit = UI.SIZE_UNITS.PERCENT }
        local heightDef = child.height or { value = 1, unit = UI.SIZE_UNITS.PERCENT }

        -- 计算尺寸 - 使用统一的尺寸计算函数
        -- 使用 _width 和 _height 存储计算后的尺寸
        child._width = calculateDimension(widthDef, parent._width)
        child._height = calculateDimension(heightDef, parent._height)

        -- 限制最小/最大尺寸
        if child.min_width then
            child._width = math_max(child._width, calculateDimension(child.min_width, parent._width))
        end
        if child.max_width then
            child._width = math_min(child._width, calculateDimension(child.max_width, parent._width))
        end
        if child.min_height then
            child._height = math_max(child._height, calculateDimension(child.min_height, parent._height))
        end
        if child.max_height then
            child._height = math_min(child._height, calculateDimension(child.max_height, parent._height))
        end

        ::continue::
    end

    -- 然后更新位置（确保所有尺寸已计算）
    for _, child in pairs(parent.children) do
        if not child.is_display then goto continue end

        -- 获取偏移量（支持百分比和像素值）
        local offsetX = child.offset and child.offset.x or 0
        local offsetY = child.offset and child.offset.y or 0

        -- 转换百分比偏移
        if type(offsetX) == "number" and offsetX >= 0 and offsetX <= 1 then
            offsetX = parent._width * offsetX
        else
            offsetX = offsetX or 0
        end
        if type(offsetY) == "number" and offsetY >= 0 and offsetY <= 1 then
            offsetY = parent._height * offsetY
        else
            offsetY = offsetY or 0
        end

        -- 锚点位置计算
        local anchor = child.anchor or "top_left"

        -- 根据显示模式和锚点计算位置
        if child.display_mode == UI.DISPLAY_MODES.RELATIVE then
            -- 相对位置
            child._x = offsetX
            child._y = offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.CENTER then
            -- 居中
            child._x = (parent._width - child._width) / 2 + offsetX
            child._y = (parent._height - child._height) / 2 + offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.TOP_LEFT then
            -- 左上角
            child._x = offsetX
            child._y = offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.TOP_RIGHT then
            -- 右上角
            child._x = parent._width - child._width - offsetX
            child._y = offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.TOP_CENTER then
            -- 顶部居中
            child._x = (parent._width - child._width) / 2 + offsetX
            child._y = offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.BOTTOM_LEFT then
            -- 左下角
            child._x = offsetX
            child._y = parent._height - child._height - offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.BOTTOM_RIGHT then
            -- 右下角
            child._x = parent._width - child._width - offsetX
            child._y = parent._height - child._height - offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.BOTTOM_CENTER then
            -- 底部居中
            child._x = (parent._width - child._width) / 2 + offsetX
            child._y = parent._height - child._height - offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.LEFT_CENTER then
            -- 左侧居中
            child._x = offsetX
            child._y = (parent._height - child._height) / 2 + offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.RIGHT_CENTER then
            -- 右侧居中
            child._x = parent._width - child._width - offsetX
            child._y = (parent._height - child._height) / 2 + offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.FILL then
            -- 填充父容器 - 仅设置位置，不重置尺寸
            child._x = offsetX
            child._y = offsetY
        elseif child.display_mode == UI.DISPLAY_MODES.ABSOLUTE then
            -- 绝对定位（相对于屏幕）
            child._x = offsetX
            child._y = offsetY
        else
            -- 默认相对定位
            child._x = offsetX
            child._y = offsetY
        end

        -- 根据锚点微调位置
        if anchor == "top_left" then
            -- 默认，无需调整
        elseif anchor == "top_center" then
            child._x = child._x - child._width / 2
        elseif anchor == "top_right" then
            child._x = child._x - child._width
        elseif anchor == "center_left" then
            child._y = child._y - child._height / 2
        elseif anchor == "center" then
            child._x = child._x - child._width / 2
            child._y = child._y - child._height / 2
        elseif anchor == "center_right" then
            child._x = child._x - child._width
            child._y = child._y - child._height / 2
        elseif anchor == "bottom_left" then
            child._y = child._y - child._height
        elseif anchor == "bottom_center" then
            child._x = child._x - child._width / 2
            child._y = child._y - child._height
        elseif anchor == "bottom_right" then
            child._x = child._x - child._width
            child._y = child._y - child._height
        end

        -- 调试: 打印位置和尺寸信息
        if UI.debug.enabled then
            print(string.format(
                "[UI DEBUG] child %s: mode=%s, anchor=%s, x=%d, y=%d, width=%d, height=%d",
                child.id, child.display_mode, child.anchor or "none",
                math_floor(child._x), math_floor(child._y),
                math_floor(child._width), math_floor(child._height)
            ))
        end

        -- 递归处理子节点
        updateChildren(child)

        ::continue::
    end
end

-- 修复: 确保body尺寸正确更新
function UI:update()
    local screenWidth = graphics_getWidth()
    local screenHeight = graphics_getHeight()

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

    if UI.debug.enabled then
        print("[UI DEBUG] Body updated:")
        print(string.format("  Position: (%d, %d)", math_floor(body._x), math_floor(body._y)))
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
local function drawChildren(parent)
    if not parent.children then return end

    -- 应用父节点变换
    graphics_push()
    graphics_translate(parent._x, parent._y)

    -- 收集子节点到列表用于排序
    local childrenList = {}
    for _, child in pairs(parent.children) do
        table_insert(childrenList, child)
    end

    -- 按z_index排序（从低到高）
    table_sort(childrenList, function(a, b)
        return (a.z_index or 0) < (b.z_index or 0)
    end)

    -- 绘制子节点
    for _, child in ipairs(childrenList) do
        if child.is_display then
            graphics_push()
            -- 应用子节点变换
            graphics_translate(child._x, child._y)

            -- 绘制子节点内容
            if type(child.draw) == "function" then
                child:draw()
            end

            -- 调试: 绘制锚点
            if UI.debug.enabled and UI.debug.anchors then
                set_color(1, 1, 0, 1)
                love.graphics.circle("fill", 0, 0, 3)
                set_color(1, 1, 1, 1)
            end

            -- 递归绘制子节点的子节点
            drawChildren(child)

            graphics_pop()
        end
    end

    graphics_pop()
end

-- 主绘制函数
function UI:draw()
    if self.body and self.body.is_display ~= false then
        -- 绘制调试网格
        if UI.debug.enabled and UI.debug.grid then
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
        if UI.debug.enabled and UI.debug.outlines then
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

        -- 确保元素有必要的字段
        element.id = element.id or ("element_" .. tostring(math.random(10000, 99999)))
        element.z_index = element.z_index or 1
        element.is_display = element.is_display ~= false
        element.display_mode = element.display_mode or UI.DISPLAY_MODES.RELATIVE
        element.anchor = element.anchor or "top_left"
        element.offset = element.offset or { x = 0, y = 0 }

        -- 设置尺寸默认值
        if not element.width then
            element.width = { value = 1, unit = UI.SIZE_UNITS.PERCENT }
        end
        if not element.height then
            element.height = { value = 1, unit = UI.SIZE_UNITS.PERCENT }
        end

        parent.children[element.id] = element
        element.parent = createParentProxy(parent)

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
                    node.children[key] = nil
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
        element.is_display = visible
        print("[UI DEBUG] Set visibility for", elementId, "to", visible)

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
            tostring(node.is_display ~= false)))

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
function UI:checkForUpdates()
    if self.needsUpdate then
        self:update()
        self.needsUpdate = false
        return true
    end
    return false
end

-- 初始化UI
function UI:init()
    self.needsUpdate = true
    self:update()
end

-- 初始化UI
UI:init()

return UI
