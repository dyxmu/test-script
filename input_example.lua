repeat task.wait() until game:IsLoaded()
local t1 = tick()
local http = (syn and syn.request) or (http and http.request) or request

local KillSounds = {
    { "1.wav", "https://www.dropbox.com/scl/fi/zvp0ibqke894vbekuvnru/1.wav?rlkey=bgesj9ve0dcv69v1hvojksgga&st=7qrcr0os&dl=1", 86386  },
    { "2.wav", "https://www.dropbox.com/scl/fi/xmxz4jvr1hjbqjpgpqa8i/2.wav?rlkey=72evxa2dk9cv387b8194v6t5o&st=sazbbytj&dl=1", 37558  },
    { "3.wav", "https://www.dropbox.com/scl/fi/eb8lag6mtok88jfujwpnw/3.wav?rlkey=phgz2wirlhx48koqr93dm0ayg&st=1y0yci7c&dl=1", 36400  },
    { "4.wav", "https://www.dropbox.com/scl/fi/pwlvaz9drbfisz3a7cjl1/4.wav?rlkey=8iein4awf2g931nkf10bfxfhd&st=ym5nprv3&dl=1", 39231  },
    { "5.wav", "https://www.dropbox.com/scl/fi/r9noqi8z1rhv6of7t9ohc/5.wav?rlkey=az0hlaidzl3pqp9ggh35fktzv&st=i7f6o4op&dl=1", 79378  },
    { "6.wav", "https://www.dropbox.com/scl/fi/p4k65zljr6n5tvibglcq9/6.wav?rlkey=uydz1z1ha27efxkbok9uwk46i&st=5gykuyj7&dl=1", 224744 },
    { "7.wav", "https://www.dropbox.com/scl/fi/ne6p7a6p6nwqxv2bn8dw0/7.wav?rlkey=xkqumx4d2cr7omcca5kru1jv2&st=6j4mzojt&dl=1", 89344  },
}

if not isfolder("Paradise\\Sound") then
    if not isfolder("Paradise") then makefolder("Paradise") end
    makefolder("Paradise\\Sound")
end

for _, f in ipairs(KillSounds) do
    local path = "Paradise\\Sound\\" .. f[1]
    local size = 0

    if isfile(path) then
        local ok, c = pcall(readfile, path)
        if ok then size = #c end
    end

    while size ~= f[3] do
        local ok, res = pcall(http, { Url = f[2], Method = "GET" })
        if ok and res then
            pcall(writefile, path, res.Body or res.body or "")
        end

        size = 0
        if isfile(path) then
            local ok2, c = pcall(readfile, path)
            if ok2 then size = #c end
        end

        if size ~= f[3] then task.wait(1) end
    end
end
getgenv().libkeybind = Enum.KeyCode.F2

local Locals = {
    ["ReplicatedStorage"] = game:GetService("ReplicatedStorage"),
    ["Players"] = game:GetService("Players"),
    ["LocalPlayer"] = game:GetService("Players").LocalPlayer,
    ["Camera"] = workspace.CurrentCamera,
    ["UserInputService"] = game:GetService("UserInputService"),
    ["Count"] = 1,
}

Locals["GameState"] = require(Locals.ReplicatedStorage.Database.Components.GameState)
Locals["Packets"] = require(Locals.ReplicatedStorage.Database.Security.Remotes)
pcall(function()
    Locals["CharacterController"] = require(Locals.ReplicatedStorage.Classes.CharacterController)
end)

