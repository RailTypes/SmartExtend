--!nonstrict

--[[

#############################
## SmartExtend Demo Plugin ##
#############################

Scripted by @RailTypes
Created 2025-07-10 UTC
Updated 2025-07-19 UTC
Version 0.1.0-alpha
Licensed under MIT
Repository at https://github.com/RailTypes/SmartExtend

]]

-- Services
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")

-- Instances
local container = script.Parent
local gui = container.SmartExtendDemo:Clone()

-- Modules
local SmartExtend = require(container.SmartExtend)

-- Plugin instances
local toolbar = plugin:CreateToolbar("SmartExtend Demo")
local button = toolbar:CreateButton("SmartExtend Demo", "Toggles the SmartExtend Demo window.", "")

-- Connections
local selectionChangedCon: RBXScriptConnection?

-- Selection
local selected: Model | BasePart
local isSelected = false

-- Preview
local preview: Instance?

-- Variables
local active = false
local extending = false
local directionIdx = 0
local scale = 1
local rotEpsilon: number? = nil
local sizeEpsilon: number? = nil

-- GUI setup
gui.Parent = CoreGui
gui.Main.Preview.CurrentCamera = workspace.CurrentCamera

-- Sets the visibility of the options.
local function setOptionsVisible(visible: boolean)
	gui.Main.Direction.Visible = visible
	gui.Main.Scale.Visible = visible
	gui.Main.RotEpsilon.Visible = visible
	gui.Main.SizeEpsilon.Visible = visible
	gui.Main.Preview.Visible = visible
	gui.Main.Extend.Visible = visible
end

-- Turns the given text box into a "number" box.
local function numberBox(
	textBox: TextBox,
	callback: (number: number?) -> (number?)?,
	value: number?,
	required: boolean?
)
	if value then textBox.Text = tostring(value) end

	textBox.FocusLost:Connect(function()
		local number = tonumber(textBox.Text)
		if required and value and not number then
			textBox.Text = tostring(value)
			return
		end

		if callback then
			number = callback(number)
			if not number then textBox.Text = "" return end
		end

		value = number
		textBox.Text = tostring(number)
	end)
end

-- Creates a preview.
local function generatePreview()
	if preview then preview:Destroy() end
	if not isSelected then return end

	local newPreview = selected:Clone()
	SmartExtend(
		newPreview,
		Enum.NormalId:FromValue(directionIdx) :: Enum.NormalId,
		scale,
		rotEpsilon,
		sizeEpsilon
	)
	newPreview.Parent = gui.Main.Preview
	preview = newPreview
end

-- Extends the selected model.
local function extend()
	if not isSelected or extending then return end

	local identifier = ChangeHistoryService:TryBeginRecording("SmartExtend")
	if not identifier then
		warn("SmartExtend: Recording identifier could not be generated.")
		return
	end

	extending = true

	SmartExtend(
		selected,
		Enum.NormalId:FromValue(directionIdx) :: Enum.NormalId,
		scale,
		rotEpsilon,
		sizeEpsilon
	)

	ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Commit)
	extending = false
	generatePreview()
end

-- Updates the direction.
local function updateDirection()
	directionIdx = (directionIdx + 1) % 6
	local direction = Enum.NormalId:FromValue(directionIdx) :: Enum.NormalId
	gui.Main.Direction.Text = direction.Name
	generatePreview()
end

-- Updates things when the selection changes.
local function onSelectionChanged()
	local currentSelected = Selection:Get()[1]

	if not currentSelected or not ((currentSelected:IsA("Model") and currentSelected.PrimaryPart) or currentSelected:IsA("BasePart")) then
		isSelected = false
		gui.Main.Path.Text = "Select a Model with a PrimaryPart or a BasePart to get started."
		setOptionsVisible(false)
		generatePreview()
		return
	end

	selected = currentSelected
	isSelected = true

	gui.Main.Path.Text = currentSelected:GetFullName()
	setOptionsVisible(true)
	generatePreview()
end

-- Toggles the plugin.
local function togglePlugin()
	active = not active

	-- Manage connections
	if active then
		selectionChangedCon = Selection.SelectionChanged:Connect(onSelectionChanged)
		onSelectionChanged()
	else
		if selectionChangedCon then selectionChangedCon:Disconnect() end
	end

	button:SetActive(active)
	gui.Enabled = active
end

-- Unloads the plugin.
local function unload()
	gui:Destroy()
end

-- Initialize
gui.Main.Extend.Activated:Connect(extend)
gui.Main.Direction.Activated:Connect(updateDirection)
button.Click:Connect(togglePlugin)
plugin.Unloading:Connect(unload)

numberBox(gui.Main.Scale, function(number)
	if not number then return end
	local processed = math.max(number, 0)
	scale = processed
	generatePreview()
	return processed
end, scale, true)

numberBox(gui.Main.RotEpsilon, function(number)
	if not number then
		rotEpsilon = nil
		generatePreview()
		return
	end

	local processed = math.max(number, 0)
	rotEpsilon = processed
	generatePreview()
	return processed
end)

numberBox(gui.Main.SizeEpsilon, function(number)
	if not number then
		sizeEpsilon = nil
		generatePreview()
		return
	end

	local processed = math.max(number, 0)
	sizeEpsilon = processed
	generatePreview()
	return processed
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	gui.Main.Preview.CurrentCamera = workspace.CurrentCamera
end)
