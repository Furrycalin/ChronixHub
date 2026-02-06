-- PlayerLightModule.lua
-- 一个用于为本地玩家创建和管理绑定光源的模块

local Players = game:GetService("Players")

local PlayerLightModule = {}

-- 配置表模板：定义光源的所有参数
local DefaultLightConfig = {
    -- PointLight 属性
    Enabled = true,
    Brightness = 2,
    Range = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Shadows = false,

    -- 附加 Attachment 的属性
    Attachment_Name = "PlayerLightAttachment",
    Offset_Position = Vector3.new(0, 1.5, 0),
    Offset_Rotation = Vector3.new(0, 0, 0),

    -- 绑定的目标身体部位
    AttachToBodyPart = "UpperTorso",
}

-- 光源实例的构造函数
local function createLightInstance(config)
    local self = {}
    -- 使用传入的配置覆盖默认配置
    self.config = {}
    for k, v in pairs(DefaultLightConfig) do
        self.config[k] = config[k] ~= nil and config[k] or v
    end

    self.attachment = nil
    self.pointLight = nil
    self.character = nil
    self.connection = nil

    -- 内部方法：应用光源到角色
    local function _applyLight(char)
        if self.attachment then self.attachment:Destroy() end
        if self.pointLight then self.pointLight:Destroy() end

        local bodyPart = char:FindFirstChild(self.config.AttachToBodyPart)
        if not bodyPart or not bodyPart:IsA("BasePart") then
            warn("无法在角色上找到身体部位: " .. self.config.AttachToBodyPart)
            return
        end

        self.attachment = Instance.new("Attachment")
        self.attachment.Name = self.config.Attachment_Name
        self.attachment.CFrame = CFrame.new(self.config.Offset_Position) * CFrame.Angles(
            math.rad(self.config.Offset_Rotation.X),
            math.rad(self.config.Offset_Rotation.Y),
            math.rad(self.config.Offset_Rotation.Z)
        )
        self.attachment.Parent = bodyPart

        self.pointLight = Instance.new("PointLight")
        self.pointLight.Enabled = self.config.Enabled
        self.pointLight.Brightness = self.config.Brightness
        self.pointLight.Range = self.config.Range
        self.pointLight.Color = self.config.Color
        self.pointLight.Shadows = self.config.Shadows
        self.pointLight.Parent = self.attachment
    end

    -- 公共方法：初始化并应用光源
    self.spawn = function()
        local localPlayer = Players.LocalPlayer
        if not localPlayer then
            Players.LocalPlayerAdded:Connect(function(player)
                if player == Players.LocalPlayer then
                    self:_attachToCharacter(player)
                end
            end)
            return
        end
        self:_attachToCharacter(localPlayer)
    end

    -- 内部辅助方法：处理角色加载和重生
    self._attachToCharacter = function(player)
        local char = player.Character or player.CharacterAdded:Wait()
        self.character = char
        
        -- 等待基础部件加载
        local humanoidRootPart = char:WaitForChild("HumanoidRootPart")
        if humanoidRootPart then
            _applyLight(char)
        end

        -- 监听角色重生
        if self.connection then self.connection:Disconnect() end
        self.connection = player.CharacterAdded:Connect(function(newChar)
            wait()
            -- 如果实例已被卸载，则不再处理重生
            if not self.attachment and not self.pointLight then return end
            
            self.character = newChar
            _applyLight(newChar)
        end)
    end

    -- 公共方法：卸载光源
    self.unload = function()
        if self.attachment then
            self.attachment:Destroy()
            self.attachment = nil
        end
        if self.pointLight then
            self.pointLight:Destroy()
            self.pointLight = nil
        end
        if self.connection then
            self.connection:Disconnect()
            self.connection = nil
        end
        self.character = nil
        print("光源实例已卸载。")
    end

    -- 初始化光源
    self:spawn()

    return self
end

-- 模块的入口函数，用于创建新的光源实例
PlayerLightModule.new = function(config)
    -- 确保传入的是一个表，即使是空的
    config = config or {}
    return createLightInstance(config)
end

return PlayerLightModule