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

local ChronixUI = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/ChronixUI%20Lib.lua"))()
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
local AirWalk = loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/AirWalk.lua"))()

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

-- 获取游戏名（修复：返回字符串而不是 table）
local function getGameName(universeId)
    local url = "https://games.roblox.com/v1/games?universeIds=" .. universeId
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        if data.data and #data.data > 0 then
            local gameInfo = data.data[1]
            -- 返回游戏名称字符串
            return gameInfo.name or "未知游戏"
        else
            warn("未找到游戏信息")
            print(data)
            getGameNameNotSuccess = true
            return "未知游戏"
        end
    else
        warn("获取游戏名失败:", response)
        getGameNameNotSuccess = true
        return "未知游戏"
    end
end

-- 定义 displayName（后面要用）
local displayName = LocalPlayer.DisplayName

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
            gameInfo = getGameName(game.GameId), -- 现在是字符串

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
            executecode = "",
            nightvision = false,
        },
        otherdata = {
            musicbox = Instance.new("Sound"),
            testSound = Instance.new("Sound"),
            daySettings = {
                ClockTime = 14, -- 白天时间（14:00）
                GeographicLatitude = 41.73, -- 纬度（影响太阳高度）
            },
            nightSettings = {
                ClockTime = 2, -- 黑夜时间（02:00）
                GeographicLatitude = 41.73, -- 纬度
            },
            musicData = {
                isPlay = false,
                isPause = false,
                PlayLocation = 0,
                currentId = "142376088",
                musicIds = {
                    "142376088", "1846368080", "5409360995", "1848354536", "1841647093", 
                    "1837879082", "1837768517", "9041745502", "9048375035", "1840684208", 
                    "118939739460633", "1846999567", "1840434670", "9046863253", "1848028342", 
                    "1843404009", "1845756489", "1846862303", "1841998846", "122600689240179", 
                    "1837101327", "125793633964645", "1846088038", "1845554017", "1838635121", 
                    "16190757458", "1846442964", "1839703786", "1839444520", "1838028467", 
                    "7028518546", "121336636707861", "87540733242308", "1838667168", "1838667680", 
                    "1845179120", "136598811626191", "79451196298919", "1837769001", "103086632976213", 
                    "120817494107898", "5410084188", "104483584177040", "7024220835", "1842976958", 
                    "7023635858", "1835782117", "7029024726", "7029017448", "5410085694", 
                    "1843471292", "7029005367", "131020134622685", "7024340270", "1836057733", 
                    "9047104336", "9047104411", "1843324336", "1845215540"
                }
            },
            audioData = {
                enable = false,
                threshold = 50,
                currentSelectedId = nil,
                isTesting = false,
                testSound = nil,
                audioListItems = {},
                audioListContainer = nil,
                lastScanTime = 0,
                scanConnection = nil,
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
    },
    Supported_Games = {
        { gameid = 2162087722, name = "兽化项目" },
        { gameid = 6508759464, name = "格蕾丝" },
        { gameid = 5166944221, name = "死亡球" },
        { gameid = 9161109257, name = "小屋角色扮演" },
        { gameid = 6352299542, name = "妄想办公室" },
        { gameid = 972475338,  name = "南极探险队" },
        { gameid = 6996099240, name = "噩梦之行" },
        { gameid = 5265348926, name = "西部森林" },
        { gameid = 5429450445, name = "警笛头:遗产" },
    },
    othergamedata = {
        west_wood = {
            monster = NameTagModule.new("WendigoAI", "模糊", 20, true, "怪物")
        },
        sirenhead_legacy = {
            cratemodule = HighlightModule.new("crate", "other", "item"),
            cratenametagmodule = NameTagModule.new("crate", "模糊", 20, true, "盒子"),
            berrymodule = HighlightModule.new("berry", "other", "item"),
            berrynametagmodule = NameTagModule.new("berry", "模糊", 20, true, "浆果"),
        },
        nightmare_run = {
            monster = MovableHighlighter_NM.new(),
            HLCheese = HighlightModule.new("Cheese", "other", "item"),
        },
        project_transfur = {
            bot = HighlightModule.new("Bot", "other", "item"),
            botnt = NameTagModule.new("Bot", "模糊", 20, true, "Bot兽"),
            smallsafe = HighlightModule.new("__BasicSmallSafe", "other", "item"),
            smallsafent = NameTagModule.new("__BasicSmallSafe", "模糊", 20, true, "小保险箱"),
            largesafe = HighlightModule.new("__BasicLargeSafe", "other", "item"),
            largesafent = NameTagModule.new("__BasicLargeSafe", "模糊", 20, true, "大保险箱"),
            goldensafe = HighlightModule.new("__LargeGoldenSafe", "other", "item"),
            goldensafent = NameTagModule.new("__LargeGoldenSafe", "模糊", 20, true, "金保险箱"),
            crate = HighlightModule.new("Surplus Crate", "other", "item"),
            cratent = NameTagModule.new("Surplus Crate", "模糊", 20, true, "武器盒"),
            sd = HighlightModule.new("SupplyDrop", "other", "item"),
            sdnt = NameTagModule.new("SupplyDrop", "模糊", 20, true, "空投"),
        },
        delesions_office = {
            entitywarning = false,
            tipotherplayer = false,
            auto013 = false,
            entitys = {
                NormalEntity = { name = "EN-001", tip = "立刻躲在柜子中！" },
                NormalEntityType2 = { name = "EN-001-02", tip = "立刻躲在柜子中！" },
                SnakeEntity = { name = "EN-002", tip = "多待在柜子里一会！" },
                TrainEntity = { name = "EN-003", tip = "不要犹豫，立刻躲起来！" },
                LateEntity = { name = "EN-004", tip = "稍后躲在柜子中！" },
                ReboundingEntity = { name = "EN-005", tip = "把握住进柜子的时间，他会来回冲！" },
                PeaceEntity = { name = "EN-006", tip = "千万不要躲在柜子中！" },
                VisionEntity = { name = "EN-007", tip = "不要躲在墙壁后！" },
                FocusEntity = { name = "EN-008", tip = "躲在柜子中，记住钥匙的位置！" },
                ShadowEntity = { name = "EN-011", tip = "他在黑暗中，不要看他！" },
                GhostEntity = { name = "EN-012", tip = "注意他的规则！" },
                UnknownEntity = { name = "EN-013", tip = "快点输入 'staycalmstayfocused'"},
                ChaserEntity = { name = "EN-015", tip = "快跑！" },
                DelmonEntity = { name = "EN-0??", tip = "暂未收录该数据" },
                DoorcamperEntity = { name = "EN-017", tip = "多注意门后！" }
            }
        },
        grace = {
            autolever = false,
            deleteentity = false,
        },
    }
}
data.basicdata.otherdata.musicbox.Volume = 0.5
data.basicdata.otherdata.musicbox.Looped = false
data.basicdata.otherdata.musicbox.Parent = game:GetService("SoundService")
data.basicdata.otherdata.testSound.Volume = 0.5
data.basicdata.otherdata.testSound.Parent = game:GetService("SoundService")

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

