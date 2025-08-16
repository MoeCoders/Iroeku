local GalEngine = {}
local current_chapter = nil
local chapters = {}
local state = {
    background = nil,
    bgm = nil,
    characters = {},
    variables = {},
    current_choice = nil
}

-- 重置引擎状态
function GalEngine.reset()
    state.background = nil
    state.bgm = nil
    state.characters = {}
    state.variables = {}
    state.current_choice = nil
end

-- 章节管理
function GalEngine.chapter(name, func)
    chapters[name] = func
end

function GalEngine.startChapter(name)
    if not chapters[name] then
        error("章节不存在: " .. name)
    end

    current_chapter = name
    GalEngine.reset()
    chapters[name]()
end

-- 设置背景
function GalEngine.background(image)
    state.background = image
    print("[背景] " .. image)
end

-- 角色定义
function GalEngine.Character(def)
    local char = {
        name = def.name,
        image = def.image,
        x = def.x or 0,
        y = def.y or 0,
        visible = false,
        other = def.other or {}
    }

    --- 显示角色
    function char:show()
        self.visible = true
        print(string.format("[显示角色] %s (%s) at (%d,%d)",
            self.name, self.image, self.x, self.y))
    end

    --- 隐藏角色
    function char:hide()
        self.visible = false
        print("[隐藏角色] " .. self.name)
    end

    setmetatable(char, {
        __call = function(self, ...)
            local args = { ... }
            -- 处理带语音的对话
            if type(args[1]) == "string" and args[1]:match("%.ogg$") then
                print(string.format("[语音] %s: %s", args[1], args[2]))
                print(string.format("[对话] %s: %s", self.name, args[2]))
                return
            end
            -- 普通对话
            print(string.format("[对话] %s: %s", self.name, args[1]))
        end
    })

    state.characters[def.name] = char
    return char
end

-- 选择分支
function GalEngine.Choice(options)
    print("\n[选择分支]")
    for i, opt in ipairs(options) do
        print(i .. ": " .. opt)
    end

    state.current_choice = options
    local choice
    repeat
        io.write("请选择 (1-" .. #options .. "): ")
        choice = tonumber(io.read())
    until choice and choice >= 1 and choice <= #options

    state.current_choice = nil
    return choice
end

-- 旁白处理
function GalEngine.narrator(text)
    -- 移除文本标记保留原始文本
    local clean_text = text:gsub("<[^>]+>", "")
    print("[旁白] " .. clean_text)
end

-- 跳转到章节
function GalEngine.gotoChapter(name)
    if not chapters[name] then
        error("尝试跳转到不存在的章节: " .. name)
    end
    GalEngine.startChapter(name)
end

-- 获取当前章节
function GalEngine.currentChapter()
    return current_chapter
end

-- 获取角色
function GalEngine.getCharacter(name)
    return state.characters[name]
end

-- 设置全局变量
function GalEngine.setVar(name, value)
    state.variables[name] = value
end

-- 获取全局变量
function GalEngine.getVar(name)
    return state.variables[name]
end

-- 设置元表处理全局变量
setmetatable(_G, {
    __index = function(_, k)
        return state.variables[k]
    end,
    __newindex = function(_, k, v)
        state.variables[k] = v
    end
})

-- 别名
GalEngine._ = GalEngine.narrator

return GalEngine
