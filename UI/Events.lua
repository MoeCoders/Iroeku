local Events = {}
local RectLayout = require("UI.RectLayout")

function Events.onClick(x, y)
    local element = RectLayout.Layout:getShapeDataAtPoint(x, y)
    if not element then return end
    print("The element " .. element.id .. " was clicked.")
    if type(element.events.onClick) == "function" then
        element.events.onClick()
    end
end

return Events
