local utils = require("UI.utils")
local rectangle = love.graphics.rectangle
local set_color = love.graphics.setColor
local math_floor = math.floor
local buttons = require("UI.Layout.body.main_menu.left_pl.buttons")
local Element = require("UI.Components.Element")

local left_pl = Element.new({
    id = "left",
    z_index = 1,
    visible = true,
    width = { value = 0.3, unit = utils.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    display_mode = utils.DISPLAY_MODES.RELATIVE,
    anchor = "top_left",
    children = {
        buttons
    },
    draw = function(self)
        set_color(1, 1, 1, 0.7)
        rectangle("fill", 0, 0, self._width, self._height)

        -- 调试: 显示位置和尺寸信息
        if utils.debug.enabled then
            if utils.debug.positions or utils.debug.sizes then
                set_color(0, 0, 0, 1)
                local text = self.id
                if utils.debug.sizes then
                    text = text ..
                        string.format("\nSize: %d x %d", math_floor(self._width), math_floor(self._height))
                end
                if utils.debug.positions then
                    text = text .. string.format("\nRel_Pos: (%d, %d)", math_floor(self._x), math_floor(self._y))
                    text = text ..
                        string.format("\nAbs_Pos: (%d, %d)", math_floor(self._abs_x), math_floor(self._abs_y))
                end
                if utils.debug.anchors then
                    text = text .. string.format("\nAnchor: %s", self.anchor or "none")
                end
                love.graphics.print(text, 10, 10)
                set_color(1, 1, 1, 1)
            end

            if utils.debug.outlines then
                set_color(0, 1, 0, 1)
                rectangle("line", 0, 0, self._width, self._height)
                set_color(1, 1, 1, 1)
            end
        end
    end,
})
return left_pl
