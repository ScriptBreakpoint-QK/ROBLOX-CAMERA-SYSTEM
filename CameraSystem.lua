-- Created by @ScriptBreakpoint
-- Feel free to use this, crediting me is optional but definitely appreciated

-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local ContextActionService = game:GetService("ContextActionService")

-- Player setup
local player = Players.LocalPlayer
local mouse = game.Players.LocalPlayer:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")


local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChild("Humanoid")
local playerCamera = Workspace.CurrentCamera
local isMouseHeld = false

playerCamera.CameraType = Enum.CameraType.Scriptable -- just in case
local camerasFolder = Workspace:FindFirstChild("Cameras")
local spacesFolder = Workspace:FindFirstChild("Spaces")
local soundsFolder = Workspace:FindFirstChild("Sounds")
local musicFolder = workspace:WaitForChild("Music")
local interactablesFolder = workspace:WaitForChild("INTERACTABLE_OBJECTS")



local cameraSwitchSound = soundsFolder and soundsFolder:FindFirstChild("CAMERA_SWITCH")
local enterRoomSound = soundsFolder and soundsFolder:FindFirstChild("ENTER_ROOM")
local leaveRoomSound = soundsFolder and soundsFolder:FindFirstChild("LEAVE_ROOM")
local PlaceDiscoverySound = soundsFolder and soundsFolder:FindFirstChild("PLACE_DISCOVER")
local HoldMouseSound = soundsFolder and soundsFolder:FindFirstChild("HOLD_MOUSE")
local ReleaseMouseSound = soundsFolder and soundsFolder:FindFirstChild("RELEASE_MOUSE")
local HoverMouse = soundsFolder and soundsFolder:FindFirstChild("HOVER_CURSOR")
local PathfindingSound = soundsFolder and soundsFolder:FindFirstChild("PATHFINDING_TRIGGER")
local PathfindingStopSound = soundsFolder and soundsFolder:FindFirstChild("PATHFINDING_STOP")
local SALUTE_SFX = soundsFolder and soundsFolder:FindFirstChild("SALUTE_SFX")

local driftingSong = musicFolder and musicFolder:FindFirstChild("Drifting")

local validClasses = {
	["Part"] = true,
	["MeshPart"] = true,
	["UnionOperation"] = true,
	["Model"] = true
}

-- Configurations
local highlightDistanceThreshold = 99999  
local pathfindingStopDistance = 20     

local tween
local originalCFrame

local debounceTime = .25 
local lastCameraSwitchTime = 0  
local transitionTime = 1 
local sensitivity = 0.5 
local smoothFactor = 0.1 
local easingStyle = Enum.EasingStyle.Quart
local easingDirection = Enum.EasingDirection.InOut
local cameraEasingStyle = Enum.EasingStyle.Sine
local cameraEasingDirection = Enum.EasingDirection.InOut
local fovChangeSpeed = 0.05 
local minFOV = 50 
local maxFOV = 95
local maxFocusDistance = 5 
local blurRadiusNear = 10 
local blurRadiusFar = 50  
local cameraOffset = Vector3.new(0, 5, 10) 
local swayIntensity = 0.5 
local swaySpeed = 1
local distanceThreshold = 10
local cameraLerpSpeed = 0.1
local fadeDuration = 2  
local movementThreshold = 2 
local isPathfinding = false 
local manualMovementDetected = false 
local playerInProximity = false
local timeNearCamera = 0
local proximityDuration = 3 
local waveAnimationId = "rbxassetid://94830737065558"
local waveTriggered = false
local lastPlayerPosition


local isFading = false
local cooldown = false
local HoverCooldown = 1

local draggingCursorAssetId = "rbxasset://textures/Cursors/DragDetector/ActivatedCursor.png"  
local defaultCursorAssetId = "rbxasset://textures/Cursors/DragDetector/HoverCursor.png"  

local cooldownTime = 2 
local isOnCooldown = false  

local defaultPlaybackSpeed = 0.8
driftingSong.PlaybackSpeed = defaultPlaybackSpeed
driftingSong:Play() 

mouse.Icon = defaultCursorAssetId

local specificColor = Color3.fromRGB(180, 128, 255)

