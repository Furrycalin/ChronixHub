-- 检查是否已经执行过
if _G.ShadersLoaded then
    print("光影脚本已加载，跳过重复执行")
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- ===== 清理现有非默认效果 =====
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or 
       v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
        v:Destroy()
    end
end

-- ===== 基础环境设置 (Shader.lua核心) =====
-- 这些属性在日夜切换时保持不变
Lighting.FogEnd = 1000
Lighting.FogStart = 0
Lighting.ShadowSoftness = 0
Lighting.GlobalShadows = true
Lighting.ClockTime = 6.7  -- 初始时间

-- ===== 添加视觉效果 (静态部分) =====
-- Bloom效果 (主)
local mainBloom = Instance.new("BloomEffect")
mainBloom.Intensity = 0.1
mainBloom.Threshold = 0
mainBloom.Size = 100
mainBloom.Parent = Lighting

-- 太阳光线
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.05
sunRays.Parent = Lighting

-- 天空盒
local sunsetSky = Instance.new("Sky")
sunsetSky.Name = "Sunset"
sunsetSky.SkyboxUp = "rbxassetid://323493360"
sunsetSky.SkyboxLf = "rbxassetid://323494252"
sunsetSky.SkyboxBk = "rbxassetid://323494035"
sunsetSky.SkyboxFt = "rbxassetid://323494130"
sunsetSky.SkyboxDn = "rbxassetid://323494368"
sunsetSky.SkyboxRt = "rbxassetid://323494067"
sunsetSky.SunAngularSize = 14
sunsetSky.Parent = Lighting

-- 颜色校正层 (基础)
local baseColorCorrection = Instance.new("ColorCorrectionEffect")
baseColorCorrection.Name = "BaseColor"
baseColorCorrection.Saturation = 0.05
baseColorCorrection.TintColor = Color3.fromRGB(255, 224, 219)
baseColorCorrection.Parent = Lighting

-- 第二个Bloom效果 (高强度光晕)
local intenseBloom = Instance.new("BloomEffect")
intenseBloom.Enabled = true
intenseBloom.Intensity = 0.99
intenseBloom.Size = 9999
intenseBloom.Threshold = 0
intenseBloom.Parent = Lighting

-- 深度场效果
local dof = Instance.new("DepthOfFieldEffect")
dof.Enabled = true
dof.FarIntensity = 0.077
dof.FocusDistance = 21.54
dof.InFocusRadius = 20.77
dof.NearIntensity = 0.277
dof.Parent = Lighting

-- 暖色调颜色校正
local warmCorrection = Instance.new("ColorCorrectionEffect")
warmCorrection.Brightness = 0.015
warmCorrection.Contrast = 0.25
warmCorrection.Enabled = true
warmCorrection.Saturation = 0.2
warmCorrection.TintColor = Color3.fromRGB(217, 145, 57)
warmCorrection.Parent = Lighting

-- 柔和颜色校正
local softCorrection = Instance.new("ColorCorrectionEffect")
softCorrection.Brightness = 0
softCorrection.Contrast = -0.07
softCorrection.Saturation = 0
softCorrection.Enabled = true
softCorrection.TintColor = Color3.fromRGB(255, 247, 239)
softCorrection.Parent = Lighting

-- 增亮颜色校正
local brightCorrection = Instance.new("ColorCorrectionEffect")
brightCorrection.Brightness = 0.2
brightCorrection.Contrast = 0.45
brightCorrection.Saturation = -0.1
brightCorrection.Enabled = true
brightCorrection.TintColor = Color3.fromRGB(255, 255, 255)
brightCorrection.Parent = Lighting

-- 第二层太阳光线
local secondSunRays = Instance.new("SunRaysEffect")
secondSunRays.Enabled = true
secondSunRays.Intensity = 0.01
secondSunRays.Spread = 0.146
secondSunRays.Parent = Lighting

-- 地形水效果
local terrain = workspace.Terrain
if terrain then
    terrain.WaterWaveSize = 0.1
    terrain.WaterWaveSpeed = 22
    terrain.WaterTransparency = 0.9
    terrain.WaterReflectance = 0.05
end

