-- LocalPlayerLightAttachmentModule.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayerLightModule = {}
LocalPlayerLightModule.__index = LocalPlayerLightModule
LocalPlayerLightModule._instances = {}
-- 新增：标记模块是否已卸载（脚本销毁时置为true）
LocalPlayerLightModule._isUnloaded = false

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
    -- 防护：模块已卸载时，直接返回nil，避免创建新实例
    if LocalPlayerLightModule._isUnloaded then
        warn("LocalPlayerLightModule: 模块已卸载，无法创建新实例")
        return nil
    end

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
    -- 新增：标记实例是否已卸载（避免重复卸载）
    self._isInstanceUnloaded = false
    self.config = config
    self.PlayerLightData = nil
    self._characterAddedConn = nil
    self.localPlayer = Players.LocalPlayer

    if self.localPlayer and not LocalPlayerLightModule._isUnloaded then
        self:_init()
    else
        -- 防护：模块已卸载时，直接清理
        if LocalPlayerLightModule._isUnloaded then
            self:unload()
            return nil
        end
        Players.LocalPlayerAdded:Connect(function(player)
            -- 防护：回调执行时检查模块/实例状态
            if LocalPlayerLightModule._isUnloaded or self._isInstanceUnloaded then
                return
            end
            self.localPlayer = player
            self:_init()
        end)
    end

    table.insert(LocalPlayerLightModule._instances, self)
    return self
end

-- 新增：通用防护函数（检查self和模块是否有效）
local function isSelfValid(self)
    return not (
        LocalPlayerLightModule._isUnloaded 
        or self._isInstanceUnloaded 
        or type(self) ~= "table"
    )
end

function LocalPlayerLightModule:_init()
    -- 前置防护：self无效时直接退出
    if not isSelfValid(self) then
        return
    end
    self:_waitForCharacterAndAttachLight()

    if self.localPlayer and not LocalPlayerLightModule._isUnloaded then
        self._characterAddedConn = self.localPlayer.CharacterAdded:Connect(function()
            -- 防护：回调执行时检查状态
            if not isSelfValid(self) then
                return
            end
            task.wait()
            self:_waitForCharacterAndAttachLight()
        end)
    end
end

function LocalPlayerLightModule:_waitForCharacterAndAttachLight()
    -- 前置防护：self无效时直接退出（核心！解决154行报错）
    if not isSelfValid(self) then
        return
    end

    local character = self.localPlayer and self.localPlayer.Character or self.localPlayer.CharacterAdded:Wait()
    -- 防护：character为空或模块已卸载时退出
    if not character or LocalPlayerLightModule._isUnloaded then
        return
    end

    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoidRootPart then
        warn("LocalPlayerLightModule: 超时未找到HumanoidRootPart，跳过光源创建")
        return
    end

    -- 调用前再次检查self有效性（避免脚本卸载时执行到这里）
    if isSelfValid(self) then
        self:_cleanupOldLight()
    end

    local bodyPart = character:FindFirstChild(self.config.AttachToBodyPart)
    if not bodyPart or not bodyPart:IsA("BasePart") then
        warn(`LocalPlayerLightModule: 无法找到身体部位 {self.config.AttachToBodyPart}`)
        return
    end

    -- 再次防护
    if not isSelfValid(self) then
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

function LocalPlayerLightModule:_cleanupOldLight()
    -- 前置防护：self无效时直接退出
    if not isSelfValid(self) then
        return
    end

    if not self.PlayerLightData then
        return
    end

    if type(self.PlayerLightData.PointLight) == "userdata" and self.PlayerLightData.PointLight:IsA("PointLight") then
        pcall(function()
            self.PlayerLightData.PointLight:Destroy()
        end)
    end
    self.PlayerLightData.PointLight = nil

    if type(self.PlayerLightData.Attachment) == "userdata" and self.PlayerLightData.Attachment:IsA("Attachment") then
        pcall(function()
            self.PlayerLightData.Attachment:Destroy()
        end)
    end
    self.PlayerLightData.Attachment = nil

    self.PlayerLightData = nil
end

function LocalPlayerLightModule:enable()
    if not isSelfValid(self) then
        warn("LocalPlayerLightModule: 实例已卸载，无法启用光源")
        return
    end
    if self.PlayerLightData and type(self.PlayerLightData.PointLight) == "userdata" and self.PlayerLightData.PointLight:IsA("PointLight") then
        self.PlayerLightData.PointLight.Enabled = true
        print(`LocalPlayerLightModule: 光源 {self.config.Attachment_Name} 已启用`)
    else
        warn("LocalPlayerLightModule: 光源尚未创建/已被销毁，无法启用")
    end
end

function LocalPlayerLightModule:disable()
    if not isSelfValid(self) then
        warn("LocalPlayerLightModule: 实例已卸载，无法禁用光源")
        return
    end
    if self.PlayerLightData and type(self.PlayerLightData.PointLight) == "userdata" and self.PlayerLightData.PointLight:IsA("PointLight") then
        self.PlayerLightData.PointLight.Enabled = false
        print(`LocalPlayerLightModule: 光源 {self.config.Attachment_Name} 已禁用`)
    else
        warn("LocalPlayerLightModule: 光源尚未创建/已被销毁，无法禁用")
    end
end

function LocalPlayerLightModule:unload()
    -- 防护：避免重复卸载
    if self._isInstanceUnloaded then
        return
    end
    -- 标记实例已卸载（核心！阻止后续所有操作）
    self._isInstanceUnloaded = true

    -- 调用清理前检查self
    if isSelfValid(self) then
        self:_cleanupOldLight()
    end

    if type(self._characterAddedConn) == "userdata" and self._characterAddedConn.Connected then
        pcall(function()
            self._characterAddedConn:Disconnect()
        end)
    end
    self._characterAddedConn = nil

    if LocalPlayerLightModule._instances and #LocalPlayerLightModule._instances > 0 then
        for i = #LocalPlayerLightModule._instances, 1, -1 do
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
    -- 标记模块已卸载（核心！阻止创建新实例）
    LocalPlayerLightModule._isUnloaded = true

    if LocalPlayerLightModule._instances and #LocalPlayerLightModule._instances > 0 then
        for _, instance in ipairs(LocalPlayerLightModule._instances) do
            if instance and type(instance.unload) == "function" and not instance._isInstanceUnloaded then
                instance:unload()
            end
        end
    end
    LocalPlayerLightModule._instances = {}
    print("LocalPlayerLightModule: 所有光源实例已全部卸载")
end

-- 新增：监听脚本销毁事件（Roblox专属，脚本被删除时自动调用unloadAll）
local function onScriptDestroyed()
    LocalPlayerLightModule.unloadAll()
end
-- 假设脚本是ModuleScript，绑定到自身的Destroying事件
if script and script:IsA("ModuleScript") then
    script.Destroying:Connect(onScriptDestroyed)
end

return LocalPlayerLightModule