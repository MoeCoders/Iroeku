local utils = require("UI.utils")
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle
local math_floor = math.floor
local Element = require("UI.Components.Element")
local right_pl = Element.new({
    id = "right",
    z_index = 2,
    visible = true,
    width = { value = 0.7, unit = utils.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    display_mode = utils.DISPLAY_MODES.RELATIVE,
    anchor = "top_right",
    children = nil,
})

local function DrawRightPl(self)
    set_color(0.9, 0.9, 1, 0.5)
    rectangle("fill", 0, 0, self._width, self._height)

    -- 调试: 显示位置和尺寸信息
    if utils.debug.enabled then
        if utils.debug.positions or utils.debug.sizes then
            set_color(0, 0, 0, 1)
            local text = "Right Panel"
            if utils.debug.sizes then
                text = text ..
                    string.format("\nSize: %d x %d", math_floor(self._width), math_floor(self._height))
            end
            if utils.debug.positions then
                text = text .. string.format("\nPos: (%d, %d)", math_floor(self._x), math_floor(self._y))
            end
            if utils.debug.anchors then
                text = text .. string.format("\nAnchor: %s", self.anchor or "none")
            end
            love.graphics.print(text, 10, 10)
            set_color(0.9, 0.9, 1, 1)
        end

        if utils.debug.outlines then
            set_color(0, 0, 1, 1)
            rectangle("line", 0, 0, self._width, self._height)
            set_color(0.9, 0.9, 1, 1)
        end
    end
end

right_pl:setDrawFunc(DrawRightPl)
return right_pl
