if not game:IsLoaded() then
	game.Loaded:Wait()
end

if _G.ChronixHubisLoaded then
    warn("⛔ ChronixHub Already loaded! Please do not repeat the execution.")
    return
end

_G.ChronixHubisLoaded = true
_G.SA_FASTLOADING = true

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local ScriptContext = game:GetService("ScriptContext")
local TeleportService = game:GetService("TeleportService")

local LoadAnimationModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/start_animation.lua"))()
local tpWalk = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/RobloxScripts/raw/main/tpWalk.lua"))()
local StandRecovery = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/StandRecovery.lua"))()
local HighlightModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/HighlightModule.lua"))()
local PlayerLightModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/PlayerLightModule.lua"))()
local SpectatorModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/SpectatorModule.lua"))()
local FreecamModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/FreecamModule.lua"))()
local LandingEffect = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/LandingEffect.lua"))()
local NameTagModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/NameTagModule.lua"))()
local PlayerVisibleModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/PlayerVisibleModule.lua"))()
local movementModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/MovementModule.lua"))()
local MouseUnlockModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/MouseUnlockModule.lua"))()
local DeathballScripts = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/DeathBallScripts.lua"))()
local ZoomModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/ZoomModule.lua"))()
local FlingDetector = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/FlingDetector.lua"))()
local SystemNotification = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/SystemNotification.lua"))()
local PlayerESP = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/PlayerESP.lua"))()
local MovableHighlighter_NM = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/MovableHighlighter-NM.lua"))()
local GameTeleport = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/GameTeleport.lua"))()
local AntiVoidModule = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/AntiVoid.lua"))()
local ChatSpy = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/ChatSpy.lua"))()
local ChatControl = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/RobloxScripts/raw/main/chat_test.lua"))()

--=============================================================================================

LoadAnimationModule:LoadAnimation(2, {
    titleText = "ChronixHub V3",
    loadingText = "加载中... ",
    backgroundColor = Color3.new(0, 0, 0),
    textColor = Color3.new(1, 1, 1),
    language = "zh",
    onComplete = function(isCancelled)
        if isCancelled then
            iscancel = true
        end
    end,
    showCancelButton = false
})

wait(2.1)

-- 防挂机
local bb = game:service'VirtualUser'
local cc = game:service'Players'.LocalPlayer.Idled:connect(function()bb:CaptureController()bb:ClickButton2(Vector2.new())end)

local function GetDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return "Mobile" -- 移动端
    elseif UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
        return "Desktop" -- 桌面端
    elseif UserInputService.GamepadEnabled then
        return "Console" -- 控制台
    else
        return "Unknown" -- 未知设备
    end
end


local getGameNameNotSuccess = false

-- 获取游戏名
local function getGameName(universeId)
    local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        if data.data and #data.data > 0 then
            return data.data[1]
        else
            warn("未找到游戏信息")
            print(data)
            getGameNameNotSuccess = true
            return nil
        end
    else
        warn("获取游戏名失败:", response)
        getGameNameNotSuccess = true
        return nil
    end
end

