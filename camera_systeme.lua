local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CAMERA_HEIGHT = 12
local CAMERA_DISTANCE = 25
local CAMERA_LERP = 0.12

local ROTATION_SPEED = 0.2
local isRotating = false

local ShootEvent = ReplicatedStorage:WaitForChild("ShootEvent")
local ShootCursorEvent = ReplicatedStorage:WaitForChild("ShootCursor")
local baseCooldown = 0.25

local shootSound = Instance.new("Sound")
shootSound.SoundId = "rbxassetid://8561500387"
shootSound.Volume = 0.1
shootSound.RollOffMaxDistance = 100
shootSound.EmitterSize = 10
shootSound.Looped = false

local RADIUS = 6
local SEGMENTS = 32

local CharacterController = {}
CharacterController.__index = CharacterController

function CharacterController.new(character)
	local self = setmetatable({}, CharacterController)

	self.character = character
	self.hrp = character:WaitForChild("HumanoidRootPart")
	self.head = character:WaitForChild("Head")
	self.humanoid = character:WaitForChild("Humanoid")

	self.currentAngle = 0
	self.camCFrame = camera.CFrame
	self.lastShotTime = 0
	self.ringParts = {}
	self.connections = {}
	self.isDestroyed = false

	self.shootSound = shootSound:Clone()
	self.shootSound.Parent = self.head

	repeat 
		task.wait() 
	until self.hrp.Anchored == false and self.humanoid.Health > 0

	self:Setup()

	return self
end

function CharacterController:Setup()
	self.humanoid.AutoRotate = false
	self.currentAngle = self.hrp.Orientation.Y

	camera.CameraType = Enum.CameraType.Scriptable
	local backOffset = -self.hrp.CFrame.LookVector * CAMERA_DISTANCE
	local desiredPos = self.hrp.Position + Vector3.new(0, CAMERA_HEIGHT, 0) + backOffset
	self.camCFrame = CFrame.new(desiredPos, self.hrp.Position)
	camera.CFrame = self.camCFrame

	self:CreateVisuals()
	self:ConnectInputs()
	self:ConnectLoop()

	table.insert(self.connections, self.humanoid.Died:Connect(function()
		self:Destroy()
	end))
end

function CharacterController:ConnectInputs()
	local inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRotating = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		end
	end)
	table.insert(self.connections, inputBegan)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRotating = false
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
	table.insert(self.connections, inputEnded)
end

function CharacterController:CreateVisuals()
	self.folder = Instance.new("Folder")
	self.folder.Name = "AimVisual"
	self.folder.Parent = workspace

	for i = 1, SEGMENTS do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Size = Vector3.new(0.2, 0.2, 0.5)
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 255, 255)
		p.Transparency = 0.3
		p.Parent = self.folder
		table.insert(self.ringParts, p)
	end

	self.arrow = Instance.new("Part")
	self.arrow.Anchored = true
	self.arrow.CanCollide = false
	self.arrow.Shape = Enum.PartType.Ball
	self.arrow.Size = Vector3.new(0.6, 0.6, 0.6)
	self.arrow.Material = Enum.Material.Neon
	self.arrow.Color = Color3.fromRGB(255, 255, 255)
	self.arrow.Transparency = 0
	self.arrow.Parent = self.folder
end

function CharacterController:CreateShootEffect()
	if not self.hrp or not self.folder then return end

	local effect = Instance.new("Part")
	effect.Anchored = true
	effect.CanCollide = false
	effect.Size = Vector3.new(1, 1, 1)
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(255, 220, 100)
	effect.Transparency = 0.2
	effect.Shape = Enum.PartType.Ball
	effect.Position = self.hrp.Position + Vector3.new(0, 0.1, 0)
	effect.Parent = self.folder

	TweenService:Create(
		effect,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(14, 0.2, 14), Transparency = 1}
	):Play()

	game:GetService("Debris"):AddItem(effect, 0.4)
end

function CharacterController:ConnectLoop()
	local connection = RunService.RenderStepped:Connect(function(dt)
		if self.isDestroyed then
			return
		end

		if not self.hrp or not self.hrp.Parent or not self.humanoid or self.humanoid.Health <= 0 then
			return
		end

		self.humanoid.AutoRotate = false

		if isRotating then
			local delta = UserInputService:GetMouseDelta()
			self.currentAngle -= delta.X * ROTATION_SPEED
			self.hrp.CFrame = CFrame.new(self.hrp.Position) * CFrame.Angles(0, math.rad(self.currentAngle), 0)
		end

		local backOffset = -self.hrp.CFrame.LookVector * CAMERA_DISTANCE
		local desiredPos = self.hrp.Position + Vector3.new(0, CAMERA_HEIGHT, 0) + backOffset
		local desiredCFrame = CFrame.new(desiredPos, self.hrp.Position)
		self.camCFrame = self.camCFrame:Lerp(desiredCFrame, CAMERA_LERP)
		camera.CFrame = self.camCFrame

		local multiplier = player:GetAttribute("ShootSpeedMultiplier") or 1
		local cooldown = baseCooldown / multiplier
		if tick() - self.lastShotTime >= cooldown then
			self.lastShotTime = tick()
			local origin = self.head.Position
			local finalDir = Vector3.new(self.hrp.CFrame.LookVector.X, 0, self.hrp.CFrame.LookVector.Z).Unit
			ShootEvent:FireServer(origin, finalDir)
		end

		if self.folder and self.folder.Parent then
			local dir = self.hrp.CFrame.LookVector
			local aimCenter = self.hrp.Position + Vector3.new(0, 0.1, 0)

			for i, part in ipairs(self.ringParts) do
				if part and part.Parent then
					local angle = (i / SEGMENTS) * math.pi * 2
					local offset = Vector3.new(
						math.cos(angle) * RADIUS,
						0.1,
						math.sin(angle) * RADIUS
					)
					local pos = aimCenter + offset
					part.CFrame = CFrame.new(pos, aimCenter) * CFrame.Angles(0, 0, math.rad(90))
				end
			end

			if self.arrow and self.arrow.Parent then
				local pointPos = aimCenter + dir * (RADIUS + 1.5)
				self.arrow.CFrame = CFrame.new(pointPos)
			end
		end
	end)

	table.insert(self.connections, connection)
end

function CharacterController:Destroy()
	if self.isDestroyed then return end

	self.isDestroyed = true

	isRotating = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	for _, connection in ipairs(self.connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	self.connections = {}

	if self.folder then
		self.folder:Destroy()
	end
	self.folder = nil
	self.ringParts = {}
	self.arrow = nil

	if self.shootSound then
		self.shootSound:Destroy()
	end
	self.shootSound = nil

	camera.CameraType = Enum.CameraType.Custom
end

local currentController = nil

local function onCharacterAdded(character)
	if currentController then
		currentController:Destroy()
		currentController = nil
	end

	isRotating = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	task.wait(0.2)

	if not character or not character.Parent then
		return
	end

	currentController = CharacterController.new(character)
end

ShootCursorEvent.OnClientEvent:Connect(function(state)
	if state and currentController and not currentController.isDestroyed and currentController.shootSound then
		currentController.shootSound:Stop()
		currentController.shootSound.TimePosition = 0
		currentController.shootSound:Play()
		currentController:CreateShootEffect()
	end
end)

game:GetService("Players").PlayerRemoving:Connect(function(removingPlayer)
	if removingPlayer == player and currentController then
		currentController:Destroy()
	end
end)

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
