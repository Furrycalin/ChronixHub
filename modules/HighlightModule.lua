-- highlight_module.lua
-- 一个用于根据名称高亮模型的模块

local highlighter = {}

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

-- 高亮实例的构造函数
local function createHighlighterInstance(modelName, matchMode, colorPresetKey)
    local self = {}
    self.modelName = modelName
    self.matchMode = matchMode
    self.colorPreset = colorPresets[colorPresetKey]
    self.loop = false -- 默认不循环检查
    self.activeHandles = {} -- 存储当前激活的Highlight对象
    self.connection = nil -- 存储Workspace.DescendantAdded的连接

    if not self.colorPreset then
        warn("警告: 未知的颜色预设 '" .. tostring(colorPresetKey) .. "', 将使用默认颜色。")
        self.colorPreset = {outlineColor = Color3.new(1, 1, 1), fillColor = Color3.new(1, 1, 1)}
    end

    -- 内部辅助函数：为单个Part创建Highlight
    local function addHighlight(part)
        if part:IsA("BasePart") and not part:FindFirstChild("Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = self.colorPreset.fillColor
            highlight.OutlineColor = self.colorPreset.outlineColor
            -- 可以在这里根据需要调整OutlineTransparency和FillTransparency
            -- highlight.OutlineTransparency = 0.2
            -- highlight.FillTransparency = 0.8
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

    -- 公共方法: 应用高亮
    self.apply = function()
        -- 清理之前可能存在的连接
        if self.connection then
            self.connection:Disconnect()
        end

        -- 遍历当前Workspace中已存在的模型
        for _, obj in workspace:GetDescendants() do
            if obj.Name == self.modelName or (self.matchMode ~= "only" and string.find(obj.Name, self.modelName)) then
                if obj:IsA("Model") then
                    -- 如果是Model，遍历其内部的所有Part
                    for _, part in obj:GetDescendants() do
                        addHighlight(part)
                    end
                elseif obj:IsA("BasePart") then
                    -- 如果本身就是Part，则直接高亮
                    addHighlight(obj)
                end
            end
        end

        -- 如果启用了循环检查，则监听新添加的对象
        if self.loop then
            self.connection = workspace.DescendantAdded:Connect(function(descendant)
                -- 检查新增的descendant本身及其父级链
                local current = descendant
                while current do
                    if current.Name == self.modelName or (self.matchMode ~= "only" and string.find(current.Name, self.modelName)) then
                        if current:IsA("Model") then
                            -- 对于新增的Model，监听其内部Parts的变化
                            for _, part in current:GetDescendants() do
                                if part:IsA("BasePart") then
                                    addHighlight(part)
                                end
                            end
                            -- 还需要监听此Model未来可能新增的子部件
                            local modelChildAddedConn = current.DescendantAdded:Connect(function(newPart)
                                if newPart:IsA("BasePart") then
                                    addHighlight(newPart)
                                end
                            end)
                            -- 在实例销毁时，也要断开这个监听器
                            self.modelConns = self.modelConns or {}
                            table.insert(self.modelConns, modelChildAddedConn)
                        elseif current:IsA("BasePart") then
                            addHighlight(current)
                        end
                        break -- 找到匹配项后，无需继续向上查找
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
        if self.modelConns then
            for _, conn in pairs(self.modelConns) do
                conn:Disconnect()
            end
            self.modelConns = nil
        end
        for _, handle in pairs(self.activeHandles) do
            removeHighlight(handle)
        end
        self.activeHandles = {}
    end

    -- 公共方法: 卸载此实例（包括销毁高亮和从活动列表中移除）
    self.unload = function()
        self.destroy()
        -- 从全局活动列表中移除此实例
        for i, v in ipairs(activeHighlighters) do
            if v == self then
                table.remove(activeHighlighters, i)
                break
            end
        end
    end

    -- 创建实例后，将其添加到活动列表中
    table.insert(activeHighlighters, self)

    return self
end

-- 主函数 new，用于创建高亮实例
highlighter.new = function(modelName, matchMode, colorPresetKey)
    return createHighlighterInstance(modelName, matchMode, colorPresetKey)
end

-- 全局卸载方法，用于卸载整个脚本的所有功能
highlighter.unload = function()
    for i = #activeHighlighters, 1, -1 do
        local h = activeHighlighters[i]
        h.unload() -- 调用每个实例的unload方法
        -- h.destroy() -- 或者只调用destroy也可以，但unload更彻底
    end
    -- activeHighlighters表现在应该为空
end

return highlighter