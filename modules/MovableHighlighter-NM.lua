-- ================================================
-- 文件名：MovableHighlighter.lua
-- 放置位置：ReplicatedStorage（客户端 require 使用）
-- ================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local MovableHighlighter = {}

-- 默认配置
local DEFAULT_CONFIG = {
    fillColor = Color3.fromRGB(255, 215, 0),
    outlineColor = Color3.fromRGB(255, 0, 0),
    fillTransparency = 0.7,
    outlineTransparency = 0.0,
    maxHeight = 100,
    excludedNames = {"Camera", "Terrain"},
    batchSize = 80,
}

-- 实例表
local instances = {}

-- -------------------------------------------------
-- 实例元表
-- -------------------------------------------------
local Highlighter = {}
Highlighter.__index = Highlighter

-- 创建新实例
function MovableHighlighter.new(config)
    local self = setmetatable({}, Highlighter)
    self.config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        self.config[k] = (config and config[k] ~= nil) and config[k] or v
    end
    self.enabled = false
    self.activeHighlights = {}          -- { [BasePart] = Highlight }
    self.partConnections = {}           -- { [BasePart] = RBXScriptConnection }
    self.scanConnection = nil
    self.descendantConnection = nil
    self.pendingTask = nil
    table.insert(instances, self)
    return self
end

-- -------------------------------------------------
-- 判断部件是否属于玩家角色（向上查找根模型）
-- -------------------------------------------------
local function isPartOfPlayer(part)
    local model = part
    while model and not model:IsA("Model") do
        model = model.Parent
    end
    return model and Players:GetPlayerFromCharacter(model) ~= nil
end

-- -------------------------------------------------
-- 判断部件是否合法（可高亮）
-- -------------------------------------------------
local function isValidPart(self, part)
    if not part:IsA("BasePart") then return false end
    if part.Anchored then return false end
    if isPartOfPlayer(part) then return false end            -- 排除玩家及其物品
    if table.find(self.config.excludedNames, part.Name) then return false end
    if part.Position.Y >= self.config.maxHeight then return false end
    return true
end

-- -------------------------------------------------
-- 为部件添加高亮（防重复，并监听父级变化）
-- -------------------------------------------------
local function addHighlightToPart(self, part)
    if self.activeHighlights[part] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MovableObjectHighlight"
    highlight.FillColor = self.config.fillColor
    highlight.OutlineColor = self.config.outlineColor
    highlight.FillTransparency = self.config.fillTransparency
    highlight.OutlineTransparency = self.config.outlineTransparency
    highlight.Adornee = part
    highlight.Parent = part
    self.activeHighlights[part] = highlight

    -- 监听父级变化：当部件变成玩家角色的一部分时，自动移除高亮
    local conn = part.AncestryChanged:Connect(function()
        if not self.enabled then return end
        if not isValidPart(self, part) then
            -- 移除高亮
            if self.activeHighlights[part] then
                self.activeHighlights[part]:Destroy()
                self.activeHighlights[part] = nil
            end
            if self.partConnections[part] then
                self.partConnections[part]:Disconnect()
                self.partConnections[part] = nil
            end
        end
    end)
    self.partConnections[part] = conn
end

-- -------------------------------------------------
-- 移除所有高亮和连接
-- -------------------------------------------------
local function removeAllHighlights(self)
    for part, highlight in pairs(self.activeHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
        if self.partConnections[part] then
            self.partConnections[part]:Disconnect()
            self.partConnections[part] = nil
        end
    end
    self.activeHighlights = {}
    self.partConnections = {}
end

-- -------------------------------------------------
-- 分帧扫描现有物体
-- -------------------------------------------------
local function scanExistingAsync(self)
    if self.scanConnection then
        self.scanConnection:Disconnect()
        self.scanConnection = nil
    end

    -- 收集需要检查的对象
    local allObjects = Workspace:GetDescendants()
    local relevant = {}
    for _, obj in ipairs(allObjects) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            table.insert(relevant, obj)
        end
    end

    local total = #relevant
    local processed = 0
    local batchSize = self.config.batchSize
    local taskId = {}
    self.pendingTask = taskId

    self.scanConnection = RunService.RenderStepped:Connect(function()
        if not self.enabled or taskId ~= self.pendingTask then
            if self.scanConnection then
                self.scanConnection:Disconnect()
                self.scanConnection = nil
            end
            return
        end
        local endIdx = math.min(processed + batchSize, total)
        for i = processed + 1, endIdx do
            local obj = relevant[i]
            if obj:IsA("BasePart") and isValidPart(self, obj) then
                addHighlightToPart(self, obj)
            elseif obj:IsA("Model") then
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") and isValidPart(self, part) then
                        addHighlightToPart(self, part)
                    end
                end
            end
        end
        processed = endIdx
        if processed >= total then
            if self.scanConnection then
                self.scanConnection:Disconnect()
                self.scanConnection = nil
            end
            self.pendingTask = nil
        end
    end)
end

-- -------------------------------------------------
-- 监听新物体
-- -------------------------------------------------
local function startListeners(self)
    if self.descendantConnection then
        self.descendantConnection:Disconnect()
        self.descendantConnection = nil
    end
    self.descendantConnection = Workspace.DescendantAdded:Connect(function(desc)
        if not self.enabled then return end
        if desc:IsA("BasePart") and isValidPart(self, desc) then
            addHighlightToPart(self, desc)
        elseif desc:IsA("Model") then
            for _, part in ipairs(desc:GetDescendants()) do
                if part:IsA("BasePart") and isValidPart(self, part) then
                    addHighlightToPart(self, part)
                end
            end
        end
    end)
end

-- -------------------------------------------------
-- 停止所有监听
-- -------------------------------------------------
local function stopAll(self)
    if self.scanConnection then
        self.scanConnection:Disconnect()
        self.scanConnection = nil
    end
    if self.descendantConnection then
        self.descendantConnection:Disconnect()
        self.descendantConnection = nil
    end
    self.pendingTask = nil
end

-- -------------------------------------------------
-- 公共方法
-- -------------------------------------------------
function Highlighter:enable()
    if self.enabled then return end
    self.enabled = true
    task.defer(function()
        if not self.enabled then return end
        scanExistingAsync(self)
        startListeners(self)
    end)
end

function Highlighter:disable()
    if not self.enabled then return end
    self.enabled = false
    stopAll(self)
    removeAllHighlights(self)
end

function Highlighter:unload()
    self:disable()
    for i, inst in ipairs(instances) do
        if inst == self then
            table.remove(instances, i)
            break
        end
    end
    setmetatable(self, nil)
end

function MovableHighlighter.unloadAll()
    for i = #instances, 1, -1 do
        instances[i]:unload()
    end
end

return MovableHighlighter