local Config = {
    ["RageTab"] = { 
        ["SilentAim"] = {
            ["Enabled"] = false,
            ["TeamCheck"] = false,
            ["Wallbang"] = false,
            ["AutoStop"] = false,
            ["DrawFOV"] = false,
            ["SilentColor"] = Color3.fromRGB(255, 255, 255),
            ["HitChance"] = 50,
            ["FOV"] = 100,
            ["Backtrack"] = 100,
            ["TargetPart"] = "Head",
        },
        ["AntiAim"] = {
            ["Enabled"] = false,
            ["Pitch"] = "Down",
            ["Yaw"] = "Spin",
            ["SpinSpeed"] = 15,
        },
    },
    ["VisualsTab"] = {
        ["ESP"] = {
            ["Enabled"] = false,
            ["TeamCheck"] = false,
            ["Boxes"] = false,
            ["BoxColor"] = Color3.fromRGB(255, 255, 255),
            ["HealthBar"] = false,
            ["Names"] = false,
        },
        ["Chams"] = {
            ["Enabled"] = false,
            ["TeamCheck"] = false,
            ["VisibleColor"] = Color3.fromRGB(120, 255, 120),
            ["HiddenEnabled"] = false,
            ["HiddenColor"] = Color3.fromRGB(255, 60, 60),
            ["FillTransparency"] = 0.5,
            ["OutlineTransparency"] = 0,
        },
        ["Worlds"] = {
            ["AspectRatio"] = false,
            ["AspectRatioValue"] = {1, 1},
        },
    },
    ["MovmentTab"] = {
        ["AutoBhop"] = false,
        ["BHSpeed"] = 35,
    },
    ["MiscTab"] = {
        ["Exploits"] = {
            ["Silent Walk"] = false,
            ["NoFall"] = false,
            ["Desync"] = false,
            ["Fakeping"] = false,
            ["FakepingValue"] = 300,
        },
        ["Other"] = {
            ["AntiAfk"] = false,
            ["Kill Sounds"] = false,
            ["AutoRejoin"] = false,
        },
    },
}

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = Config.RageTab.SilentAim.DrawFOV
fovCircle.Radius = Config.RageTab.SilentAim.FOV
fovCircle.Color = Config.RageTab.SilentAim.SilentColor
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.NumSides = 64

game:GetService("RunService").RenderStepped:Connect(function()
    local viewport = game:GetService("Workspace").CurrentCamera.ViewportSize
    fovCircle.Position = Vector2.new(
        math.floor(viewport.X / 2),
        math.floor(viewport.Y / 2)
    )
    fovCircle.Radius = Config.RageTab.SilentAim.FOV
    fovCircle.Visible = Config.RageTab.SilentAim.DrawFOV and Config.RageTab.SilentAim.Enabled
end)

local function rakhook(packet)
    if packet.PacketId == 0x1B then
        local buf = packet.AsBuffer
        buffer.writeu32(buf, 1, 0xFFFFFFFF)
        packet:SetData(buf)
    end
end

local NixLib = loadstring(game:HttpGet("https://pastebin.com/raw/Y0AdXf2R"))()
local Window = NixLib:CreateWindow("Paradise BloxStrike")

local RageTab = Window:AddTab("Rage", NixLib.Assets["legit_icon"], {17, 17})
local SilentAim = RageTab:AddSection("Silent Aim", "left")

if SilentAim then
    SilentAim:AddToggle("Enable", false, function(v)
        Config.RageTab.SilentAim.Enabled = v
    end)

    SilentAim:AddDropdown("Target Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(v)
        Config.RageTab.SilentAim.TargetPart = v
    end)

    SilentAim:AddToggle("Team check", false, function(v)
        Config.RageTab.SilentAim.TeamCheck = v
    end)

    SilentAim:AddToggle("Wallbang", false, function(v) 
        Config.RageTab.SilentAim.Wallbang = v 
    end)

    SilentAim:AddToggle("Auto stop", false, function(v) 
        Config.RageTab.SilentAim.AutoStop = v 
    end)

    SilentAim:AddToggle("Draw FOV", false, function(v)
        Config.RageTab.SilentAim.DrawFOV = v
        fovCircle.Visible = v and Config.RageTab.SilentAim.Enabled
    end, {
        colorPicker = true, 
        defaultColor = Config.RageTab.SilentAim.SilentColor,
        colorCallback = function(c) 
            Config.RageTab.SilentAim.SilentColor = c
            fovCircle.Color = c
        end
    })

    SilentAim:AddToggle("Multipoint", true, function(v)
        Config.RageTab.SilentAim.Multipoint = v
    end)

    local SettingsSection = RageTab:AddSection("Settings", "right")

    SettingsSection:AddSlider("FOV", 1, 500, 100, 1, function(v)
        Config.RageTab.SilentAim.FOV = v
    end)

    SettingsSection:AddSlider("Hit Chance", 0, 100, 50, 1, function(v)
        Config.RageTab.SilentAim.HitChance = v
    end)

    SettingsSection:AddSlider("Backtrack", 0, 200, 100, 1, function(v)
        Config.RageTab.SilentAim.Backtrack = v
    end)

    local AntiAimSection = RageTab:AddSection("Anti-Aim", "right")

    AntiAimSection:AddToggle("Enable", false, function(v)
        Config.RageTab.AntiAim.Enabled = v
    end)

    AntiAimSection:AddDropdown("Pitch", {"Down", "Up", "Zero"}, "Down", function(v)
        Config.RageTab.AntiAim.Pitch = v
    end)

    AntiAimSection:AddDropdown("Yaw", {"Spin", "Backward", "Random"}, "Spin", function(v)
        Config.RageTab.AntiAim.Yaw = v
    end)

    AntiAimSection:AddSlider("Spin Speed", 1, 50, 15, 1, function(v)
        Config.RageTab.AntiAim.SpinSpeed = v
    end)
