-- highlight_module_optimized.lua
-- 高性能高亮模块（异步分帧，防止重复，可调批大小）

local highlighter = {}
local RunService = game:GetService("RunService")

-- 预定义颜色方案
local colorPresets = {
    item = {
        outlineColor = Color3.fromRGB(0, 170, 255),
        fillColor = Color3.fromRGB(0, 170, 255)
    }
}

-- 存储所有活动的高亮器实例（用于全局卸载）
local activeHighlighters = {}

-- 任务ID生成器
local taskCounter = 0
local function getNewTaskId()
    taskCounter = taskCounter + 1
    return taskCounter
end

-- 创建高亮器实例
-- @param modelName     要匹配的名称
-- @param matchMode     "only" 完全匹配，否则模糊匹配
-- @param colorPresetKey 颜色预设键名（如 "item"）
-- @param batchSize     每帧处理的对象数量（默认100，可根据性能调整）
local function createHighlighterInstance(modelName, matchMode, colorPresetKey, batchSize)
    local self = {}
    
    self.modelName = modelName
    self.matchMode = matchMode
    self.batchSize = batchSize or 100   -- 默认每帧100个对象
    self.colorPreset = colorPresets[colorPresetKey] or {
        outlineColor = Color3.new(1, 1, 1),
        fillColor = Color3.new(1, 1, 1)
    }
    self.loop = false
    self.activeHandles = {}          -- 存储所有高亮实例（用于快速销毁）
    self.partToHighlight = {}        -- 部件 -> 高亮（防止重复添加）
    self.scanConnection = nil        -- 当前扫描连接的引用
    self.descendantConnection = nil   -- workspace.DescendantAdded 连接
    self.modelConns = {}              -- 模型内部的 DescendantAdded 连接
    
    -- 内部：为单个部件添加高亮（防重复）
    local function addHighlight(part)
        if not part:IsA("BasePart") then return end
        -- 检查是否已为此部件创建过高亮
        if self.partToHighlight[part] then
            return
        end
        local highlight = Instance.new("Highlight")
        highlight.FillColor = self.colorPreset.fillColor
        highlight.OutlineColor = self.colorPreset.outlineColor
        highlight.Parent = part
        table.insert(self.activeHandles, highlight)
        self.partToHighlight[part] = highlight
    end
    
    -- 内部：移除指定高亮
    local function removeHighlight(highlight)
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    
    -- 内部：异步扫描核心（分帧处理）
    local function asyncApplyCore(taskId)
        -- 断开旧扫描连接（如果有）
        if self.scanConnection then
            self.scanConnection:Disconnect()
            self.scanConnection = nil
        end
        
        local allObjects = workspace:GetDescendants()
        local total = #allObjects
        local processed = 0
        local batch = self.batchSize
        
        -- 创建新的扫描连接
        self.scanConnection = RunService.RenderStepped:Connect(function()
            -- 任务已被取消，清理自己并退出
            if taskId ~= self.currentApplyTaskId then
                if self.scanConnection then
                    self.scanConnection:Disconnect()
                    self.scanConnection = nil
                end
                return
            end
            
            local endIdx = math.min(processed + batch, total)
            for i = processed + 1, endIdx do
                local obj = allObjects[i]
                -- 名称匹配
                if obj.Name == self.modelName or (self.matchMode ~= "only" and string.find(obj.Name, self.modelName)) then
                    if obj:IsA("Model") then
                        for _, part in obj:GetDescendants() do
                            addHighlight(part)
                        end
                    elseif obj:IsA("BasePart") then
                        addHighlight(obj)
                    end
                end
            end
            processed = endIdx
            
            if processed >= total then
                -- 扫描完成，断开连接
                if self.scanConnection then
                    self.scanConnection:Disconnect()
                    self.scanConnection = nil
                end
                self.isApplyingAsync = false
            end
        end)
    end
    
    -- 公共方法：应用高亮（异步）
    self.apply = function()
        -- 如果正在应用，取消当前任务（通过更新ID）
        if self.isApplyingAsync then
            self.currentApplyTaskId = getNewTaskId()
            -- 主动断开旧扫描连接（更快取消）
            if self.scanConnection then
                self.scanConnection:Disconnect()
                self.scanConnection = nil
            end
        else
            self.currentApplyTaskId = getNewTaskId()
        end
        
        -- 清理之前的动态监听（loop相关）
        if self.descendantConnection then
            self.descendantConnection:Disconnect()
            self.descendantConnection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}
        
        self.isApplyingAsync = true
        asyncApplyCore(self.currentApplyTaskId)
        
        -- 如果启用循环，监听新加入的对象
        if self.loop then
            self.descendantConnection = workspace.DescendantAdded:Connect(function(descendant)
                -- 向上查找直到根，检查是否有符合条件的祖先
                local current = descendant
                while current do
                    if current.Name == self.modelName or (self.matchMode ~= "only" and string.find(current.Name, self.modelName)) then
                        if current:IsA("Model") then
                            -- 为模型内所有部件添加高亮
                            for _, part in current:GetDescendants() do
                                addHighlight(part)
                            end
                            -- 监听模型内部新增部件
                            local childConn = current.DescendantAdded:Connect(function(newPart)
                                addHighlight(newPart)
                            end)
                            table.insert(self.modelConns, childConn)
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
    
    -- 公共方法：销毁此高亮器创建的所有高亮
    self.destroy = function()
        -- 断开所有连接
        if self.scanConnection then
            self.scanConnection:Disconnect()
            self.scanConnection = nil
        end
        if self.descendantConnection then
            self.descendantConnection:Disconnect()
            self.descendantConnection = nil
        end
        for _, conn in pairs(self.modelConns) do
            conn:Disconnect()
        end
        self.modelConns = {}
        
        -- 销毁所有高亮
        for _, highlight in pairs(self.activeHandles) do
            removeHighlight(highlight)
        end
        self.activeHandles = {}
        self.partToHighlight = {}
        
        -- 取消异步任务
        if self.isApplyingAsync then
            self.currentApplyTaskId = getNewTaskId()
            self.isApplyingAsync = false
        end
    end
    
    -- 公共方法：卸载此实例（从全局列表移除）
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

-- 对外接口
highlighter.new = createHighlighterInstance

-- 全局卸载所有高亮器
highlighter.unload = function()
    for i = #activeHighlighters, 1, -1 do
        activeHighlighters[i]:unload()
    end
end

return highlighter