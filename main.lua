local UI = require("UI")

local gameDisplay = require("display")

-- 初始化矩形的一些默认值
function love.load()
    -- load background image
    gameDisplay.backgroundImage = love.graphics.newImage("resources/bg.png")
    love.keyboard.setKeyRepeat(false)
end

function love.update(dt)
    UI:update()
end

-- 绘制背景
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
        UI.body.children.main_menu.is_display = not UI.body.children.main_menu.is_display
    end
end
