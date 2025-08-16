local conf = require("conf")
local utils = {}
utils = {
    debug = {
        enabled = conf.debug or false, -- 是否启用调试
        grid = true,                   -- 是否显示网格
        outlines = true,               -- 是否显示轮廓
        positions = true,              -- 是否显示位置信息
        sizes = true,                  -- 是否显示尺寸信息
        anchors = true,                -- 是否显示锚点
    },

    -- 支持的显示模式
    DISPLAY_MODES = {
        RELATIVE = "relative",           -- 相对位置 (默认)
        CENTER = "center",               -- 居中
        TOP_LEFT = "top_left",           -- 左上角
        TOP_RIGHT = "top_right",         -- 右上角
        TOP_CENTER = "top_center",       -- 顶部居中
        BOTTOM_LEFT = "bottom_left",     -- 左下角
        BOTTOM_RIGHT = "bottom_right",   -- 右下角
        BOTTOM_CENTER = "bottom_center", -- 底部居中
        LEFT_CENTER = "left_center",     -- 左侧居中
        RIGHT_CENTER = "right_center",   -- 右侧居中
        FILL = "fill",                   -- 填充父容器
        ABSOLUTE = "absolute"            -- 绝对定位 (相对于屏幕)
    },

    -- 支持的尺寸单位
    SIZE_UNITS = {
        PIXELS = "pixels",   -- 像素值
        PERCENT = "percent", -- 百分比
        ASPECT = "aspect"    -- 保持宽高比
    },
    ANCHOR_POINTS = {
        top_left = { x = 0, y = 0 },
        top_center = { x = 0.5, y = 0 },
        top_right = { x = 1, y = 0 },
        center_left = { x = 0, y = 0.5 },
        center = { x = 0.5, y = 0.5 },
        center_right = { x = 1, y = 0.5 },
        bottom_left = { x = 0, y = 1 },
        bottom_center = { x = 0.5, y = 1 },
        bottom_right = { x = 1, y = 1 }
    },
}
return utils
