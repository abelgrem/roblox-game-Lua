local enemy = script.Parent
local humanoid = enemy:WaitForChild("Humanoid")
local hrp = enemy:WaitForChild("HumanoidRootPart")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiveXPEvent = ReplicatedStorage:WaitForChild("GiveXP")


local XPValue = 100 
local CoinsValue = 10 


local speed = 21
humanoid.WalkSpeed = speed

local hasGivenReward = false


local function getClosestPlayer()
	local closestPlayer = nil
	local closestDistance = math.huge
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist < closestDistance then
				closestDistance = dist
				closestPlayer = player
			end
		end
	end
	return closestPlayer
end


RunService.Heartbeat:Connect(function()
	if humanoid.Health <= 0 then return end
	if hrp.Anchored then return end
	local target = getClosestPlayer()
	if target then
		humanoid:MoveTo(target.Character.HumanoidRootPart.Position)
	end
end)


humanoid.Died:Connect(function()

	if hasGivenReward then return end
	hasGivenReward = true


	local playerToReward = getClosestPlayer()

	if playerToReward then
		-- Donne XP
		GiveXPEvent:FireClient(playerToReward, XPValue)


		local leaderstats = playerToReward:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value = coins.Value + CoinsValue
			end
		end

		if playerToReward.Character then
			local coinSound = Instance.new("Sound")
			coinSound.SoundId = "rbxassetid://138072213"
			coinSound.Volume = 0.5
			coinSound.Parent = playerToReward.Character:FindFirstChild("HumanoidRootPart")
			if coinSound.Parent then
				coinSound:Play()
				game:GetService("Debris"):AddItem(coinSound, 2)
			end
		end
	end


	for _, part in pairs(enemy:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 1
		elseif part:IsA("Decal") or part:IsA("Texture") then
			part.Transparency = 1
		end
	end


	enemy:Destroy()
end)
