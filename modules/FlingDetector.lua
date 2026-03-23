-- Fling Detection Module
local FlingDetector = {}
FlingDetector.__index = FlingDetector

-- 创建新的检测器实例
function FlingDetector.new()
    local self = setmetatable({}, FlingDetector)
    
    -- 服务缓存
    self.Services = setmetatable({}, {__index = function(Self, Index)
        local NewService = game.GetService(game, Index)
        if NewService then
            Self[Index] = NewService
        end
        return NewService
    end})
    
    -- 内部变量
    self.Enabled = false
    self.Loaded = true
    self.Connections = {}
    self.PlayerStates = {}
    self.LocalPlayer = nil
    self.HeartbeatConnection = nil
    
    return self
end

-- 初始化本地玩家
function FlingDetector:InitLocalPlayer()
    self.LocalPlayer = self.Services.Players.LocalPlayer
end

-- 重置玩家角色物理属性
function FlingDetector:ResetPlayerPhysics(Character, PrimaryPart)
    for i, v in ipairs(Character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            v.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            v.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0)
        end
    end
    if PrimaryPart then
        PrimaryPart.CanCollide = false
        PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        PrimaryPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0)
    end
end

-- 处理单个玩家的检测
function FlingDetector:HandlePlayer(Player)
    if not self.Enabled or not self.Loaded then return end
    
    local playerState = {
        Detected = false,
        Character = nil,
        PrimaryPart = nil
    }
    self.PlayerStates[Player] = playerState
    
    local function CharacterAdded(NewCharacter)
        playerState.Character = NewCharacter
        repeat
            wait()
            playerState.PrimaryPart = NewCharacter:FindFirstChild("HumanoidRootPart")
        until playerState.PrimaryPart
        playerState.Detected = false
    end
    
    -- 初始角色设置
    CharacterAdded(Player.Character or Player.CharacterAdded:Wait())
    
    -- 连接角色添加事件
    local characterConnection = Player.CharacterAdded:Connect(CharacterAdded)
    table.insert(self.Connections, characterConnection)
end

-- 心跳检测函数
function FlingDetector:HeartbeatCheck()
    if not self.Enabled or not self.Loaded then return end
    
    for Player, state in pairs(self.PlayerStates) do
        if state.Character and state.Character:IsDescendantOf(workspace) and 
           state.PrimaryPart and state.PrimaryPart:IsDescendantOf(state.Character) then
            
            local angularVel = state.PrimaryPart.AssemblyAngularVelocity.Magnitude
            local linearVel = state.PrimaryPart.AssemblyLinearVelocity.Magnitude
            
            if angularVel > 50 or linearVel > 100 then
                if not state.Detected then
                    self.Services.StarterGui:SetCore("ChatMakeSystemMessage", {
                        Text = "Fling Exploit Detected Player : "..tostring(Player);
                        Color = Color3.fromRGB(255, 200, 0);
                    })
                    state.Detected = true
                end
                self:ResetPlayerPhysics(state.Character, state.PrimaryPart)
            end
        end
    end
end

-- 设置所有现有玩家
function FlingDetector:SetupExistingPlayers()
    for i, v in ipairs(self.Services.Players:GetPlayers()) do
        if v ~= self.LocalPlayer then
            self:HandlePlayer(v)
        end
    end
end

-- 启动检测系统
function FlingDetector:Start()
    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end
    
    self.Enabled = true
    self.HeartbeatConnection = self.Services.RunService.Heartbeat:Connect(function()
        self:HeartbeatCheck()
    end)
    table.insert(self.Connections, self.HeartbeatConnection)
    
    -- 连接新玩家事件
    local playerAddedConnection = self.Services.Players.PlayerAdded:Connect(function(Player)
        if self.Enabled and self.Loaded and Player ~= self.LocalPlayer then
            self:HandlePlayer(Player)
        end
    end)
    table.insert(self.Connections, playerAddedConnection)
end

-- 公开方法：启用检测
function FlingDetector:enable()
    if not self.Loaded then
        warn("FlingDetector: Cannot enable - detector is unloaded")
        return false
    end
    
    if self.Enabled then
        warn("FlingDetector: Already enabled")
        return true
    end
    
    self:Start()
    print("FlingDetector: Enabled")
    return true
end

-- 公开方法：禁用检测
function FlingDetector:disable()
    if not self.Enabled then
        warn("FlingDetector: Already disabled")
        return false
    end
    
    self.Enabled = false
    print("FlingDetector: Disabled")
    return true
end

-- 公开方法：卸载脚本
function FlingDetector:unload()
    if not self.Loaded then
        warn("FlingDetector: Already unloaded")
        return false
    end
    
    self.Enabled = false
    self.Loaded = false
    
    -- 断开所有连接
    for _, connection in ipairs(self.Connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    self.Connections = {}
    
    -- 清理玩家状态
    self.PlayerStates = {}
    
    print("FlingDetector: Unloaded")
    return true
end

-- 创建单例实例
local detector = FlingDetector.new()
detector:InitLocalPlayer()
detector:SetupExistingPlayers()

-- 返回带有控制方法的对象
return {
    enable = function()
        return detector:enable()
    end,
    disable = function()
        return detector:disable()
    end,
    unload = function()
        return detector:unload()
    end,
    -- 可选：获取当前状态的方法
    isEnabled = function()
        return detector.Enabled and detector.Loaded
    end,
    isLoaded = function()
        return detector.Loaded
    end
}