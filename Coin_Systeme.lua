local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")


local CoinsDataStore = DataStoreService:GetDataStore("PlayerCoinsData_v1")
local GemsDataStore = DataStoreService:GetDataStore("PlayerGemsData_v1")


local GiveCoinsEvent = Instance.new("RemoteEvent")
GiveCoinsEvent.Name = "GiveCoins"
GiveCoinsEvent.Parent = ReplicatedStorage

local UpdateCoinsEvent = Instance.new("RemoteEvent")
UpdateCoinsEvent.Name = "UpdateCoins"
UpdateCoinsEvent.Parent = ReplicatedStorage

local GiveGemsEvent = Instance.new("RemoteEvent")
GiveGemsEvent.Name = "GiveGems"
GiveGemsEvent.Parent = ReplicatedStorage

local UpdateGemsEvent = Instance.new("RemoteEvent")
UpdateGemsEvent.Name = "UpdateGems"
UpdateGemsEvent.Parent = ReplicatedStorage

local function giveCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = coins.Value + amount
			UpdateCoinsEvent:FireClient(player, coins.Value)
		end
	end
end


local function giveGems(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local gems = leaderstats:FindFirstChild("Gems")
		if gems then
			gems.Value = gems.Value + amount
			UpdateGemsEvent:FireClient(player, gems.Value)
		end
	end
end


local function loadPlayerData(player)
	local userId = player.UserId
	local coins, gems = 0, 0

	local successCoins, dataCoins = pcall(function()
		return CoinsDataStore:GetAsync(userId)
	end)

	local successGems, dataGems = pcall(function()
		return GemsDataStore:GetAsync(userId)
	end)

	if successCoins and dataCoins then
		coins = dataCoins
	end

	if successGems and dataGems then
		gems = dataGems
	end

	return coins, gems
end


local function savePlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coins = leaderstats:FindFirstChild("Coins")
	local gems = leaderstats:FindFirstChild("Gems")
	local userId = player.UserId

	if coins then
		local success, errorMessage = pcall(function()
			CoinsDataStore:SetAsync(userId, coins.Value)
		end)
		if success then
			print("Pièces sauvegardées pour " .. player.Name .. " : " .. coins.Value)
		else
			warn("Erreur sauvegarde pièces pour " .. player.Name .. " : " .. errorMessage)
		end
	end

	if gems then
		local success, errorMessage = pcall(function()
			GemsDataStore:SetAsync(userId, gems.Value)
		end)
		if success then
			print("Gemmes sauvegardées pour " .. player.Name .. " : " .. gems.Value)
		else
			warn("Erreur sauvegarde gemmes pour " .. player.Name .. " : " .. errorMessage)
		end
	end
end


Players.PlayerAdded:Connect(function(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	local gems = Instance.new("IntValue")
	gems.Name = "Gems"
	gems.Value = 0
	gems.Parent = leaderstats


	local savedCoins, savedGems = loadPlayerData(player)
	coins.Value = savedCoins
	gems.Value = savedGems

	print(player.Name .. " a rejoint avec " .. savedCoins .. " pièces et " .. savedGems .. " gemmes")


	wait(0.5)
	UpdateCoinsEvent:FireClient(player, coins.Value)
	UpdateGemsEvent:FireClient(player, gems.Value)


	spawn(function()
		while player.Parent do
			wait(60)
			savePlayerData(player)
		end
	end)
end)


Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)


GiveCoinsEvent.OnServerEvent:Connect(function(player, amount)
	giveCoins(player, amount)
end)


GiveGemsEvent.OnServerEvent:Connect(function(player, amount)
	giveGems(player, amount)
end)

spawn(function()
	while true do
		wait(300)
		for _, player in pairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
		print("Sauvegarde automatique effectuée pour tous les joueurs")
	end
end)


game:BindToClose(function()
	print("Serveur en fermeture - Sauvegarde de tous les joueurs...")
	for _, player in pairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	wait(3)
end)
