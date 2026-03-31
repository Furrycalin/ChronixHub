-- ChatSpy 模块
local ChatSpy = {}

-- 私有状态
local enabled = false
local connections = {}  -- 存储所有事件连接
local spyOnSelf = false  -- 是否偷听自己的消息
local publicMode = false -- 是否公开广播（转发到全局聊天）
local ignoreList = {     -- 忽略列表
    {Message = ":part/1/1/1", ExactMatch = true},
    {Message = ":part/10/10/10", ExactMatch = true},
    {Message = "A?????????", ExactMatch = false},
    {Message = ":colorshifttop 10000 0 0", ExactMatch = true},
    {Message = ":colorshiftbottom 10000 0 0", ExactMatch = true},
    {Message = ":colorshifttop 0 10000 0", ExactMatch = true},
    {Message = ":colorshiftbottom 0 10000 0", ExactMatch = true},
    {Message = ":colorshifttop 0 0 10000", ExactMatch = true},
    {Message = ":colorshiftbottom 0 0 10000", ExactMatch = true},
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- 判断是否为旧版聊天系统
local isLegacyChat = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

-- 加载系统通知模块
local SystemNotification = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/SystemNotification.lua"))()

-- 等待聊天系统加载
local DefaultChatSystemChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
local SayMessageRequest = DefaultChatSystemChatEvents:WaitForChild("SayMessageRequest")
local OnMessageDoneFiltering = DefaultChatSystemChatEvents:WaitForChild("OnMessageDoneFiltering")

-- 辅助函数：检查消息是否应被忽略
local function isIgnored(message)
    for _, v in ipairs(ignoreList) do
        if v.ExactMatch and message == v.Message then
            return true
        elseif not v.ExactMatch and message:find(v.Message) then
            return true
        end
    end
    return false
end

-- 辅助函数：发送偷听消息到聊天框（使用 SystemNotification）
local function sendSpyMessage(text)
    local messageText = "[SPY] - " .. text
    if publicMode then
        -- 公开模式：广播到全局聊天
        SayMessageRequest:FireServer(messageText, "All")
    else
        -- 私有模式：仅自己可见的系统消息
        if isLegacyChat then
            -- 旧版聊天系统
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = messageText,
                Color = Color3.fromRGB(255, 0, 0)
            })
        else
            -- 新版聊天系统：使用自定义方法发送红色消息
            SystemNotification.Custom(messageText, Color3.fromRGB(255, 0, 0), "SourceSans", 14)
        end
    end
end

-- 处理单条聊天消息
local function onChatted(player, message)
    -- 检查是否开启、是否应该偷听自己
    if not enabled then return end
    if not spyOnSelf and player == LocalPlayer then return end
    
    -- 清理消息格式
    local cleanedMessage = message:gsub("[\n\r]", ""):gsub("\t", " "):gsub("[ ]+", " ")
    
    -- 尝试判断消息是否为隐藏消息（已被过滤）
    local isHidden = true
    local connection = OnMessageDoneFiltering.OnClientEvent:Connect(function(packet, channel)
        if packet.SpeakerUserId == player.UserId and 
           cleanedMessage:sub(#cleanedMessage - #packet.Message + 1) == packet.Message and
           (channel == "All" or (channel == "Team" and not publicMode and Players[packet.FromSpeaker] and Players[packet.FromSpeaker].Team == LocalPlayer.Team)) then
            isHidden = false
        end
    end)
    
    wait(1)
    connection:Disconnect()
    
    -- 输出偷听的消息
    if isHidden and enabled and not isIgnored(cleanedMessage) then
        if #cleanedMessage > 1200 then
            cleanedMessage = cleanedMessage:sub(1, 1200) .. "..."
        end
        local outputText = "[" .. player.Name .. "]: " .. cleanedMessage
        sendSpyMessage(outputText)
    end
end

-- 辅助函数：发送状态消息（使用 SystemNotification）
local function sendStatusMessage(text, isError)
    local color = isError and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    if isLegacyChat then
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[SPY] - " .. text,
            Color = color
        })
    else
        if isError then
            SystemNotification.Error("[SPY] - " .. text)
        else
            SystemNotification.Success("[SPY] - " .. text)
        end
    end
end

-- 为单个玩家设置监听
local function setupPlayer(player)
    local conn = player.Chatted:Connect(function(message)
        onChatted(player, message)
    end)
    if not connections[player] then
        connections[player] = {}
    end
    table.insert(connections[player], conn)
end

-- 清理所有连接
local function clearAllConnections()
    for player, connList in pairs(connections) do
        for _, conn in ipairs(connList) do
            conn:Disconnect()
        end
    end
    connections = {}
end

-- 公开函数：开启 ChatSpy
function ChatSpy.enable()
    if enabled then return end
    enabled = true
    
    -- 为所有现有玩家设置监听
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
    
    -- 监听新加入的玩家
    local playerAddedConn = Players.PlayerAdded:Connect(setupPlayer)
    connections["_playerAdded"] = {playerAddedConn}
    
    sendStatusMessage("Enabled", false)
    
    -- 显示聊天框（如有必要，针对旧版聊天系统）
    if isLegacyChat then
        local success, chatFrame = pcall(function()
            return LocalPlayer.PlayerGui.Chat.Frame
        end)
        if success and chatFrame then
            chatFrame.ChatChannelParentFrame.Visible = true
            chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position + UDim2.new(UDim.new(), chatFrame.ChatChannelParentFrame.Size.Y)
        end
    end
end

-- 公开函数：关闭 ChatSpy（停止偷听，但不清除监听）
function ChatSpy.disable()
    if not enabled then return end
    enabled = false
    sendStatusMessage("Disabled", true)
end

-- 公开函数：完全卸载
function ChatSpy.unload()
    enabled = false
    clearAllConnections()
    
    -- 发送卸载通知
    if isLegacyChat then
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[SPY] - Unloaded",
            Color = Color3.fromRGB(255, 0, 0)
        })
    else
        SystemNotification.UnloadedGradient("[SPY] - Unloaded")
    end
    
    -- 清空模块方法
    ChatSpy.enable = nil
    ChatSpy.disable = nil
    ChatSpy.unload = nil
end

-- 可选：配置方法（供用户在加载后修改设置）
function ChatSpy.setSpyOnSelf(value)
    spyOnSelf = value
end

function ChatSpy.setPublicMode(value)
    publicMode = value
end

return ChatSpy