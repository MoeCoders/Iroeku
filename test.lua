local engine = require "engine"

-- 定义角色（全局定义，可在多个章节使用）
local 舞
local 我

-- 第一章
engine.chapter("第一章", function()
    engine.background "校园_日.jpg"

    -- 创建角色
    舞 = engine.Character {
        name = "舞",
        image = "舞_制服1.png",
        x = 720,
        y = 96,
        other = {
            好感度 = 50
        }
    }

    我 = engine.Character {
        name = "我",
        image = "主角_默认.png",
        x = 400,
        y = 96
    }

    舞:show()
    舞 "勇太也有兴趣吧？"

    local choice = engine.Choice {
        "确实……不能说没有。",
        "鬼才会有。"
    }

    if choice == 1 then
        舞.other.好感度 = 舞.other.好感度 + 20
        我:show()
        我 "确实……不能说没有。"
        engine._ "我回想起今天在教室里做的那个<#ff0000>怪梦<font>。"
    else
        我:show()
        我 "鬼才会有。"
        舞.image = "舞_制服_生气1.png"
        舞 "咦咦咦~~~明明就很有意思耶~~\n……来，这一段你看一下嘛。"
    end

    -- 进入下一章
    engine.gotoChapter "第二章"
end)

-- 第二章
engine.chapter("第二章", function()
    engine.background "教室_日.jpg"

    舞:show()
    我:show()

    if 舞.好感度 > 60 then
        舞 "今天的课程很有趣吧？"
        我 "嗯，特别是数学课。"
    else
        舞.image = "舞_制服_生气1.png"
        舞 "哼，不理你了！"
    end

    engine._ "一天的学习生活就这样结束了。"
end)

-- 启动游戏
print("游戏开始")
engine.startChapter("第一章")
