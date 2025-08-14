local conf = require("conf")
local display = require("display")
local UI = {}
local aaa = love.graphics.newImage("resources/logo.jpg")
UI.body = {
    width = nil,
    height = nil,
    x = nil,
    y = nil,
    children = {
        background = {},
        main_menu = {}
    },
}

UI.body.children.background = {
    z_index = 1,
    is_display = true,
    width_percent = 1,
    height_percent = 1,
    x = 0,
    y = 0,
    children = nil,
    draw = function(self)
        -- 计算缩放比例
        if self.parent then
            local scaleX = self.parent.width / display.backgroundImage:getWidth()
            local scaleY = self.parent.height / display.backgroundImage:getHeight()
            love.graphics.scale(scaleX, scaleY)
        end
        -- 绘制背景图（此时坐标已被translate转换，所以用0,0）
        love.graphics.draw(display.backgroundImage, self.x, self.y)
    end
}
UI.body.children.main_menu = {
    z_index = 2,
    is_display = true,
    width_percent = 1,
    height_percent = 1,
    x = 0,
    y = 0,
    children = nil,
    draw = function(self)
        local scaleX = UI.body.width / display.backgroundImage:getWidth()
        local scaleY = UI.body.height / display.backgroundImage:getHeight()
        love.graphics.scale(scaleX, scaleY)

        -- 绘制背景图（此时坐标已被translate转换，所以用0,0）
        love.graphics.draw(aaa, self.x, self.y)
    end
}

function UI:update()
    -- Body容器，长宽根据配置的横纵比计算，大小自适应，位置居中
    UI.body.width = math.min(love.graphics.getWidth(), love.graphics.getHeight() * conf.aspectRatio)
    UI.body.height = UI.body.width / conf.aspectRatio
    UI.body.x = (love.graphics.getWidth() - UI.body.width) / 2
    UI.body.y = (love.graphics.getHeight() - UI.body.height) / 2
end

local draw_children
function draw_children(parent)
    if parent.children ~= nil then
        local queue = {}
        for k, _ in pairs(parent.children) do
            table.insert(queue, k)
        end
        table.sort(queue, function(a, b)
            return parent.children[a].z_index < parent.children[b].z_index
        end)
        for _, k in ipairs(queue) do
            local child = parent.children[k]
            child.width = parent.width * child.width_percent
            child.height = parent.height * child.height_percent
            child.parent = { width = parent.width, height = parent.height }
            if child.is_display then
                love.graphics.push()
                love.graphics.translate(parent.x, parent.y)
                child:draw()
                draw_children(child)
                love.graphics.pop()
            end
        end
    end
end

function UI:draw()
    draw_children(UI.body)
end

return UI
