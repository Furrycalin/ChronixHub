-- highlight_module_optimized.lua
-- 一个用于根据名称高亮模型的模块 (优化版 - 异步处理)

local highlighter = {}

local RunService = game:GetService("RunService")

-- 预定义的颜色方案
local colorPresets = {
    player = {
        outlineColor = Color3.fromRGB(0, 170, 255), -- 蓝色轮廓
        fillColor = Color3.fromRGB(0, 170, 255)    -- 蓝色填充 (通常设为透明或半透)
    },
    item = {
        outlineColor = Color3.fromRGB(0, 255, 127), -- 绿色轮廓
        fillColor = Color3.fromRGB(0, 255, 127)    -- 绿色填充
    }
}

-- 存储所有已创建的高亮实例，以便于全局卸载
local activeHighlighters = {}

-- 一个简单的ID生成器，用于标记不同的任务，防止冲突
local taskCounter = 0
local function getNewTaskId()
    taskCounter = taskCounter + 1
    return taskCounter
end

-- 高亮实例的构造函数
local function createHighlighterInstance(modelName, matchMode, colorPresetKey)
    local self = {}

    -- 实例属性
    self.modelName = modelName
    self.matchMode = matchMode
    self.colorPreset = colorPresets[colorPresetKey] or {
        outlineColor = Color3.new(1, 1, 1),
        fillColor = Color3.new(1, 1, 1)
    }
    self.loop = false
    self.activeHandles = {}
    self.connection = nil
    self.modelConns = {}

    if not self.colorPreset then
        warn("警告: 未知的颜色预设 '" .. tostring(colorPresetKey) .. "', 将使用默认颜色。")
    end

    -- 用于存储正在执行的异步任务，以便在需要时取消
    self.currentApplyTaskId = nil
    self.isApplyingAsync = false

    -- 内部辅助函数：为单个Part创建Highlight
    local function addHighlight(part)
        if part:IsA("BasePart") and not part:FindFirstChild("Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = self.colorPreset.fillColor
            highlight.OutlineColor = self.colorPreset.outlineColor
            highlight.Parent = part
            table.insert(self.activeHandles, highlight)
        end
    end

    -- 内部辅助函数：移除单个Highlight
    local function removeHighlight(highlight)
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end

    -- 内部辅助函数：异步应用高亮的核心逻辑
    local function asyncApplyCore(taskId)
        -- 如果任务ID不同，说明有新的任务被启动，当前任务应被废弃
        if taskId ~= self.currentApplyTaskId then
            return
        end

        local allObjects = workspace:GetDescendants()
        local totalObjects = #allObjects
        local processedCount = 0
        local batchSize = 10 -- 每帧处理的对象数量，可根据性能调整

        -- 使用RunService的RenderStepped信号来分帧处理
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if taskId ~= self.currentApplyTaskId then
                connection:Disconnect()
                return
            end

            local endIdx = math.min(processedCount + batchSize, totalObjects)
            for i = processedCount + 1, endIdx do
                local obj = allObjects[i]
                if obj.Name == self.modelName or (self.matchMode ~= "only" and string.find(obj.Name, self.modelName)) then
                    if obj:IsA("Model") then
                        for _, part in obj:GetDescendants() do
                            if part:IsA("BasePart") then
                                addHighlight(part)
                            end
                        end
                    elseif obj:IsA("BasePart") then
                        addHighlight(obj)
                    end
                end
            end
            processedCount = endIdx

            -- 如果处理完了，断开连接
            if processedCount >= totalObjects then
                connection:Disconnect()
                self.isApplyingAsync = false
                print(string.format("异步高亮应用完成。模型名: %s, 处理对象数: %d", self.modelName, totalObjects))
            end
        end)
    end


    -- 公共方法: 应用高亮 (异步版本)
    self.apply = function()
        -- 如果当前正在应用一个任务，先取消它
        if self.isApplyingAsync then
            self.currentApplyTaskId = getNewTaskId() -- 更新ID使旧任务失效
        end

        -- 清理之前可能存在的连接
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}

        -- 开始新的异步任务
        self.currentApplyTaskId = getNewTaskId()
        self.isApplyingAsync = true
        asyncApplyCore(self.currentApplyTaskId)

        -- 如果启用了循环检查，则监听新添加的对象
        if self.loop then
            self.connection = workspace.DescendantAdded:Connect(function(descendant)
                local current = descendant
                while current do
                    if current.Name == self.modelName or (self.matchMode ~= "only" and string.find(current.Name, self.modelName)) then
                        if current:IsA("Model") then
                            for _, part in current:GetDescendants() do
                                if part:IsA("BasePart") then
                                    addHighlight(part)
                                end
                            end
                            local modelChildAddedConn = current.DescendantAdded:Connect(function(newPart)
                                if newPart:IsA("BasePart") then
                                    addHighlight(newPart)
                                end
                            end)
                            table.insert(self.modelConns, modelChildAddedConn)
                        elseif current:IsA("BasePart") then
                            addHighlight(current)
                        end
                        break
                    end
                    current = current.Parent
                end
            end)
        end
    end

    -- 公共方法: 销毁此实例创建的所有高亮
    self.destroy = function()
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}
        
        -- 立即销毁所有已知的高亮句柄
        for _, handle in pairs(self.activeHandles) do
            removeHighlight(handle)
        end
        self.activeHandles = {}
        
        -- 如果正在执行异步任务，也取消它
        if self.isApplyingAsync then
             self.currentApplyTaskId = getNewTaskId() -- 使当前任务失效
             self.isApplyingAsync = false
        end
    end

    -- 公共方法: 卸载此实例
    self.unload = function()
        self.destroy()
        for i, v in ipairs(activeHighlighters) do
            if v == self then
                table.remove(activeHighlighters, i)
                break
            end
        end
    end

    table.insert(activeHighlighters, self)
    return self
end

highlighter.qwe = createHighlighterInstance
highlighter.unload = function()
    for i = #activeHighlighters, 1, -1 do
        local h = activeHighlighters[i]
        h.unload()
    end
end

return highlighter