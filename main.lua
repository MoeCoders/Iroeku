--- 主模块
local UI = require("UI")
local RectLayout = require("UI.RectLayout")
local gameDisplay = require("display")

--- LOVE2D 加载函数
function love.load()
    gameDisplay.backgroundImage = love.graphics.newImage("resources/bg.png")
    love.keyboard.setKeyRepeat(false)
end

--- 每帧更新
--- @param dt number 帧间隔时间
function love.update(dt)
    UI:checkForUpdates()
end

--- 调整窗口大小
--- @param w number
--- @param h number
function love.resize(w, h)
    -- 标记UI需要更新
    UI.needsUpdate = true
end

--- 绘制函数
function love.draw()
    if love.window.isMinimized() then
        return
    end
    UI:draw()
end

--- 按键按下处理
--- @param key string
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

--- 按键释放处理
--- @param key string
function love.keyreleased(key)
    if key == "a" then
        local rightElement = UI:findElement("right")
        if rightElement then
            UI:setElementVisibility("right", not rightElement.is_display)
        end
    end
end

--- 鼠标按下处理
--- @param x number 鼠标 X 坐标
--- @param y number 鼠标 Y 坐标
--- @param button number 鼠标按键
function love.mousepressed(x, y, button)
    local e = RectLayout.Layout:getShapeDataAtPoint(x, y)
    print("Clicked on element with ID: " .. (e and e.id or "none"))
end