-- ===== 动态日夜效果配置 =====
-- 白天模式 (6:00 - 18:00)
local daySettings = {
    Brightness = 2.14,
    ExposureCompensation = 0.24,
    Ambient = Color3.fromRGB(59, 33, 27),
    OutdoorAmbient = Color3.fromRGB(34, 0, 49),
    ColorShift_Top = Color3.fromRGB(240, 127, 14),
    ColorShift_Bottom = Color3.fromRGB(11, 0, 20),
    FogColor = Color3.fromRGB(94, 76, 106),
    FogStart = 200,      -- 雾气起始距离改为200，让白天雾气减小（原为0）
    FogEnd = 1000,
    FogEnabled = true
}

-- 夜晚模式 (18:00 - 6:00)
local nightSettings = {
    Brightness = 0.35,            -- 进一步降低亮度，让夜晚更暗
    ExposureCompensation = -0.3,  -- 降低曝光
    Ambient = Color3.fromRGB(10, 6, 15),     -- 更暗的环境光
    OutdoorAmbient = Color3.fromRGB(5, 3, 12), -- 更暗的室外环境
    ColorShift_Top = Color3.fromRGB(40, 25, 70),   -- 偏紫的顶光
    ColorShift_Bottom = Color3.fromRGB(3, 0, 10),  -- 很暗的底光
    FogColor = Color3.fromRGB(15, 10, 25),
    FogStart = 9999,     -- 雾气起始距离设为极大，无雾
    FogEnd = 10000,
    FogEnabled = false
}

-- 黄昏/黎明过渡模式
local transitionSettings = {
    Brightness = 1.0,
    ExposureCompensation = 0.05,
    Ambient = Color3.fromRGB(30, 20, 30),
    OutdoorAmbient = Color3.fromRGB(15, 8, 25),
    ColorShift_Top = Color3.fromRGB(160, 85, 50),
    ColorShift_Bottom = Color3.fromRGB(15, 4, 25),
    FogColor = Color3.fromRGB(65, 50, 75),
    FogStart = 80,
    FogEnd = 900,
    FogEnabled = true
}

-- 根据时间应用光照设置
local function applyTimeBasedSettings(clockTime)
    -- 判断时间段
    local isDay = clockTime >= 6 and clockTime < 18
    local isTransition = (clockTime >= 5.5 and clockTime < 6) or (clockTime >= 18 and clockTime < 18.5)
    
    local settings
    if isDay then
        settings = daySettings
    elseif isTransition then
        settings = transitionSettings
    else
        settings = nightSettings
    end
    
    -- 应用光照属性
    Lighting.Brightness = settings.Brightness
    Lighting.ExposureCompensation = settings.ExposureCompensation
    Lighting.Ambient = settings.Ambient
    Lighting.OutdoorAmbient = settings.OutdoorAmbient
    Lighting.ColorShift_Top = settings.ColorShift_Top
    Lighting.ColorShift_Bottom = settings.ColorShift_Bottom
    Lighting.FogColor = settings.FogColor
    
    -- 控制雾气
    if settings.FogEnabled then
        Lighting.FogStart = settings.FogStart
        Lighting.FogEnd = settings.FogEnd
    else
        -- 无雾：将起始距离设得比终点还远
        Lighting.FogStart = 9999
        Lighting.FogEnd = 10000
    end
    
    -- 根据时间调整Bloom强度
    if not isDay then
        mainBloom.Intensity = 0.03      -- 夜晚Bloom进一步减弱
        intenseBloom.Intensity = 0.3
    else
        mainBloom.Intensity = 0.1
        intenseBloom.Intensity = 0.99
    end
end

-- 初始化时应用一次
applyTimeBasedSettings(Lighting.ClockTime)

-- 监听时间变化
local lastTime = Lighting.ClockTime
RunService.Heartbeat:Connect(function()
    local currentTime = Lighting.ClockTime
    if math.abs(currentTime - lastTime) >= 0.01 then
        lastTime = currentTime
        applyTimeBasedSettings(currentTime)
    end
end)

-- 如果ClockTime被其他地方修改，也触发更新
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
    applyTimeBasedSettings(Lighting.ClockTime)
end)

-- 设置全局变量，标记脚本已执行
_G.ShadersLoaded = true