local function TeleportTo(x, y, z)
	-- 验证输入是否为数字
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		warn("[Teleport] 请传入三个数字：TeleportTo(x, y, z)")
		return false
	end

	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("[Teleport] 未找到 HumanoidRootPart")
		return false
	end

	-- 执行传送
	rootPart.CFrame = CFrame.new(Vector3.new(x, y, z))

    ChronixUI:Notify({ Title = "提示", Content = string.format("✅ 已传送到 (%.1f, %.1f, %.1f)", x, y, z), Type = "success", Duration = 5 })
	return true
end

local function TeleportToPresent(presentNumber)
	if type(presentNumber) ~= "number" then
		return false
	end

	local mainModel = Workspace:FindFirstChild("XMas_PresentHunt%") 
		or Workspace:FindFirstChild("XMas_PresentHunt")
	if not mainModel then
		return false
	end

	local presents = mainModel:FindFirstChild("Presents")
	if not presents then
		return false
	end

	local gift = presents:FindFirstChild(tostring(presentNumber))
	if not gift or not gift:IsA("Model") then
		return false
	end

	-- 获取礼物位置（使用 GetPivot 获取整体中心）
	local giftCFrame = gift:GetPivot()
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local targetCFrame = CFrame.new(giftCFrame.Position + Vector3.new(0, 3, 0))
	rootPart.CFrame = targetCFrame

    ChronixUI:Notify({ Title = "提示", Content = string.format("✅ 已传送到礼物 #%d！", presentNumber), Type = "success", Duration = 5 })
	return true
end

-- 检测新实例并匹配预定义列表
local function detectEntity(instance)
    if instance:IsA("BasePart") then
        for entityName, entityInfo in pairs(data.othergamedata.delesions_office.entitys) do
            if instance.Name == entityName then
                if data.othergamedata.delesions_office.entitywarning then
                    ChronixUI:Notify({ Title = "！警告！", Content = "实体" .. entityInfo.name .. "已生成！\n" .. entityInfo.tip, Type = "warning", Duration = 5 })
                    if data.othergamedata.delesions_office.tipotherplayer then ChatControl:chat("警告！实体" .. entityInfo.name .. "已生成！" .. entityInfo.tip) end
                end
                if data.othergamedata.delesions_office.auto013 then
                    if instance.Name == "UnknownEntity" then
                        ChronixUI:Notify({ Title = "自动EN-013", Content = "正在自动键入'staycalmstayfocused'...", Type = "warning", Duration = 5 })
                        wait(2)
                        local str = "staycalmstayfocused"
                        for i = 1, #str do
                            local char = string.sub(str, i, i) -- 提取第 i 个字符
                            VirtualInputManager:SendKeyEvent(true, char, false, game)
                            wait(0.2)
                        end
                    end
                end
                break
            end
        end
    end
end

--=============================================================================================