end

local VisualsTab = Window:AddTab("Visuals", NixLib.Assets["visuals_icon"], {17, 17})
local ESPSection = VisualsTab:AddSection("ESP", "left")

if ESPSection then
    ESPSection:AddToggle("Enable", false, function(v)
        Config.VisualsTab.ESP.Enabled = v
    end)

    ESPSection:AddToggle("Team Check", false, function(v)
        Config.VisualsTab.ESP.TeamCheck = v
    end)

    ESPSection:AddToggle("Boxes", false, function(v)
        Config.VisualsTab.ESP.Boxes = v
    end, {
        colorPicker = true,
        defaultColor = Config.VisualsTab.ESP.BoxColor,
        colorCallback = function(c)
            Config.VisualsTab.ESP.BoxColor = c
        end
    })

    ESPSection:AddToggle("Health Bar", false, function(v)
        Config.VisualsTab.ESP.HealthBar = v
    end)

    ESPSection:AddToggle("Names", false, function(v)
        Config.VisualsTab.ESP.Names = v
    end)

    local ChamsSection = VisualsTab:AddSection("Chams", "right")

    ChamsSection:AddToggle("Enable", false, function(v)
        Config.VisualsTab.Chams.Enabled = v
    end, {
        colorPicker = true,
        defaultColor = Config.VisualsTab.Chams.VisibleColor,
        colorCallback = function(c)
            Config.VisualsTab.Chams.VisibleColor = c
        end
    })

    ChamsSection:AddToggle("Team Check", false, function(v)
        Config.VisualsTab.Chams.TeamCheck = v
    end)

    ChamsSection:AddToggle("Hidden Color", false, function(v)
        Config.VisualsTab.Chams.HiddenEnabled = v
    end, {
        colorPicker = true,
        defaultColor = Config.VisualsTab.Chams.HiddenColor,
        colorCallback = function(c)
            Config.VisualsTab.Chams.HiddenColor = c
        end
    })

    local WorldSection = VisualsTab:AddSection("World", "left")

    WorldSection:AddToggle("Aspect Ratio", false, function(v)
        Config.VisualsTab.Worlds.AspectRatio = v
    end)

    WorldSection:AddSlider("Aspect Ratio L", 0.01, 1, 1, 0.1, function(v)
        Config.VisualsTab.Worlds.AspectRatioValue = {v, Config.VisualsTab.Worlds.AspectRatioValue[2]}
    end)

    WorldSection:AddSlider("Aspect Ratio R", 0.01, 1, 1, 0.1, function(v)
        Config.VisualsTab.Worlds.AspectRatioValue = {Config.VisualsTab.Worlds.AspectRatioValue[1], v}
    end)
end

local MovmentTab = Window:AddTab("Movement", NixLib.Assets["movement_icon"], {17, 17})
local BHopSection = MovmentTab:AddSection("Player", "left")

