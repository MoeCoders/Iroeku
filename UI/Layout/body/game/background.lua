local display = require("display")
local utils = require("UI.utils")
local Element = require("UI.Components.Element")
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle
local graphics_draw = love.graphics.draw

display.backgroundImage = display.backgroundImage

local function drawBackground(self)
    local a = love.graphics.newCanvas(self._width, self._height)
    love.graphics.setCanvas(a)
    if not display.backgroundImage then return end

    -- 计算缩放比例以适应节点尺寸
    local scaleX = self._width / display.backgroundImage:getWidth()
    local scaleY = self._height / display.backgroundImage:getHeight()

    -- 绘制背景图并缩放以适应节点
    set_color(1, 1, 1, 1)
    graphics_draw(display.backgroundImage, 0, 0, 0, scaleX, scaleY)
    love.graphics.setCanvas()
    graphics_draw(a)
    -- 调试: 绘制轮廓
    if utils.debug.enabled and utils.debug.outlines then
        set_color(1, 0, 0, 1)
        rectangle("line", 0, 0, self._width, self._height)
        set_color(1, 1, 1, 1)
    end
end

local background = Element.new({
    id = "background",
    z_index = 1,
    visible = true,
    width = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    display_mode = utils.DISPLAY_MODES.FILL,
    anchor = "top_left",
    children = {
        sd = Element.new({
            id = "sd",
            z_index = 1,
            visible = true,
            width = { value = 0.3, unit = utils.SIZE_UNITS.PERCENT },
            height = { value = 0.3, unit = utils.SIZE_UNITS.PERCENT },
            anchor = "center",
            draw = function(self)
                set_color(0, 1, 0, 1)
                rectangle("fill", 0, 0, self._width, self._height)
            end
        })
    },
})

background:setDrawFunc(drawBackground)

return background