local fadeScreen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
fadeScreen.IgnoreGuiInset = true
local fadeFrame = Instance.new("Frame", fadeScreen)
fadeFrame.Size = UDim2.new(1, 0, 1, 0)
fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
fadeFrame.Visible = false
fadeFrame.BackgroundTransparency = 1
local specificLocationsFolder = Workspace:FindFirstChild("SPECIFIC_LOCATIONS")
local fadeDuration = 1.5 
local specificColor = Color3.fromRGB(180, 128, 255)
local isInSpecificSpace = false  
-- DOF
local depthOfField = Instance.new("DepthOfFieldEffect")
depthOfField.Parent = playerCamera
-- Motion Blur
local motionBlur = Instance.new("BlurEffect")
motionBlur.Parent = playerCamera
motionBlur.Size = 0 

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Parent = playerCamera
colorCorrection.Saturation = 0.1 

local currentSpace = nil
local isTweening = false

local waveAnimation = Instance.new("Animation")
waveAnimation.AnimationId = waveAnimationId
local waveTrack
local function startWaving()
	if humanoid and not waveTriggered then
		waveTriggered = true
		waveTrack = humanoid:LoadAnimation(waveAnimation)
		waveTrack:Play()
		SALUTE_SFX:Play()
	end
end

local function stopWaving()
	if waveTrack then
		waveTrack:Stop()
		waveTrack = nil
	end
	waveTriggered = false
end

local function faceCamera() -- OPTIONAL
	if isTweening then return end
	isTweening = true
	
	originalCFrame = humanoidRootPart.CFrame
	local cameraDirection = (playerCamera.CFrame.Position - humanoidRootPart.Position).unit
	cameraDirection = Vector3.new(cameraDirection.X, 0, cameraDirection.Z)
	local targetCFrame = CFrame.lookAt(humanoidRootPart.Position, humanoidRootPart.Position + cameraDirection)
	local tweenInfo = TweenInfo.new(
		0.5, 
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)

	tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
	tween:Play()
	local function cancelTweenOnMovement()
		if tween then tween:Cancel() end
		isTweening = false
		ContextActionService:UnbindAction("CancelTweenOnMovement")
	end

	ContextActionService:BindAction("CancelTweenOnMovement", function()
		cancelTweenOnMovement()
	end, false, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)

	ContextActionService:BindAction("CancelControllerMove", function()
		cancelTweenOnMovement()
	end, false, Enum.KeyCode.Thumbstick1, Enum.UserInputType.Touch)

	tween.Completed:Connect(function()
		ContextActionService:UnbindAction("CancelTweenOnMovement")
		ContextActionService:UnbindAction("CancelControllerMove")
		isTweening = false
	end)
end


local function applyCameraSway()
	local time = tick() * swaySpeed
	local swayX = math.sin(time) * swayIntensity + .5
	local swayY = math.cos(time) * swayIntensity + .5
	return Vector3.new(swayX, swayY, 0)
end

local function tweenPlaybackSpeed(targetSpeed)
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	local playbackTween = TweenService:Create(driftingSong, tweenInfo, { PlaybackSpeed = targetSpeed })
	playbackTween:Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isMouseHeld = true
		mouse.Icon = draggingCursorAssetId
		HoldMouseSound:Play()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isMouseHeld = false
		mouse.Icon = defaultCursorAssetId
		ReleaseMouseSound:Play()
	end
end)



local function applyMouseInfluence()
	if isMouseHeld then
		local mouseDelta = Vector2.new(mouse.X - playerCamera.ViewportSize.X / 2, mouse.Y - playerCamera.ViewportSize.Y / 2)
		
		local influenceFactor = 0.012
		--local touchInfluenceFactor = 0.012 NOT IMPLEMENTED
		--local thumbstickInfluenceFactor = 0.03 NOT IMPLEMENTED
		
		local mouseOffset = Vector3.new(mouseDelta.X * influenceFactor, -mouseDelta.Y * influenceFactor, 0)

		return mouseOffset
	else
		return Vector3.new(0, 0, 0)
	end
end

local function calculateCameraCFrame(targetCameraPart)
	local lookAtPosition = humanoidRootPart.Position
	local cameraPosition = targetCameraPart.Position + cameraOffset + applyCameraSway() + applyMouseInfluence()
	return playerCamera.CFrame:Lerp(CFrame.new(cameraPosition, lookAtPosition), cameraLerpSpeed)