if BHopSection then
    BHopSection:AddToggle("Auto Bhop", false, function(v)
        Config.MovmentTab.AutoBhop = v
    end)

    BHopSection:AddSlider("Bhop Speed", 1, 40, 35, 1, function(v)
        Config.MovmentTab.BHSpeed = v
    end)
end

local MiscTab = Window:AddTab("Misc", NixLib.Assets["misc_icon"], {17, 17})
local ExploitsSection = MiscTab:AddSection("Exploits", "left")

if ExploitsSection then
    ExploitsSection:AddToggle("Silent Walk", false, function(v)
        Config.MiscTab.Exploits["Silent Walk"] = v
    end)

    ExploitsSection:AddToggle("No Fall Damage", false, function(v)
        Config.MiscTab.Exploits["NoFall"] = v
    end)

    if raknet and raknet.add_send_hook then
        ExploitsSection:AddToggle("Desync", false, function(v)
            Config.MiscTab.Exploits["Desync"] = v
            if v then
                raknet.add_send_hook(rakhook)
            else
                raknet.remove_send_hook(rakhook)
            end
        end)
    end

    local Other = MiscTab:AddSection("Other", "right")

    Other:AddToggle("Anti-AFK", false, function(v)
        Config.MiscTab.Other["AntiAfk"] = v
    end)

    Other:AddToggle("Deathmatch Kill Sounds", false, function(v)
        Config.MiscTab.Other["Kill Sounds"] = v
    end)

    Other:AddToggle("Auto Rejoin", false, function(v)
        Config.MiscTab.Other["AutoRejoin"] = v
    end)
end

local _origCamCF = nil

