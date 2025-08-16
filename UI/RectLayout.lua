-- RectLayout.lua
local RectLayout = {}
RectLayout.__index = RectLayout

-- 创建新的布局空间
function RectLayout.new(spaceRect, config)
    config = config or {}
    local minGridSize = config.minGridSize or 10
    local maxGridSize = config.maxGridSize or 100
    local gridDensity = config.gridDensity or 0.5

    -- 预分配对象池
    return setmetatable({
        spaceRect = spaceRect,
        shapes = {},
        grid = {},
        minGridSize = minGridSize,
        maxGridSize = maxGridSize,
        gridDensity = gridDensity,
        nextShapeId = 1,

        -- 对象池
        _bboxPool = {},       -- 边界框对象池
        _pointArrayPool = {}, -- 点数组对象池

        -- 临时表（带容量控制）
        _tempCandidateIds = setmetatable({}, {
            __index = function(t, k)
                if type(k) == "number" then
                    return rawget(t, k)
                end
                return false
            end
        }),
        _tempSortedIds = {},

        -- 内存统计
        _memoryStats = {
            totalShapes = 0,
            totalGridCells = 0,
            bboxPoolSize = 0,
            pointPoolSize = 0
        },

        -- 小网格优化配置
        _smallGridThreshold = config.smallGridThreshold or 500000, -- 总网格单元数阈值
        _adaptiveGridMode = config.adaptiveGrid or "dynamic"       -- dynamic, fixed, hybrid
    }, RectLayout)
end

