-- Created by @ScriptBreakpoint
-- Feel free to use this, crediting me is optional but definitely appreciated

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local TweenService = game:GetService("TweenService")
local playerGui = player:WaitForChild("PlayerGui")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")


local activeBillboardGui

local interactionCounts = {}
local maxInteractionsBeforeAngry = 3
local lastInteractedPrompt = nil
local currentText = "" 

local canSkip = false
local typewriteStartTime = 0

local proximityPrompts = {
	workspace.INTERACTABLE_OBJECTS:WaitForChild("Tree1"):WaitForChild("ProximityPromptPart"):FindFirstChildOfClass("ProximityPrompt"),
	workspace.INTERACTABLE_OBJECTS:WaitForChild("Tree2"):WaitForChild("ProximityPromptPart"):FindFirstChildOfClass("ProximityPrompt"),
	workspace.INTERACTABLE_OBJECTS:WaitForChild("SpawnPoint3"):WaitForChild("ProximityPromptPart"):FindFirstChildOfClass("ProximityPrompt"),
	workspace.INTERACTABLE_OBJECTS:WaitForChild("Dummy4"):WaitForChild("ProximityPromptPart"):FindFirstChildOfClass("ProximityPrompt"),
}

local cutscenesFolder = workspace:WaitForChild("CUTSCENES")
local cinematicGui = playerGui:WaitForChild("CinematicEffects")
local soundsFolder = workspace:FindFirstChild("Sounds")

local lastTriggeredTime = 0 
local cooldownDuration = 1
local skipTypewriting = false

local InteractSound = soundsFolder and soundsFolder:FindFirstChild("INTERACT_OBJECT")
local InteractFinish = soundsFolder and soundsFolder:FindFirstChild("INTERACT_FINISH")
local InteractAppear = soundsFolder and soundsFolder:FindFirstChild("INTERACT_APPEAR")
local InteractDisappear = soundsFolder and soundsFolder:FindFirstChild("INTERACT_DISAPPEAR")
local InteractOver = soundsFolder and soundsFolder:FindFirstChild("INTERACT_FINISH_TEXT")
local InteractTalk = soundsFolder and soundsFolder:FindFirstChild("INTERACT_TALK")
local KeyAppearing = soundsFolder and soundsFolder:FindFirstChild("KEY_APPEARING")
local SkipSound = soundsFolder and soundsFolder:FindFirstChild("SKIP_TEXT")



local CheerSfx = soundsFolder and soundsFolder:FindFirstChild("CHEER_SFX")
local SaluteSfx = soundsFolder and soundsFolder:FindFirstChild("SALUTE_SFX")
local ThinkingSfx = soundsFolder and soundsFolder:FindFirstChild("THINKING_SFX")
local ConfusedSFX = soundsFolder and soundsFolder:FindFirstChild("CONFUSED_SFX")
local LaughSFX = soundsFolder and soundsFolder:FindFirstChild("LAUGH_SFX")
local AmazedSFX = soundsFolder and soundsFolder:FindFirstChild("AMAZED_SFX")



local minSpeed = 0.9
local maxSpeed = 1.1
local randomPlaybackSpeed2 = math.random(minSpeed * 100, maxSpeed * 100) / 100

local frame = cinematicGui.Frame
local textLabel = frame.TextLabel
local imageLabel = frame.ImageLabel

local playerCamera = workspace.CurrentCamera
local humanoid = player.Character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
local originalCameraType = playerCamera.CameraType
local originalCFrame = playerCamera.CFrame
local originalWalkSpeed = humanoid.WalkSpeed
local originalJumpPower = humanoid.JumpHeight
local isInCutscene = false
local inactivityStartTime = nil
local textShown = false
local textFadeCoroutine = nil

local textVariations = {
	"It's a {displayText}. Looks interesting I suppose..?",
	"It's a {displayText}.",
	"A {displayText}...?",
	"It's a {displayText}. Truly fascinating.",
	"I see a {displayText}. What now..?",
	"It's a {displayText}. Maybe if I stare at it long enough, it'll explain itself.",
	"A {displayText}? Ah yes, the missing piece to absolutely nothing! ??",
	"It's a {displayText}. Might as well add it to my collection of useless items! ??",
	"A {displayText} stands here. It's hard to notice that."
}