do
    game:GetService("RunService").RenderStepped:Connect(function()
        _origCamCF = workspace.CurrentCamera.CFrame
        if Config.VisualsTab.Worlds.AspectRatio then
            local stretchL = Config.VisualsTab.Worlds.AspectRatioValue[1]
            local stretchR = Config.VisualsTab.Worlds.AspectRatioValue[2]
            local x,y,z, r00,r01,r02, r10,r11,r12, r20,r21,r22 = _origCamCF:GetComponents()
            Locals["Camera"].CFrame = CFrame.new(x,y,z,
                r00 * stretchL, r01 * stretchR, r02,
                r10 * stretchL, r11 * stretchR, r12,
                r20 * stretchL, r21 * stretchR, r22)
        end
    end)

    game:GetService("RunService").RenderStepped:Connect(function()
        if Config.MovmentTab.AutoBhop and Locals["LocalPlayer"].Character and Locals["LocalPlayer"].Character:FindFirstChild("Humanoid") and Locals["LocalPlayer"].Character:FindFirstChild("HumanoidRootPart") and not Locals["LocalPlayer"].Character.HumanoidRootPart.Anchored and Locals["UserInputService"]:IsKeyDown(Enum.KeyCode.Space) and Locals["GameState"].GetState() ~= "Buy Period" then
            if Locals["LocalPlayer"].Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
                Locals["LocalPlayer"].Character.Humanoid.Jump = true
            else
                if Locals["LocalPlayer"].Character.Humanoid.MoveDirection.Magnitude > 0 then
                    Locals["LocalPlayer"].Character.HumanoidRootPart.CFrame = Locals["LocalPlayer"].Character.HumanoidRootPart.CFrame + Vector3.new(Locals["LocalPlayer"].Character.Humanoid.MoveDirection.X * Config.MovmentTab.BHSpeed * 0.1, 0, Locals["LocalPlayer"].Character.Humanoid.MoveDirection.Z * Config.MovmentTab.BHSpeed * 0.1)
                end
            end
        end
    end)

    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
        Locals["Count"] = 1
    end)

    game:GetService("Players").LocalPlayer.PlayerGui.MainGui.Gameplay.Middle.KillFeed.ChildAdded:Connect(function(child)
        if child.Name == "Kill" and Config.MiscTab.Other["Kill Sounds"] then
            if child:FindFirstChild("Contents") then
                if child.Contents.Player.Text == game:GetService("Players").LocalPlayer.DisplayName then
                    local asset_id = getcustomasset("Paradise\\Sound\\" .. Locals["Count"] .. ".wav")
                    local sound = Instance.new("Sound")
                    sound.Parent = workspace
                    sound.SoundId = asset_id
                    sound.Volume = 1
                    sound:Play()
                    Locals["Count"] = Locals["Count"] + 1
                    if Locals["Count"] > 7 then
                        Locals["Count"] = 1
                    end
                end
            end
        end
    end)

    -- ESP + Chams
    local espCache = {}
    local espCfg = Config.VisualsTab.ESP
    local chamsCfg = Config.VisualsTab.Chams

    local function newDraw(class, props)
        local d = Drawing.new(class)
        for k, v in pairs(props) do d[k] = v end
        return d
    end

    local function espIsTeammate(model, chars)
        local myTeam = Locals["LocalPlayer"]:GetAttribute("Team")
        if not myTeam then return false end
        local targetPlayer = game:GetService("Players"):FindFirstChild(model.Name)
        if not targetPlayer then return false end
        return targetPlayer:GetAttribute("Team") == myTeam
    end

    local function espIsVisible(part)
        local cam = workspace.CurrentCamera
        local origin = cam.CFrame.Position
        local dir = part.Position - origin
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local exc = { cam, Locals["LocalPlayer"].Character }
        local chars = workspace:FindFirstChild("Characters")
        if chars then
            for _, tf in pairs(chars:GetChildren()) do
                for _, m in pairs(tf:GetChildren()) do
                    if m ~= part.Parent then table.insert(exc, m) end
                end
            end
        end
        for _ = 1, 10 do
            params.FilterDescendantsInstances = exc
            local r = workspace:Raycast(origin, dir, params)
            if not r then return true end
            if r.Instance:IsDescendantOf(part.Parent) then return true end
            if r.Instance.Transparency >= 0.5 or not r.Instance.CanCollide or r.Instance.Name == "Glass" then
                table.insert(exc, r.Instance)
            else
                return false
            end
        end
        return false
    end

    local function makeCornerLines()
        local lines = {}
        for i = 1, 8 do
            lines[i] = newDraw("Line", { Thickness = 2, Color = Color3.fromRGB(255, 255, 255), Visible = false })
        end
        return lines
    end

    local function addESP(model)
        if espCache[model] then return end

        local hl = Instance.new("Highlight")
        hl.FillTransparency = chamsCfg.FillTransparency
        hl.OutlineTransparency = chamsCfg.OutlineTransparency
        hl.Adornee = model
        hl.Enabled = false
        hl.Parent = model

        espCache[model] = {
            highlight = hl,
            corners = makeCornerLines(),
            hpBg = newDraw("Line", { Thickness = 4, Color = Color3.new(0, 0, 0), Visible = false }),
            hpBar = newDraw("Line", { Thickness = 2, Visible = false }),
            nameTag = newDraw("Text", { Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false }),
        }
    end

    local function removeESP(model)
        local d = espCache[model]
        if not d then return end
        if d.highlight then d.highlight:Destroy() end
        for _, l in ipairs(d.corners) do l:Remove() end
        if d.hpBg then d.hpBg:Remove() end
        if d.hpBar then d.hpBar:Remove() end
        if d.nameTag then d.nameTag:Remove() end
        espCache[model] = nil
    end

    local function updateESP()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local chars = workspace:FindFirstChild("Characters")
        if not chars then return end

        local savedCF = cam.CFrame
        if _origCamCF then cam.CFrame = _origCamCF end

        local active = {}
        for _, tf in pairs(chars:GetChildren()) do
            for _, model in pairs(tf:GetChildren()) do
                if model.Name == Locals["LocalPlayer"].Name then continue end
                local hum = model:FindFirstChildOfClass("Humanoid")
                local hrp = model:FindFirstChild("HumanoidRootPart")
                local head = model:FindFirstChild("Head")
                if not hum or hum.Health <= 0 or not hrp or not head then continue end

                local isTeammate = espIsTeammate(model, chars)

                active[model] = true
                addESP(model)
                local d = espCache[model]

                -- Chams
                if chamsCfg.Enabled and not (chamsCfg.TeamCheck and isTeammate) then
                    if chamsCfg.HiddenEnabled then
                        d.highlight.Enabled = true
                        d.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        local vis = espIsVisible(head)
                        d.highlight.FillColor = vis and chamsCfg.VisibleColor or chamsCfg.HiddenColor
                        d.highlight.OutlineColor = vis and chamsCfg.VisibleColor or chamsCfg.HiddenColor
                    else
                        local vis = espIsVisible(head)
                        d.highlight.Enabled = vis
                        d.highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                        d.highlight.FillColor = chamsCfg.VisibleColor
                        d.highlight.OutlineColor = chamsCfg.VisibleColor
                    end
                    d.highlight.FillTransparency = chamsCfg.FillTransparency
                    d.highlight.OutlineTransparency = chamsCfg.OutlineTransparency
                else
                    d.highlight.Enabled = false
                end

                -- ESP 2D
                local skipESP = not espCfg.Enabled or (espCfg.TeamCheck and isTeammate)
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                if not onScreen or skipESP then
                    for _, l in ipairs(d.corners) do l.Visible = false end
                    d.hpBg.Visible = false
                    d.hpBar.Visible = false
                    d.nameTag.Visible = false
                    continue
                end

                local headTop = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local h = math.abs((pos.Y - headTop.Y) * 2.3)
                local w = h / 1.5
                local L = math.floor(w * 0.3)

                local x1 = math.floor(pos.X - w / 2)
                local y1 = math.floor(pos.Y - h / 2)
                local x2 = x1 + math.floor(w)
                local y2 = y1 + math.floor(h)

                if espCfg.Boxes then
                    local c = d.corners
                    local col = espCfg.BoxColor
                    -- top-left
                    c[1].From = Vector2.new(x1, y1); c[1].To = Vector2.new(x1 + L, y1); c[1].Color = col; c[1].Visible = true
                    c[2].From = Vector2.new(x1, y1); c[2].To = Vector2.new(x1, y1 + L); c[2].Color = col; c[2].Visible = true
                    -- top-right
                    c[3].From = Vector2.new(x2, y1); c[3].To = Vector2.new(x2 - L, y1); c[3].Color = col; c[3].Visible = true
                    c[4].From = Vector2.new(x2, y1); c[4].To = Vector2.new(x2, y1 + L); c[4].Color = col; c[4].Visible = true
                    -- bottom-left
                    c[5].From = Vector2.new(x1, y2); c[5].To = Vector2.new(x1 + L, y2); c[5].Color = col; c[5].Visible = true
                    c[6].From = Vector2.new(x1, y2); c[6].To = Vector2.new(x1, y2 - L); c[6].Color = col; c[6].Visible = true
                    -- bottom-right
                    c[7].From = Vector2.new(x2, y2); c[7].To = Vector2.new(x2 - L, y2); c[7].Color = col; c[7].Visible = true
                    c[8].From = Vector2.new(x2, y2); c[8].To = Vector2.new(x2, y2 - L); c[8].Color = col; c[8].Visible = true
                else
                    for _, l in ipairs(d.corners) do l.Visible = false end
                end

                if espCfg.HealthBar then
                    local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barX = x1 - 5
                    d.hpBg.From = Vector2.new(barX, y2)
                    d.hpBg.To = Vector2.new(barX, y1)
                    d.hpBg.Visible = true
                    d.hpBar.From = Vector2.new(barX, y2)
                    d.hpBar.To = Vector2.new(barX, y2 - (h * hp))
                    d.hpBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
                    d.hpBar.Visible = true
                else
                    d.hpBg.Visible = false
                    d.hpBar.Visible = false
                end

                if espCfg.Names then
                    d.nameTag.Position = Vector2.new(pos.X, y1 - 16)
                    d.nameTag.Text = model.Name
                    d.nameTag.Visible = true
                else
                    d.nameTag.Visible = false
                end
            end
        end

        cam.CFrame = savedCF

        for model in pairs(espCache) do
            if not active[model] then removeESP(model) end
        end
    end

    game:GetService("RunService").RenderStepped:Connect(updateESP)

    -- Auto Rejoin
    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if Config.MiscTab.Other["AutoRejoin"] then
            task.wait(1)
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end
    end)
