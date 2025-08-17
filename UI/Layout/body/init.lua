local main = require("UI.Layout.body.main_menu")
local game = require("UI.Layout.body.game")

local body = {
    id = "body",
    _x = 0,
    _y = 0,
    _abs_x = 0,
    _abs_y = 0,
    children = { main, game },
    visible = true
}
return body
