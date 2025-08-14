local UI = require("UI")

local gameDisplay = require("display")

-- 初始化矩形的一些默认值
function love.load()
    love.window.setFullscreen(false)
    local msgpack = require("libs/msgpack")
    -- load background image
    gameDisplay.backgroundImage = love.graphics.newImage("resources/bg.png")
end

function love.update(dt)
    UI.update()
end

-- 绘制背景
function love.draw()
    -- 图片大小自适应，根据Body尺寸显示，保持纵横比, 并居中显示
    UI.draw()
end
