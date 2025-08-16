local UI = require("UI")
local RectLayout = require("UI.RectLayout")
local gameDisplay = require("display")

-- 初始化矩形的一些默认值
function love.load()
    -- load background image
    gameDisplay.backgroundImage = love.graphics.newImage("resources/bg.png")
    love.keyboard.setKeyRepeat(false)
end

function love.update(dt)
    UI:checkForUpdates()
end

function love.resize(w, h)
    -- 标记UI需要更新
    UI.needsUpdate = true
end

function love.draw()
    -- 图片大小自适应，根据Body尺寸显示，保持纵横比, 并居中显示
    UI:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.keyreleased(key)
    if key == "a" then
        UI:setElementVisibility("right", not UI:findElement("right").is_display)
    end
end

function love.mousepressed(x, y, button)
    local e = RectLayout.Layout:getShapeDataAtPoint(x, y)
    print("Clicked on element with ID: " .. (e and e.id or "none"))
end