local data = {
    basicdata = {
        player = {
            name = LocalPlayer.Name,
            displayname = LocalPlayer.DisplayName,
            userid = LocalPlayer.UserId,
            isPremium = (LocalPlayer.MembershipType == Enum.MembershipType.Premium),
            avatar = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100),
            appearanceInfo = Players:GetCharacterAppearanceInfoAsync(LocalPlayer.UserId),
            deviceType = GetDeviceType(),
            gameInfo = getGameName(game.GameId), -- .name
            ---
            speed = LocalPlayer.Character.Humanoid.WalkSpeed, islockspeed = false,
            jump = LocalPlayer.Character.Humanoid.JumpPower, islockjump = false,
            maxhealth = LocalPlayer.Character.Humanoid.MaxHealth, islockmaxhealth = false,
            health = LocalPlayer.Character.Humanoid.Health, islockhealth = false,
            gravity = game.Workspace.Gravity, islockgravity = false,
        },
        releasetools = {
            zoom = ZoomModule.new(),
            Lantern = PlayerLightModule.new({ Brightness = 3, Range = 20, Color = Color3.fromRGB(255, 165, 0), Shadows = true }),
            SuperLighter = PlayerLightModule.new({ Brightness = 2, Range = 1000 }),
            noclip = false,
            infjump = false,
            antifall = false,
            antidead = false,
        },
        otherdata = {
            daySettings = {
                ClockTime = 14, -- 白天时间（14:00）
                GeographicLatitude = 41.73, -- 纬度（影响太阳高度）
            },
            nightSettings = {
                ClockTime = 2, -- 黑夜时间（02:00）
                GeographicLatitude = 41.73, -- 纬度
            }
        }
    },
    scriptlist = {
        {
            name = "高级聊天系统",
            link = "https://raw.atomgit.com/Furrycalin/RobloxScripts/raw/main/customChatSystem.lua"
        },
        {
            name = "飞行V4",
            link = "https://raw.atomgit.com/Furrycalin/RobloxScripts/raw/main/FlyV4.lua"
        },
        {
            name = "超高画质",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/Graphics.lua"
        },
        {
            name = "光影",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/Shader.lua"
        },
        {
            name = "通用自瞄",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/Zimiao.lua"
        },
        {
            name = "IY5.5.9(指令挂)",
            link = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
        },
        {
            name = "Dex",
            link = "https://cdn.wearedevs.net/scripts/Dex%20Explorer.txt"
        },
        {
            name = "DexDark",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/DexDark.lua"
        },
        {
            name = "OldMSPaint",
            link = "https://raw.githubusercontent.com/notpoiu/mspaint/main/main.lua"
        },
        {
            name = "Doors变身脚本",
            link = "https://raw.githubusercontent.com/ChronoAccelerator/Public-Scripts/main/Morphing/MorphScript.lua"
        },
        {
            name = "Doors扫描器",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/DoorsNVC3000.lua"
        },
        {
            name = "Doors剪刀",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/shears_done.lua"
        },
        {
            name = "Doors紫色手电筒",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/PurpleFlashlightScript.lua"
        },
        {
            name = "Doors巧克力罐",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/ChocolateBar.lua"
        },
        {
            name = "通用ESP",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/ESP.lua"
        },
        {
            name = "冬凌中心",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/DongLingLobby.lua"
        },
        {
            name = "玩家控制",
            link = "https://raw.atomgit.com/Furrycalin/ScriptStorage/raw/main/PlayerControl.lua"
        },
        {
            name = "吃掉世界",
            link = "https://raw.githubusercontent.com/AppleScript001/Eat_World_Simulator/main/README.md"
        },
        {
            name = "收养我吧",
            link = "https://raw.githubusercontent.com/lf4d7/daphie/main/ame.lua"
        },
        {
            name = "动画中心",
            link = "https://raw.githubusercontent.com/GamingScripter/Animation-Hub/main/Animation%20Gui"
        },
        {
            name = "阿尔宙斯",
            link = "https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20X%20V3"
        },
        {
            name = "VChine V2",
            link = "https://pastebin.com/raw/SuDKzFKD"
        }
    }
}

local function rejoinCurrentGame()
    local placeId1 = game.PlaceId          -- 当前游戏的地图ID
    local jobId1 = game.JobId              -- 当前游戏服务器的唯一ID

    if jobId1 and jobId1 ~= "" then
        -- 传送到同一实例
        TeleportService:TeleportToPlaceInstance(placeId1, jobId1, player)
    else
        -- 如果没有 JobId（极少情况），则退而求其次使用普通传送（可能随机分配到其他服务器）
        warn("无法获取 JobId，将使用普通传送，可能不会回到同一个房间。")
        TeleportService:Teleport(placeId1, player)
    end
end

-- 切换为白天
local function setDay()
    for property, value in pairs(data.basicdata.otherdata.daySettings) do
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(Lighting, tweenInfo, { [property] = value })
        tween:Play()
    end
end

-- 切换为黑夜
local function setNight()
    for property, value in pairs(data.basicdata.otherdata.nightSettings) do
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(Lighting, tweenInfo, { [property] = value })
        tween:Play()
    end
end

--=============================================================================================

local ChronixUI = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/ChronixUI%20Lib.lua"))()

local mainWindow = ChronixUI:CreateWindow({
    Name = "ChronixHubv3",
    Size = UDim2.new(0, 680, 0, 420)
})

local basicTab = mainWindow:CreateTab({ Name = "基础设置" })

basicTab:AddTitle("基础数据修改")

basicTab:AddSlider({
    Label = "玩家移速",
    Min = 0, Max = 1000, Default = data.basicdata.player.speed,
    Callback = function(v) LocalPlayer.Character.Humanoid.WalkSpeed = v; data.basicdata.player.speed = v end
})

