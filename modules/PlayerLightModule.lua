-- LocalPlayerLightAttachmentModule.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayerLightModule = {}
LocalPlayerLightModule.__index = LocalPlayerLightModule
LocalPlayerLightModule._instances = {}

local DEFAULT_CONFIG = {
    Brightness = 2,
    Range = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Shadows = false,
    Attachment_Name = "PlayerLightAttachment",
    Offset_Position = Vector3.new(0, 1.5, 0),
    Offset_Rotation = Vector3.new(0, 0, 0),
    AttachToBodyPart = "UpperTorso",
}

function LocalPlayerLightModule.new(customConfig)
    local config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        config[k] = v
    end
    if type(customConfig) == "table" then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    config.Enabled = false

    local self = setmetatable({}, LocalPlayerLightModule)
    self.config = config
    self.PlayerLightData = nil
    self._characterAddedConn = nil
    self.localPlayer = Players.LocalPlayer

    if self.localPlayer then
        self:_init()
    else
        Players.LocalPlayerAdded:Connect(function(player)
            self.localPlayer = player
            self:_init()
        end)
    end

    table.insert(LocalPlayerLightModule._instances, self)
    return self
end

function LocalPlayerLightModule:_init()
    self:_waitForCharacterAndAttachLight()

    -- 【修改1】给连接赋值前先检查，避免空值
    if self.localPlayer then
        self._characterAddedConn = self.localPlayer.CharacterAdded:Connect(function()
            task.wait()
            self:_waitForCharacterAndAttachLight()
        end)
    end
end

function LocalPlayerLightModule:_waitForCharacterAndAttachLight()
    -- 【修改2】加超时保护，避免无限等待导致PlayerLightData始终为nil
    local character = self.localPlayer and self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10) -- 超时10秒
    if not humanoidRootPart then
        warn("LocalPlayerLightModule: 超时未找到HumanoidRootPart，跳过光源创建")
        return
    end

    self:_cleanupOldLight()

    local bodyPart = character:FindFirstChild(self.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn(`LocalPlayerLightModule: 无法找到身体部位 {self.config.AttachToBodyPart}`)
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = self.config.Attachment_Name
    attachment.CFrame = CFrame.new(self.config.Offset_Position) 
        * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
    attachment.Parent = bodyPart

    local pointLight = Instance.new("PointLight")
    pointLight.Enabled = self.config.Enabled
    pointLight.Brightness = self.config.Brightness
    pointLight.Range = self.config.Range
    pointLight.Color = self.config.Color
    pointLight.Shadows = self.config.Shadows
    pointLight.Parent = attachment

    self.PlayerLightData = {
        Attachment = attachment,
        PointLight = pointLight,
    }

    print(`LocalPlayerLightModule: 已为本地玩家创建光源实例（{self.config.Attachment_Name}）`)
end

-- 【修改3】极致防呆的_cleanupOldLight（所有索引都加检查）
function LocalPlayerLightModule:_cleanupOldLight()
    -- 第一层：检查PlayerLightData是否存在（核心防呆）
    if not self.PlayerLightData then
        return -- 直接退出，无任何操作
    end

    -- 第二层：检查PointLight是否存在，且是有效实例
    if type(self.PlayerLightData.PointLight) == "userdata" and self.PlayerLightData.PointLight:IsA("PointLight") then
        pcall(function()
            self.PlayerLightData.PointLight:Destroy()
        end)
    end
    self.PlayerLightData.PointLight = nil -- 强制置空，避免残留引用

    -- 第二层：检查Attachment是否存在，且是有效实例
    if type(self.PlayerLightData.Attachment) == "userdata" and self.PlayerLightData.Attachment:IsA("Attachment") then
        pcall(function()
            self.PlayerLightData.Attachment:Destroy()
        end)
    end
    self.PlayerLightData.Attachment = nil -- 强制置空

    -- 清空整个PlayerLightData
    self.PlayerLightData = nil
end

function LocalPlayerLightModule:enable()
    if self.PlayerLightData and type(self.PlayerLightData.PointLight) == "userdata" and self.PlayerLightData.PointLight:IsA("PointLight") then
        self.PlayerLightData.PointLight.Enabled = true
        print(`LocalPlayerLightModule: 光源 {self.config.Attachment_Name} 已启用`)
    else
        warn("LocalPlayerLightModule: 光源尚未创建/已被销毁，无法启用")
    end
end

function LocalPlayerLightModule:disable()
    if self.PlayerLightData and type(self.PlayerLightData.PointLight) == "userdata" and self.PlayerLightData.PointLight:IsA("PointLight") then
        self.PlayerLightData.PointLight.Enabled = false
        print(`LocalPlayerLightModule: 光源 {self.config.Attachment_Name} 已禁用`)
    else
        warn("LocalPlayerLightModule: 光源尚未创建/已被销毁，无法禁用")
    end
end

-- 【修改4】极致防呆的unload方法（所有操作都加nil检查）
function LocalPlayerLightModule:unload()
    -- 1. 清理光源（即使PlayerLightData是nil，_cleanupOldLight也会直接退出）
    self:_cleanupOldLight()

    -- 2. 断开连接（先检查连接是否存在，且是有效连接）
    if type(self._characterAddedConn) == "userdata" and self._characterAddedConn.Connected then
        pcall(function()
            self._characterAddedConn:Disconnect()
        end)
    end
    self._characterAddedConn = nil -- 强制置空

    -- 3. 从全局列表移除（加检查，避免索引空列表）
    if LocalPlayerLightModule._instances and #LocalPlayerLightModule._instances > 0 then
        for i = #LocalPlayerLightModule._instances, 1, -1 do -- 倒序遍历，避免索引错乱
            local instance = LocalPlayerLightModule._instances[i]
            if instance == self then
                table.remove(LocalPlayerLightModule._instances, i)
                break
            end
        end
    end

    print(`LocalPlayerLightModule: 光源实例 {self.config.Attachment_Name} 已卸载（无空值错误）`)
end

function LocalPlayerLightModule.unloadAll()
    if LocalPlayerLightModule._instances and #LocalPlayerLightModule._instances > 0 then
        for _, instance in ipairs(LocalPlayerLightModule._instances) do
            if instance and type(instance.unload) == "function" then
                instance:unload()
            end
        end
    end
    LocalPlayerLightModule._instances = {}
    print("LocalPlayerLightModule: 所有光源实例已全部卸载")
end

return LocalPlayerLightModule