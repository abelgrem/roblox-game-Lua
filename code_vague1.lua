local EnemyNames = { "Enemy1V", "Enemy2V" }
local WaveDelay = 1
local ShootHandler = game:GetService("ServerScriptService"):WaitForChild("ShootHandler")
local wave2Script = script.Parent:FindFirstChild("WAVE2")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- 🔴 Désactiver le script et ShootHandler si le joueur meurt
local function disableOnPlayerDeath()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					ShootHandler.Disabled = true
					script.Disabled = true
				end)
			end
		end
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				ShootHandler.Disabled = true
				script.Disabled = true
			end)
		end)
	end
end
disableOnPlayerDeath()

-- Fonction pour activer un ennemi
local function unlockEnemy(enemy)
	for _, part in ipairs(enemy:GetDescendants()) do
		if part.Name == "Sword" and part:IsA("Part") then
			part.Transparency = 0
			part.CanCollide = true
		end
		if part:IsA("MeshPart") then
			for _, subPart in ipairs(part:GetChildren()) do
				if subPart:IsA("Part") then
					subPart.Transparency = 0
				end
			end
		end
	end
	local hrp = enemy:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = false end
	local healthGui = enemy:FindFirstChild("HealthBarGui")
	if healthGui then healthGui.Enabled = true end
	local aiScript = enemy:FindFirstChild("EnemyAIV")
	if aiScript then aiScript.Disabled = false end
	local swordScript = enemy:FindFirstChild("EnemyVSwordDamage")
	if swordScript then swordScript.Disabled = false end
end

