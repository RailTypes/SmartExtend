--!strict
--!optimize 2
--!native

--[[

#################
## SmartExtend ##
#################

Scripted by @RailTypes
Created 2025-07-09 UTC
Updated 2025-07-19 UTC
Version 0.1.0-alpha+17
Licensed under Apache-2.0
Repository at https://github.com/RailTypes/SmartExtend

]]

-- Constants
local DEFAULT_ROT_EPSILON = 1e-5
local DEFAULT_SIZE_EPSILON = 1e-5

-- Returns true if the difference between the two numbers is within the epsilon.
local function isWithinEpsilon(a: number, b: number, epsilon: number)
	return math.abs(a - b) <= epsilon
end

-- Uses the given face to return an axis from the given vector.
local function faceToAxis(vector: Vector3, face: Enum.NormalId): number
	if face == Enum.NormalId.Right or face == Enum.NormalId.Left then
		return vector.X
	elseif face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		return vector.Y
	elseif face == Enum.NormalId.Back or face == Enum.NormalId.Front then
		return vector.Z
	else
		return tonumber("nan") :: number
	end
end

-- Uses the given localized CFrame and primary direction to determine the secondary direction.
local function getLocalDirection(
	cframe: CFrame,
	primaryDirection: Enum.NormalId,
	epsilon: number
): Enum.NormalId?
	epsilon = 1 - epsilon

	local cVector =
		if primaryDirection == Enum.NormalId.Right then cframe.XVector
		elseif primaryDirection == Enum.NormalId.Top then cframe.YVector
		elseif primaryDirection == Enum.NormalId.Back then cframe.ZVector
		elseif primaryDirection == Enum.NormalId.Left then cframe:Inverse().XVector
		elseif primaryDirection == Enum.NormalId.Bottom then cframe:Inverse().YVector
		elseif primaryDirection == Enum.NormalId.Front then cframe.LookVector
		else Vector3.zero

	if cVector.X >= epsilon then
		return Enum.NormalId.Left
	elseif cVector.X <= -epsilon then
		return Enum.NormalId.Right
	elseif cVector.Y >= epsilon then
		return Enum.NormalId.Bottom
	elseif cVector.Y <= -epsilon then
		return Enum.NormalId.Top
	elseif cVector.Z >= epsilon then
		return Enum.NormalId.Back
	elseif cVector.Z <= -epsilon then
		return Enum.NormalId.Front
	else
		return nil
	end
end

-- Extends a part by the given scale in the given direction.
local function doExtend(
	part: BasePart,
	primaryPart: BasePart,
	primaryDirection: Enum.NormalId,
	sizeDirection: Enum.NormalId,
	scale: number
)
	local rotOffset = primaryPart.CFrame:ToObjectSpace(part.CFrame).Rotation
	local size = faceToAxis(part.Size, sizeDirection)
	part.CFrame *= rotOffset:Inverse() * CFrame.new(
		if primaryDirection == Enum.NormalId.Right
			then (size * scale - size) / 2
			elseif primaryDirection == Enum.NormalId.Left
			then (size * scale - size) / -2
			else 0,
		if primaryDirection == Enum.NormalId.Top
			then (size * scale - size) / 2
			elseif primaryDirection == Enum.NormalId.Bottom
			then (size * scale - size) / -2
			else 0,
		if primaryDirection == Enum.NormalId.Back
			then (size * scale - size) / 2
			elseif primaryDirection == Enum.NormalId.Front
			then (size * scale - size) / -2
			else 0
	) * rotOffset
	part.Size = Vector3.new(
		if sizeDirection == Enum.NormalId.Right or sizeDirection == Enum.NormalId.Left
			then part.Size.X * scale
			else part.Size.X,
		if sizeDirection == Enum.NormalId.Top or sizeDirection == Enum.NormalId.Bottom
			then part.Size.Y * scale
			else part.Size.Y,
		if sizeDirection == Enum.NormalId.Back or sizeDirection == Enum.NormalId.Front
			then part.Size.Z * scale
			else part.Size.Z
	)
end

-- Places or removes the given instance along the given part in the given direction.
local function instanceAlongPart(
	instance: PVInstance,
	primaryPart: BasePart,
	direction: Enum.NormalId,
	scale: number
)
	local offset = primaryPart.CFrame:ToObjectSpace(instance:GetPivot())
	local ratio = math.clamp((faceToAxis(offset.Position, direction)
		+ faceToAxis(primaryPart.Size, direction) / 2)
		/ faceToAxis(primaryPart.Size, direction), 0, 1)
	if direction == Enum.NormalId.Left
		or direction == Enum.NormalId.Bottom
		or direction == Enum.NormalId.Front
	then
		ratio = 1 - ratio
	end

	if scale > 1 then
		local amount = math.floor(scale - ratio)
		if amount < 1 then return end

		local size = faceToAxis(primaryPart.Size, direction)
		for i = 1, amount do
			local clone = instance:Clone()
			local dist = size * i
			clone:PivotTo(primaryPart.CFrame * CFrame.new(
				if direction == Enum.NormalId.Right then dist
					elseif direction == Enum.NormalId.Left then -dist
					else 0,
				if direction == Enum.NormalId.Top then dist
					elseif direction == Enum.NormalId.Bottom then -dist
					else 0,
				if direction == Enum.NormalId.Back then dist
					elseif direction == Enum.NormalId.Front then -dist
					else 0
			) * offset)
			clone.Parent = instance.Parent
		end
	elseif scale < 1 and ratio > scale then
		instance:Destroy()
	end
end

-- Begins the loop of extending parts.
local function doLoop(
	instance: Instance,
	primaryPart: BasePart,
	direction: Enum.NormalId,
	scale: number,
	rotEpsilon: number,
	sizeEpsilon: number
)
	for index, child in instance:GetChildren() do
		if child == primaryPart then continue end

		if child:IsA("BasePart") then
			local localCFrame = primaryPart.CFrame:ToObjectSpace(child.CFrame)
			local localDirection = getLocalDirection(localCFrame, direction, rotEpsilon)
			local sizeEq = if localDirection then isWithinEpsilon(
				faceToAxis(primaryPart.Size, direction),
				faceToAxis(child.Size, localDirection),
				sizeEpsilon
			) else false
			if localDirection and sizeEq then
				doExtend(child, primaryPart, direction, localDirection, scale)
			else
				instanceAlongPart(child, primaryPart, direction, scale)
			end
		elseif child:IsA("PVInstance") then
			instanceAlongPart(child, primaryPart, direction, scale)
		else
			doLoop(child, primaryPart, direction, scale, rotEpsilon, sizeEpsilon)
		end
	end
end

-- Extends the given model or part by the given scale in the given direction while using less parts.
local function SmartExtend(
	extending: Model | BasePart,
	direction: Enum.NormalId,
	scale: number,
	rotEpsilon: number?,
	sizeEpsilon: number?
): boolean
	local primaryPart = if extending:IsA("Model") then extending.PrimaryPart else extending
	if not primaryPart then return false end

	local rotEpsilon = if type(rotEpsilon) == "number" then rotEpsilon else DEFAULT_ROT_EPSILON
	local sizeEpsilon = if type(sizeEpsilon) == "number" then sizeEpsilon else DEFAULT_SIZE_EPSILON

	doLoop(extending, primaryPart, direction, scale, rotEpsilon, sizeEpsilon)
	doExtend(primaryPart, primaryPart, direction, direction, scale)

	return true
end

-- Return the function.
return SmartExtend