end


local function adjustCameraFOV(distanceToPlayer)
	if distanceToPlayer < maxFocusDistance then
		playerCamera.FieldOfView = math.clamp(playerCamera.FieldOfView - fovChangeSpeed, minFOV, maxFOV)
	else
		playerCamera.FieldOfView = math.clamp(playerCamera.FieldOfView + fovChangeSpeed, minFOV, maxFOV)
	end
end

local function adjustDOF(distanceToPlayer)
	local speedFactor = humanoidRootPart.Velocity.Magnitude / 10
	local dynamicFocusDistance = maxFocusDistance + speedFactor

	if distanceToPlayer < dynamicFocusDistance then
		depthOfField.FarIntensity = 0.5
		depthOfField.FocusDistance = distanceToPlayer
		depthOfField.InFocusRadius = blurRadiusNear
	else
		depthOfField.FarIntensity = 0.8
		depthOfField.FocusDistance = distanceToPlayer
		depthOfField.InFocusRadius = blurRadiusFar
	end
end


local function adjustMotionBlur(speed)
	motionBlur.Size = math.clamp(speed * 0.2, 0, 10)
end

local function tweenBrightness(targetBrightness)
	local tweenInfo = TweenInfo.new(transitionTime, cameraEasingStyle, cameraEasingDirection)
	local brightnessTween = TweenService:Create(colorCorrection, tweenInfo, { Brightness = targetBrightness })
	brightnessTween:Play()
end

local function adjustColor(distanceToPlayer)
	local targetBrightness
	if distanceToPlayer < maxFocusDistance then
		colorCorrection.Contrast = 0.4
		targetBrightness = -0.2
	else
		colorCorrection.Contrast = 0.2
		targetBrightness = 0
	end
	tweenBrightness(targetBrightness)
end

local function isPlayerInsidePart(part)
	local partCFrame = part.CFrame
	local partSize = part.Size
	local relativePosition = partCFrame:pointToObjectSpace(humanoidRootPart.Position)

	return math.abs(relativePosition.X) <= partSize.X / 2 and
		math.abs(relativePosition.Y) <= partSize.Y / 2 and
		math.abs(relativePosition.Z) <= partSize.Z / 2
end

local function switchCameraTo(targetCameraPart)
	local currentTime = tick() 
	if currentTime - lastCameraSwitchTime < debounceTime then return end 

	spawn(function()
		if isTweening then return end  
		isTweening = true

		if cameraSwitchSound then
			cameraSwitchSound:Play()
		end

		local targetCFrame = calculateCameraCFrame(targetCameraPart)
		playerCamera.CFrame = targetCFrame

		isTweening = false
		lastCameraSwitchTime = tick()  
	end)
end




local function getAllCamerasAndSpaces()
	local cameraPositions = {}
	local index = 1

	while true do
		local cameraPart = camerasFolder:FindFirstChild("C" .. index)
		local spacePart = spacesFolder:FindFirstChild("S" .. index)
		if cameraPart and spacePart then
			cameraPositions["S" .. index] = cameraPart
		else
			break
		end
		index = index + 1
	end
	return cameraPositions
end

local function getWorldSpaceMovementDirection()
	local moveDirection = Vector3.new(0, 0, 0)

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDirection = moveDirection + Vector3.new(0, 0, -1)  -- Forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDirection = moveDirection + Vector3.new(0, 0, 1)   -- Backward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDirection = moveDirection + Vector3.new(-1, 0, 0)  -- Left
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDirection = moveDirection + Vector3.new(1, 0, 0)   -- Right
	end

	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit
	end

	return moveDirection
end


local function fadeInOut(isFadingIn, callback, delayTime)
	spawn(function()
		fadeFrame.Visible = true
		local targetTransparency = isFadingIn and 1 or 0
		local fadeTweenInfo = TweenInfo.new(fadeDuration, easingStyle, easingDirection)
		local fadeTween = TweenService:Create(fadeFrame, fadeTweenInfo, { BackgroundTransparency = targetTransparency })

		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			if not isFadingIn then
				task.wait(delayTime or 0.5)
			end

			if isFadingIn then
				fadeFrame.Visible = false
			end

			if callback then
				callback()
			end
		end)
	end)
