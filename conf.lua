--- @class GameConfig
--- @field title string
--- @field subtitle string
--- @field aspectRatio number
--- @field debug boolean

function love.conf(t)
    t.window.title = "My Game"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.modules.physics = false
end

local gameConfig = {
    title = "My Game",
    subtitle = "A fun game",
    aspectRatio = 16 / 9,
    debug = true
}

return gameConfig
