local utils = require("UI.utils")
local left_pl = require("UI.Layout.body.main_menu.left_pl")
local right_pl = require("UI.Layout.body.main_menu.right_pl.init")
local Element = require("UI.Components.Element")

local main_menu = Element.new({
    id = "main_menu",
    z_index = 2,
    visible = true,
    width = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    -- display_mode = utils.DISPLAY_MODES.FILL,
    anchor = "top_left",
    children = {
        left_pl,
        right_pl
    },
}
)
return main_menu
