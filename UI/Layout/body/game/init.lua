local utils = require("UI.utils")
local background = require("UI.Layout.body.game.background")
local Element = require("UI.Components.Element")

local game_UI = Element.new({
    visible = true,
    width = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    height = { value = 1, unit = utils.SIZE_UNITS.PERCENT },
    z_index = 1,
    anchor = "top_left",
    draw = nil,
    children = {
        background
    }
})

return game_UI
