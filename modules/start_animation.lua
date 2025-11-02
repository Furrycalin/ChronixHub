-- 基于早期稳定版本重新构建的加载动画模块
local LoadAnimationModule = {}

function LoadAnimationModule:LoadAnimation(duration, config)
    -- 创建音效
    local loadingSound = Instance.new("Sound", game:GetService("SoundService"))
    loadingSound.SoundId = "rbxassetid://1837581587"
    loadingSound.Volume = 0.3
    loadingSound:Play()
    
    -- 默认配置
    local defaultConfig = {
        titleText = "ChronixHub V3",
        loadingText = "加载中... ",
        backgroundColor = Color3.new(0.102, 0.098, 0.102), -- #1a191a
        textColor = Color3.new(1, 1, 1),
        language = "zh",
        onComplete = function() end,
        showCancelButton = true
    }

    -- 合并用户配置
    config = config or {}
    for k, v in pairs(defaultConfig) do
        if config[k] == nil then
            config[k] = v
        end
    end

    -- 多语言支持
    local translations = {
        en = { title = "ChronixHub V3", loading = "Loading... ", cancel = "Cancel" },
        zh = { title = "ChronixHub V3", loading = "加载中... ", cancel = "取消" }
    }
    config.titleText = translations[config.language].title
    config.loadingText = translations[config.language].loading
    local cancelText = translations[config.language].cancel

    -- 错误处理：防止重复调用
    if game.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadAnimationGui") then
        return
    end

    -- 创建界面
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LoadAnimationGui"
    screenGui.Parent = game.Players.LocalPlayer.PlayerGui

    -- 使用固定的1030*605像素大小，总共缩小20%
    local uiScale = 0.75
    local uiWidth = 1030 * uiScale
    local uiHeight = 605 * uiScale

    -- 创建主框架
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, uiWidth, 0, uiHeight)
    frame.Position = UDim2.new(0.5, -uiWidth/2, 0.5, -uiHeight/2)
    frame.BackgroundColor3 = config.backgroundColor
    frame.BackgroundTransparency = 0
    frame.ClipsDescendants = true -- 超出部分不显示
    frame.Parent = screenGui

    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.03, 0)
    corner.Parent = frame

    -- 创建左上角圆形嵌入 - 颜色#141414
    local circleSize = uiHeight / 3
    local topLeftCircle = Instance.new("Frame")
    topLeftCircle.Name = "TopLeftCircle"
    topLeftCircle.Size = UDim2.new(0, circleSize, 0, circleSize)
    topLeftCircle.Position = UDim2.new(0, -circleSize/2, 0, -circleSize/2)
    topLeftCircle.BackgroundColor3 = Color3.new(0.078, 0.078, 0.078) -- #141414
    topLeftCircle.BackgroundTransparency = 0
    topLeftCircle.Parent = frame

    -- 圆形圆角
    local topLeftCircleCorner = Instance.new("UICorner")
    topLeftCircleCorner.CornerRadius = UDim.new(0.5, 0)
    topLeftCircleCorner.Parent = topLeftCircle

    -- 创建右下角圆形嵌入 - 颜色#141414
    local bottomRightCircle = Instance.new("Frame")
    bottomRightCircle.Name = "BottomRightCircle"
    bottomRightCircle.Size = UDim2.new(0, circleSize, 0, circleSize)
    bottomRightCircle.Position = UDim2.new(0, uiWidth - circleSize/2, 0, uiHeight - circleSize/2)
    bottomRightCircle.BackgroundColor3 = Color3.new(0.078, 0.078, 0.078) -- #141414
    bottomRightCircle.BackgroundTransparency = 0
    bottomRightCircle.Parent = frame

    -- 圆形圆角
    local bottomRightCircleCorner = Instance.new("UICorner")
    bottomRightCircleCorner.CornerRadius = UDim.new(0.5, 0)
    bottomRightCircleCorner.Parent = bottomRightCircle

    -- 创建标题文本
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(0, 350, 0, 50)
    titleFrame.Position = UDim2.new(0, uiWidth/2 - 145, 0, uiHeight*0.3)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = frame

    -- ChronixHub 文本
    local chronixText = Instance.new("TextLabel")
    chronixText.Text = "ChronixHub"
    chronixText.Size = UDim2.new(0, 240, 0, 50)
    chronixText.Position = UDim2.new(0, 0, 0, 0)
    chronixText.TextColor3 = Color3.new(1, 1, 1)
    chronixText.BackgroundTransparency = 1
    chronixText.Font = Enum.Font.SourceSansBold
    chronixText.TextSize = 32
    chronixText.Parent = titleFrame

    -- V3 文本
    local v3Text = Instance.new("TextLabel")
    v3Text.Text = "V3"
    v3Text.Size = UDim2.new(0, 70, 0, 50)
    v3Text.Position = UDim2.new(0, 180, 0, 0)
    v3Text.TextColor3 = Color3.new(0.8, 1, 0.5)
    v3Text.BackgroundTransparency = 1
    v3Text.Font = Enum.Font.SourceSansBold
    v3Text.TextSize = 32
    v3Text.Parent = titleFrame

    -- 加载文本
    local loadingText = Instance.new("TextLabel")
    loadingText.Text = config.loadingText .. "0%"
    loadingText.Size = UDim2.new(0, 250, 0, 35)
    loadingText.Position = UDim2.new(0, uiWidth/2 - 125, 0, uiHeight*0.5)
    loadingText.TextColor3 = config.textColor
    loadingText.BackgroundTransparency = 1
    loadingText.Font = Enum.Font.SourceSans
    loadingText.TextSize = 18
    loadingText.Parent = frame

    -- 创建进度条背景
    local progressBarBackground = Instance.new("Frame")
    progressBarBackground.Size = UDim2.new(0, uiWidth*0.8, 0, 6)
    progressBarBackground.Position = UDim2.new(0, uiWidth*0.1, 0, uiHeight*0.6)
    progressBarBackground.BackgroundTransparency = 1
    progressBarBackground.ClipsDescendants = true
    progressBarBackground.Parent = frame

    -- 进度条背景圆角
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0.5, 0)
    progressBgCorner.Parent = progressBarBackground

    -- 进度条背景黑色边框
    local progressBorder = Instance.new("UIStroke")
    progressBorder.Color = Color3.new(0, 0, 0)
    progressBorder.Thickness = 1
    progressBorder.Parent = progressBarBackground

    -- 创建进度条
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 0, 6)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = Color3.new(0.8, 1, 0.5)
    progressBar.Parent = progressBarBackground

    -- 进度条圆角
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0.5, 0)
    progressCorner.Parent = progressBar

    -- 创建取消按钮
    local cancelButton = Instance.new("TextButton")
    cancelButton.Text = "✕"
    cancelButton.Size = UDim2.new(0, 30, 0, 30)
    cancelButton.Position = UDim2.new(0, uiWidth - 40, 0, 10)
    cancelButton.TextColor3 = Color3.new(1, 1, 1)
    cancelButton.BackgroundTransparency = 0.8
    cancelButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    cancelButton.Font = Enum.Font.SourceSans
    cancelButton.TextSize = 16
    cancelButton.Parent = frame

    -- 取消按钮圆角
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0.2, 0)
    cancelCorner.Parent = cancelButton

    -- 取消按钮悬停效果
    cancelButton.MouseEnter:Connect(function()
        cancelButton.BackgroundTransparency = 0.6
        cancelButton.TextColor3 = Color3.new(0.8, 1, 0.5)
    end)

    cancelButton.MouseLeave:Connect(function()
        cancelButton.BackgroundTransparency = 0.8
        cancelButton.TextColor3 = Color3.new(1, 1, 1)
    end)

    -- 使用 coroutine 管理动画
    local function playAnimationAsync()
        -- 主动画：整个界面从屏幕右侧划入中间
        local slideIn = game:GetService("TweenService"):Create(
            frame, 
            TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -uiWidth/2, 0.5, -uiHeight/2)}
        )
        slideIn:Play()
        slideIn.Completed:Wait()

        -- 模拟加载进度 - 跳跃式更新
        local isCancelled = false
        local progressSteps = {0, 0.2, 0.5, 0.9, 1}
        local stepDurations = {1.5, 2.0, 2.5, 2.0}
        local pauseDurations = {2.0, 1.0, 1.0}
        local currentStep = 1

        -- 取消按钮事件
        cancelButton.MouseButton1Click:Connect(function()
            isCancelled = true
            -- 停止音乐
            loadingSound:Stop()
            loadingSound:Destroy()
            -- 取消时的动画
            local slideOut = game:GetService("TweenService"):Create(
                frame, 
                TweenInfo.new(0.4, Enum.EasingStyle.Quad),
                {Position = UDim2.new(1.5, 0, 0.5, -uiHeight/2)}
            )
            slideOut:Play()
            slideOut.Completed:Wait()
            screenGui:Destroy()
            config.onComplete(true)
        end)

        -- 跳跃式进度更新
        while currentStep < #progressSteps and not isCancelled do
            local targetProgress = progressSteps[currentStep + 1]
            
            -- 进度条动画
            local progressTween = game:GetService("TweenService"):Create(
                progressBar,
                TweenInfo.new(stepDurations[currentStep], Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, targetProgress * uiWidth * 0.8, 0, 6)}
            )
            progressTween:Play()
            
            -- 更新文本显示
            local stepStartTime = tick()
            while tick() - stepStartTime < stepDurations[currentStep] and not isCancelled do
                local elapsed = tick() - stepStartTime
                local tweenProgress = elapsed / stepDurations[currentStep]
                local currentProgress = progressSteps[currentStep] + (targetProgress - progressSteps[currentStep]) * tweenProgress
                local displayProgress = math.floor(currentProgress * 100)
                loadingText.Text = config.loadingText .. displayProgress .. "%"
                wait(0.05)
            end
            
            -- 更新到下一个步骤
            currentStep = currentStep + 1
            
            -- 在指定进度处添加卡顿
            if currentStep <= 4 and not isCancelled then
                local displayProgress = math.floor(progressSteps[currentStep] * 100)
                loadingText.Text = config.loadingText .. displayProgress .. "%"
                wait(pauseDurations[currentStep - 1])
            end
        end

        if not isCancelled then
            -- 完成动画
            loadingText.Text = "加载完毕!"
            progressBar.Size = UDim2.new(0, uiWidth * 0.8, 0, 6)
            cancelButton.Parent = nil
            
            -- 音乐跳转到指定位置
            loadingSound.TimePosition = 128
            
            wait(0.5)
            loadingText.Text = config.loadingText .. "100%"
            
            -- 完成时的动画
            local slideOut = game:GetService("TweenService"):Create(
                frame, 
                TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Position = UDim2.new(-0.5, 0, 0.5, -uiHeight/2)}
            )
            slideOut:Play()
            slideOut.Completed:Wait()

            -- 清除界面
            screenGui:Destroy()
            config.onComplete(false)
        end
    end

    -- 启动动画协程
    coroutine.wrap(playAnimationAsync)()
end

return LoadAnimationModule