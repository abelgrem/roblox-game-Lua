local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")


local ArmorDataStore = DataStoreService:GetDataStore("PlayerArmor_v1")


local OpenArmorShopEvent = ReplicatedStorage:WaitForChild("OpenArmorShop")
local CloseArmorShopEvent = ReplicatedStorage:WaitForChild("CloseArmorShop")
local BuyArmorEvent = ReplicatedStorage:WaitForChild("BuyArmor")
local GetPlayerArmorEvent = ReplicatedStorage:WaitForChild("GetPlayerArmor")

local ARMOR_LEVELS = {
	[1] = {
		name = "Armure de Cuir",
		description = "Protection basique +50 PV",
		price = 10,  -- Prix baissé de 100 à 10
		healthBonus = 50,
		armorType = "Leather",
		color = Color3.fromRGB(139, 90, 43)
	},
	[2] = {
		name = "Armure de Bois",
		description = "Protection améliorée +100 PV",
		price = 25,  -- Prix baissé de 500 à 25
		healthBonus = 100,
		armorType = "Wood",
		color = Color3.fromRGB(101, 67, 33)
	},
	[3] = {
		name = "Armure de Pierre",
		description = "Protection solide +200 PV",
		price = 50,  -- Prix baissé de 1500 à 50
		healthBonus = 200,
		armorType = "Stone",
		color = Color3.fromRGB(128, 128, 128)
	}
}

local function loadPlayerArmor(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return ArmorDataStore:GetAsync(userId)
	end)

	if success and data then
		print("Armure chargée pour " .. player.Name .. ": Niveau " .. (data.ArmorLevel or 0))
		return data
	else
		print("Nouvelle armure créée pour " .. player.Name)
		return {ArmorLevel = 0}
	end
end


local function savePlayerArmor(player, armorData)
	local userId = player.UserId
	local success, errorMessage = pcall(function()
		ArmorDataStore:SetAsync(userId, armorData)
	end)

	if success then
		print("✅ Armure sauvegardée pour " .. player.Name .. " - Niveau: " .. (armorData.ArmorLevel or 0))
	else
		warn("❌ Erreur sauvegarde armure pour " .. player.Name .. " : " .. tostring(errorMessage))
	end
end

local function createArmorVisual(character, armorLevel)
	
	local oldArmor = character:FindFirstChild("ArmorParts")
	if oldArmor then
		oldArmor:Destroy()
	end

	if armorLevel == 0 then return end

	local armorData = ARMOR_LEVELS[armorLevel]
	if not armorData then return end


	local armorFolder = Instance.new("Folder")
	armorFolder.Name = "ArmorParts"
	armorFolder.Parent = character

	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then return end


	local chestArmor = Instance.new("Part")
	chestArmor.Name = "ChestArmor"
	chestArmor.Size = Vector3.new(2.2, 2.2, 1.2)
	chestArmor.Color = armorData.color
	chestArmor.Material = Enum.Material.Metal
	chestArmor.CanCollide = false
	chestArmor.Transparency = 0.3
	chestArmor.Parent = armorFolder


	local weld = Instance.new("Weld")
	weld.Part0 = torso
	weld.Part1 = chestArmor
	weld.C0 = CFrame.new(0, 0, 0)
	weld.Parent = chestArmor

	local function createShoulder(side)
		local arm = character:FindFirstChild(side .. "Arm") or character:FindFirstChild(side .. "UpperArm")
		if not arm then return end

		local shoulder = Instance.new("Part")
		shoulder.Name = side .. "Shoulder"
		shoulder.Size = Vector3.new(1.3, 0.8, 1.3)
		shoulder.Color = armorData.color
		shoulder.Material = Enum.Material.Metal
		shoulder.CanCollide = false
		shoulder.Transparency = 0.3
		shoulder.Parent = armorFolder

		local shoulderWeld = Instance.new("Weld")
		shoulderWeld.Part0 = torso
		shoulderWeld.Part1 = shoulder
		if side == "Left" then
			shoulderWeld.C0 = CFrame.new(-1.5, 0.8, 0)
		else
			shoulderWeld.C0 = CFrame.new(1.5, 0.8, 0)
		end
		shoulderWeld.Parent = shoulder
	end

	createShoulder("Left")
	createShoulder("Right")

	print("✨ Armure " .. armorData.name .. " équipée visuellement sur " .. character.Name)
end