basicTab:AddToggle({
    Label = "锁定玩家移速",
    Default = false,
    Callback = function(v) data.basicdata.player.islockspeed = v end
})

basicTab:AddSlider({
    Label = "跳跃力量",
    Min = 0, Max = 100, Default = data.basicdata.player.jump,
    Callback = function(v) LocalPlayer.Character.Humanoid.JumpPower = v; data.basicdata.player.jump = v end
})

basicTab:AddToggle({
    Label = "锁定跳跃力量",
    Default = false,
    Callback = function(v) data.basicdata.player.islockjump = v end
})

basicTab:AddSlider({
    Label = "最大血量",
    Min = 0, Max = 1000, Default = data.basicdata.player.maxhealth,
    Callback = function(v) LocalPlayer.Character.Humanoid.MaxHealth = v; data.basicdata.player.maxhealth = v end
})

basicTab:AddToggle({
    Label = "锁定最大血量",
    Default = false,
    Callback = function(v) data.basicdata.player.islockmaxhealth = v end
})

basicTab:AddSlider({
    Label = "当前血量",
    Min = 0, Max = 1000, Default = data.basicdata.player.health,
    Callback = function(v) LocalPlayer.Character.Humanoid.Health = v; data.basicdata.player.health = v end
})

basicTab:AddToggle({
    Label = "锁定当前血量",
    Default = false,
    Callback = function(v) data.basicdata.player.islockhealth = v end
})

basicTab:AddSlider({
    Label = "世界重力",
    Min = 0, Max = 1000, Default = data.basicdata.player.gravity,
    Callback = function(v) LocalPlayer.Character.Humanoid.Gravity = v; data.basicdata.player.gravity = v end
})

basicTab:AddToggle({
    Label = "锁定世界重力",
    Default = false,
    Callback = function(v) data.basicdata.player.islockgravity = v end
})

local ToolsTab = mainWindow:CreateTab({ Name = "工具" })

ToolsTab:AddTitle("各种实用工具")

ToolsTab:AddButton({ Text = "回满血", Callback = function() LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth end })

ToolsTab:AddButton({ Text = "自杀", Callback = function() LocalPlayer.Character.Humanoid.Health = 0 end })

ToolsTab:AddButton({ Text = "获得点击传送工具", Callback = function() mouse = game.Players.LocalPlayer:GetMouse() tool = Instance.new("Tool") tool.RequiresHandle = false tool.Name = "手持点击传送" tool.Activated:connect(function() local pos = mouse.Hit+Vector3.new(0,2.5,0) pos = CFrame.new(pos.X,pos.Y,pos.Z) game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = pos end) tool.Parent = game.Players.LocalPlayer.Backpack end })

ToolsTab:AddToggle({
    Label = "TPWalk",
    Default = false,
    Callback = function(v) tpWalk:Enabled(v) end
})

ToolsTab:AddToggle({
    Label = "鼠标解锁",
    Default = false,
    Callback = function(v)
        if v then
            MouseUnlockModule.Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按下K+L组合键开关解锁鼠标", Type = "success", Duration = 5 })
        else
            MouseUnlockModule.Disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "望远镜",
    Default = false,
    Callback = function(v)
        if v then
            data.basicdata.releasetools.zoom:Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按住C放大", Type = "success", Duration = 5 })
        else
            data.basicdata.releasetools.zoom:Disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "隐身",
    Default = false,
    Callback = function(v)
        if v then
            PlayerVisibleModule.enable()
        else
            PlayerVisibleModule.disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "落地特效",
    Default = false,
    Callback = function(v)
        if v then
            LandingEffect.enable()
        else
            LandingEffect.disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "夜视",
    Default = false,
    Callback = function(v)
        if v then
            game.Lighting.Ambient = Color3.new(1, 1, 1)
        else
            game.Lighting.Ambient = Color3.new(0, 0, 0)
        end
    end
})

ToolsTab:AddToggle({
    Label = "随身灯笼",
    Default = false,
    Callback = function(v) data.basicdata.releasetools.Lantern.enable = v end
})

ToolsTab:AddToggle({
    Label = "超级光明",
    Default = false,
    Callback = function(v) data.basicdata.releasetools.SuperLighter.enable = v end
})

ToolsTab:AddToggle({
    Label = "灵魂出窍",
    Default = false,
    Callback = function(v) FreecamModule.freecamenable = v end
})

