local utils = require("UI.utils")
local set_color = love.graphics.setColor
local rectangle = love.graphics.rectangle
local math_floor = math.floor

local main_menu = {
    id = "main_menu",
    z_index = 2,
    is_display = true,
    width = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    display_mode = utils.DISPLAY_MODES.FILL,
    anchor = "top_left",
    children = {
        left = {
            id = "left",
            z_index = 1,
            is_display = true,
            width = { value = 0.3, unit = utils.SIZE_UNITS.PERCENT },
            height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
            display_mode = utils.DISPLAY_MODES.RELATIVE,
            anchor = "top_left",
            children = {
                buttonlist = {
                    id = "button_list",
                    z_index = 1,
                    is_display = true,
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
                }
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
            end
        },
        right = {
            id = "right",
            z_index = 2,
            is_display = true,
            width = { value = 0.7, unit = utils.SIZE_UNITS.PERCENT },
            height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
            display_mode = utils.DISPLAY_MODES.RELATIVE,
            anchor = "top_right",
            children = nil,
            draw = function(self)
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
        }
    },
    draw = nil
}

return main_menu
