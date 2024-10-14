-- Created by @ScriptBreakpoint
-- Feel free to use this, crediting me is optional but definitely appreciated

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local clickCount = 0
local maxClicks = 16
local clickCooldown = false
local cooldownTime = .75

local animationVariations = {
	{animationId = "rbxassetid://116464331311895", sound = "rbxassetid://154157584"},
	{animationId = "rbxassetid://94830737065558", sound = "rbxassetid://154157291"},
	{animationId = "rbxassetid://72715042421188", sound = "rbxassetid://154157524"},
	{animationId = "rbxassetid://108173226132784", sound = "rbxassetid://27808972"},
	{animationId = "rbxassetid://94367235438901", sound = "rbxassetid://154157543"}
}

local assetsToPreload = {}
for _, entry in pairs(animationVariations) do
	local animation = Instance.new("Animation")
	animation.AnimationId = entry.animationId
	table.insert(assetsToPreload, animation)

	local sound = Instance.new("Sound")
	sound.SoundId = entry.sound
	table.insert(assetsToPreload, sound)
end

ContentProvider:PreloadAsync(assetsToPreload)

local function playRandomAnimation()
	local randomIndex = math.random(1, #animationVariations)
	local selectedEntry = animationVariations[randomIndex]

	local animation = Instance.new("Animation")
	animation.AnimationId = selectedEntry.animationId
	local animationTrack = animator:LoadAnimation(animation)
	animationTrack:Play()

	local sound = Instance.new("Sound")
	sound.SoundId = selectedEntry.sound
	sound.Parent = character
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	local movementListener
	movementListener = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if humanoid.MoveDirection.Magnitude > 0 then
			animationTrack:Stop()
			movementListener:Disconnect()
		end
	end)

	animationTrack.Stopped:Connect(function()
	end)
end

local function onCharacterClicked()
	if not clickCooldown then
		clickCount = clickCount + 1
		print("Click count", clickCount)

		if clickCount >= maxClicks then
			print("Max clicks reached")
			playRandomAnimation()
			clickCount = 0
		end

		clickCooldown = true
		wait(cooldownTime)
		clickCooldown = false
	end
end

UIS.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mouse = player:GetMouse()
		local mousePosition = mouse.Hit.p

		local camera = workspace.CurrentCamera
		local rayOrigin = camera.CFrame.Position
		local rayDirection = (mousePosition - rayOrigin).unit * 500

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {player.Character}
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

		if raycastResult then
			local hitPart = raycastResult.Instance
			if hitPart.Parent and hitPart.Parent == player.Character then
				onCharacterClicked()
			end
		end
	end
end)