-- Afficher du texte à l'écran du joueur (VERSION AMÉLIORÉE)
local function showWaveText(player, waveNumber, isComplete)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	-- Supprimer les anciens WaveTextGui
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui.Name == "WaveTextGui" then
			gui:Destroy()
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.ResetOnSpawn = false
	screenGui.Name = "WaveTextGui"
	screenGui.Parent = playerGui

	-- Conteneur principal
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 500, 0, 150)
	container.Position = UDim2.new(0.5, 0, 0.3, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 20)
	containerCorner.Parent = container

	-- Gradient de fond
	local containerGradient = Instance.new("UIGradient")
	containerGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
	}
	containerGradient.Rotation = 90
	containerGradient.Parent = container

	-- Bordure lumineuse
	local containerStroke = Instance.new("UIStroke")
	if isComplete then
		containerStroke.Color = Color3.fromRGB(100, 255, 100)
	else
		containerStroke.Color = Color3.fromRGB(255, 100, 100)
	end
	containerStroke.Thickness = 3
	containerStroke.Transparency = 0.3
	containerStroke.Parent = container

	-- Barre décorative en haut
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 6)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = isComplete and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	topBar.BorderSizePixel = 0
	topBar.Parent = container

	local topBarCorner = Instance.new("UICorner")
	topBarCorner.CornerRadius = UDim.new(0, 20)
	topBarCorner.Parent = topBar

	local topBarMask = Instance.new("Frame")
	topBarMask.Size = UDim2.new(1, 0, 0.5, 0)
	topBarMask.Position = UDim2.new(0, 0, 0.5, 0)
	topBarMask.BackgroundColor3 = topBar.BackgroundColor3
	topBarMask.BorderSizePixel = 0
	topBarMask.Parent = topBar

	-- Icône décorative
	local icon = Instance.new("Frame")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0.5, 0, 0, 25)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.BackgroundColor3 = isComplete and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	icon.BorderSizePixel = 0
	icon.Parent = container

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.3, 0)
	iconCorner.Parent = icon

	-- Symbole dans l'icône
	local iconSymbol = Instance.new("TextLabel")
	iconSymbol.Size = UDim2.new(1, 0, 1, 0)
	iconSymbol.BackgroundTransparency = 1
	iconSymbol.Font = Enum.Font.GothamBlack
	iconSymbol.TextSize = 32
	iconSymbol.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconSymbol.Text = isComplete and "✓" or "⚔"
	iconSymbol.Parent = icon

	-- Texte principal
	local mainText = Instance.new("TextLabel")
	mainText.Size = UDim2.new(1, -40, 0, 50)
	mainText.Position = UDim2.new(0, 20, 0, 90)
	mainText.BackgroundTransparency = 1
	mainText.Font = Enum.Font.GothamBlack
	mainText.TextSize = 28
	mainText.TextColor3 = Color3.fromRGB(255, 255, 255)
	mainText.Text = isComplete and ("VAGUE " .. waveNumber .. " TERMINÉE !") or ("VAGUE " .. waveNumber)
	mainText.TextXAlignment = Enum.TextXAlignment.Center
	mainText.Parent = container

	-- Effet de brillance sur le texte
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = isComplete and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	textStroke.Thickness = 1
	textStroke.Transparency = 0.5
	textStroke.Parent = mainText

	-- Sous-texte
	if not isComplete then
		local subText = Instance.new("TextLabel")
		subText.Size = UDim2.new(1, -40, 0, 20)
		subText.Position = UDim2.new(0, 20, 1, -30)
		subText.BackgroundTransparency = 1
		subText.Font = Enum.Font.GothamBold
		subText.TextSize = 14
		subText.TextColor3 = Color3.fromRGB(200, 200, 210)
		subText.Text = "Préparez-vous au combat !"
		subText.TextXAlignment = Enum.TextXAlignment.Center
		subText.Parent = container
	end

	-- Animation d'apparition
	container.Size = UDim2.new(0, 0, 0, 0)
	container.Rotation = -10

	local appearTween = TweenService:Create(
		container,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 500, 0, 150), Rotation = 0}
	)
	appearTween:Play()

	-- Animation de pulsation de l'icône (réduite à 2 cycles)
	local iconAnimRunning = true
	task.spawn(function()
		for i = 1, 2 do
			if not iconAnimRunning then break end
			TweenService:Create(
				icon,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{Size = UDim2.new(0, 70, 0, 70)}
			):Play()
			task.wait(0.25)
			if not iconAnimRunning then break end
			TweenService:Create(
				icon,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{Size = UDim2.new(0, 60, 0, 60)}
			):Play()
			task.wait(0.25)
		end
	end)

	-- Animation de pulsation de la bordure (réduite à 2 cycles)
	local strokeAnimRunning = true
	task.spawn(function()
		for i = 1, 2 do
			if not strokeAnimRunning then break end
			TweenService:Create(
				containerStroke,
				TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0}
			):Play()
			task.wait(0.25)
			if not strokeAnimRunning then break end
			TweenService:Create(
				containerStroke,
				TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.5}
			):Play()
			task.wait(0.25)
		end
	end)

	-- Animation de disparition après 1 seconde
	task.delay(1, function()
		iconAnimRunning = false
		strokeAnimRunning = false

		if not screenGui or not screenGui.Parent then return end

		local disappearTween = TweenService:Create(
			container,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0), Rotation = 10}
		)
		disappearTween:Play()

		disappearTween.Completed:Connect(function()
			if screenGui and screenGui.Parent then
				screenGui:Destroy()
			end
		end)
	end)
end

wait(WaveDelay)

-- 🔴 Récupérer le nouveau dossier ENEMY
local EnemyFolder = workspace:WaitForChild("ENEMY")

-- Débloquer les ennemis
local activeEnemies = {}
for _, name in ipairs(EnemyNames) do
	local enemy = EnemyFolder:FindFirstChild(name)
	if enemy then
		unlockEnemy(enemy)
		table.insert(activeEnemies, enemy)
	end
end

-- Afficher "Vague 1"
for _, player in ipairs(Players:GetPlayers()) do
	showWaveText(player, 1, false)
end

-- Activer le tir
ShootHandler.Disabled = false

-- BOUCLE DE FIN DE VAGUE
local function isWaveOver()
	for _, enemy in ipairs(activeEnemies) do
		if enemy and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
			return false
		end
	end
	return true
end

while not isWaveOver() do
	wait(0.2)
end

-- Vague terminée
for _, player in ipairs(Players:GetPlayers()) do
	showWaveText(player, 1, true)
end

-- Attendre que l'animation se termine avant de passer à la wave 2
wait(1.5)

-- Déclencher WAVE2
if wave2Script then
	wave2Script.Disabled = false
end

-- Désactiver Vague1
script.Disabled = true