end

local function specialCameraZoomIn()
	local targetFOV = 30 
	local tweenInfo = TweenInfo.new(fadeDuration, easingStyle, easingDirection)
	local zoomTween = TweenService:Create(playerCamera, tweenInfo, { FieldOfView = targetFOV })
	zoomTween:Play()
end

local function resetCameraFOV()
	local targetFOV = maxFOV 
	local tweenInfo = TweenInfo.new(fadeDuration, easingStyle, easingDirection)
	local resetFOVTween = TweenService:Create(playerCamera, tweenInfo, { FieldOfView = targetFOV })
	resetFOVTween:Play()
end

local function getLinkedParts(spaceName)
	local cameraPart = camerasFolder:FindFirstChild("C" .. spaceName:sub(2))
	local teleportPart = specificLocationsFolder:FindFirstChild("T*" .. spaceName:sub(2))  -- Using T* notation
	return cameraPart, teleportPart
end

local function isInteractable(object)
	return object:IsDescendantOf(interactablesFolder)
	
end

local function isValidTarget(object)
	local ancestor = object:FindFirstAncestor(interactablesFolder.Name)
	return ancestor ~= nil
end

mouse.Move:Connect(function()
	local target = mouse.Target

	if isInteractable(target) and not cooldown then
		HoverMouse:Play()
		cooldown = true

		task.delay(HoverCooldown,function()
			cooldown = false 
			

		end)
	end
end)



local function updateCharacterReferences()
	character = player.Character or player.CharacterAdded:Wait()
	humanoidRootPart = character:WaitForChild("HumanoidRootPart") 
	humanoid = character:FindFirstChild("Humanoid")
end

local function teleportPlayerTo(targetPosition)
	humanoidRootPart.CFrame = CFrame.new(targetPosition)
end

local function getLinkedPartsForExit(spaceName)
	local cameraPart = camerasFolder:FindFirstChild("C" .. spaceName:sub(2)) --C parts r for cameras
	local teleportPart = specificLocationsFolder:FindFirstChild("T*" .. spaceName:sub(2))  --"T*" part is for exit
	return cameraPart, teleportPart
end

local function getLinkedPartsForEntry(spaceName)
	local cameraPart = camerasFolder:FindFirstChild("C" .. spaceName:sub(2))
	local teleportPart = specificLocationsFolder:FindFirstChild("T" .. spaceName:sub(2))  --"T" part is for entry
	return cameraPart, teleportPart
end


local function updateSwayIntensity()
	local speed = humanoidRootPart.Velocity.Magnitude
	swayIntensity = math.clamp(speed / 20, 0.1, 0.5)  -- min and max sway
end

--experimental
local function isWithinDistance(model)
	local distance = (humanoidRootPart.Position - model.PrimaryPart.Position).Magnitude
	return distance <= highlightDistanceThreshold
end
--

local function createBillboardOnTarget(targetModel)
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 100, 0, 100)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.ImageTransparency = 0.2
	imageLabel.Image = "rbxassetid://6803353442"
	imageLabel.Parent = billboardGui

	billboardGui.Parent = targetModel.PrimaryPart

	local rotationTween = TweenService:Create(imageLabel, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, -1), {
		Rotation = imageLabel.Rotation + 360
	})
	rotationTween:Play()

	return billboardGui
end

local function stopPathfinding()
	if isPathfinding then
		humanoid:MoveTo(humanoidRootPart.Position)
		isPathfinding = false
		warn("Pathfinding canceled due to manual movement.")
		PathfindingStopSound:Play()  
	end
end

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local PathfindingService = game:GetService("PathfindingService")

local isOnCooldown = false
local isPathfindingActive = false  

local isOnCooldown = false
local isPathfindingActive = false

