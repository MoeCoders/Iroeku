local main = require("UI.Layout.body.main_menu")

local body = {
    id = "body",
    _x = 0,
    _y = 0,
    _abs_x = 0,
    _abs_y = 0,
    children = { main },
    is_display = true
}
return body
