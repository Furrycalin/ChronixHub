-- LocalPlayerLight.lua （最终修复版）
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local LightModule = {}
LightModule.__index = LightModule
local allLights = {}

-- 构造函数
function LightModule.new(customConfig)
    if not localPlayer then
        warn("[LightModule] 本地玩家不存在，创建失败")
        return nil
    end

    local config = {
        brightness = 2,
        range = 10,
        color = Color3.new(1,1,1),
        shadows = false,
        offset = Vector3.new(0,1.5,0),
        bind_part = "UpperTorso",
        attach_name = "PlayerLight"
    }

    if type(customConfig) == "table" then
        config.brightness = customConfig.brightness or config.brightness
        config.range = customConfig.range or config.range
        config.color = customConfig.color or config.color
        config.shadows = customConfig.shadows or config.shadows
        config.offset = customConfig.offset or config.offset
        config.bind_part = customConfig.bind_part or config.bind_part
        config.attach_name = customConfig.attach_name or config.attach_name
    end

    local lightObj = {
        config = config,
        light_data = nil,
        char_conn = nil
    }
    setmetatable(lightObj, LightModule)

    lightObj:_bind_character()
    table.insert(allLights, lightObj)

    return lightObj
end

-- 内部绑定角色
function LightModule:_bind_character()
    local self = self

    local function on_char_added(character)
        local bindPart = character:WaitForChild(self.config.bind_part, 5)
        if not bindPart then
            warn("[LightModule] 未找到绑定部位："..self.config.bind_part)
            return
        end

        self:cleanup()

        local attach = Instance.new("Attachment")
        attach.Name = self.config.attach_name
        attach.Position = self.config.offset
        attach.Parent = bindPart

        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = self.config.brightness
        pointLight.Range = self.config.range
        pointLight.Color = self.config.color
        pointLight.Shadows = self.config.shadows
        pointLight.Enabled = false
        pointLight.Parent = attach

        self.light_data = {
            attach = attach,
            light = pointLight
        }
        print("[LightModule] 光源创建成功")
    end

    self.char_conn = localPlayer.CharacterAdded:Connect(on_char_added)
    if localPlayer.Character then
        task.spawn(on_char_added, localPlayer.Character)
    end
end

-- 开启光源
function LightModule:enable()
    if not self.light_data then
        warn("[LightModule] 光源未创建，无法开启")
        return
    end
    if not self.light_data.light or not self.light_data.light:IsA("PointLight") then
        warn("[LightModule] 光源组件丢失，无法开启")
        return
    end
    self.light_data.light.Enabled = true
    print("[LightModule] 光源已开启")
end

-- 关闭光源
function LightModule:disable()
    if not self.light_data then
        warn("[LightModule] 光源未创建，无法关闭")
        return
    end
    if not self.light_data.light or not self.light_data.light:IsA("PointLight") then
        warn("[LightModule] 光源组件丢失，无法关闭")
        return
    end
    self.light_data.light.Enabled = false
    print("[LightModule] 光源已关闭")
end

-- 清理光源
function LightModule:cleanup()
    if not self.light_data then
        return
    end

    if self.light_data.light then
        pcall(function() self.light_data.light:Destroy() end)
        self.light_data.light = nil
    end

    if self.light_data.attach then
        pcall(function() self.light_data.attach:Destroy() end)
        self.light_data.attach = nil
    end

    self.light_data = nil
    print("[LightModule] 光源已清理")
end

-- 卸载实例
function LightModule:unload()
    self:cleanup()

    if self.char_conn then
        pcall(function() self.char_conn:Disconnect() end)
        self.char_conn = nil
    end

    for i = #allLights, 1, -1 do
        if allLights[i] == self then
            table.remove(allLights, i)
            break
        end
    end

    print("[LightModule] 光源实例已卸载")
end

-- 全局卸载（修复核心）
function LightModule.unload()
    -- 过滤nil元素
    local validLights = {}
    for _, light in ipairs(allLights) do
        if light ~= nil then
            table.insert(validLights, light)
        end
    end
    allLights = validLights

    -- 倒序遍历有效实例
    for i = #allLights, 1, -1 do
        local lightInstance = allLights[i]
        if type(lightInstance) == "table" and type(lightInstance.unload) == "function" then
            lightInstance:unload()
        end
        table.remove(allLights, i)
    end

    allLights = {}
    print("[LightModule] 所有光源已卸载（无空值错误）")
end

return LightModule