local function moveToObject(targetModel)
	if isOnCooldown then return end
	isOnCooldown = true 

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	game.StarterGui:SetCore("ResetButtonCallback", false)
	local function disableWASDMovement(actionName, inputState, inputObject)
		return Enum.ContextActionResult.Sink
	end

	ContextActionService:BindAction("DisableWASDMovement", disableWASDMovement, false,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)

	local function disableJump(actionName, userInputState, inputObject)
		if userInputState == Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	ContextActionService:BindAction("DisableJump", disableJump, false, Enum.KeyCode.ButtonA)

	local function disableTouchMovement(actionName, userInputState, inputObject)
		if userInputState == Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	ContextActionService:BindAction("DisableTouchMovement", disableTouchMovement, false, Enum.UserInputType.Touch)

	isPathfindingActive = true

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentMaxSlope = 45,
		WaypointSpacing = 3
	})

	path:ComputeAsync(humanoidRootPart.Position, targetModel.PrimaryPart.Position)

	if path.Status == Enum.PathStatus.Success then
		PathfindingSound:Play()

		local targetBillboard = createBillboardOnTarget(targetModel)

		local waypoints = path:GetWaypoints()
		for _, waypoint in ipairs(waypoints) do
			humanoid:MoveTo(waypoint.Position)
			humanoid.MoveToFinished:Wait()

			local distance = (humanoidRootPart.Position - targetModel.PrimaryPart.Position).Magnitude
			if distance <= pathfindingStopDistance then
				PathfindingStopSound:Play()
				break
			end
		end

		targetBillboard:Destroy()

	else
		warn("Pathfinding failed for model: " .. targetModel.Name)
		if path.Status == Enum.PathStatus.NoPath then
			warn("No valid path found. Maybe check the environment for obstacles first.")
		elseif path.Status == Enum.PathStatus.Blocked then
			warn("Path is blocked. Prob consider looking for obstacles near the player.")
		end
	end

	ContextActionService:UnbindAction("DisableWASDMovement")
	ContextActionService:UnbindAction("DisableJump")
	ContextActionService:UnbindAction("DisableTouchMovement")

	isPathfindingActive = false
	game.StarterGui:SetCore("ResetButtonCallback", true)

	task.wait(cooldownTime)
	isOnCooldown = false
end





local isDragging = false

mouse.Button1Down:Connect(function()
	local target = mouse.Target

	if target and isValidTarget(target) then
		isDragging = true
		task.wait(.5)

		local model = target:FindFirstAncestorWhichIsA("Model") or target
		moveToObject(model)
	end
end)

mouse.Button1Up:Connect(function()
	isDragging = false
end)



mouse.Button1Down:Connect(function()
	local target = mouse.Target

	if target and isValidTarget(target) then
		local model = target:FindFirstAncestorWhichIsA("Model") or target

		moveToObject(model)
	end
end)


local function fadeInOutWithTimedCameraSwitch(isFadingIn, cameraSwitchCallback, cameraSwitchDelay, completeCallback)
	spawn(function()
		if isFading then return end 
		isFading = true

		fadeFrame.Visible = true
		local targetTransparency = isFadingIn and 1 or 0
		local fadeTweenInfo = TweenInfo.new(fadeDuration, easingStyle, easingDirection)
		local fadeTween = TweenService:Create(fadeFrame, fadeTweenInfo, { BackgroundTransparency = targetTransparency })

		fadeTween:Play()

		fadeTween.Completed:Connect(function()
			if not isFadingIn and cameraSwitchCallback then
				task.wait(cameraSwitchDelay) 
				cameraSwitchCallback()
			end

			if isFadingIn then
				fadeFrame.Visible = false 
			end

			isFading = false

			if completeCallback then
				completeCallback()
			end
		end)
	end)
end
	
