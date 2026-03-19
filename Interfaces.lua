local Players = game:GetService("Players") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local PauseEvent = ReplicatedStorage:WaitForChild("LevelPauseEvent")
local CardModule = require(ReplicatedStorage:WaitForChild("CardEffects"))

local timerStopped = false

local gui = Instance.new("ScreenGui")
gui.Name = "UIXP"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0.4,0,0,4)
container.Position = UDim2.new(0.3,0,0,2)
container.BackgroundColor3 = Color3.fromRGB(8,8,10)
container.BackgroundTransparency = 0.7
container.BorderSizePixel = 0
container.Parent = gui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(1,0)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Color3.fromRGB(0,180,240)
containerStroke.Thickness = 0.5
containerStroke.Transparency = 0.85
containerStroke.Parent = container

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0,0,1,0)
bar.BackgroundColor3 = Color3.fromRGB(0,200,255)
bar.BackgroundTransparency = 0.2
bar.BorderSizePixel = 0
bar.Parent = container

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1,0)
barCorner.Parent = bar

local barGradient = Instance.new("UIGradient")
barGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0,220,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0,160,240))
}
barGradient.Offset = Vector2.new(0,0)
barGradient.Parent = bar

task.spawn(function()
	while bar.Parent do
		TweenService:Create(
			barGradient,
			TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
			{Offset = Vector2.new(1,0)}
		):Play()
		break
	end
end)

local barGlow = Instance.new("Frame")
barGlow.Size = UDim2.new(1,0,1,4)
barGlow.Position = UDim2.new(0,0,0,-2)
barGlow.BackgroundColor3 = Color3.fromRGB(0,200,255)
barGlow.BackgroundTransparency = 0.9
barGlow.BorderSizePixel = 0
barGlow.ZIndex = bar.ZIndex - 1
barGlow.Parent = bar

local barGlowCorner = Instance.new("UICorner")
barGlowCorner.CornerRadius = UDim.new(1,0)
barGlowCorner.Parent = barGlow

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(0,150,0,30)
infoText.Position = UDim2.new(0.5,0,0,8)
infoText.AnchorPoint = Vector2.new(0.5,0)
infoText.BackgroundColor3 = Color3.fromRGB(12,12,15)
infoText.BackgroundTransparency = 0.3
infoText.BorderSizePixel = 0
infoText.Font = Enum.Font.GothamMedium
infoText.TextSize = 12
infoText.TextColor3 = Color3.fromRGB(255,255,255)
infoText.Visible = false
infoText.Parent = container

local infoTextCorner = Instance.new("UICorner")
infoTextCorner.CornerRadius = UDim.new(0,6)
infoTextCorner.Parent = infoText

local infoTextStroke = Instance.new("UIStroke")
infoTextStroke.Color = Color3.fromRGB(0,180,240)
infoTextStroke.Thickness = 1
infoTextStroke.Transparency = 0.6
infoTextStroke.Parent = infoText

local levelIndicator = Instance.new("TextLabel")
levelIndicator.Size = UDim2.new(0,40,0,16)
levelIndicator.Position = UDim2.new(0,-45,0.5,0)
levelIndicator.AnchorPoint = Vector2.new(0,0.5)
levelIndicator.BackgroundColor3 = Color3.fromRGB(12,12,15)
levelIndicator.BackgroundTransparency = 0.4
levelIndicator.BorderSizePixel = 0
levelIndicator.Font = Enum.Font.GothamBold
levelIndicator.TextSize = 11
levelIndicator.TextColor3 = Color3.fromRGB(255,215,0)
levelIndicator.Parent = container

local levelIndicatorCorner = Instance.new("UICorner")
levelIndicatorCorner.CornerRadius = UDim.new(0,8)
levelIndicatorCorner.Parent = levelIndicator

local levelIndicatorStroke = Instance.new("UIStroke")
levelIndicatorStroke.Color = Color3.fromRGB(255,215,0)
levelIndicatorStroke.Thickness = 1
levelIndicatorStroke.Transparency = 0.6
levelIndicatorStroke.Parent = levelIndicator

container.MouseEnter:Connect(function()
	infoText.Visible = true
	TweenService:Create(infoText,TweenInfo.new(0.2, Enum.EasingStyle.Quad),{BackgroundTransparency = 0.1}):Play()
	TweenService:Create(container,TweenInfo.new(0.2, Enum.EasingStyle.Quad),{Size = UDim2.new(0.4,0,0,6), BackgroundTransparency = 0.5}):Play()
	TweenService:Create(containerStroke,TweenInfo.new(0.2),{Transparency = 0.6, Thickness = 1}):Play()
end)

container.MouseLeave:Connect(function()
	infoText.Visible = false
	TweenService:Create(container,TweenInfo.new(0.2, Enum.EasingStyle.Quad),{Size = UDim2.new(0.4,0,0,4), BackgroundTransparency = 0.7}):Play()
	TweenService:Create(containerStroke,TweenInfo.new(0.2),{Transparency = 0.85, Thickness = 0.5}):Play()
end)

local XP = 0
local Level = 1
local function getXpForLevel(lvl) return lvl * 100 end

local function updateBar()
	local ratio = math.clamp(XP / getXpForLevel(Level),0,1)

	TweenService:Create(bar,TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = UDim2.new(ratio,0,1,0)}):Play()

	TweenService:Create(containerStroke,TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Transparency = 0.4}):Play()

	task.delay(0.2, function()
		TweenService:Create(containerStroke,TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Transparency = 0.85}):Play()
	end)

	TweenService:Create(levelIndicator,TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),{Size = UDim2.new(0,44,0,18)}):Play()

	task.delay(0.15, function()
		TweenService:Create(levelIndicator,TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),{Size = UDim2.new(0,40,0,16)}):Play()
	end)

	levelIndicator.Text = "Nv."..Level
	infoText.Text = Level.." • "..XP.."/"..getXpForLevel(Level).." XP"
end

function addXP(amount)
	XP += amount
	local leveledUp = false

	while XP >= getXpForLevel(Level) do
		XP -= getXpForLevel(Level)
		Level += 1
		leveledUp = true
	end

	updateBar()

	if leveledUp then
		PauseEvent:FireServer()
	end
end

local GiveXPEvent = ReplicatedStorage:WaitForChild("GiveXP")
GiveXPEvent.OnClientEvent:Connect(addXP)

player.CharacterAdded:Connect(function()
	XP = 0
	Level = 1
	updateBar()
end)

updateBar()
