-- LocalPlayerLight.lua （重写后极简版）
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- 模块核心（极简，无复杂嵌套）
local LightModule = {}
LightModule.__index = LightModule -- 必加：让实例能访问模块方法

-- 存储所有实例（用于全局卸载）
local allLights = {}

-- ==============================================
-- 构造函数：创建光源实例（外部调用：LightModule.new(配置)）
-- ==============================================
function LightModule.new(customConfig)
    -- 1. 基础防护：本地玩家不存在直接返回
    if not localPlayer then
        warn("[LightModule] 本地玩家不存在，创建失败")
        return nil
    end

    -- 2. 默认配置（极简）
    local config = {
        brightness = 2,
        range = 10,
        color = Color3.new(1,1,1),
        shadows = false,
        offset = Vector3.new(0,1.5,0),
        bind_part = "UpperTorso",
        attach_name = "PlayerLight"
    }

    -- 3. 合并自定义配置（选填，不填用默认）
    if type(customConfig) == "table" then
        config.brightness = customConfig.brightness or config.brightness
        config.range = customConfig.range or config.range
        config.color = customConfig.color or config.color
        config.shadows = customConfig.shadows or config.shadows
        config.offset = customConfig.offset or config.offset
        config.bind_part = customConfig.bind_part or config.bind_part
        config.attach_name = customConfig.attach_name or config.attach_name
    end

    -- 4. 实例对象（所有属性明确初始化，杜绝"找不到变量"）
    local lightObj = {
        config = config,        -- 配置表
        light_data = nil,       -- 存储光源/附件（初始nil）
        char_conn = nil         -- 角色监听连接（初始nil）
    }
    setmetatable(lightObj, LightModule) -- 绑定元表，关键！

    -- 5. 绑定角色（核心逻辑）
    lightObj:_bind_character()

    -- 6. 加入全局列表
    table.insert(allLights, lightObj)

    return lightObj
end

-- ==============================================
-- 内部方法：绑定角色（私有，只在创建实例时调用）
-- ==============================================
function LightModule:_bind_character()
    local self = self -- 明确self，避免作用域问题

    -- 监听角色加载/重生
    local function on_char_added(character)
        -- 等待绑定部位加载（超时5秒）
        local bindPart = character:WaitForChild(self.config.bind_part, 5)
        if not bindPart then
            warn("[LightModule] 未找到绑定部位："..self.config.bind_part)
            return
        end

        -- 先清理旧光源（防重复）
        self:cleanup()

        -- 创建附件
        local attach = Instance.new("Attachment")
        attach.Name = self.config.attach_name
        attach.Position = self.config.offset
        attach.Parent = bindPart

        -- 创建点光源（默认禁用）
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = self.config.brightness
        pointLight.Range = self.config.range
        pointLight.Color = self.config.color
        pointLight.Shadows = self.config.shadows
        pointLight.Enabled = false -- 默认关闭
        pointLight.Parent = attach

        -- 赋值light_data（只有创建成功才赋值）
        self.light_data = {
            attach = attach,
            light = pointLight
        }
        print("[LightModule] 光源创建成功")
    end

    -- 绑定监听（存储连接）
    self.char_conn = localPlayer.CharacterAdded:Connect(on_char_added)
    -- 立即执行一次（处理已加载的角色）
    if localPlayer.Character then
        task.spawn(on_char_added, localPlayer.Character)
    end
end

-- ==============================================
-- 公共方法：开启光源（外部调用：实例:enable()）
-- ==============================================
function LightModule:enable()
    -- 第一步：检查light_data是否存在（核心防呆）
    if not self.light_data then
        warn("[LightModule] 光源未创建，无法开启")
        return
    end
    -- 第二步：检查光源是否有效
    if not self.light_data.light or not self.light_data.light:IsA("PointLight") then
        warn("[LightModule] 光源组件丢失，无法开启")
        return
    end
    -- 开启光源
    self.light_data.light.Enabled = true
    print("[LightModule] 光源已开启")
end

-- ==============================================
-- 公共方法：关闭光源（外部调用：实例:disable()）
-- ==============================================
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

-- ==============================================
-- 公共方法：清理光源（外部/内部调用：实例:cleanup()）
-- ==============================================
function LightModule:cleanup()
    -- 检查light_data是否存在，不存在直接返回（杜绝空值）
    if not self.light_data then
        return
    end

    -- 安全销毁光源
    if self.light_data.light then
        pcall(function() self.light_data.light:Destroy() end)
        self.light_data.light = nil
    end

    -- 安全销毁附件
    if self.light_data.attach then
        pcall(function() self.light_data.attach:Destroy() end)
        self.light_data.attach = nil
    end

    -- 置空light_data
    self.light_data = nil
    print("[LightModule] 光源已清理")
end

-- ==============================================
-- 公共方法：卸载实例（外部调用：实例:unload()）
-- ==============================================
function LightModule:unload()
    -- 1. 清理光源（即使light_data为nil，cleanup也会直接返回）
    self:cleanup()

    -- 2. 断开监听（检查连接是否存在）
    if self.char_conn then
        pcall(function() self.char_conn:Disconnect() end)
        self.char_conn = nil
    end

    -- 3. 从全局列表移除
    for i = #allLights, 1, -1 do
        if allLights[i] == self then
            table.remove(allLights, i)
            break
        end
    end

    print("[LightModule] 光源实例已卸载")
end

-- ==============================================
-- 全局方法：卸载所有实例（外部调用：LightModule.unload_all()）
-- ==============================================
function LightModule.unload_all()
    for _, light in ipairs(allLights) do
        if light and type(light.unload) == "function" then
            light:unload()
        end
    end
    allLights = {}
    print("[LightModule] 所有光源已卸载")
end

-- 返回模块
return LightModule