local function triggerPlaceDiscovery(discoveryText)
	local discoveryGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	local textLabel = Instance.new("TextLabel", discoveryGui)

	textLabel.Size = UDim2.new(0.5, 0, 0.1, 0)
	textLabel.Position = UDim2.new(0.25, 0, 0, 0) 
	textLabel.Text = discoveryText or "Area"  -- Default
	textLabel.TextScaled = true
	textLabel.BackgroundTransparency = 1
	textLabel.TextTransparency = 1
	textLabel.TextStrokeTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Font = Enum.Font.Arimo
	textLabel.AnchorPoint = Vector2.new(0, 0)

	local positionTween = TweenService:Create(textLabel, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.25, 0, 0, 0.3) })
	local sizeTween = TweenService:Create(textLabel, TweenInfo.new(7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(.5, 0, 0.5, 0) })
	local fadeInTween = TweenService:Create(textLabel, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { TextTransparency = 0.85 })
	local fadeOutTween = TweenService:Create(textLabel, TweenInfo.new(5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { TextTransparency = 1 })

	fadeInTween:Play()
	positionTween:Play()
	sizeTween:Play()

	fadeInTween.Completed:Connect(function()
		fadeOutTween:Play()
		fadeOutTween.Completed:Connect(function()
			discoveryGui:Destroy()
		end)
	end)

	if PlaceDiscoverySound then
		PlaceDiscoverySound:Play()
	end
end

local function fadeInOutWithVignette(isFadingIn, callback)
	local targetTransparency = isFadingIn and 1 or 0
	local vignetteOverlay = Instance.new("ImageLabel", fadeFrame)
	vignetteOverlay.Size = UDim2.new(1, 0, 1, 0)
	vignetteOverlay.Image = "rbxassetid://4576475446"
	vignetteOverlay.ImageTransparency = 1 

	local fadeTweenInfo = TweenInfo.new(fadeDuration, cameraEasingStyle, cameraEasingDirection)
	local fadeTween = TweenService:Create(fadeFrame, fadeTweenInfo, { BackgroundTransparency = targetTransparency })
	local vignetteTween = TweenService:Create(vignetteOverlay, fadeTweenInfo, { ImageTransparency = targetTransparency })

	fadeTween:Play()
	vignetteTween:Play()

	fadeTween.Completed:Connect(function()
		vignetteOverlay:Destroy()
		if isFadingIn then
			fadeFrame.Visible = false
		end
		if callback then
			callback()
		end
	end)
end

local function isPlayerAlive()
	return humanoid and humanoid.Health > 0
end


local function createBillboardGui()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(4, 0, 2, 0)  
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)  
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 50  
	billboardGui.Enabled = false  

	local textLabel = Instance.new("TextLabel")
	textLabel.Text = "Me"
	textLabel.Size = UDim2.new(1, 0, 1, 0)  
	textLabel.BackgroundTransparency = 1  
	textLabel.TextScaled = true  
	textLabel.TextColor3 = Color3.new(1, 1, 1) 
	textLabel.Font = Enum.Font.Code  
	textLabel.Parent = billboardGui 
	textLabel.TextTransparency = 1

	return billboardGui
end

local billboardGui = createBillboardGui()
billboardGui.Parent = humanoidRootPart  






player.CharacterAdded:Connect(function(newCharacter)
	updateCharacterReferences()  

	fadeScreen:Destroy() 
	fadeScreen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	fadeScreen.IgnoreGuiInset = true
	fadeFrame = Instance.new("Frame", fadeScreen)
	fadeFrame.Size = UDim2.new(1, 0, 1, 0)
	fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	fadeFrame.Visible = false
	fadeFrame.BackgroundTransparency = 1

	playerCamera.CameraType = Enum.CameraType.Scriptable
	resetCameraFOV()

	billboardGui:Destroy()
	billboardGui = createBillboardGui()
	billboardGui.Parent = humanoidRootPart

	fadeInOut(true, function()
		resetCameraFOV()
		humanoid.WalkSpeed = 16  
		isTweening = false
	end)
end)

local function fadeOutBillboard(duration)
	fadeFrame.Visible = true  
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
	local transparencyTween = TweenService:Create(billboardGui.TextLabel, tweenInfo, { TextTransparency = 1 })

	transparencyTween:Play()

	transparencyTween.Completed:Connect(function()
		billboardGui.Enabled = false  
	end)
end

local function tweenText(distance)
	local maxDistance = 10
	local minDistance = 3
	local distanceFactor = math.clamp((maxDistance - distance) / (maxDistance - minDistance), 0, 1)
	local targetTransparency = 1 - distanceFactor

	--[[print("Distance:", distance)
	print("Distance Factor:", distanceFactor)
	print("Target Transparency:", targetTransparency)]] -- DEBUG

	if distance > maxDistance then
		fadeOutBillboard(0.1)
	else
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
		local transparencyTween = TweenService:Create(billboardGui.TextLabel, tweenInfo, { TextTransparency = targetTransparency })
		transparencyTween:Play()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed) -- DEBUG
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		print("Thumbstick movement detected")
	end
end)