local function applyArmor(player)
	local armorJson = player:GetAttribute("Armor_Data")
	local armor

	if not armorJson then
		armor = loadPlayerArmor(player)
		player:SetAttribute("Armor_Data", game:GetService("HttpService"):JSONEncode(armor))
	else
		armor = game:GetService("HttpService"):JSONDecode(armorJson)
	end

	local armorLevel = armor.ArmorLevel or 0


	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	if armorLevel > 0 and ARMOR_LEVELS[armorLevel] then
		local armorData = ARMOR_LEVELS[armorLevel]


		humanoid.MaxHealth = 100 + armorData.healthBonus
		humanoid.Health = humanoid.MaxHealth

		player:SetAttribute("ArmorLevel", armorLevel)
		player:SetAttribute("MaxHealthBonus", armorData.healthBonus)


		createArmorVisual(character, armorLevel)

		print("✨ " .. player.Name .. " - Armure: " .. armorData.name .. " (+" .. armorData.healthBonus .. " PV)")
	else
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		player:SetAttribute("ArmorLevel", 0)
		player:SetAttribute("MaxHealthBonus", 0)

		print("✨ " .. player.Name .. " - Pas d'armure équipée")
	end
end

-- Quand un joueur rejoint
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		applyArmor(player)
	end)
end)

-- Quand un joueur quitte
Players.PlayerRemoving:Connect(function(player)
	local armorJson = player:GetAttribute("Armor_Data")
	if armorJson then
		local armor = game:GetService("HttpService"):JSONDecode(armorJson)
		savePlayerArmor(player, armor)
	end
end)

GetPlayerArmorEvent.OnServerInvoke = function(player)
	local armorJson = player:GetAttribute("Armor_Data") or game:GetService("HttpService"):JSONEncode({ArmorLevel = 0})
	local armor = game:GetService("HttpService"):JSONDecode(armorJson)

	local result = {
		armorLevel = armor.ArmorLevel or 0,
		maxLevel = #ARMOR_LEVELS
	}

	print("📊 Envoi des données armure au client pour " .. player.Name .. ": Niveau " .. result.armorLevel)

	return result
end


BuyArmorEvent.OnServerEvent:Connect(function(player, targetLevel)
	print("🛒 Demande d'achat d'armure de " .. player.Name .. " pour niveau " .. tostring(targetLevel))


	if type(targetLevel) ~= "number" or targetLevel < 1 or targetLevel > #ARMOR_LEVELS then
		print("❌ Niveau d'armure invalide: " .. tostring(targetLevel))
		return
	end


	local armorJson = player:GetAttribute("Armor_Data") or game:GetService("HttpService"):JSONEncode({ArmorLevel = 0})
	local armor = game:GetService("HttpService"):JSONDecode(armorJson)

	local currentLevel = armor.ArmorLevel or 0


	if targetLevel ~= currentLevel + 1 then
		print("❌ Doit acheter le niveau " .. (currentLevel + 1) .. " avant le niveau " .. targetLevel)
		BuyArmorEvent:FireClient(player, false, currentLevel)
		return
	end

	local armorData = ARMOR_LEVELS[targetLevel]

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then 
		print("❌ Pas de leaderstats pour " .. player.Name)
		return 
	end

	local gems = leaderstats:FindFirstChild("Gems")
	if not gems then
		print("❌ Pas de Gems dans leaderstats pour " .. player.Name)
		return
	end

	if gems.Value < armorData.price then
		print("❌ " .. player.Name .. " n'a pas assez de gemmes: " .. gems.Value .. "/" .. armorData.price)
		BuyArmorEvent:FireClient(player, false, currentLevel)
		return
	end


	gems.Value = gems.Value - armorData.price
	print("💎 " .. armorData.price .. " gemmes retirées. Nouveau solde: " .. gems.Value)

	armor.ArmorLevel = targetLevel
	player:SetAttribute("Armor_Data", game:GetService("HttpService"):JSONEncode(armor))


	applyArmor(player)


	savePlayerArmor(player, armor)


	BuyArmorEvent:FireClient(player, true, targetLevel)

	print("✅ " .. player.Name .. " a acheté " .. armorData.name)
end)


task.spawn(function()
	while true do
		task.wait(300)
		for _, player in pairs(Players:GetPlayers()) do
			local armorJson = player:GetAttribute("Armor_Data")
			if armorJson then
				local armor = game:GetService("HttpService"):JSONDecode(armorJson)
				savePlayerArmor(player, armor)
			end
		end
		print("💾 Sauvegarde automatique des armures effectuée")
	end
end)


game:BindToClose(function()
	print("💾 Sauvegarde finale des armures avant fermeture du serveur...")
	for _, player in pairs(Players:GetPlayers()) do
		local armorJson = player:GetAttribute("Armor_Data")
		if armorJson then
			local armor = game:GetService("HttpService"):JSONDecode(armorJson)
			savePlayerArmor(player, armor)
		end
	end
	task.wait(3)
end)

print("🛡️ ArmorSystem initialisé")