local uniqueTexts = {
	["spawnpoint"] = {
		"Oh look, a {displayText} . Guess this is where I'll keep reappearing like a bad habit",
		"This {displayText} feels important. Is this where it all begins?",
		"Standing at the {displayText}, a new journey awaits."
	}
}

local animationVariations = {

	{animationId = "rbxassetid://116464331311895", sound = "rbxassetid://154157584"},
	{animationId = "rbxassetid://94830737065558", sound = "rbxassetid://154157291"},
	{animationId = "rbxassetid://72715042421188", sound = "rbxassetid://154157524"},

}

local punctuationSounds = {
	["?"] = ConfusedSFX,
	["!"] = AmazedSFX,
	["..."] = ThinkingSfx,
	["...?"] = ConfusedSFX, 
	["..?"] = ConfusedSFX, 
}


local function disableJump(actionName, userInputState, inputObject)
	if userInputState == Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Space and not gameProcessed then
		skipTypewriting = true
	end
end)

local function getUniqueText(displayText)
	for keyword, texts in pairs(uniqueTexts) do
		if string.lower(displayText):find(keyword) then
			return texts[math.random(1, #texts)]
		end
	end
	return textVariations[math.random(1, #textVariations)]
end

local function RandomInteractFinish()
	local randomPlaybackSpeed = math.random(minSpeed * 100, maxSpeed * 100) / 100
	InteractFinish.PlaybackSpeed = randomPlaybackSpeed
	InteractFinish:Play()
end

local function RandomInteractTalk()
	local randomPlaybackSpeed = math.random(minSpeed * 100, maxSpeed * 100) / 100
	InteractTalk.PlaybackSpeed = randomPlaybackSpeed
	InteractTalk:Play()
end

local function tweenCharacterToFace(targetPart)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local rootPosition = humanoidRootPart.Position
	local targetPosition = Vector3.new(targetPart.Position.X, rootPosition.Y, targetPart.Position.Z)
	local direction = (targetPosition - rootPosition).Unit
	local lookAtCFrame = CFrame.new(rootPosition, rootPosition + direction)

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = lookAtCFrame})
	tween:Play()
end

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

	animationTrack.Stopped:Connect(function()
		print("Animation stopped:", selectedEntry.animationId)
	end)
end


local function createBillboardGui(proximityPrompt)
	if not activeBillboardGui then
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Size = UDim2.new(0, 20, 0, 20)
		billboardGui.StudsOffset = Vector3.new(0, 2, 0)
		billboardGui.AlwaysOnTop = true

		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Size = UDim2.new(1, 0, 1, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.ImageTransparency = 1
		imageLabel.Image = "rbxassetid://12915938148"
		imageLabel.Parent = billboardGui

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(0, 50, 0, 50)
		textLabel.Position = UDim2.new(0, 10, 0, 0) 
		textLabel.BackgroundTransparency = 1
		textLabel.TextTransparency = 1
		textLabel.Font = Enum.Font.Arimo
		textLabel.TextSize = 16
		textLabel.TextColor3 = Color3.new(1, 1, 1) 
		textLabel.ZIndex = 2 
		textLabel.Parent = billboardGui

		if proximityPrompt then
			local keyCode = proximityPrompt.KeyboardKeyCode
			textLabel.Text = "[ " .. keyCode.Name .. " ]"
		else
			textLabel.Text = "[ ? ]"
		end

		activeBillboardGui = billboardGui
		billboardGui.Parent = player.Character:WaitForChild("Head")

		local rotationTween = TweenService:Create(imageLabel, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, -1), {
			Rotation = imageLabel.Rotation + 360
		})
		rotationTween:Play()

		return imageLabel, textLabel
	end
	return activeBillboardGui:FindFirstChildOfClass("ImageLabel"), activeBillboardGui:FindFirstChildOfClass("TextLabel")
end

local function fadeInTextLabel(textLabel)
	if textFadeCoroutine then
		coroutine.close(textFadeCoroutine) 
	end

	textFadeCoroutine = coroutine.create(function()
		task.wait(4.5) 
		if textLabel and activeBillboardGui then 
			local textFadeIn = TweenService:Create(textLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { TextTransparency = 0 })
			textFadeIn:Play()
			KeyAppearing:Play()
		end
	end)

	coroutine.resume(textFadeCoroutine)
end

local function resetTextFadeIn()
	if textFadeCoroutine then
		coroutine.close(textFadeCoroutine) 
		textFadeCoroutine = nil
	end
end

local function fadeOutTextLabel(textLabel)
	if textLabel then
		local textFadeOut = TweenService:Create(textLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { TextTransparency = 1 })
		textFadeOut:Play()
	end
end

local function checkInactivity(textLabel)
	if not inactivityStartTime then
		inactivityStartTime = tick()
	else
		local elapsed = tick() - inactivityStartTime
		if elapsed >= 2 and not textShown then
			fadeInTextLabel(textLabel)
			textShown = true
		end
	end
end

local function resetInactivityTimer()
	inactivityStartTime = nil
	textShown = false
end

local function fadeInBillboardGui(imageLabel)
	if imageLabel then
		imageLabel.ImageTransparency = 1 
		local fadeInTween = TweenService:Create(imageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { ImageTransparency = 0 })
		fadeInTween:Play()
	end
end

local function fadeOutBillboardGui(imageLabel)
	if imageLabel then
		local fadeOutTween = TweenService:Create(imageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { ImageTransparency = 1 })
		fadeOutTween:Play()
	end
end

local function showCustomPrompt(proximityPrompt)
	if not activeBillboardGui then
		createBillboardGui(proximityPrompt)
	end

	if activeBillboardGui then
		activeBillboardGui.Enabled = true 
		local imageLabel = activeBillboardGui:FindFirstChildOfClass("ImageLabel")
		local textLabel = activeBillboardGui:FindFirstChildOfClass("TextLabel")
		if imageLabel then
			fadeInBillboardGui(imageLabel)
			fadeInTextLabel(textLabel)
			InteractAppear:Play()
		else
			warn("I did not find the ImageLabel OR it couldn't be found or created for some reason.")
		end
	end
end

local function hideCustomPrompt()
	if activeBillboardGui then
		local imageLabel = activeBillboardGui:FindFirstChildOfClass("ImageLabel")
		local textLabel = activeBillboardGui:FindFirstChildOfClass("TextLabel")
		if imageLabel then
			fadeOutBillboardGui(imageLabel)
			fadeOutTextLabel(textLabel) 
			InteractDisappear:Play()
			resetTextFadeIn()
		else
			warn("I did not find the ImageLabel while it was trying to disappear.")
		end
		task.wait(0.5)
		activeBillboardGui.Enabled = false 
	end
end

local function tweenCamera(targetCFrame, targetFOV, duration)
	local cameraTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local cameraTween = TweenService:Create(playerCamera, cameraTweenInfo, { CFrame = targetCFrame, FieldOfView = targetFOV })
	cameraTween:Play()

	--ContextActionService:BindAction("DisableJump", disableJump, false, Enum.KeyCode.Space)

	return cameraTween
end

local function getModelCenter(model)
	local totalPosition = Vector3.new(0, 0, 0)
	local partCount = 0

	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			totalPosition = totalPosition + part.Position
			partCount = partCount + 1
		end
	end

	if partCount > 0 then
		return totalPosition / partCount
	else
		warn("One of your models doesn't have parts smh.")
		return nil
	end
end

local function tweenGuiVisibility(targetTransparency, duration)
	local guiTweenInfo = TweenInfo.new(.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local guiTween = TweenService:Create(imageLabel, guiTweenInfo, { ImageTransparency = targetTransparency })
	local textTween = TweenService:Create(textLabel, guiTweenInfo, { TextTransparency = targetTransparency })

	guiTween:Play()
	textTween:Play()
end

local function playCinematic(cutscenePart, displayText, currentPrompt)
	if isInCutscene or not cutscenePart then return end
	isInCutscene = true

	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0

	if lastInteractedPrompt and lastInteractedPrompt ~= currentPrompt then
		for prompt in pairs(interactionCounts) do
			interactionCounts[prompt] = 0  -- Reset counts for all prompts
		end
	end

	lastInteractedPrompt = currentPrompt

	if not interactionCounts[currentPrompt] then
		interactionCounts[currentPrompt] = 0
	end

	interactionCounts[currentPrompt] = interactionCounts[currentPrompt] + 1

	local isAngry = interactionCounts[currentPrompt] >= maxInteractionsBeforeAngry
	local specialAngryMessage = " Again.. How many times are we going to do this? Seriously, stop-"

	local targetPosition
	if cutscenePart:IsA("Model") then
		if cutscenePart.PrimaryPart then
			targetPosition = cutscenePart.PrimaryPart.Position
		else
			targetPosition = getModelCenter(cutscenePart)
		end
	else
		targetPosition = cutscenePart.Position
	end

	originalCameraType = playerCamera.CameraType
	originalCFrame = playerCamera.CFrame
	playerCamera.CameraType = Enum.CameraType.Scriptable

	for _, prompt in pairs(proximityPrompts) do
		if prompt then
			prompt.Enabled = false
			InteractSound:Play()
		end
	end

	local targetCFrame = CFrame.new(targetPosition + cutscenePart.CFrame.LookVector * -10, targetPosition)
	local cameraTween = tweenCamera(targetCFrame, 45, 2)

	frame.Visible = true
	frame.BackgroundTransparency = 1
	textLabel.TextTransparency = 1
	textLabel.Text = ""
	tweenGuiVisibility(0, 1) 

	cameraTween.Completed:Connect(function()
		RandomInteractFinish()
		playRandomAnimation()

		local function displayFancyText(text)
			local punctuationPause = {
				["."] = 0.5,
				[","] = 0.2,
				["?"] = 0.5,
				["!"] = 0.4,
				["..."] = 0.2,
				["...?"] = 0.3,
				["..?"] = 0.2
			}

			currentText = text  
			typewriteStartTime = tick() 
			canSkip = false             

			for i = 1, #text do					
				textLabel.Text = text:sub(1, i)
				local char = text:sub(i, i)
				if punctuationPause[char] then
					task.wait(punctuationPause[char])
					local sound = punctuationSounds[char]
					if sound then
						local soundClone = sound:Clone()
						soundClone.Parent = textLabel
						soundClone:Play()
						soundClone.Ended:Connect(function()
							soundClone:Destroy()
						end)
					end
				else
					task.wait(0.05)
					RandomInteractTalk()
				end
			end
		end


		if isAngry then
			displayFancyText(specialAngryMessage)
			interactionCounts[currentPrompt] = 0  
		else
			local randomMessage = textVariations[math.random(1, #textVariations)]
			displayFancyText(randomMessage:gsub("{displayText}", displayText))
		end

		humanoid.WalkSpeed = originalWalkSpeed
		task.wait(2.5)

		InteractOver:Play()
		tweenGuiVisibility(1, 1)
		task.wait(1)
		frame.Visible = false

		playerCamera.CameraType = originalCameraType
		humanoid.JumpHeight = originalJumpPower
		humanoid.WalkSpeed = originalWalkSpeed

		isInCutscene = false

		for _, prompt in pairs(proximityPrompts) do
			if prompt then
				prompt.Enabled = true
			end
		end
	end)
end

for i, prompt in pairs(proximityPrompts) do
	if prompt then
		prompt.PromptShown:Connect(function()
			showCustomPrompt(prompt)
		end)

		prompt.PromptHidden:Connect(function()
			hideCustomPrompt()
		end)

		prompt.Triggered:Connect(function()
			local currentTime = tick()
			if currentTime - lastTriggeredTime >= cooldownDuration then
				lastTriggeredTime = currentTime

				local cutscenePart = cutscenesFolder:FindFirstChild(tostring(i))
				local displayText = prompt.Parent.Parent.Name:gsub("%d+", "")
				playCinematic(cutscenePart, displayText, prompt)  
				tweenCharacterToFace(prompt.Parent)
			end
		end)
	end
end
local activeBillboardGui = nil