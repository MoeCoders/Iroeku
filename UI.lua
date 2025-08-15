local conf = require("conf")
local display = require("display")

-- 局部化常用函数和模块
local math_min = math.min
local graphics_getWidth = love.graphics.getWidth
local graphics_getHeight = love.graphics.getHeight
local graphics_push = love.graphics.push
local graphics_pop = love.graphics.pop
local graphics_translate = love.graphics.translate
local graphics_scale = love.graphics.scale
local graphics_draw = love.graphics.draw
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local table_sort = table.sort
local table_insert = table.insert

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
        width = 0,
        height = 0,
        x = 0,
        y = 0,
        children = {}
    }
}

-- 资源预加载
display.logoImage = display.logoImage or love.graphics.newImage("resources/logo.jpg")

-- 背景绘制函数
local function drawBackground(self)
    if not display.backgroundImage then return end

    local width = display.backgroundImage:getWidth()
    local height = display.backgroundImage:getHeight()

    if width > 0 and height > 0 then
        -- 通过代理访问父元素属性
        local scaleX = self.parent.width / width
        local scaleY = self.parent.height / height
        graphics_scale(scaleX, scaleY)
    end

    graphics_draw(display.backgroundImage, self.x, self.y)
end

-- 主菜单绘制函数
local function drawLogo(self)
    graphics_push()
    graphics_scale(self.width_percent, self.height_percent)
    if not display.logoImage then return end

    local imgWidth = display.logoImage:getWidth()
    local imgHeight = display.logoImage:getHeight()

    if imgWidth > 0 and imgHeight > 0 then
        -- 通过代理访问父元素属性
        local scale = math.min(self.parent.width / imgWidth, self.parent.height / imgHeight)
        graphics_scale(scale, scale)
    end

    graphics_draw(display.logoImage, self.x, self.y)
    graphics_pop()
end

-- 初始化UI结构
UI.body.children.background = {
    z_index = 1,
    is_display = true,
    width_percent = 1,
    height_percent = 1,
    x = 0,
    y = 0,
    children = nil,
    draw = drawBackground
}

UI.body.children.main_menu = {
    z_index = 2,
    is_display = true,
    width_percent = 0.5,
    height_percent = 0.5,
    x = 0,
    y = 0,
    children = {
        logo = {
            z_index = 1,
            is_display = true,
            width_percent = 0.5,
            height_percent = 0.5,
            x = 0,
            y = 0,
            children = nil,
            draw = drawLogo
        }
    },
    draw = drawLogo
}

-- 更新UI尺寸和位置
function UI:update()
    local screenWidth = graphics_getWidth()
    local screenHeight = graphics_getHeight()

    -- 安全处理宽高比
    local aspectRatio = conf.aspectRatio or (16 / 9)
    if aspectRatio <= 0 then aspectRatio = 16 / 9 end

    -- 计算自适应尺寸
    local bodyWidth = math_min(screenWidth, screenHeight * aspectRatio)
    local bodyHeight = bodyWidth / aspectRatio

    -- 更新body属性
    local body = self.body
    body.width = bodyWidth
    body.height = bodyHeight
    body.x = (screenWidth - bodyWidth) / 2
    body.y = (screenHeight - bodyHeight) / 2
end

-- 递归绘制子节点
local function drawChildren(parent)
    if not parent.children then return end

    -- 收集子节点到列表用于排序
    local childrenList = {}
    for _, child in pairs(parent.children) do
        table_insert(childrenList, child)
    end

    -- 按z_index排序
    table_sort(childrenList, function(a, b)
        return (a.z_index or 0) < (b.z_index or 0)
    end)

    -- 绘制子节点
    for _, child in ipairs(childrenList) do
        if child.is_display then
            -- 计算子节点尺寸
            child.width = parent.width * (child.width_percent or 1)
            child.height = parent.height * (child.height_percent or 1)

            -- 使用元表代理父元素访问
            if not child.parent then
                child.parent = createParentProxy(parent)
            else
                child.parent._parent = parent
            end

            graphics_push()
            graphics_translate(parent.x, parent.y)

            -- 安全调用draw方法
            if type(child.draw) == "function" then
                child:draw()
            end

            -- 递归绘制子节点
            drawChildren(child)

            graphics_pop()
        end
    end
end

-- 主绘制函数
function UI:draw()
    if self.body and self.body.is_display ~= false then
        drawChildren(self.body)
    end
end

return UI
