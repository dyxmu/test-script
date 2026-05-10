-- Deobfuscated by WeAreDevs/Prometheus Deobfuscator
-- Original file: e7c1542cc14c3a61.lua
-- String constants: 3060
-- Decoded API calls: pairs, concat, loadstring, crypt, isfile, floor, iskeydown, error, table, http, pcall, vUY, warn, tonumber, workspace, cAx, random, readfile, gethui, unpack, getexecutorname, wHi, setclipboard, game, delfile, remove, char, rconsoleprint, debug, keypress, settings, find, gmatch, syn, len, math, request, fluxus, byte, tostring, setmetatable, lower, executor, string, task, writefile, ipairs, tick, print, getgenv, gsub

-- ============================================================================
-- Deobfuscated by WeAreDevs/Prometheus Deobfuscator
-- Full source reconstruction via runtime tracing + Roblox API stubs
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local httpResult_1 = game:HttpGet("https://raw.githubusercontent.com/accsultan428-sys/Scriptloader2/refs/heads/main/Keys")
print("✅ Loaded 0 valid keys from GitHub")
local Humanoid = Players.LocalPlayer.Character:WaitForChild("Humanoid")
local HumanoidRootPart = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
-- isfile("ArqelRed_Key.txt")
CoreGui:FindFirstChild("ArqelRedSystem"):Destroy()
Lighting:FindFirstChild("ArqelRedBlur"):Destroy()
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "ArqelRedBlur"
blurEffect.Size = 0
blurEffect.Parent = Lighting
TweenService.Create(TweenService, blurEffect, TweenInfo.new(0.4), {}):Play()
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ArqelRedSystem"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = CoreGui
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 320)
frame.Position = UDim2.new(0.5, 0, 1.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = screenGui
local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0, 12)
uICorner.Parent = frame
local uIStroke = Instance.new("UIStroke")
uIStroke.Color = Color3.fromRGB(180, 20, 30)
uIStroke.Thickness = 1.5
uIStroke.Transparency = 0.3
uIStroke.Parent = frame
local frame2 = Instance.new("Frame")
frame2.Size = UDim2.new(1, 0, 0, 55)
frame2.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
frame2.BorderSizePixel = 0
frame2.Parent = frame
local uICorner2 = Instance.new("UICorner")
uICorner2.CornerRadius = UDim.new(0, 12)
uICorner2.Parent = frame2
local frame3 = Instance.new("Frame")
frame3.Size = UDim2.new(1, 0, 0, 8)
frame3.Position = UDim2.new(0, 0, 1, -8)
frame3.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
frame3.BorderSizePixel = 0
frame3.Parent = frame2
local frame4 = Instance.new("Frame")
frame4.Size = UDim2.new(1, 0, 0, 2)
frame4.Position = UDim2.new(0, 0, 1, 0)
frame4.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
frame4.BorderSizePixel = 0
frame4.Parent = frame2
local imageLabel = Instance.new("ImageLabel")
imageLabel.Size = UDim2.new(0, 32, 0, 32)
imageLabel.Position = UDim2.new(0, 14, 0.5, 0)
imageLabel.AnchorPoint = Vector2.new(0, 0.5)
imageLabel.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
imageLabel.BackgroundTransparency = 0.2
imageLabel.Image = "rbxassetid://85977955810367"
imageLabel.ImageColor3 = Color3.fromRGB(180, 20, 30)
imageLabel.Parent = frame2
local uICorner3 = Instance.new("UICorner")
uICorner3.CornerRadius = UDim.new(0, 8)
uICorner3.Parent = imageLabel
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -90, 1, 0)
textLabel.Position = UDim2.new(0, 56, 0, 0)
textLabel.BackgroundTransparency = 1
textLabel.Text = "KEY SYSTEM FIQZR7"
textLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
textLabel.TextSize = 20
textLabel.Font = {}
textLabel.TextXAlignment = {}
textLabel.Parent = frame2
local textLabel2 = Instance.new("TextLabel")
textLabel2.Size = UDim2.new(1, -90, 0, 16)
textLabel2.Position = UDim2.new(0, 56, 0, 32)
textLabel2.BackgroundTransparency = 1
textLabel2.Text = "Free Script | .gg/Fiqqzr7"
textLabel2.TextColor3 = Color3.fromRGB(150, 150, 170)
textLabel2.TextSize = 11
textLabel2.Font = {}
textLabel2.TextXAlignment = {}
textLabel2.Parent = frame2
local textButton = Instance.new("TextButton")
textButton.Size = UDim2.new(0, 30, 0, 30)
textButton.Position = UDim2.new(1, -14, 0.5, 0)
textButton.AnchorPoint = Vector2.new(1, 0.5)
textButton.BackgroundTransparency = 1
textButton.Text = "✕"
textButton.TextColor3 = Color3.fromRGB(150, 150, 170)
textButton.TextSize = 16
textButton.Font = {}
textButton.Parent = frame2
textButton.MouseEnter:Connect(function()
    TweenService.Create(TweenService, textButton, TweenInfo.new(0.15), {}):Play()
end)
textButton.MouseLeave:Connect(function()
    TweenService.Create(TweenService, textButton, TweenInfo.new(0.15), {}):Play()
end)
local frame5 = Instance.new("Frame")
frame5.Size = UDim2.new(0.9, 0, 0, 55)
frame5.Position = UDim2.new(0.5, 0, 0, 70)
frame5.AnchorPoint = Vector2.new(0.5, 0)
frame5.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
frame5.BorderSizePixel = 0
frame5.Parent = frame
local uICorner4 = Instance.new("UICorner")
uICorner4.CornerRadius = UDim.new(0, 8)
uICorner4.Parent = frame5
local uIStroke2 = Instance.new("UIStroke")
uIStroke2.Color = Color3.fromRGB(180, 20, 30)
uIStroke2.Thickness = 1
uIStroke2.Transparency = 0.6
uIStroke2.Parent = frame5
local textLabel3 = Instance.new("TextLabel")
textLabel3.Size = UDim2.new(0, 28, 0, 28)
textLabel3.Position = UDim2.new(0, 14, 0.5, 0)
textLabel3.AnchorPoint = Vector2.new(0, 0.5)
textLabel3.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
textLabel3.BackgroundTransparency = 0.15
textLabel3.Text = "●"
textLabel3.TextColor3 = Color3.fromRGB(180, 20, 30)
textLabel3.TextSize = 20
textLabel3.Font = {}
textLabel3.Parent = frame5
local uICorner5 = Instance.new("UICorner")
uICorner5.CornerRadius = UDim.new(0, 6)
uICorner5.Parent = textLabel3
local textLabel4 = Instance.new("TextLabel")
textLabel4.Size = UDim2.new(1, -60, 0, 22)
textLabel4.Position = UDim2.new(0, 52, 0, 10)
textLabel4.BackgroundTransparency = 1
textLabel4.Text = "Enter your key"
textLabel4.TextColor3 = Color3.fromRGB(245, 245, 255)
textLabel4.TextSize = 14
textLabel4.Font = {}
textLabel4.TextXAlignment = {}
textLabel4.Parent = frame5
local textLabel5 = Instance.new("TextLabel")
textLabel5.Size = UDim2.new(1, -60, 0, 16)
textLabel5.Position = UDim2.new(0, 52, 0, 32)
textLabel5.BackgroundTransparency = 1
textLabel5.Text = "Key Lifetime? Open Ticket"
textLabel5.TextColor3 = Color3.fromRGB(150, 150, 170)
textLabel5.TextSize = 11
textLabel5.Font = {}
textLabel5.TextXAlignment = {}
textLabel5.Parent = frame5
local frame6 = Instance.new("Frame")
frame6.Size = UDim2.new(0.9, 0, 0, 50)
frame6.Position = UDim2.new(0.5, 0, 0, 140)
frame6.AnchorPoint = Vector2.new(0.5, 0)
frame6.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
frame6.BorderSizePixel = 0
frame6.Parent = frame
local uICorner6 = Instance.new("UICorner")
uICorner6.CornerRadius = UDim.new(0, 8)
uICorner6.Parent = frame6
local uIStroke3 = Instance.new("UIStroke")
uIStroke3.Color = Color3.fromRGB(55, 55, 70)
uIStroke3.Thickness = 1.5
uIStroke3.Parent = frame6
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -24, 1, 0)
textBox.Position = UDim2.new(0, 12, 0.5, 0)
textBox.AnchorPoint = Vector2.new(0, 0.5)
textBox.BackgroundTransparency = 1
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(245, 245, 255)
textBox.PlaceholderText = "FIQQ-XXXX-XXXX"
textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
textBox.TextSize = 13
textBox.Font = {}
textBox.ClearTextOnFocus = false
textBox.Parent = frame6
textBox.Focused:Connect(function()
    TweenService.Create(TweenService, uIStroke3, TweenInfo.new(0.15), {}):Play()
end)
textBox.FocusLost:Connect(function()
    TweenService.Create(TweenService, uIStroke3, TweenInfo.new(0.15), {}):Play()
end)
local textButton2 = Instance.new("TextButton")
textButton2.Size = UDim2.new(0.85, 0, 0, 45)
textButton2.Position = UDim2.new(0.5, 0, 0, 205)
textButton2.AnchorPoint = Vector2.new(0.5, 0)
textButton2.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
textButton2.BorderSizePixel = 0
textButton2.Text = ""
textButton2.AutoButtonColor = false
textButton2.Parent = frame
local uICorner7 = Instance.new("UICorner")
uICorner7.CornerRadius = UDim.new(0, 8)
uICorner7.Parent = textButton2
local uIStroke4 = Instance.new("UIStroke")
uIStroke4.Color = Color3.fromRGB(210, 40, 50)
uIStroke4.Thickness = 1
uIStroke4.Transparency = 0.5
uIStroke4.Parent = textButton2
local textLabel6 = Instance.new("TextLabel")
textLabel6.Size = UDim2.new(1, 0, 1, 0)
textLabel6.BackgroundTransparency = 1
textLabel6.Text = "REDEEM KEY"
textLabel6.TextColor3 = Color3.fromRGB(245, 245, 255)
textLabel6.TextSize = 14
textLabel6.Font = {}
textLabel6.Parent = textButton2
textButton2.MouseEnter:Connect(function()
    TweenService.Create(TweenService, textButton2, TweenInfo.new(0.15), {}):Play()
    TweenService.Create(TweenService, uIStroke4, TweenInfo.new(0.15), {}):Play()
end)
textButton2.MouseLeave:Connect(function()
    TweenService.Create(TweenService, textButton2, TweenInfo.new(0.15), {}):Play()
    TweenService.Create(TweenService, uIStroke4, TweenInfo.new(0.15), {}):Play()
end)
local textButton3 = Instance.new("TextButton")
textButton3.Size = UDim2.new(0.85, 0, 0, 35)
textButton3.Position = UDim2.new(0.5, 0, 0, 260)
textButton3.AnchorPoint = Vector2.new(0.5, 0)
textButton3.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
textButton3.BorderSizePixel = 0
textButton3.Text = "GET KEY IN DISCORD"
textButton3.TextColor3 = Color3.fromRGB(150, 150, 170)
textButton3.TextSize = 11
textButton3.Font = {}
textButton3.Parent = frame
local uICorner8 = Instance.new("UICorner")
uICorner8.CornerRadius = UDim.new(0, 8)
uICorner8.Parent = textButton3
local uIStroke5 = Instance.new("UIStroke")
uIStroke5.Color = Color3.fromRGB(45, 45, 55)
uIStroke5.Thickness = 1
uIStroke5.Parent = textButton3
textButton3.MouseEnter:Connect(function()
    TweenService.Create(TweenService, textButton3, TweenInfo.new(0.15), {}):Play()
    TweenService.Create(TweenService, uIStroke5, TweenInfo.new(0.15), {}):Play()
end)
textButton3.MouseLeave:Connect(function()
    TweenService.Create(TweenService, textButton3, TweenInfo.new(0.15), {}):Play()
    TweenService.Create(TweenService, uIStroke5, TweenInfo.new(0.15), {}):Play()
end)
textButton3.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/k89KC3EZQt")
    local screenGui2 = Instance.new("ScreenGui")
    screenGui2.Name = "ArqelRedNotify"
    screenGui2.ResetOnSpawn = false
    screenGui2.Parent = CoreGui
    local frame7 = Instance.new("Frame")
    frame7.Size = UDim2.new(0, 320, 0, 65)
    frame7.Position = UDim2.new(1, 330, 1, -20)
    frame7.AnchorPoint = Vector2.new(1, 1)
    frame7.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame7.BorderSizePixel = 0
    frame7.Parent = screenGui2
    local uICorner9 = Instance.new("UICorner")
    uICorner9.CornerRadius = UDim.new(0, 8)
    uICorner9.Parent = frame7
    local uIStroke6 = Instance.new("UIStroke")
    uIStroke6.Color = Color3.fromRGB(180, 20, 30)
    uIStroke6.Thickness = 1.5
    uIStroke6.Parent = frame7
    local textLabel7 = Instance.new("TextLabel")
    textLabel7.Size = UDim2.new(0, 30, 0, 30)
    textLabel7.Position = UDim2.new(0, 12, 0.5, 0)
    textLabel7.AnchorPoint = Vector2.new(0, 0.5)
    textLabel7.BackgroundTransparency = 1
    textLabel7.Text = "●"
    textLabel7.TextColor3 = Color3.fromRGB(180, 20, 30)
    textLabel7.TextSize = 20
    textLabel7.Font = {}
    textLabel7.Parent = frame7
    local textLabel8 = Instance.new("TextLabel")
    textLabel8.Size = UDim2.new(1, -55, 0, 22)
    textLabel8.Position = UDim2.new(0, 50, 0, 8)
    textLabel8.BackgroundTransparency = 1
    textLabel8.Text = "Info"
    textLabel8.TextColor3 = Color3.fromRGB(245, 245, 255)
    textLabel8.TextSize = 14
    textLabel8.Font = {}
    textLabel8.TextXAlignment = {}
    textLabel8.Parent = frame7
    local textLabel9 = Instance.new("TextLabel")
    textLabel9.Size = UDim2.new(1, -55, 0, 22)
    textLabel9.Position = UDim2.new(0, 50, 0, 30)
    textLabel9.BackgroundTransparency = 1
    textLabel9.Text = "DISCORD FIQQZR7 EXPLOITS"
    textLabel9.TextColor3 = Color3.fromRGB(150, 150, 170)
    textLabel9.TextSize = 12
    textLabel9.Font = {}
    textLabel9.TextXAlignment = {}
    textLabel9.Parent = frame7
    local frame8 = Instance.new("Frame")
    frame8.Size = UDim2.new(1, 0, 0, 2)
    frame8.Position = UDim2.new(0, 0, 1, -2)
    frame8.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame8.BorderSizePixel = 0
    frame8.Parent = frame7
    local frame9 = Instance.new("Frame")
    frame9.Size = UDim2.new(1, 0, 1, 0)
    frame9.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
    frame9.BorderSizePixel = 0
    frame9.Parent = frame8
    TweenService.Create(TweenService, frame7, TweenInfo.new(0.4, {}), {}):Play()
    TweenService.Create(TweenService, frame9, TweenInfo.new(8, {}), {}):Play()
    task.delay(8, function()
        TweenService.Create(TweenService, frame7, TweenInfo.new(0.3, {}), {}):Play()
        task.wait(0.3)
        screenGui2:Destroy()
    end)