end

-- Silent Aim Engine
local SA = Config.RageTab.SilentAim
SA.Multipoint = true
SA.MultipointParts = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }

local WS, LP = game:GetService("Workspace"), game:GetService("Players").LocalPlayer
local function Cam() return WS.CurrentCamera end

local function getChars() return WS:FindFirstChild("Characters") end

local function isSameTeam(m, ag)
    if not SA.TeamCheck then return false end
    local myTeam = LP:GetAttribute("Team")
    if not myTeam then return false end
    local targetPlayer = game:GetService("Players"):FindFirstChild(m.Name)
    if not targetPlayer then return false end
    return targetPlayer:GetAttribute("Team") == myTeam
end

local function isVisible(part, ag)
    if SA.Wallbang then return true end
    local cp = Cam().CFrame.Position
    local dir = part.Position - cp
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    local ex = { Cam(), LP.Character }
    if WS:FindFirstChild("Debris") then table.insert(ex, WS.Debris) end
    if WS:FindFirstChild("RaycastVisualizers") then table.insert(ex, WS.RaycastVisualizers) end
    if ag then
        for _, tf in pairs(ag:GetChildren()) do
            for _, m in pairs(tf:GetChildren()) do
                if m ~= part.Parent then table.insert(ex, m) end
            end
        end
    end
    for _ = 1, 15 do
        p.FilterDescendantsInstances = ex
        local r = WS:Raycast(cp, dir, p)
        if not r then return true end
        if r.Instance:IsDescendantOf(part.Parent) then return true end
        if r.Instance.Transparency >= 0.5 or not r.Instance.CanCollide or r.Instance.Name:lower():find("hitbox") or r.Instance.Name == "Glass" then
            table.insert(ex, r.Instance)
        else return false end
    end
    return false
