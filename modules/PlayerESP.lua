-- EspSimple 模块
local EspSimple = {}

-- 私有状态
local enabled = false
local highlights = {}      -- 玩家 -> Highlight
local labels = {}          -- 玩家 -> BillboardGui
local connections = {}     -- 玩家 -> {CharacterAdded连接, CharacterRemoving连接}
local playerAddedConn = nil
local playerRemovingConn = nil
-- 在 DEFAULT_CONFIG 上方添加
local FRIEND_COLOR = Color3.new(0, 1, 0)  -- 绿色
local NON_FRIEND_COLOR = Color3.new(1, 0, 0) -- 红色

-- 本地玩家
local localPlayer = game.Players.LocalPlayer

-- 默认配置（不可修改）
local DEFAULT_CONFIG = {
    fillColor = Color3.new(1, 0, 0),
    fillTransparency = 0.8,
    outlineColor = Color3.new(1, 0, 0),
    outlineTransparency = 0,
    onlyOutline = false,
    labelOffset = Vector3.new(0, 3, 0),
    labelSize = UDim2.new(0, 200, 0, 50),
    textSize = 18,
    textColor = Color3.new(1, 1, 1),
}

-- 添加高亮
local function addHighlight(player, character)
    if player == localPlayer or not character then return end
    
    -- 【新增】判断是否为好友
    local isFriend = player:IsFriendsWith(localPlayer.UserId)
    local fillColor = isFriend and FRIEND_COLOR or NON_FRIEND_COLOR
    local outlineColor = fillColor -- 让轮廓颜色与填充色相同，你也可以单独设置

    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = fillColor          -- 使用动态颜色
    highlight.FillTransparency = DEFAULT_CONFIG.fillTransparency
    highlight.OutlineColor = outlineColor    -- 使用动态轮廓色
    highlight.OutlineTransparency = DEFAULT_CONFIG.outlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    if DEFAULT_CONFIG.onlyOutline then
        highlight.FillTransparency = 1
    end
    highlights[player] = highlight
end

-- 添加名字标签
local function addLabel(player, character)
    if player == localPlayer or not character then return end
    local head = character:WaitForChild("Head", 5)
    if not head then return end

    -- 【新增】判断是否为好友
    local isFriend = player:IsFriendsWith(localPlayer.UserId)
    local prefix = isFriend and "⭐ " or ""  -- 好友名字前加星标

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = DEFAULT_CONFIG.labelSize
    billboard.StudsOffset = DEFAULT_CONFIG.labelOffset
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    if player.DisplayName == player.Name then
        label.Text = prefix .. player.DisplayName  -- 应用前缀
    else
        label.Text = prefix .. player.DisplayName .. " (@" .. player.Name .. ")"
    end
    label.TextColor3 = DEFAULT_CONFIG.textColor
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = DEFAULT_CONFIG.textSize
    label.Parent = billboard

    labels[player] = billboard
end

-- 移除单个玩家的所有效果
local function removePlayerEffects(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
    local l = labels[player]
    if l then
        l:Destroy()
        labels[player] = nil
    end
end

-- 为单个玩家设置监听（角色变化）
local function setupPlayer(player)
    if not enabled then return end
    if player == localPlayer then return end

    -- 如果已有连接，先清理
    if connections[player] then
        for _, conn in ipairs(connections[player]) do
            conn:Disconnect()
        end
        connections[player] = nil
        removePlayerEffects(player)
    end

    -- 如果当前有角色，立即添加效果
    local character = player.Character
    if character then
        addHighlight(player, character)
        addLabel(player, character)
    end

    -- 角色添加时
    local charAdded = player.CharacterAdded:Connect(function(newChar)
        removePlayerEffects(player)   -- 移除旧效果
        addHighlight(player, newChar)
        addLabel(player, newChar)
    end)

    -- 角色移除时（可选，但有助于及时清理）
    local charRemoving = player.CharacterRemoving:Connect(function()
        removePlayerEffects(player)
    end)

    connections[player] = {charAdded, charRemoving}
end

-- 清理所有玩家效果并断开所有连接
local function clearAll()
    for player, conns in pairs(connections) do
        for _, conn in ipairs(conns) do
            conn:Disconnect()
        end
        removePlayerEffects(player)
    end
    connections = {}
    highlights = {}
    labels = {}
end

-- 全局监听玩家加入/离开
local function startGlobalListeners()
    if playerAddedConn then return end
    playerAddedConn = game.Players.PlayerAdded:Connect(setupPlayer)
    playerRemovingConn = game.Players.PlayerRemoving:Connect(removePlayerEffects)
end

local function stopGlobalListeners()
    if playerAddedConn then
        playerAddedConn:Disconnect()
        playerAddedConn = nil
    end
    if playerRemovingConn then
        playerRemovingConn:Disconnect()
        playerRemovingConn = nil
    end
end

-- 公开函数：开启ESP
function EspSimple.enable()
    if enabled then return end
    enabled = true
    startGlobalListeners()
    -- 为所有现有玩家（除了自己）添加效果
    for _, player in ipairs(game.Players:GetPlayers()) do
        setupPlayer(player)
    end
end

-- 公开函数：关闭ESP（清除所有效果，但仍保持监听，下次开启时自动恢复）
function EspSimple.disable()
    if not enabled then return end
    enabled = false
    clearAll()
    -- 注意：全局监听仍保留，但setupPlayer内部会检查enabled，所以不会添加效果
    -- 但为了彻底，也可以停止监听，不过enable时还要重新建立。我们选择保留监听，因为监听代价很小
    -- 但disable后玩家加入不会有任何效果，直到再次enable
end

-- 公开函数：完全卸载（彻底销毁，不能再被启用）
function EspSimple.unload()
    enabled = false
    clearAll()
    stopGlobalListeners()
    -- 清空所有表，防止再次调用
    highlights = nil
    labels = nil
    connections = nil
    -- 将公开函数置空，防止误调用
    EspSimple.enable = nil
    EspSimple.disable = nil
    EspSimple.unload = nil
end

return EspSimple