ToolsTab:AddToggle({
    Label = "平移",
    Default = false,
    Callback = function(v)
        if v then
            movementModule.Enable()
            ChronixUI:Notify({ Title = "提示", Content = "按下↑↓←→键进行平移", Type = "success", Duration = 5 })
        else
            movementModule.Disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "穿墙",
    Default = false,
    Callback = function(v)
        data.basicdata.releasetools.noclip = v
        Stepped = game:GetService("RunService").Stepped:Connect(function()
            if not data.basicdata.releasetools.noclip == false then
                for a, b in pairs(Workspace:GetChildren()) do
                    if b.Name == Players.LocalPlayer.Name then
                        for i, v in pairs(Workspace[Players.LocalPlayer.Name]:GetChildren()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end end end end
            else
                for a, b in pairs(Workspace:GetChildren()) do
                    if b.Name == Players.LocalPlayer.Name then
                        for i, v in pairs(Workspace[Players.LocalPlayer.Name]:GetChildren()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = true
                            end end end end
            Stepped:Disconnect()
            end
        end)
    end
})

ToolsTab:AddToggle({
    Label = "连跳",
    Default = false,
    Callback = function(v)
        data.basicdata.releasetools.infjump = v
        JR = game:GetService("UserInputService").JumpRequest:Connect(function()
            if not data.basicdata.releasetools.infjump then
                JR:Disconnect()
            end
            if data.basicdata.releasetools.infjump then
                local c = LocalPlayer.Character
                if c and c.Parent then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState("Jumping")
                    end
                end
            end
        end)
    end
})

ToolsTab:AddToggle({
    Label = "玩家透视",
    Default = false,
    Callback = function(v)
        if v then
            PlayerESP.enable()
        else
            PlayerESP.disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "旁观模式",
    Default = false,
    Callback = function(v)
        if v then
            SpectatorModule.start()
        else
            SpectatorModule.close()
        end
    end
})

ToolsTab:AddToggle({
    Label = "防击倒",
    Default = false,
    Callback = function(v) data.basicdata.releasetools.antifall = v end
})

ToolsTab:AddToggle({
    Label = "晕厥康复",
    Default = false,
    Callback = function(v)
        if v then
            StandRecovery:enableDetection()
        else
            StandRecovery:disableDetection()
        end
    end
})

ToolsTab:AddToggle({
    Label = "防甩飞",
    Default = false,
    Callback = function(v)
        if v then
            FlingDetector.enable()
        else
            FlingDetector.disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "防甩飞",
    Default = false,
    Callback = function(v)
        if v then
            FlingDetector.enable()
        else
            FlingDetector.disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "反物理劫持",
    Default = false,
    Callback = function(v)
        if v then
            AntiVoidModule.enable()
        else
            AntiVoidModule.disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "防死亡",
    Default = false,
    Callback = function(v)
        if v then
            AntiVoidModule.enable()
        else
            AntiVoidModule.disable()
        end
    end
})

ToolsTab:AddToggle({
    Label = "聊天偷听",
    Default = false,
    Callback = function(v)
        if v then
            ChatSpy.enable()
        else
            ChatSpy.disable()
        end
    end
})

ToolsTab:AddButton({ Text = "重新加入当前房间(服务器)", Callback = function() rejoinCurrentGame() end })
ToolsTab:AddButton({ Text = "切换时间为白天", Callback = function() setDay() end })
ToolsTab:AddButton({ Text = "切换时间为黑夜", Callback = function() setNight() end })
ToolsTab:AddButton({ Text = "优化世界光效", Callback = function() loadstring(game:HttpGet("https://raw.gitcode.com/Furrycalin/ChronixHub/raw/main/modules/WorldShader.lua"))() end })
ToolsTab:AddButton({ Text = "打印眼前实例名到控制台", Callback = function()
    -- 使用已有的 player 和 character，从 character 获取 head
    local head = character:WaitForChild("Head")

    -- 混淆变量名
    local _p = RaycastParams.new()
    _p.FilterDescendantsInstances = {character}
    _p.FilterType = Enum.RaycastFilterType.Blacklist
    
    local _o = head.Position
    local _d = head.CFrame.LookVector * 100
    
    local _r = workspace:Raycast(_o, _d, _p)
    
    if _r then
        local _h = _r.Instance
        print("面前实例名称：", _h.Name)
        print("完整路径：", _h:GetFullName())
    else
        print("面前没有检测到实例")
    end
end })
ToolsTab:AddButton({ Text = "打印当前玩家坐标到控制台", Callback = function()
    -- 防止跟现有的重复导致冲突
    local rootPart1 = character:WaitForChild("HumanoidRootPart")
    local position1 = rootPart1.Position
    print(string.format("玩家坐标: (%.2f, %.2f, %.2f)", position1.X, position1.Y, position1.Z))
end })

local scripthubTab = mainWindow:CreateTab({ Name = "脚本中心" })
scripthubTab:AddTitle("各种脚本")
local function addscripts(name, link)
    scripthubTab:AddButton({ Text = name, Callback = function()
        ChronixUI:Notify({ Title = "提示", Content = name .. "正在启动，请耐心等待。", Type = "success", Duration = 5 })
        loadstring(game:HttpGet(link))()
        ChronixUI:Notify({ Title = "提示", Content = name .. "启动成功。", Type = "success", Duration = 5 })
    end })
end
for index, scriptInfo in ipairs(data.scriptlist) do
    addscripts(scriptInfo.name, scriptInfo.link)
end

local playerteleporterTab = mainWindow:CreateTab({ Name = "玩家传送" })


local infoTab = mainWindow:CreateTab({ Name = "信息" })
infoTab:AddParagraph({
    Title = "关于 Chronix UI",
    Content = "Chronix UI v1.5\n\n一个完整的 OrionLib 风格 UI 框架\n支持所有常用控件\n\n功能列表:\n• 按钮\n• 下拉框\n• 滑块\n• 开关\n• 输入框\n• 按键绑定（带回调）\n• 颜色选择器\n• 段落文字\n• 分隔线\n\n按 RightShift 隐藏/显示菜单"
})

--======================================================================================

-- 监听状态变化
local hscc = humanoid.StateChanged:Connect(function(oldState, newState)
    if data.basicdata.releasetools.antifall then
        if newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) -- 强制恢复站立状态
            ChronixUI:Notify({ Title = "提示", Content = "检测到被击倒，已恢复站立状态", Type = "success", Duration = 5 })
        end
    end
end)

local gsr = game:GetService("RunService").Stepped:Connect(function()
    if data.basicdata.player.islockspeed then LocalPlayer.Character.Humanoid.WalkSpeed = data.basicdata.player.speed end
    if data.basicdata.player.islockjump then LocalPlayer.Character.Humanoid.JumpPower = data.basicdata.player.jump end
    if data.basicdata.player.islockmaxhealth then LocalPlayer.Character.Humanoid.MaxHealth = data.basicdata.player.maxhealth end
    if data.basicdata.player.islockhealth then LocalPlayer.Character.Humanoid.Health = data.basicdata.player.health end
    if data.basicdata.player.islockgravity then game.Workspace.Gravity = data.basicdata.player.gravity end
    if data.basicdata.releasetools.antidead then Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end
end)

--======================================================================================

SystemNotification.Rainbow("ChronixHubV2 Already Success Loaded!\nWelcome " .. data.basicdata.player.displayname)
ChronixUI:Notify({ Title = "提示", Content = "ChronixHub 启动成功。", Type = "success", Duration = 5 })

local function unloadchronixhub()
    SystemNotification.UnloadedGradient("ChronixHubv2 Already Unload!")
    print("ChronixHubv2 已卸载。")
    _G.ChronixHubisLoaded = false
    data.basicdata.releasetools.noclip = false
    data.basicdata.releasetools.infjump = false
    PlayerVisibleModule.unload()
    NameTagModule.unload()
    LandingEffect.unload()
    FreecamModule.unload()
    SpectatorModule.unload()
    PlayerLightModule:unload()
    HighlightModule.unload()
    StandRecovery:unload()
    _G.DeathBallScript:Unload()
    data.basicdata.releasetools.zoom:Unload()
    FlingDetector.unload()
    PlayerESP.unload()
    MovableHighlighter_NM.unloadAll()
    AntiVoidModule.unload()
    ChatSpy.unload()
    -- musicbox:Stop()
    -- musicbox:Destroy()
    -- chatcheck:Disconnect()
    -- offce:Disconnect()
    -- al:Disconnect()
    -- ds:Disconnect()
    -- Stepped6:Disconnect()
    cc:Disconnect()
    gsr:Disconnect()
    hscc:Disconnect()
    -- toggleFeature(false)
    -- mainFrame:Destroy()
    script:Destroy()
end

mainWindow:OnClose(function()
    unloadChronixHub()
end)