-- 从对象池获取边界框
local function acquireBBox(self, xmin, ymin, xmax, ymax)
    local pool = self._bboxPool
    if #pool > 0 then
        local bbox = pool[#pool]
        pool[#pool] = nil
        bbox.xmin, bbox.ymin, bbox.xmax, bbox.ymax = xmin, ymin, xmax, ymax
        return bbox
    end
    return { xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax }
end

-- 从对象池获取点数组
local function acquirePointArray(self, ...)
    local pool = self._pointArrayPool
    if #pool > 0 then
        local points = pool[#pool]
        pool[#pool] = nil

        -- 清空并填充新数据
        local count = select("#", ...)
        for i = 1, count do
            points[i] = select(i, ...)
        end

        -- 移除多余的元素
        for i = count + 1, #points do
            points[i] = nil
        end

        return points
    end
    return { ... }
end

-- 释放对象到对象池
local function releaseToPool(pool, obj, maxSize)
    if #pool < (maxSize or 100) then
        table.insert(pool, obj)
    end
end

-- 计算图形密度并确定网格大小
local function calculateGridSize(layout, shapeBbox)
    local area = (shapeBbox.xmax - shapeBbox.xmin) * (shapeBbox.ymax - shapeBbox.ymin)
    local spaceArea = layout.spaceRect.width * layout.spaceRect.height

    if spaceArea <= 0 then return layout.minGridSize end

    local ratio = math.min(1.0, math.max(0.01, area / spaceArea))
    local gridSize = layout.minGridSize +
        (layout.maxGridSize - layout.minGridSize) *
        (1 - ratio) * layout.gridDensity

    return math.floor(gridSize)
end

-- 添加矩形图形
function RectLayout:addRectShape(rectData, x1, y1, x2, y2)
    local xmin, xmax = math.min(x1, x2), math.max(x1, x2)
    local ymin, ymax = math.min(y1, y2), math.max(y1, y2)

    -- 使用对象池获取边界框
    local bbox = acquireBBox(self, xmin, ymin, xmax, ymax)

    local shape = {
        id = self.nextShapeId,
        type = "rect",
        data = rectData,
        bbox = bbox,
        points = { xmin, ymin, xmax, ymin, xmax, ymax, xmin, ymax }
    }

    self:_addShapeToGrid(shape)
    self.shapes[shape.id] = shape
    self.nextShapeId = self.nextShapeId + 1
    self._memoryStats.totalShapes = self._memoryStats.totalShapes + 1

    return shape
end

-- 添加多边形图形
function RectLayout:addPolygonShape(polyData, ...)
    local xmin, ymin = math.huge, math.huge
    local xmax, ymax = -math.huge, -math.huge

    -- 使用对象池获取点数组
    local points = acquirePointArray(self, ...)

    -- 计算边界框
    for i = 1, #points, 2 do
        local x, y = points[i], points[i + 1]
        if x < xmin then xmin = x end
        if y < ymin then ymin = y end
        if x > xmax then xmax = x end
        if y > ymax then ymax = y end
    end

    -- 使用对象池获取边界框
    local bbox = acquireBBox(self, xmin, ymin, xmax, ymax)

    local shape = {
        id = self.nextShapeId,
        type = "polygon",
        data = polyData,
        bbox = bbox,
        points = points
    }

    self:_addShapeToGrid(shape)
    self.shapes[shape.id] = shape
    self.nextShapeId = self.nextShapeId + 1
    self._memoryStats.totalShapes = self._memoryStats.totalShapes + 1

    return shape
end

-- 小网格优化：自适应网格尺寸算法
local function adaptiveGridSize(self, gridSize, shapeBbox)
    -- 计算网格单元总数
    local gridWidth = math.floor(self.spaceRect.width / gridSize)
    local gridHeight = math.floor(self.spaceRect.height / gridSize)
    local totalCells = gridWidth * gridHeight

    -- 如果网格单元总数超过阈值，调整网格尺寸
    if totalCells > self._smallGridThreshold then
        -- 计算调整因子
        local scaleFactor = math.sqrt(totalCells / self._smallGridThreshold)
        local newGridSize = math.max(
            self.minGridSize,
            math.min(gridSize * scaleFactor, self.maxGridSize)
        )

        -- 更新内存统计
        self._memoryStats.adaptiveAdjustments = (self._memoryStats.adaptiveAdjustments or 0) + 1

        return math.floor(newGridSize)
    end

    return gridSize
end

-- 将图形添加到动态网格（优化小网格情况）
function RectLayout:_addShapeToGrid(shape)
    local gridSize = calculateGridSize(self, shape.bbox)

    -- 应用小网格优化策略
    if self._adaptiveGridMode == "dynamic" then
        gridSize = adaptiveGridSize(self, gridSize, shape.bbox)
    elseif self._adaptiveGridMode == "hybrid" then
        -- 计算网格单元总数
        local gridWidth = math.floor(self.spaceRect.width / gridSize)
        local gridHeight = math.floor(self.spaceRect.height / gridSize)
        local totalCells = gridWidth * gridHeight

        if totalCells > self._smallGridThreshold then
            -- 切换到固定网格模式
            gridSize = self.minGridSize + (self.maxGridSize - self.minGridSize) * 0.7
        end
    end

    local gx1 = math.floor((shape.bbox.xmin - self.spaceRect.x) / gridSize)
    local gy1 = math.floor((shape.bbox.ymin - self.spaceRect.y) / gridSize)
    local gx2 = math.ceil((shape.bbox.xmax - self.spaceRect.x) / gridSize)
    local gy2 = math.ceil((shape.bbox.ymax - self.spaceRect.y) / gridSize)

    -- 边界检查
    gx1 = math.max(gx1, 0)
    gy1 = math.max(gy1, 0)

    -- 计算网格边界
    local gridWidth = math.floor(self.spaceRect.width / gridSize)
    local gridHeight = math.floor(self.spaceRect.height / gridSize)
    if gridWidth <= 0 or gridHeight <= 0 then return end

    gx2 = math.min(gx2, gridWidth)
    gy2 = math.min(gy2, gridHeight)

    -- 检查该形状覆盖的网格单元数
    local shapeCells = (gx2 - gx1 + 1) * (gy2 - gy1 + 1)
    if shapeCells > 1000 then
        -- 如果形状覆盖太多单元，使用更粗粒度的网格
        gridSize = math.min(gridSize * 1.5, self.maxGridSize)

        -- 重新计算网格坐标
        gx1 = math.floor((shape.bbox.xmin - self.spaceRect.x) / gridSize)
        gy1 = math.floor((shape.bbox.ymin - self.spaceRect.y) / gridSize)
        gx2 = math.ceil((shape.bbox.xmax - self.spaceRect.x) / gridSize)
        gy2 = math.ceil((shape.bbox.ymax - self.spaceRect.y) / gridSize)

        gx1 = math.max(gx1, 0)
        gy1 = math.max(gy1, 0)
        gridWidth = math.floor(self.spaceRect.width / gridSize)
        gridHeight = math.floor(self.spaceRect.height / gridSize)
        if gridWidth <= 0 or gridHeight <= 0 then return end
        gx2 = math.min(gx2, gridWidth)
        gy2 = math.min(gy2, gridHeight)
    end

    -- 初始化网格层级
    if not self.grid[gridSize] then
        self.grid[gridSize] = {}
    end
    local gridForSize = self.grid[gridSize]

    -- 使用稀疏网格存储（仅在需要时分配单元格）
    for gy = gy1, gy2 do
        if not gridForSize[gx1] then
            gridForSize[gx1] = {}
        end

        if not gridForSize[gx1][gy] then
            gridForSize[gx1][gy] = {}
            self._memoryStats.totalGridCells = self._memoryStats.totalGridCells + 1
        end

        -- 对于小网格，使用更高效的存储方式
        if (gx2 - gx1) > 0 then
            for gx = gx1 + 1, gx2 do
                if not gridForSize[gx] then
                    gridForSize[gx] = {}
                end

                if not gridForSize[gx][gy] then
                    gridForSize[gx][gy] = gridForSize[gx1][gy] -- 共享同一单元格引用
                end
            end
        end

        -- 直接存储shape ID (整数)
        table.insert(gridForSize[gx1][gy], shape.id)
    end
end

-- 判断点是否在矩形内（精确检测）
local function pointInRect(x, y, rect)
    return x >= rect.bbox.xmin and x <= rect.bbox.xmax and
        y >= rect.bbox.ymin and y <= rect.bbox.ymax
end

-- 高效的多边形包含检测
local function pointInPolygon(x, y, poly)
    local inside = false
    local count = #poly
    if count < 6 then return false end

    local j = count - 1
    for i = 1, count, 2 do
        local xi, yi = poly[i], poly[i + 1]
        local xj, yj = poly[j], poly[j + 1]

        if ((yi > y) ~= (yj > y)) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
            inside = not inside
        end
        j = i
    end

    return inside
end

-- 获取覆盖某点的图形（按添加顺序逆序检查）
function RectLayout:getShapeDataAtPoint(x, y)
    -- 检查点是否在空间范围内
    if x < self.spaceRect.x or x > self.spaceRect.x + self.spaceRect.width or
        y < self.spaceRect.y or y > self.spaceRect.y + self.spaceRect.height then
        return nil
    end

    -- 使用临时表收集候选ID
    local candidateIds = self._tempCandidateIds
    local candidateCount = 0

    -- 清空候选ID表（保留表结构）
    for k in pairs(candidateIds) do
        candidateIds[k] = nil
    end

    -- 遍历所有存在的网格大小
    for gridSize, gridForSize in pairs(self.grid) do
        -- 计算当前网格大小下的网格坐标
        local gx = math.floor((x - self.spaceRect.x) / gridSize)
        local gy = math.floor((y - self.spaceRect.y) / gridSize)

        -- 检查网格单元是否存在
        local row = gridForSize[gx]
        if row then
            local cell = row[gy]
            if cell then
                -- 添加该单元中的所有图形ID
                for _, shapeId in ipairs(cell) do
                    if not candidateIds[shapeId] then
                        candidateIds[shapeId] = true
                        candidateCount = candidateCount + 1
                    end
                end
            end
        end
    end

    -- 如果没有候选图形，提前返回
    if candidateCount == 0 then
        return nil
    end

    -- 按ID逆序排序（后添加的图形优先）
    local sortedIds = self._tempSortedIds
    local sortedCount = #sortedIds

    -- 清空排序表
    for i = 1, sortedCount do
        sortedIds[i] = nil
    end

    -- 填充排序表
    for id in pairs(candidateIds) do
        table.insert(sortedIds, id)
    end

    -- 按ID从大到小排序（最新添加的优先）
    table.sort(sortedIds, function(a, b) return a > b end)

    -- 精确检测图形包含
    for i = 1, #sortedIds do
        local id = sortedIds[i]
        local shape = self.shapes[id]
        if shape then -- 确保图形未被删除
            local bbox = shape.bbox
            -- 边界框快速检测
            if x >= bbox.xmin and x <= bbox.xmax and
                y >= bbox.ymin and y <= bbox.ymax then
                -- 精确几何检测
                if shape.type == "rect" then
                    return shape.data
                elseif shape.type == "polygon" then
                    if pointInPolygon(x, y, shape.points) then
                        return shape.data
                    end
                end
            end
        end
    end

    return nil
end

-- 深度清理网格结构
local function deepCleanGrid(grid)
    for gridSize, gridForSize in pairs(grid) do
        for gx, gyTable in pairs(gridForSize) do
            for gy, cell in pairs(gyTable) do
                gyTable[gy] = nil -- 清除单元格
            end
            gridForSize[gx] = nil -- 清除行
        end
        grid[gridSize] = nil      -- 清除网格层级
    end
end

-- 清空所有图形
function RectLayout:clear()
    -- 回收所有边界框和点数组
    for id, shape in pairs(self.shapes) do
        if shape.bbox then
            releaseToPool(self._bboxPool, shape.bbox, 200)
        end
        if shape.type == "polygon" and shape.points then
            releaseToPool(self._pointArrayPool, shape.points, 100)
        end
        self.shapes[id] = nil
    end

    -- 深度清理网格
    deepCleanGrid(self.grid)

    -- 重置状态
    self.nextShapeId = 1
    self._memoryStats.totalShapes = 0
    self._memoryStats.totalGridCells = 0
    self._memoryStats.bboxPoolSize = #self._bboxPool
    self._memoryStats.pointPoolSize = #self._pointArrayPool

    -- 清理临时表
    for k in pairs(self._tempCandidateIds) do
        self._tempCandidateIds[k] = nil
    end
    for i = #self._tempSortedIds, 1, -1 do
        self._tempSortedIds[i] = nil
    end
end

-- 重置整个布局
function RectLayout:reset(spaceRect, config)
    -- 清除所有现有数据
    self:clear()

    -- 更新空间矩形
    if spaceRect then
        self.spaceRect = spaceRect
    end

    -- 更新配置参数
    if config then
        self.minGridSize = config.minGridSize or self.minGridSize
        self.maxGridSize = config.maxGridSize or self.maxGridSize
        self.gridDensity = config.gridDensity or self.gridDensity
        self._smallGridThreshold = config.smallGridThreshold or self._smallGridThreshold
        self._adaptiveGridMode = config.adaptiveGrid or self._adaptiveGridMode
    end
end

-- 内存优化方法（针对小网格）
function RectLayout:optimizeMemory()
    -- 压缩网格中的稀疏数组
    for gridSize, gridForSize in pairs(self.grid) do
        -- 检查网格行
        for gx, gyTable in pairs(gridForSize) do
            -- 移除空的行
            if not next(gyTable) then
                gridForSize[gx] = nil
            else
                -- 检查列
                for gy, cell in pairs(gyTable) do
                    if not next(cell) then
                        gyTable[gy] = nil
                    end
                end
            end
        end
    end

    -- 缩小对象池
    if #self._bboxPool > 200 then
        self._bboxPool = {}
    end
    if #self._pointArrayPool > 100 then
        self._pointArrayPool = {}
    end

    -- 更新内存统计
    self._memoryStats.bboxPoolSize = #self._bboxPool
    self._memoryStats.pointPoolSize = #self._pointArrayPool

    -- 建议Lua垃圾回收
    collectgarbage("step")
end

-- 获取内存统计信息
function RectLayout:getMemoryStats()
    return {
        shapes = self._memoryStats.totalShapes,
        gridCells = self._memoryStats.totalGridCells,
        bboxPool = self._memoryStats.bboxPoolSize,
        pointPool = self._memoryStats.pointPoolSize,
        luaMemory = collectgarbage("count"),
        adaptiveAdjustments = self._memoryStats.adaptiveAdjustments or 0
    }
end

-- 配置小网格优化策略
function RectLayout:setSmallGridOptimization(mode, threshold)
    self._adaptiveGridMode = mode or "dynamic"
    self._smallGridThreshold = threshold or 500000
end

-- 记录当前显示位于上层的界面布局
RectLayout.Layout = RectLayout.new(
    { x = 0, y = 0, width = love.graphics.getWidth(), height = love.graphics.getHeight() }, {
        minGridSize = 2,
        maxGridSize = 20,
        gridDensity = 0.7
    })

return RectLayout