end

local function findTarget()
    local ag = getChars()
    if not ag then return nil end
    local cam = Cam()
    local c = Vector2.new(math.floor(cam.ViewportSize.X / 2), math.floor(cam.ViewportSize.Y / 2))
    local bd, bp = SA.FOV, nil
    for _, tf in pairs(ag:GetChildren()) do
        for _, model in pairs(tf:GetChildren()) do
            if model.Name == LP.Name or isSameTeam(model, ag) then continue end
            local h = model:FindFirstChildOfClass("Humanoid")
            if not h or h.Health <= 0 then continue end
            local parts = {}
            if SA.Multipoint then
                for _, pn in ipairs(SA.MultipointParts) do local p = model:FindFirstChild(pn); if p then table.insert(parts, p) end end
            else
                local p = model:FindFirstChild(SA.TargetPart) or model:FindFirstChild("Head"); if p then table.insert(parts, p) end
            end
            for _, part in ipairs(parts) do
                local sp, on = cam:WorldToViewportPoint(part.Position)
                if not on then continue end
                local d = (Vector2.new(sp.X, sp.Y) - c).Magnitude
                if d < bd and isVisible(part, ag) then bd, bp = d, part end
            end
        end
    end
    return bp
end

local function buildHits(origin, dir, tgt)
    local hits, exc = {}, { LP.Character, Cam() }
    local tp = 0
    local ep, ip = RaycastParams.new(), RaycastParams.new()
    ep.FilterType = Enum.RaycastFilterType.Exclude
    ip.FilterType = Enum.RaycastFilterType.Include
    local cur = origin
    for _ = 1, 4 do
        ep.FilterDescendantsInstances = exc
        local h = WS:Raycast(cur, dir * 1000, ep)
        if not h then break end
        table.insert(hits, { Instance = h.Instance, Position = h.Position, Normal = h.Normal, Material = h.Material.Name, Distance = (h.Position - cur).Magnitude, Exit = false })
        ip.FilterDescendantsInstances = { h.Instance }
        local ex = WS:Raycast(h.Position + dir * 10, -dir * 11, ip)
        if ex then
            local pen = (ex.Position - h.Position).Magnitude
            tp += pen; if tp > 5 then break end
            table.insert(hits, { Instance = ex.Instance, Position = ex.Position, Normal = ex.Normal, Material = h.Material.Name, Distance = pen, Exit = true })
        end
        table.insert(exc, h.Instance)
        if h.Instance:IsDescendantOf(tgt.Parent) then break end
        cur = h.Position
    end
    local found = false
    for _, h in ipairs(hits) do if h.Instance and h.Instance:IsDescendantOf(tgt.Parent) then found = true; break end end
    if not found then
        table.insert(hits, { Instance = tgt, Position = tgt.Position, Normal = Vector3.new(0,1,0), Material = "SmoothPlastic", Distance = (tgt.Position - origin).Magnitude, Exit = false })
    end
    return hits