local isMobile = (game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").MouseEnabled)
local windowSize = isMobile and UDim2.new(0, 476, 0, 294) or UDim2.new(0, 680, 0, 420)

local mainWindow = ChronixUI:CreateWindow({
    Name = "ChronixHubv3",
    Size = windowSize
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
        data.basicdata.releasetools.nightvision = v
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
    Label = "空中移动",
    Default = false,
    Callback = function(v)
        if v then
            AirWalk.enable()
        else
            AirWalk.disable()
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
    Callback = function(v) data.basicdata.releasetools.antidead = v end
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
playerteleporterTab:AddTitle("玩家列表")
playerteleporterTab:AddDivider()
local playerButtons = {}
local function updatePlayerList()
    for playerName, button in pairs(playerButtons) do
        if button and button.Destroy then
            button:Destroy()
        end
    end
    playerButtons = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local button = playerteleporterTab:AddButton({
                Text = player.DisplayName .. " (" .. player.Name .. ")",
                Callback = function()
                    local character = LocalPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        local targetCharacter = player.Character
                        if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                            character:SetPrimaryPartCFrame(CFrame.new(targetCharacter.HumanoidRootPart.Position))
                            ChronixUI:Notify({
                                Title = "传送成功",
                                Content = "已传送到 " .. player.DisplayName,
                                Type = "success",
                                Duration = 2
                            })
                        else
                            ChronixUI:Notify({
                                Title = "传送失败",
                                Content = "目标玩家角色不存在",
                                Type = "error",
                                Duration = 2
                            })
                        end
                    else
                        ChronixUI:Notify({
                            Title = "传送失败",
                            Content = "无法获取你的角色",
                            Type = "error",
                            Duration = 2
                        })
                    end
                end
            })
            playerButtons[player.Name] = button
        end
    end
end
updatePlayerList()


local waypointTab = mainWindow:CreateTab({ Name = "路径点传送" })
local waypointsData = {}
local waypointUIElements = {}
local function clearWaypointList()
    for _, elements in ipairs(waypointUIElements) do
        for _, element in ipairs(elements) do
            if element and element.Destroy then
                element:Destroy()
            end
        end
    end
    waypointUIElements = {}
end
local function refreshWaypointList()
    clearWaypointList()

    for _, waypoint in ipairs(waypointsData) do
        local elements = {}

        -- 添加分隔线（除了第一个）
        if waypoint.id > 1 then
            local divider = waypointTab:AddDivider()
            table.insert(elements, divider)
        end

        -- 标题（确保 id 是数字，note 是字符串）
        local idNum = tonumber(waypoint.id) or 0
        local noteStr = type(waypoint.note) == "string" and waypoint.note or tostring(waypoint.note)
        local titleText = string.format("📍 路径点 #%d", idNum)
        if noteStr ~= "" then
            titleText = titleText .. " - " .. noteStr
        end
        local title = waypointTab:AddTitle(titleText)
        table.insert(elements, title)

        -- 坐标显示（确保 position 是 Vector3，并提取数字）
        local pos = waypoint.position
        local x, y, z = pos and pos.X or 0, pos and pos.Y or 0, pos and pos.Z or 0
        local coordText = string.format("坐标: X: %.1f, Y: %.1f, Z: %.1f", x, y, z)
        local coordLabel = waypointTab:AddLabel(coordText)
        table.insert(elements, coordLabel)

        -- 备注输入框
        local noteInput = waypointTab:AddInput({
            Label = "备注",
            Placeholder = "输入备注信息...",
            Callback = function(text)
                waypoint.note = text or ""
                refreshWaypointList()
            end
        })
        -- 设置初始备注文本
        local textBox = noteInput:FindFirstChildOfClass("TextBox")
        if textBox then
            textBox.Text = noteStr
        end
        table.insert(elements, noteInput)

        -- 传送按钮
        local teleportBtn = waypointTab:AddButton({
            Text = "🚀 传送到此路径点",
            Callback = function()
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char:SetPrimaryPartCFrame(CFrame.new(pos))
                    ChronixUI:Notify({
                        Title = "传送成功",
                        Content = string.format("已传送到 %s", noteStr ~= "" and noteStr or "路径点"),
                        Type = "success",
                        Duration = 2
                    })
                else
                    ChronixUI:Notify({
                        Title = "传送失败",
                        Content = "无法获取你的角色",
                        Type = "error",
                        Duration = 2
                    })
                end
            end
        })
        table.insert(elements, teleportBtn)

        -- 删除按钮
        local deleteBtn = waypointTab:AddButton({
            Text = "🗑️ 删除此路径点",
            Callback = function()
                -- 从数据中删除
                for i, data in ipairs(waypointsData) do
                    if data.id == waypoint.id then
                        table.remove(waypointsData, i)
                        break
                    end
                end
                -- 重新编号
                for i, data in ipairs(waypointsData) do
                    data.id = i
                end
                -- 刷新显示
                refreshWaypointList()
                ChronixUI:Notify({
                    Title = "已删除",
                    Content = "路径点已移除",
                    Type = "info",
                    Duration = 1
                })
            end
        })
        table.insert(elements, deleteBtn)

        table.insert(waypointUIElements, elements)
    end
end
local function addWaypoint(position, note)
    -- 确保 position 是 Vector3
    local pos = position
    if type(pos) ~= "Vector3" then
        pos = Vector3.new(pos.X or 0, pos.Y or 0, pos.Z or 0)
    end
    local waypoint = {
        id = #waypointsData + 1,
        position = pos,
        note = note or ""
    }
    table.insert(waypointsData, waypoint)
    refreshWaypointList()
end
waypointTab:AddTitle("路径点管理")
waypointTab:AddDivider()
waypointTab:AddLabel("点击下方按钮保存当前位置作为路径点")
waypointTab:AddButton({
    Text = "➕ 添加当前路径点",
    Callback = function()
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local position = character.HumanoidRootPart.Position
            addWaypoint(position)
            ChronixUI:Notify({
                Title = "路径点已添加",
                Content = string.format("位置: (%.1f, %.1f, %.1f)", position.X, position.Y, position.Z),
                Type = "success",
                Duration = 2
            })
        else
            ChronixUI:Notify({
                Title = "添加失败",
                Content = "无法获取当前位置",
                Type = "error",
                Duration = 2
            })
        end
    end
})
waypointTab:AddDivider()
waypointTab:AddTitle("已保存的路径点")
waypointTab:AddDivider()


local musicTab = mainWindow:CreateTab({ Name = "音乐播放器" })
musicTab:AddTitle("音乐播放器")
musicTab:AddDivider()

-- 添加预设ID选择下拉框
musicTab:AddLabel("选择预设音乐 (rbxassetid)")
local musicDropdown = musicTab:AddDropdown({
    Label = "预设音乐ID",
    Options = data.basicdata.otherdata.musicData.musicIds,
    Default = data.basicdata.otherdata.musicData.currentId,
    Callback = function(selected)
        data.basicdata.otherdata.musicData.currentId = selected
        -- 同时更新输入框的文本
        if customIdInput then
            local textBox = customIdInput:FindFirstChildOfClass("TextBox")
            if textBox then
                textBox.Text = selected
            end
        end
    end
})

musicTab:AddDivider()

-- 添加自定义ID输入框
musicTab:AddLabel("或手动输入自定义ID")
local customIdInput = musicTab:AddInput({
    Label = "自定义音乐ID",
    Placeholder = "输入 rbxassetid，例如: 142376088",
    Callback = function(text)
        -- 当用户输入时，更新当前ID
        if text and text ~= "" then
            data.basicdata.otherdata.musicData.currentId = text
        end
    end
})
-- 设置初始值
local textBox = customIdInput:FindFirstChildOfClass("TextBox")
if textBox then
    textBox.Text = data.basicdata.otherdata.musicData.currentId
end

musicTab:AddDivider()
musicTab:AddLabel("播放控制")

-- 先声明变量占位
local playStopButton = nil
local pauseResumeButton = nil

-- 先创建播放按钮（显示在上方）
playStopButton = musicTab:AddButton({
    Text = "▶️ 播放",
    Callback = function()
        if data.basicdata.otherdata.musicData.isPlay then
            -- 停止播放
            data.basicdata.otherdata.musicbox:Stop()
            data.basicdata.otherdata.musicData.isPlay = false
            data.basicdata.otherdata.musicData.isPause = false
            playStopButton.Text = "▶️ 播放"
            if pauseResumeButton then
                pauseResumeButton.Text = "⏸️ 暂停"
            end
            ChronixUI:Notify({
                Title = "已停止",
                Content = "音乐播放已停止",
                Type = "info",
                Duration = 2
            })
        else
            -- 播放音乐
            local soundId = "rbxassetid://" .. data.basicdata.otherdata.musicData.currentId
            data.basicdata.otherdata.musicbox.SoundId = soundId
            
            local success, productInfo = pcall(function()
                return MarketplaceService:GetProductInfo(tonumber(data.basicdata.otherdata.musicData.currentId))
            end)
            
            if success and productInfo then
                data.basicdata.otherdata.musicbox:Play()
                data.basicdata.otherdata.musicData.isPlay = true
                data.basicdata.otherdata.musicData.isPause = false
                playStopButton.Text = "⏹️ 停止"
                if pauseResumeButton then
                    pauseResumeButton.Text = "⏸️ 暂停"
                end
                
                ChronixUI:Notify({
                    Title = "正在播放",
                    Content = productInfo.Name .. "\n" .. (productInfo.Description or ""),
                    Type = "success",
                    Duration = 3
                })
            else
                ChronixUI:Notify({
                    Title = "播放失败",
                    Content = data.basicdata.otherdata.musicData.currentId .. "\n不是一个有效的rbxassetid",
                    Type = "error",
                    Duration = 3
                })
                data.basicdata.otherdata.musicData.isPlay = false
            end
        end
    end
})

-- 再创建暂停按钮（显示在下方）
pauseResumeButton = musicTab:AddButton({
    Text = "⏸️ 暂停",
    Callback = function()
        if not data.basicdata.otherdata.musicData.isPlay then
            ChronixUI:Notify({
                Title = "无法操作",
                Content = "请先播放音乐",
                Type = "warning",
                Duration = 2
            })
            return
        end
        
        if data.basicdata.otherdata.musicData.isPause then
            -- 继续播放
            data.basicdata.otherdata.musicbox.TimePosition = data.basicdata.otherdata.musicData.PlayLocation
            data.basicdata.otherdata.musicbox:Play()
            data.basicdata.otherdata.musicData.isPause = false
            pauseResumeButton.Text = "⏸️ 暂停"
            ChronixUI:Notify({
                Title = "继续播放",
                Content = "音乐已恢复",
                Type = "info",
                Duration = 1
            })
        else
            -- 暂停播放
            data.basicdata.otherdata.musicData.PlayLocation = data.basicdata.otherdata.musicbox.TimePosition
            data.basicdata.otherdata.musicbox:Stop()
            data.basicdata.otherdata.musicData.isPause = true
            pauseResumeButton.Text = "▶️ 继续"
            ChronixUI:Notify({
                Title = "已暂停",
                Content = "音乐已暂停",
                Type = "info",
                Duration = 1
            })
        end
    end
})

-- 循环播放按钮
loopButton = musicTab:AddButton({
    Text = "🔄 循环播放",
    Callback = function()
        data.basicdata.otherdata.musicbox.Looped = not data.basicdata.otherdata.musicbox.Looped
        loopButton.Text = data.basicdata.otherdata.musicbox.Looped and "🔁 不循环播放" or "🔄 循环播放"
        ChronixUI:Notify({
            Title = "设置已更改",
            Content = data.basicdata.otherdata.musicbox.Looped and "已开启循环播放" or "已关闭循环播放",
            Type = "info",
            Duration = 1
        })
    end
})
musicTab:AddDivider()
musicTab:AddLabel("音量控制")
local volumeLabel = musicTab:AddLabel(string.format("当前音量: %.0f%%", data.basicdata.otherdata.musicbox.Volume * 100))
musicTab:AddButton({
    Text = "🔊 音量 +",
    Callback = function()
        if data.basicdata.otherdata.musicbox.Volume < 1 then
            data.basicdata.otherdata.musicbox.Volume = math.min(1, data.basicdata.otherdata.musicbox.Volume + 0.1)
            volumeLabel.Text = string.format("当前音量: %.0f%%", data.basicdata.otherdata.musicbox.Volume * 100)
        end
    end
})
musicTab:AddButton({
    Text = "🔉 音量 -",
    Callback = function()
        if data.basicdata.otherdata.musicbox.Volume > 0 then
            data.basicdata.otherdata.musicbox.Volume = math.max(0, data.basicdata.otherdata.musicbox.Volume - 0.1)
            volumeLabel.Text = string.format("当前音量: %.0f%%", data.basicdata.otherdata.musicbox.Volume * 100)
        end
    end
})
musicTab:AddDivider()
musicTab:AddLabel("音高控制")
local pitchLabel = musicTab:AddLabel(string.format("当前音高: %.1f", data.basicdata.otherdata.musicbox.Pitch))
musicTab:AddButton({
    Text = "🎵 音高 +",
    Callback = function()
        data.basicdata.otherdata.musicbox.Pitch = data.basicdata.otherdata.musicbox.Pitch + 0.1
        pitchLabel.Text = string.format("当前音高: %.1f", data.basicdata.otherdata.musicbox.Pitch)
    end
})
musicTab:AddButton({
    Text = "🎵 音高 -",
    Callback = function()
        if data.basicdata.otherdata.musicbox.Pitch > 0.1 then
            data.basicdata.otherdata.musicbox.Pitch = data.basicdata.otherdata.musicbox.Pitch - 0.1
            pitchLabel.Text = string.format("当前音高: %.1f", data.basicdata.otherdata.musicbox.Pitch)
        end
    end
})
musicTab:AddButton({
    Text = "🔄 重置音高",
    Callback = function()
        data.basicdata.otherdata.musicbox.Pitch = 1
        pitchLabel.Text = string.format("当前音高: %.1f", data.basicdata.otherdata.musicbox.Pitch)
    end
})
musicTab:AddDivider()
musicTab:AddLabel("💡 提示：可从下拉框选择预设音乐，或手动输入自定义ID")
musicTab:AddLabel("📝 自定义ID格式：纯数字，如 142376088")


local audioCheckerTab = mainWindow:CreateTab({ Name = "音频检查器" })
local selectedIdLabel = nil
local function getLoudSounds(threshold)
    local loudSounds = {}
    local allSounds = SoundService:GetDescendants()

    for _, sound in ipairs(allSounds) do
        if sound:IsA("Sound") and sound.IsPlaying then   -- 使用 IsPlaying 代替 PlaybackState
            local volumeDB = sound.Volume * 100
            if volumeDB >= threshold then
                table.insert(loudSounds, {
                    SoundId = sound.SoundId,
                    Name = sound.Name,
                    Volume = sound.Volume,
                    VolumeDB = volumeDB,
                    Parent = sound.Parent and sound.Parent.Name or "Unknown"
                })
            end
        end
    end

    return loudSounds
end
local function clearAudioList()
    for _, item in ipairs(data.basicdata.otherdata.audioData.audioListItems) do
        if item and item.Destroy then
            item:Destroy()
        end
    end
    data.basicdata.otherdata.audioData.audioListItems = {}
end
local function refreshAudioList()
    if not data.basicdata.otherdata.audioData.enable then return end
    
    clearAudioList()
    
    local loudSounds = getLoudSounds(data.basicdata.otherdata.audioData.threshold)
    
    if #loudSounds == 0 then
        local emptyLabel = audioCheckerTab:AddLabel("未检测到超过阈值的音频")
        table.insert(data.basicdata.otherdata.audioData.audioListItems, emptyLabel)
    else
        for _, soundInfo in ipairs(loudSounds) do
            local displayText = string.format("ID: %s | 音量: %.0f dB | 来源: %s", 
                soundInfo.SoundId:match("rbxassetid://(%d+)") or "未知",
                soundInfo.VolumeDB,
                soundInfo.Parent
            )
            
            local soundButton = audioCheckerTab:AddButton({
                Text = displayText,
                Callback = function()
                    local id = soundInfo.SoundId:match("rbxassetid://(%d+)")
                    if id then
                        data.basicdata.otherdata.audioData.currentSelectedId = id
                        if selectedIdLabel then selectedIdLabel.Text = "当前选中: " .. id end
                        ChronixUI:Notify({
                            Title = "已选中",
                            Content = "音频ID: " .. id,
                            Type = "info",
                            Duration = 2
                        })
                    end
                end
            })
            table.insert(data.basicdata.otherdata.audioData.audioListItems, soundButton)
        end
    end
end
local function startAudioScanning()
    if data.basicdata.otherdata.audioData.scanConnection then
        data.basicdata.otherdata.audioData.scanConnection:Disconnect()
        data.basicdata.otherdata.audioData.scanConnection = nil
    end
    
    if data.basicdata.otherdata.audioData.enable then
        refreshAudioList()
        
        data.basicdata.otherdata.audioData.scanConnection = RunService.Heartbeat:Connect(function()
            if not data.basicdata.otherdata.audioData.enable then
                if data.basicdata.otherdata.audioData.scanConnection then
                    data.basicdata.otherdata.audioData.scanConnection:Disconnect()
                    data.basicdata.otherdata.audioData.scanConnection = nil
                end
                return
            end
            
            local currentTime = tick()
            if currentTime - data.basicdata.otherdata.audioData.lastScanTime >= 1.0 then
                data.basicdata.otherdata.audioData.lastScanTime = currentTime
                refreshAudioList()
            end
        end)
    end
end
audioCheckerTab:AddTitle("音频检查器")
audioCheckerTab:AddLabel("筛选音量分贝 (0-100)")
local thresholdInput = audioCheckerTab:AddInput({
    Label = "音量阈值",
    Placeholder = "输入阈值，例如: 50",
    Callback = function(text)
        local num = tonumber(text)
        if num then
            data.basicdata.otherdata.audioData.threshold = math.clamp(num, 0, 100)
            if data.basicdata.otherdata.audioData.enable then
                refreshAudioList()
            end
        end
    end
})
local thresholdTextBox = thresholdInput:FindFirstChildOfClass("TextBox")
if thresholdTextBox then
    thresholdTextBox.Text = tostring(data.basicdata.otherdata.audioData.threshold)
end
audioCheckerTab:AddDivider()
audioCheckerTab:AddTitle("操作面板")
audioCheckerTab:AddToggle({
    Label = "开始检测音频",
    Default = false,
    Callback = function(v)
        data.basicdata.otherdata.audioData.enable = v
        if v then
            data.basicdata.otherdata.audioData.lastScanTime = tick()
            startAudioScanning()
            ChronixUI:Notify({
                Title = "已开启",
                Content = "开始检测游戏中播放的音频",
                Type = "success",
                Duration = 2
            })
        else
            if data.basicdata.otherdata.audioData.scanConnection then
                data.basicdata.otherdata.audioData.scanConnection:Disconnect()
                data.basicdata.otherdata.audioData.scanConnection = nil
            end
            clearAudioList()
            ChronixUI:Notify({
                Title = "已关闭",
                Content = "音频检测已停止",
                Type = "info",
                Duration = 2
            })
        end
    end
})
audioCheckerTab:AddDivider()
local selectedIdLabel = audioCheckerTab:AddLabel("当前选中: 无")
audioCheckerTab:AddButton({
    Text = "📋 复制选中ID到剪贴板",
    Callback = function()
        if data.basicdata.otherdata.audioData.currentSelectedId then
            setclipboard(data.basicdata.otherdata.audioData.currentSelectedId)
            ChronixUI:Notify({
                Title = "已复制",
                Content = data.basicdata.otherdata.audioData.currentSelectedId .. " 已复制到剪贴板",
                Type = "success",
                Duration = 2
            })
        else
            ChronixUI:Notify({
                Title = "未选中",
                Content = "请先点击音频列表中的项目",
                Type = "warning",
                Duration = 2
            })
        end
    end
})
audioCheckerTab:AddDivider()
audioCheckerTab:AddTitle("测试播放")
local testIdLabel = audioCheckerTab:AddLabel("测试ID: 未选择")
local testPlayButton = audioCheckerTab:AddButton({
    Text = "🎵 尝试播放",
    Callback = function()
        if not data.basicdata.otherdata.audioData.currentSelectedId then
            ChronixUI:Notify({
                Title = "无法播放",
                Content = "请先选中一个音频ID",
                Type = "warning",
                Duration = 2
            })
            return
        end
        
        if data.basicdata.otherdata.audioData.isTesting then
            data.basicdata.otherdata.testSound:Stop()
            data.basicdata.otherdata.audioData.isTesting = false
            testPlayButton.Text = "🎵 尝试播放"
            ChronixUI:Notify({
                Title = "已停止",
                Content = "测试播放已停止",
                Type = "info",
                Duration = 1
            })
        else
            local soundId = "rbxassetid://" .. data.basicdata.otherdata.audioData.currentSelectedId
            data.basicdata.otherdata.testSound.SoundId = soundId
            
            local success, productInfo = pcall(function()
                return MarketplaceService:GetProductInfo(tonumber(data.basicdata.otherdata.audioData.currentSelectedId))
            end)
            
            if success and productInfo then
                data.basicdata.otherdata.testSound:Play()
                data.basicdata.otherdata.audioData.isTesting = true
                testPlayButton.Text = "⏹️ 结束播放"
                testIdLabel.Text = "测试ID: " .. data.basicdata.otherdata.audioData.currentSelectedId
                
                ChronixUI:Notify({
                    Title = "正在播放",
                    Content = productInfo.Name,
                    Type = "success",
                    Duration = 2
                })
                
                data.basicdata.otherdata.testSound.Ended:Connect(function()
                    if data.basicdata.otherdata.audioData.isTesting then
                        data.basicdata.otherdata.audioData.isTesting = false
                        testPlayButton.Text = "🎵 尝试播放"
                    end
                end)
            else
                ChronixUI:Notify({
                    Title = "播放失败",
                    Content = data.basicdata.otherdata.audioData.currentSelectedId .. " 不是一个有效的音频ID",
                    Type = "error",
                    Duration = 2
                })
            end
        end
    end
})
audioCheckerTab:AddDivider()
audioCheckerTab:AddTitle("检测到的音频")
audioCheckerTab:AddLabel("点击任意音频可选中并复制ID")
audioCheckerTab:AddDivider()
audioCheckerTab:AddLabel("💡 提示：阈值越低，检测到的音频越多")
audioCheckerTab:AddLabel("🎵 建议阈值设置在 10-30 之间获得最佳效果")


local chatReceiverTab = mainWindow:CreateTab({ Name = "聊天接收器" })
local chatMessages = {}
local function clearChatMessages()
    for _, element in ipairs(chatMessages) do
        if element and element.Destroy then
            element:Destroy()
        end
    end
    chatMessages = {}
end
local function addChatMessage(sender, text)
    -- 消息文本
    local messageText = sender .. ": " .. text
    local messageLabel = chatReceiverTab:AddLabel(messageText)
    table.insert(chatMessages, messageLabel)
    local copyButton = chatReceiverTab:AddButton({
        Text = "📋 复制这条消息",
        Callback = function()
            local fullText = sender .. ": " .. text
            setclipboard(fullText)
            ChronixUI:Notify({
                Title = "已复制",
                Content = "消息已复制到剪贴板",
                Type = "success",
                Duration = 2
            })
        end
    })
    table.insert(chatMessages, copyButton)
    local divider = chatReceiverTab:AddDivider()
    table.insert(chatMessages, divider)
end
chatReceiverTab:AddTitle("📨 聊天接收器")
chatReceiverTab:AddDivider()
chatReceiverTab:AddLabel("实时接收游戏中所有玩家的聊天消息")
chatReceiverTab:AddDivider()
chatReceiverTab:AddTitle("消息列表")
chatReceiverTab:AddButton({
    Text = "🗑️ 清空所有消息",
    Callback = function()
        clearChatMessages()
        ChronixUI:Notify({
            Title = "已清空",
            Content = "所有聊天消息已清除",
            Type = "info",
            Duration = 1
        })
    end
})
chatReceiverTab:AddDivider()
chatReceiverTab:AddLabel("💡 提示：点击消息下方的按钮可复制该条消息")


local executerTab = mainWindow:CreateTab({ Name = "执行器" })
executerTab:AddTitle("执行器")
executerTab:AddInput({
Label = "请输入代码",
    Placeholder = "",
    Callback = function(text)
        data.basicdata.releasetools.executecode = text
    end
})
executerTab:AddButton({
    Text = "执行",
    Callback = function()
        if data.basicdata.releasetools.executecode and data.basicdata.releasetools.executecode ~= "" then
            -- 尝试执行脚本
            local success, errorMessage = pcall(function()
                loadstring(data.basicdata.releasetools.executecode)()
            end)
            if not success then
                ChronixUI:Notify({ Title = "错误", Content = "脚本执行失败: " .. errorMessage, Type = "error", Duration = 5 })
            else
                ChronixUI:Notify({ Title = "提示", Content = "脚本执行成功!", Type = "success", Duration = 5 })
            end
        else
            ChronixUI:Notify({ Title = "错误", Content = "请输入有效的脚本!", Type = "error", Duration = 5 })
        end
    end
})


local supportedgamesTab = mainWindow:CreateTab({ Name = "支持的游戏" })
supportedgamesTab:AddTitle("支持的游戏")
for _, GetgameInfo in ipairs(data.Supported_Games) do
    if GetgameInfo.gameid then
        supportedgamesTab:AddButton({ Text = GetgameInfo.name .. "(点击进入)", Callback = function() if game.GameId == GetgameInfo.gameid then ChronixUI:Notify({ Title = "提示", Content = "你已经在这个游戏里了。", Type = "success", Duration = 5 }) else GameTeleport.teleportByGameId(GetgameInfo.gameid) end end })
    end
end


for _, GetgameInfo in ipairs(data.Supported_Games) do
    if GetgameInfo.gameid == game.GameId then
        if GetgameInfo.name == "死亡球" then
            local deathballTab = mainWindow:CreateTab({ Name = "死亡球" })
            deathballTab:AddTitle("死亡球")
            deathballTab:AddToggle({
                Label = "主功能和界面",
                Default = false,
                Callback = function(v)
                    if v then
                        _G.DeathBallScript:Enable()
                    else
                        _G.DeathBallScript:Disable()
                    end
                end
            })
        elseif GetgameInfo.name == "小屋角色扮演" then
            local cabinroleplayTab = mainWindow:CreateTab({ Name = "小屋角色扮演" })
            cabinroleplayTab:AddTitle("小屋角色扮演")
            cabinroleplayTab:AddButton({ Text = "变正常", Callback = function() ChatControl:chat("/re") end })
            cabinroleplayTab:AddButton({ Text = "变小孩", Callback = function() ChatControl:chat("/kid") end })
            cabinroleplayTab:AddButton({ Text = "鲨鱼服装", Callback = function() ChatControl:chat("/shark") end })
            cabinroleplayTab:AddButton({ Text = "修狗服装", Callback = function() ChatControl:chat("/dog") end })
            cabinroleplayTab:AddButton({ Text = "修猫服装", Callback = function() ChatControl:chat("/cat") end })
        elseif GetgameInfo.name == "南极探险队" then
            local njtxdTab = mainWindow:CreateTab({ Name = "南极探险队" })
            njtxdTab:AddTitle("南极探险队")
            njtxdTab:AddLabel("基础操作")
            njtxdTab:AddButton({ Text = "传送到 大本营", Callback = function() TeleportTo(-6015, -158, -35) end })
            njtxdTab:AddButton({ Text = "传送到 营地1", Callback = function() TeleportTo(-3719, 226, 235) end })
            njtxdTab:AddButton({ Text = "传送到 营地2", Callback = function() TeleportTo(1790, 106, -138) end })
            njtxdTab:AddButton({ Text = "传送到 营地3", Callback = function() TeleportTo(5892, 321, -18) end })
            njtxdTab:AddButton({ Text = "传送到 营地4", Callback = function() TeleportTo(8992, 596, 102) end })
            njtxdTab:AddButton({ Text = "传送到 营地5", Callback = function() TeleportTo(10990, 550, 104) end })
            njtxdTab:AddLabel("圣诞活动")
            njtxdTab:AddButton({ Text = "获取所有礼物", Callback = function() loadstring(game:HttpGet("https://raw.atomgit.com/Furrycalin/ChronixHub/raw/main/modules/SouthExpedition_Christmas_getallgifts.lua"))() end })
            local njtx_giftnumber = 0
            njtxdTab:AddInput({
                Label = "礼物号",
                Placeholder = "",
                Callback = function(text)
                    njtx_giftnumber = text
                end
            })
            njtxdTab:AddButton({ Text = "传送到礼物", Callback = function() TeleportToPresent(tonumber(njtx_giftnumber)) end })
        elseif GetgameInfo.name == "西部森林" then
            local westwoodTab = mainWindow:CreateTab({ Name = "西部森林" })
            westwoodTab:AddTitle("西部森林")
            westwoodTab:AddToggle({
                Label = "怪物标签",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.west_wood.monster:enable()
                    else
                        data.othergamedata.west_wood.monster:disable()
                    end
                end
            })
        elseif GetgameInfo.name == "警笛头:遗产" then
            local shlTab = mainWindow:CreateTab({ Name = "警笛头:遗产" })
            shlTab:AddTitle("警笛头:遗产")
            shlTab:AddToggle({
                Label = "透视盒子",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.sirenhead_legacy.cratemodule.apply()
                        data.othergamedata.sirenhead_legacy.cratenametagmodule:enable()
                    else
                        data.othergamedata.sirenhead_legacy.cratemodule.destroy()
                        data.othergamedata.sirenhead_legacy.cratenametagmodule:disable()
                    end
                end
            })
            shlTab:AddToggle({
                Label = "透视浆果",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.sirenhead_legacy.berrymodule.apply()
                        data.othergamedata.sirenhead_legacy.berrynametagmodule:enable()
                    else
                        data.othergamedata.sirenhead_legacy.berrymodule.destroy()
                        data.othergamedata.sirenhead_legacy.berrynametagmodule:disable()
                    end
                end
            })
            shlTab:AddButton({ Text = "传送到树顶", Callback = function() TeleportTo(69, 206, -72) end })
        elseif GetgameInfo.name == "噩梦之行" then
            local nmrTab = mainWindow:CreateTab({ Name = "噩梦之行" })
            nmrTab:AddTitle("噩梦之行")
            nmrTab:AddToggle({
                Label = "高亮怪物",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.nightmare_run.monster:enable()
                    else
                        data.othergamedata.nightmare_run.monster:disable()
                    end
                end
            })
            nmrTab:AddButton({ Text = "高亮芝士", Callback = function() data.othergamedata.nightmare_run.HLCheese.apply() end })
            nmrTab:AddButton({ Text = "无敌(怪物不追不杀)", Callback = function()
                -- 无敌实现
                local ClientScripts = game.Players.LocalPlayer.PlayerGui.ClientScripts
                if ClientScripts:FindFirstChild("SafeSpaceHandler") then
                    ClientScripts.SafeSpaceHandler:Destroy() -- 删除安全区处理脚本、防止被持续监测到（注意：死亡后会重新生成）
                end
                local ReplicatedStorage_upvr = game:GetService("ReplicatedStorage")
                local LocalPlayer_upvr = game.Players.LocalPlayer
                local Events_upvr = ReplicatedStorage_upvr.Events
                LocalPlayer_upvr:SetAttribute("Safe", true) -- 设置安全状态
                Events_upvr.SetAttributeEvent:FireServer("Safe", true) -- 向服务端发送安全状态
                ChronixUI:Notify({ Title = "提示", Content = "已设置玩家安全状态\n死亡前生效", Type = "success", Duration = 5 })
            end })
        elseif GetgameInfo.name == "兽化项目" then
            local ptTab = mainWindow:CreateTab({ Name = "兽化项目" })
            ptTab:AddTitle("兽化项目")
            ptTab:AddLabel("基础操作")
            ptTab:AddButton({ Text = "删除捕兽夹", Callback = function()
                local deletedCount = 0
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model.Name == "__SnarePhysical" then
                        model:Destroy()
                        deletedCount = deletedCount + 1
                    end
                end
                ChronixUI:Notify({ Title = "提示", Content = "已删除" .. deletedCount .. "个捕兽夹", Type = "success", Duration = 10 })
            end })
            ptTab:AddButton({ Text = "删除地雷", Callback = function()
                local deletedCount = 0
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model.Name == "Landmine" then
                        model:Destroy()
                        deletedCount = deletedCount + 1
                    end
                end
                ChronixUI:Notify({ Title = "提示", Content = "已删除" .. deletedCount .. "个地雷", Type = "success", Duration = 10 })
            end })
            ptTab:AddButton({ Text = "删除阔剑地雷", Callback = function()
                local deletedCount = 0
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model.Name == "__ClaymorePhysical" then
                        model:Destroy()
                        deletedCount = deletedCount + 1
                    end
                end
                ChronixUI:Notify({ Title = "提示", Content = "已删除" .. deletedCount .. "个阔剑地雷", Type = "success", Duration = 10 })
            end })
            ptTab:AddLabel("透视功能")
            ptTab:AddToggle({
                Label = "Bot兽",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.project_transfur.bot.apply()
                        data.othergamedata.project_transfur.botnt:enable()
                    else
                        data.othergamedata.project_transfur.bot.destroy()
                        data.othergamedata.project_transfur.botnt:disable()
                    end
                end
            })
            ptTab:AddToggle({
                Label = "小保险箱",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.project_transfur.smallsafe.apply()
                        data.othergamedata.project_transfur.smallsafent:enable()
                    else
                        data.othergamedata.project_transfur.smallsafe.destroy()
                        data.othergamedata.project_transfur.smallsafent:disable()
                    end
                end
            })
            ptTab:AddToggle({
                Label = "大保险箱",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.project_transfur.largesafe.apply()
                        data.othergamedata.project_transfur.largesafent:enable()
                    else
                        data.othergamedata.project_transfur.largesafe.destroy()
                        data.othergamedata.project_transfur.largesafent:disable()
                    end
                end
            })
            ptTab:AddToggle({
                Label = "金保险箱",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.project_transfur.goldensafe.apply()
                        data.othergamedata.project_transfur.goldensafent:enable()
                    else
                        data.othergamedata.project_transfur.goldensafe.destroy()
                        data.othergamedata.project_transfur.goldensafent:disable()
                    end
                end
            })
            ptTab:AddToggle({
                Label = "武器盒",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.project_transfur.crate.apply()
                        data.othergamedata.project_transfur.cratent:enable()
                    else
                        data.othergamedata.project_transfur.crate.destroy()
                        data.othergamedata.project_transfur.cratent:disable()
                    end
                end
            })
            ptTab:AddToggle({
                Label = "空投",
                Default = false,
                Callback = function(v)
                    if v then
                        data.othergamedata.project_transfur.sd.apply()
                        data.othergamedata.project_transfur.sdnt:enable()
                    else
                        data.othergamedata.project_transfur.sd.destroy()
                        data.othergamedata.project_transfur.sdnt:disable()
                    end
                end
            })
        elseif GetgameInfo.name == "妄想办公室" then
            local doTab = mainWindow:CreateTab({ Name = "妄想办公室" })
            doTab:AddTitle("妄想办公室")
            doTab:AddToggle({
                Label = "实体警告",
                Default = false,
                Callback = function(v) data.othergamedata.delesions_office.entitywarning = v end
            })
            doTab:AddToggle({
                Label = "提醒他人",
                Default = false,
                Callback = function(v) data.othergamedata.delesions_office.tipotherplayer = v end
            })
            doTab:AddToggle({
                Label = "自动EN-013",
                Default = false,
                Callback = function(v) data.othergamedata.delesions_office.auto013 = v end
            })
        elseif GetgameInfo.name == "格蕾丝" then
            local graceTab = mainWindow:CreateTab({ Name = "格蕾丝" })
            graceTab:AddTitle("格蕾丝")
            graceTab:AddToggle({
                Label = "自动拉杆",
                Default = false,
                Callback = function(v) data.othergamedata.grace.autolever = v end
            })
            graceTab:AddButton({ Text = "删除全部实体(无法关闭)", Callback = function() data.othergamedata.grace.deleteentity = true end })
        end
    end
end


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
    if data.basicdata.releasetools.antidead then humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end
end)

local pac = Players.PlayerAdded:Connect(updatePlayerList)
local prc = Players.PlayerRemoving:Connect(updatePlayerList)

ChatControl:MessageReceiver(function(msgData)
    addChatMessage(msgData.sender, msgData.text)
end)

local offce = Workspace.DescendantAdded:Connect(detectEntity)

local GGcount = 0

al = workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "base" and descendant:IsA("BasePart") and data.othergamedata.grace.autolever then
        local player = game.Players.LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            descendant.CFrame = player.Character.HumanoidRootPart.CFrame
            GGcount = GGcount + 1
            if GGcount >= 3 then
                ChronixUI:Notify({ Title = "提示", Content = "全部拉杆已被激活\n门已打开", Type = "success", Duration = 5 })
                GGcount = 0
            end
            task.wait(1)
            descendant.CFrame = player.Character.HumanoidRootPart.CFrame
        end
    end
end)

ds = workspace.DescendantAdded:Connect(function(descendant)
    if data.othergamedata.grace.deleteentity then
        if descendant.Name == "eye" or descendant.Name == "elkman" or descendant.Name == "Rush" or descendant.Name == "Worm" or descendant.Name == "eyePrime" then
            descendant:Destroy()
        end
    end
end)

Stepped6 = game:GetService("RunService").Stepped:Connect(function()
    if data.othergamedata.grace.deleteentity then 
    local RS = game:GetService("ReplicatedStorage")
    RS.eyegui:Destroy()
    RS.smilegui:Destroy()
    RS.SendRush:Destroy()
    RS.SendWorm:Destroy()
    RS.SendSorrow:Destroy()
    RS.SendGoatman:Destroy()
    wait(0.1)
    RS.Worm:Destroy()
    RS.elkman:Destroy()
    wait(0.1)
    RS.QuickNotes.Eye:Destroy()
    RS.QuickNotes.Rush:Destroy()
    RS.QuickNotes.Sorrow:Destroy()
    RS.QuickNotes.elkman:Destroy()  
    RS.QuickNotes.EyePrime:Destroy()
    RS.QuickNotes.SlugFish:Destroy()
    RS.QuickNotes.FakeDoor:Destroy()
    RS.QuickNotes.SleepyHead:Destroy()
    local SmileGui = player:FindFirstChild("PlayerGui"):FindFirstChild("smilegui")
    if SmileGui then
        SmileGui:Destroy()
    end
    end
    if data.basicdata.releasetools.nightvision then
        game.Lighting.Ambient = Color3.new(1, 1, 1)
    end
end)

--======================================================================================

-- 启动成功提示
local successMsg = "ChronixHub V3 Already Success Loaded!\nWelcome " .. displayName
if SystemNotification and SystemNotification.Rainbow then
    SystemNotification.Rainbow(successMsg)
    print(successMsg)
end

ChronixUI:Notify({ Title = "提示", Content = "ChronixHub 启动成功。", Type = "success", Duration = 5 })

-- 卸载函数
local function unloadChronixHub()
    if SystemNotification and SystemNotification.UnloadedGradient then
        SystemNotification.UnloadedGradient("ChronixHub V3 Already Unload!")
    else
        print("ChronixHub V3 已卸载。")
    end
    _G.ChronixHubisLoaded = false

    -- 清理所有资源（保持不变）
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
    if _G.DeathBallScript then _G.DeathBallScript:Unload() end
    data.basicdata.releasetools.zoom:Unload()
    FlingDetector.unload()
    PlayerESP.unload()
    MovableHighlighter_NM.unloadAll()
    AntiVoidModule.unload()
    ChatSpy.unload()

    if cc then cc:Disconnect() end
    if gsr then gsr:Disconnect() end
    if hscc then hscc:Disconnect() end

    script:Destroy()
end

Stepped67 = game:GetService("RunService").Stepped:Connect(function()
    if _G.UnloadChronixUI then
        unloadChronixHub()
        Stepped67:Disconnect()
    end
end)