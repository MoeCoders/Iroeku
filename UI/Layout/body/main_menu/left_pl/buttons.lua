local utils = require("UI.utils")
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle
local math_floor = math.floor
local Element = require("UI.Components.Element")

local buttons = Element.new({
    id = "button_list",
    z_index = 1,
    visible = true,
    width = { value = 0.7, unit = utils.SIZE_UNITS.PERCENT },
    height = { value = 0.7, unit = utils.SIZE_UNITS.PERCENT },
    anchor = "center",
    draw = function(self)
        set_color(1, 0, 0, 0.5)
        rectangle("fill", 0, 0, self._width, self._height)
        if utils.debug.enabled then
            if utils.debug.positions or utils.debug.sizes then
                set_color(0, 0, 0, 1)
                local text = self.id
                if utils.debug.sizes then
                    text = text ..
                        string.format("\nSize: %d x %d", math_floor(self._width),
                            math_floor(self._height))
                end
                if utils.debug.positions then
                    text = text ..
                        string.format("\nRel_Pos: (%d, %d)", math_floor(self._x), math_floor(self._y))
                    text = text ..
                        string.format("\nAbs_Pos: (%d, %d)", math_floor(self._abs_x),
                            math_floor(self._abs_y))
                end
                if utils.debug.anchors then
                    text = text .. string.format("\nAnchor: %s", self.anchor or "none")
                end
                love.graphics.print(text, 10, 10)
                set_color(1, 1, 1, 1)
            end
        end
    end,
})

return buttons