end

local aaAngle = 0

local Overrides = {
    ["Character.UpdateLookAngle"] = function(data)
        if not Config.RageTab.AntiAim.Enabled then return data end
        local aa = Config.RageTab.AntiAim
        local pitch = 0
        if aa.Pitch == "Down" then pitch = -math.pi / 2
        elseif aa.Pitch == "Up" then pitch = math.pi / 2
        elseif aa.Pitch == "Zero" then pitch = 0 end
        local yaw = 0
        if aa.Yaw == "Spin" then
            aaAngle = aaAngle + math.rad(aa.SpinSpeed)
            yaw = aaAngle
        elseif aa.Yaw == "Backward" then
            yaw = (data.HorizontalAngle or 0) + math.pi
        elseif aa.Yaw == "Random" then
            yaw = math.rad(math.random(0, 360))
        end
        data.HorizontalAngle = yaw
        data.VerticalLook = pitch
        return data
    end,

    ["Character.UpdateCrouchState"] = function(data)
        if Config.MiscTab.Exploits["Silent Walk"] then return true end
        return data
    end,

    ["Character.UpdateWalkState"] = function(data)
        if Config.MiscTab.Exploits["Silent Walk"] then return true end
        return data
    end,

    ["Character.FallDamage"] = function(data)
        if Config.MiscTab.Exploits["NoFall"] then return 0 end
        return data
    end,

    ["Inventory.ShootWeapon"] = function(data)
        if not SA.Enabled or not data or not data.Bullets or math.random(1, 100) > SA.HitChance then return data end
        local tgt = findTarget()
        if not tgt then return data end
        if SA.AutoStop and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local oL, oA = hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity
                hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
                task.delay(0.05, function() hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = oL, oA end)
            end
        end
        local cp = Cam().CFrame.Position
        local bq = SA.Backtrack / 1000
        if data.tick then data.tick = data.tick - bq end
        if data.Tick then data.Tick = data.Tick - bq end
        if data.time then data.time = data.time - bq end
        if data.Time then data.Time = data.Time - bq end
        for _, b in ipairs(data.Bullets) do
            local d = (tgt.Position - cp).Unit
            b.Direction, b.Origin, b.Hits = d, cp, buildHits(cp, d, tgt)
            if data.camCFrame then data.camCFrame = CFrame.new(cp, tgt.Position) end
            if data.CameraCFrame then data.CameraCFrame = CFrame.new(cp, tgt.Position) end
            if data.ViewAngle then data.ViewAngle = d end
            if data.viewangle then data.viewangle = d end
        end
        return data
    end,
}

for ns, pkts in pairs(require(game:GetService("ReplicatedStorage").Database.Security.Remotes)) do
    for name, pkt in pairs(pkts) do
        local full = ns .. "." .. name

        if pkt.Send then
            local oldSend = pkt.Send
            pkt.Send = function(data)
                if Overrides[full] then
                    if type(Overrides[full]) == "function" then
                        data = Overrides[full](data)
                    else
                        data = Overrides[full]
                    end
                end
                if data == nil then return end
                return oldSend(data)
            end
        end

        if pkt.Listen then
            local oldListen = pkt.Listen
            pkt.Listen = function(callback)
                return oldListen(function(data, player)
                    if Overrides[full] then
                        if type(Overrides[full]) == "function" then
                            data = Overrides[full](data)
                        else
                            data = Overrides[full]
                        end
                    end
                    if data == nil then return end
                    return callback(data, player)
                end)
            end
        end
    end
end