end)
frame2.InputBegan:Connect(function()
end)
UserInputService.InputChanged:Connect(function()
end)
local frame10 = Instance.new("Frame")
frame10.Name = "DoorOverlay"
frame10.Size = UDim2.new(1, 0, 1, 0)
frame10.BackgroundTransparency = 1
frame10.ClipsDescendants = true
frame10.ZIndex = 50
frame10.Parent = frame
local frame11 = Instance.new("Frame")
frame11.Name = "LeftDoor"
frame11.Size = UDim2.new(0.5, 0, 1, 0)
frame11.Position = UDim2.new(0, 0, 0, 0)
frame11.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
frame11.BorderSizePixel = 0
frame11.ZIndex = 51
frame11.Parent = frame10
local frame12 = Instance.new("Frame")
frame12.Name = "RightDoor"
frame12.Size = UDim2.new(0.5, 0, 1, 0)
frame12.Position = UDim2.new(0.5, 0, 0, 0)
frame12.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
frame12.BorderSizePixel = 0
frame12.ZIndex = 51
frame12.Parent = frame10
textButton2.MouseButton1Click:Connect(function()
    textLabel3.Text = "◌"
    textLabel4.Text = "Verifying key..."
    textLabel5.Text = "Please wait..."
    TweenService.Create(TweenService, textLabel3, TweenInfo.new(0.2), {}):Play()
    textButton2.Active = false
    task.wait(0.5)
    textLabel3.Text = "✗"
    textLabel4.Text = "Invalid Key!"
    textLabel5.Text = "Attempt 1/5"
    TweenService.Create(TweenService, textLabel3, TweenInfo.new(0.2), {}):Play()
    local screenGui3 = Instance.new("ScreenGui")
    screenGui3.Name = "ArqelRedNotify"
    screenGui3.ResetOnSpawn = false
    screenGui3.Parent = CoreGui
    local frame13 = Instance.new("Frame")
    frame13.Size = UDim2.new(0, 320, 0, 65)
    frame13.Position = UDim2.new(1, 330, 1, -20)
    frame13.AnchorPoint = Vector2.new(1, 1)
    frame13.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame13.BorderSizePixel = 0
    frame13.Parent = screenGui3
    local uICorner10 = Instance.new("UICorner")
    uICorner10.CornerRadius = UDim.new(0, 8)
    uICorner10.Parent = frame13
    local uIStroke7 = Instance.new("UIStroke")
    uIStroke7.Color = Color3.fromRGB(220, 50, 70)
    uIStroke7.Thickness = 1.5
    uIStroke7.Parent = frame13
    local textLabel10 = Instance.new("TextLabel")
    textLabel10.Size = UDim2.new(0, 30, 0, 30)
    textLabel10.Position = UDim2.new(0, 12, 0.5, 0)
    textLabel10.AnchorPoint = Vector2.new(0, 0.5)
    textLabel10.BackgroundTransparency = 1
    textLabel10.Text = "✗"
    textLabel10.TextColor3 = Color3.fromRGB(220, 50, 70)
    textLabel10.TextSize = 20
    textLabel10.Font = {}
    textLabel10.Parent = frame13
    local textLabel11 = Instance.new("TextLabel")
    textLabel11.Size = UDim2.new(1, -55, 0, 22)
    textLabel11.Position = UDim2.new(0, 50, 0, 8)
    textLabel11.BackgroundTransparency = 1
    textLabel11.Text = "Error"
    textLabel11.TextColor3 = Color3.fromRGB(245, 245, 255)
    textLabel11.TextSize = 14
    textLabel11.Font = {}
    textLabel11.TextXAlignment = {}
    textLabel11.Parent = frame13
    local textLabel12 = Instance.new("TextLabel")
    textLabel12.Size = UDim2.new(1, -55, 0, 22)
    textLabel12.Position = UDim2.new(0, 50, 0, 30)
    textLabel12.BackgroundTransparency = 1
    textLabel12.Text = "Invalid license key"
    textLabel12.TextColor3 = Color3.fromRGB(150, 150, 170)
    textLabel12.TextSize = 12
    textLabel12.Font = {}
    textLabel12.TextXAlignment = {}
    textLabel12.Parent = frame13
    local frame14 = Instance.new("Frame")
    frame14.Size = UDim2.new(1, 0, 0, 2)
    frame14.Position = UDim2.new(0, 0, 1, -2)
    frame14.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame14.BorderSizePixel = 0
    frame14.Parent = frame13
    local frame15 = Instance.new("Frame")
    frame15.Size = UDim2.new(1, 0, 1, 0)
    frame15.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
    frame15.BorderSizePixel = 0
    frame15.Parent = frame14
    TweenService.Create(TweenService, frame13, TweenInfo.new(0.4, {}), {}):Play()
    TweenService.Create(TweenService, frame15, TweenInfo.new(3, {}), {}):Play()
    task.delay(3, function()
        TweenService.Create(TweenService, frame13, TweenInfo.new(0.3, {}), {}):Play()
        task.wait(0.3)
        screenGui3:Destroy()
    end)
    textButton2.Active = true
    task.delay(2, function()
        textLabel3.Text = "●"
        textLabel4.Text = "Enter your key"
        textLabel5.Text = "Paste your license key below"
        TweenService.Create(TweenService, textLabel3, TweenInfo.new(0.2), {}):Play()
    end)
end)
textBox.FocusLost:Connect(function()
end)
textButton.MouseButton1Click:Connect(function()
    frame10.Visible = true
    frame11.Position = UDim2.new(0, -200, 0, 0)
    frame12.Position = UDim2.new(1, 200, 0, 0)
    TweenService.Create(TweenService, frame11, TweenInfo.new(0.35, {}, {}), {}):Play()
    TweenService.Create(TweenService, frame12, TweenInfo.new(0.35, {}, {}), {}):Play()
    task.wait(0.4)
    TweenService.Create(TweenService, frame, TweenInfo.new(0.4, {}), {}):Play()
    task.wait(0.4)
    TweenService.Create(TweenService, blurEffect, TweenInfo.new(0.3), {}):Play()
    task.wait(0.3)
    blurEffect:Destroy()
    screenGui:Destroy()
    print("Key system closed")
end)
TweenService.Create(TweenService, frame, TweenInfo.new(0.5, {}), {}):Play()
task.wait(0.6)
TweenService.Create(TweenService, frame11, TweenInfo.new(0.4, {}, {}), {}):Play()
TweenService.Create(TweenService, frame12, TweenInfo.new(0.4, {}, {}), {}):Play()
task.wait(0.45)
frame10.Visible = false
