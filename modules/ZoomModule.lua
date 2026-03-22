-- ZoomModule.lua
-- 摄像机缩放模块，支持按键触发、滚轮微调

local ZoomModule = {}
ZoomModule.__index = ZoomModule

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

function ZoomModule.new()
    local self = setmetatable({}, ZoomModule)

    self.config = {
        bindKey = Enum.KeyCode.C,           -- 触发按键（默认C）
        tweenTime = 0.15,                   -- 视野过渡时间
        scrollSensitivity = 5,              -- 滚轮灵敏度（值越大调整越快）
        minZoomFOV = 15,                    -- 最小视野（数值越小放大倍数越大）
    }

    self.isEnabled = false
    self.isZooming = false
    self.normalFOV = 70                     -- 正常视野（启用时从相机获取）
    self.currentZoomFOV = 30                -- 当前缩放视野（滚轮可调）
    self.originalCameraType = nil           -- 保存原始相机类型

    self.connections = {
        inputBegan = nil,
        inputEnded = nil,
        inputChanged = nil,
    }

    self.camera = workspace.CurrentCamera
    return self
end

-- 获取正常视野
function ZoomModule:GetNormalFOV()
    return self.normalFOV
end

-- 设置正常视野（谨慎使用）
function ZoomModule:SetNormalFOV(fov)
    self.normalFOV = fov
    if not self.isZooming and self.isEnabled then
        self.camera.FieldOfView = self.normalFOV
    end
end

-- 平滑更新视野
function ZoomModule:UpdateCameraFOV(targetFOV)
    local tween = TweenService:Create(self.camera, TweenInfo.new(self.config.tweenTime), {FieldOfView = targetFOV})
    tween:Play()
end

-- 滚轮调整缩放程度（仅在缩放状态下生效）
function ZoomModule:OnMouseWheel(input)
    if not self.isZooming or not self.isEnabled then return end

    local scrollDelta = input.Delta.Z
    if scrollDelta == 0 then return end

    local newZoomFOV = self.currentZoomFOV - (scrollDelta * self.config.scrollSensitivity)
    newZoomFOV = math.clamp(newZoomFOV, self.config.minZoomFOV, self.normalFOV)

    if newZoomFOV == self.currentZoomFOV then return end

    self.currentZoomFOV = newZoomFOV
    self:UpdateCameraFOV(self.currentZoomFOV)

    -- 阻止引擎默认的摄像机距离调整
    input:Processed()
end

-- 开始缩放（按住按键时触发）
function ZoomModule:StartZoom()
    if not self.isEnabled then return end

    self.isZooming = true
    -- 保存原相机类型并切换为脚本控制，彻底禁用引擎滚轮行为
    self.originalCameraType = self.camera.CameraType
    self.camera.CameraType = Enum.CameraType.Scriptable

    -- 确保当前缩放视野合理
    if self.currentZoomFOV > self.normalFOV then
        self.currentZoomFOV = math.min(30, self.normalFOV - 10)
    end
    self:UpdateCameraFOV(self.currentZoomFOV)
end

-- 结束缩放（松开按键时触发）
function ZoomModule:StopZoom()
    if not self.isEnabled then return end

    self.isZooming = false
    self:UpdateCameraFOV(self.normalFOV)

    -- 恢复原始相机类型，交还控制权
    if self.originalCameraType then
        self.camera.CameraType = self.originalCameraType
        self.originalCameraType = nil
    end
end

-- 按键绑定相关
function ZoomModule:SetBindKey(keyType)
    self.config.bindKey = keyType
end

function ZoomModule:GetBindKey()
    return self.config.bindKey
end

-- 最小缩放视野（放大倍数）
function ZoomModule:SetMinZoomFOV(minFOV)
    self.config.minZoomFOV = minFOV
    if self.isZooming and self.currentZoomFOV < minFOV then
        self.currentZoomFOV = minFOV
        self:UpdateCameraFOV(self.currentZoomFOV)
    end
end

function ZoomModule:GetMinZoomFOV()
    return self.config.minZoomFOV
end

-- 滚轮灵敏度
function ZoomModule:SetScrollSensitivity(sensitivity)
    self.config.scrollSensitivity = sensitivity
end

function ZoomModule:GetScrollSensitivity()
    return self.config.scrollSensitivity
end

-- 动画时长
function ZoomModule:SetTweenTime(time)
    self.config.tweenTime = time
end

function ZoomModule:GetTweenTime()
    return self.config.tweenTime
end

-- 判断输入是否匹配绑定按键
function ZoomModule:IsMatchingInput(input)
    return input.UserInputType == self.config.bindKey or input.KeyCode == self.config.bindKey
end

-- 启用模块
function ZoomModule:Enable()
    if self.isEnabled then return end

    self.normalFOV = self.camera.FieldOfView
    local defaultZoomFOV = math.max(15, self.normalFOV - 10)
    self.currentZoomFOV = math.min(defaultZoomFOV, self.normalFOV)

    self.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if self:IsMatchingInput(input) then
            self:StartZoom()
        end
    end)

    self.connections.inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if self:IsMatchingInput(input) then
            self:StopZoom()
        end
    end)

    -- 关键：滚轮事件在 InputChanged 中捕获，确保连续滚动正常
    self.connections.inputChanged = UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            if self.isZooming then
                self:OnMouseWheel(input)
            end
        end
    end)

    self.isEnabled = true
end

-- 禁用模块
function ZoomModule:Disable()
    if not self.isEnabled then return end

    if self.isZooming then
        self:StopZoom()
    end

    for _, conn in pairs(self.connections) do
        if conn then
            conn:Disconnect()
        end
    end
    self.connections = {inputBegan = nil, inputEnded = nil, inputChanged = nil}

    self.isEnabled = false
end

-- 完全卸载
function ZoomModule:Unload()
    self:Disable()
    self.camera = nil
    self.config = nil
    self.isEnabled = nil
    self.isZooming = nil
    self.normalFOV = nil
    self.currentZoomFOV = nil
    self.originalCameraType = nil
end

return ZoomModule