spawn(function()
	RunService.RenderStepped:Connect(function()
		
			if not humanoidRootPart or isTweening or isFading then return end
		local distanceToCamera = (humanoidRootPart.Position - playerCamera.CFrame.Position).Magnitude

		if distanceToCamera <= distanceThreshold then
			if not billboardGui.Enabled then
				billboardGui.Enabled = true
			end
			tweenText(distanceToCamera) 
		else
			if billboardGui.Enabled then
				billboardGui.Enabled = false
			end
		end


		local cameraPositions = getAllCamerasAndSpaces()
		local closestSpace = nil

		for spaceName, cameraPart in pairs(cameraPositions) do
			local spacePart = spacesFolder:FindFirstChild(spaceName)
			if spacePart and isPlayerInsidePart(spacePart) then
				closestSpace = spaceName
				break
			end
		end

		if closestSpace and closestSpace ~= currentSpace then
			currentSpace = closestSpace
			local targetCameraPart = cameraPositions[currentSpace]

			local currentSpacePart = spacesFolder:FindFirstChild(currentSpace)

			if currentSpacePart and currentSpacePart.Color == specificColor and isPlayerAlive() then
				if enterRoomSound then
					enterRoomSound:Play()
					tweenPlaybackSpeed(1)
				end

				isTweening = true 
				isInSpecificSpace = true 
				humanoid.WalkSpeed = 0 

				fadeInOut(false, function()
					local cameraPart, teleportPart = getLinkedPartsForEntry(currentSpace)

					if cameraPart then
						switchCameraTo(cameraPart) 
					end

					if teleportPart then
						teleportPlayerTo(teleportPart.Position) 
					end

					fadeInOut(true, function()
						resetCameraFOV()
						humanoid.WalkSpeed = 16  
						isTweening = false
						triggerPlaceDiscovery("| HOME |")
					end)
				end, 1.5) 

			elseif targetCameraPart then
				switchCameraTo(targetCameraPart)
			end
		end

		if isInSpecificSpace and (not closestSpace or closestSpace ~= currentSpace) and isPlayerAlive() then
			isTweening = true 
			humanoid.WalkSpeed = 0 

			if leaveRoomSound then
				leaveRoomSound:Play()
				tweenPlaybackSpeed(.7)
			end

			fadeInOutWithTimedCameraSwitch(false, function() 
				local cameraPart, teleportPart = getLinkedPartsForExit(currentSpace)

				if cameraPart then
					switchCameraTo(cameraPart)  
				end

				if teleportPart then
					teleportPlayerTo(teleportPart.Position) 
				end

			end, 1.5, function() 
				
				fadeInOutWithTimedCameraSwitch(true, nil, 0, function()
					resetCameraFOV()
					humanoid.WalkSpeed = 16  
					isInSpecificSpace = false  
					isTweening = false
					triggerPlaceDiscovery("| OUTSIDE |")
				end)
			end)
		end
		local currentSpacePart = spacesFolder:FindFirstChild(currentSpace)

		if currentSpace and isInSpecificSpace and currentSpacePart.Color == specificColor and isPlayerAlive() then
			if distanceToCamera <= distanceThreshold then
				if not playerInProximity then
					playerInProximity = true
					timeNearCamera = 0  
				end

				timeNearCamera = timeNearCamera + RunService.RenderStepped:Wait()

				if timeNearCamera >= proximityDuration and not waveTriggered then
					startWaving()
					faceCamera()
				end
			else
				playerInProximity = false
				timeNearCamera = 0
				stopWaving()
			end
		else
			playerInProximity = false
			timeNearCamera = 0
			stopWaving()
		end

		if currentSpace then
			local currentCameraPart = cameraPositions[currentSpace]
			if currentCameraPart then
				playerCamera.CFrame = playerCamera.CFrame:Lerp(calculateCameraCFrame(currentCameraPart), 0.1)  

				local distanceToPlayer = (humanoidRootPart.Position - currentCameraPart.Position).Magnitude
				adjustCameraFOV(distanceToCamera)
				adjustDOF(distanceToCamera)
				adjustColor(distanceToPlayer)

				local speed = humanoidRootPart.Velocity.Magnitude
				adjustMotionBlur(speed)
			end
		end
	end)
end)
