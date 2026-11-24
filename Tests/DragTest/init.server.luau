--!strict

const Players = game:GetService(`Players`)
const GuiS = game:GetService(`GuiService`)
const UIS = game:GetService(`UserInputService`)

const GreatUIDrag = require(`./Packages/GreatUIDrag`)
const CreateInstanceReaction = require(`./DevPackages/CreateInstanceReaction`)
const Reaction = require(`./DevPackages/Reaction`)

const CR = CreateInstanceReaction.Create
const V, _, C = Reaction:Unpack()

const PlayerGui = (Players.LocalPlayer :: Player):WaitForChild(`PlayerGui`)



--- GUI ---
-- toggled on every click of the TextButton below
const IgnoreInset = V(true)

const ScreenGui = CR(`ScreenGui`)({
	Name = `GreatUIDragTestGui`,
	IgnoreGuiInset = IgnoreInset, -- while true, the bar below covers the TopBar
	ResetOnSpawn = false,
	Parent = PlayerGui,
})

-- TopBar inset (number) -> V the bar's Size and Text follow; re-read whenever the ScreenGui's size changes (device switch, resize)
const function GetInset(): number
	return GuiS:GetGuiInset().Y
end
const Inset = V(GetInset())
ScreenGui:GetPropertyChangedSignal(`AbsoluteSize`):Connect(function()
	Inset(GetInset())
end)

CR(`TextLabel`)({
	Name = `InsetBar`,
	BackgroundColor3 = Color3.fromRGB(255, 170, 0),
	BackgroundTransparency = 0.6,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0.5,
	Size = C(function()
		return UDim2.new(1, 0, 0, Inset())
	end),
	Text = C(function()
		return `GuiInset: {Inset()}px`
	end),
	Parent = ScreenGui,
})



--- Draggable TextButton showing its own position ---
const PosX = V(0)
const PosY = V(0)
const PositionText = C(function()
	return `X: {math.round(PosX())}, Y: {math.round(PosY())}`
end)

const Button = CR(`TextButton`)({
	Name = `DragMe`,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(200, 60),
	BackgroundColor3 = Color3.fromRGB(40, 40, 60),
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
	Text = PositionText,
	Parent = ScreenGui,
})

-- initial position, before the first drag
PosX(Button.AbsolutePosition.X + Button.AbsoluteSize.X * Button.AnchorPoint.X)
PosY(Button.AbsolutePosition.Y + Button.AbsoluteSize.Y * Button.AnchorPoint.Y)

const Drag = GreatUIDrag(Button, Button, nil, nil, 60)
Drag.OnPositionChanged:Connect(function(x, y)
	PosX(x)
	PosY(y)
end)

const PosX2 = V(0)
const PosY2 = V(0)
const PositionText2 = C(function()
	return `X: {math.round(PosX2())}, Y: {math.round(PosY2())}`
end)

const Button2 = CR(`TextButton`)({
	Name = `DragMe2`,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 1),
	Size = UDim2.fromOffset(200, 60),
	BackgroundColor3 = Color3.fromRGB(40, 40, 60),
	TextColor3 = Color3.new(1, 1, 1),
	TextScaled = true,
	Text = PositionText2,
	Parent = Button,
})

-- initial position, before the first drag
PosX2(Button2.AbsolutePosition.X + Button2.AbsoluteSize.X * Button2.AnchorPoint.X)
PosY2(Button2.AbsolutePosition.Y + Button2.AbsoluteSize.Y * Button2.AnchorPoint.Y)

const Drag2 = GreatUIDrag(Button2, Button2, nil, nil, 60)
Drag2.OnPositionChanged:Connect(function(x, y)
	PosX2(x)
	PosY2(y)
end)

--- Touch event log (for testing on a real phone) ---
-- Checks the claim: MouseButton1Down fires for touches too, while TouchTap fires only AFTER the finger is lifted.
-- Every new press clears the log; times are milliseconds since the first event of the press.
-- (MouseButton1Down fires BEFORE UIS.InputBegan, so whichever comes first starts the press)
const LogGui = Instance.new(`ScreenGui`)
LogGui.Name = `TouchEventLog`
LogGui.ResetOnSpawn = false
LogGui.DisplayOrder = 10
LogGui.Parent = PlayerGui

const LogLabel = Instance.new(`TextLabel`)
LogLabel.Name = `Log`
LogLabel.AnchorPoint = Vector2.new(1, 0)
LogLabel.Position = UDim2.new(1, -8, 0, 8)
LogLabel.Size = UDim2.new(0, 340, 0.8, 0)
LogLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LogLabel.BackgroundTransparency = 0.25
LogLabel.TextColor3 = Color3.new(1, 1, 1)
LogLabel.Font = Enum.Font.Code
LogLabel.TextSize = 13
LogLabel.TextXAlignment = Enum.TextXAlignment.Left
LogLabel.TextYAlignment = Enum.TextYAlignment.Top
LogLabel.TextWrapped = true
LogLabel.RichText = true
LogLabel.Interactable = false -- never takes input from the buttons below it
LogLabel.Parent = LogGui

local PressStart = os.clock()
local PressOpen = false
local Entries: {string} = {}
local Times: {[string]: number} = {}

const function Verdict(): string
	const lines = {}
	const touch = Times[`UIS.InputBegan Touch`]
	const down = Times[`MouseButton1Down`]
	const ended = Times[`UIS.InputEnded Touch`] or Times[`UIS.InputEnded MouseButton1`]
	const tap = Times[`TouchTap`]
	if touch then
		table.insert(lines, if down then `<font color="#5f5">MouseButton1Down fired for the touch</font>` else `<font color="#f55">MouseButton1Down did NOT fire for the touch</font>`)
	end
	if tap and ended then
		table.insert(lines, if tap >= ended
			then `<font color="#5f5">TouchTap came {math.round((tap - ended) * 1000)} ms AFTER the finger lifted</font>`
			else `<font color="#fa5">TouchTap came {math.round((ended - tap) * 1000)} ms BEFORE the finger lifted</font>`)
	elseif touch and ended and not tap then
		table.insert(lines, `TouchTap didn't fire (a drag, or a long press)`)
	end
	table.insert(lines, `drag active: {if (Drag :: any)._isActive then `<font color="#ff5">yes</font>` else `no`}`)
	return table.concat(lines, `\n`)
end

const function Render()
	LogLabel.Text = `{Verdict()}\n\n{table.concat(Entries, `\n`)}`
end

const function Log(name: string, detail: string?)
	const t = os.clock()
	Times[name] = Times[name] or t
	if #Entries >= 25 then
		return
	end
	table.insert(Entries, `+{string.format(`%4d`, math.round((t - PressStart) * 1000))} ms  {name}{if detail then ` {detail}` else ``}`)
	Render()
end

-- the first event of a press clears the log, the press stays open until UIS.InputEnded
const function BeginPress()
	if PressOpen then
		return
	end
	PressOpen = true
	PressStart = os.clock()
	table.clear(Entries)
	table.clear(Times)
end

UIS.InputBegan:Connect(function(input: InputObject, isProcessed: boolean)
	const inputType = input.UserInputType
	if inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseButton1 then
		BeginPress()
		Log(`UIS.InputBegan {inputType.Name}`, `processed={isProcessed}`)
	end
end)
UIS.InputEnded:Connect(function(input: InputObject)
	const inputType = input.UserInputType
	if inputType == Enum.UserInputType.Touch or inputType == Enum.UserInputType.MouseButton1 then
		Log(`UIS.InputEnded {inputType.Name}`)
		PressOpen = false
	end
end)
Button.MouseButton1Down:Connect(function()
	BeginPress()
	Log(`MouseButton1Down`)
end)
Button.MouseButton1Up:Connect(function() Log(`MouseButton1Up`) end)
Button.Activated:Connect(function() Log(`Activated`) end)
Button.TouchTap:Connect(function() Log(`TouchTap`) end)
Button.TouchLongPress:Connect(function(_, state: Enum.UserInputState) Log(`TouchLongPress`, state.Name) end)
-- not a press start: a TouchTap after the finger lifted also fires OnDragContact (InitDrag)
Drag.OnDragContact:Connect(function() Log(`OnDragContact`) end)
Drag.OnDragStarted:Connect(function() Log(`OnDragStarted`) end)
Drag.OnDragReleased:Connect(function(_, wasDragged) Log(`OnDragReleased`, `wasDragged={wasDragged}`) end)
Drag.OnDragCompleted:Connect(function() Log(`OnDragCompleted`) end)
-- keeps "drag active" live; with the old TouchTap handle it would stay "yes" after the finger lifted
game:GetService(`RunService`).Heartbeat:Connect(Render)
Render()

--- /E Touch event log (for testing on a real phone) ---

UIS.InputEnded:Connect(function(inputObject: InputObject, isProcessed: boolean)
	if inputObject.KeyCode ~= Enum.KeyCode.E then
		return
	end
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
	task.wait(0.3)
	ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	task.wait(0.3)
	ScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)

--- SENSIBILITY TEST ---
-- UIS.InputChanged:Connect(function(inputObject: InputObject, isProcessed: boolean)
-- 	if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
-- 		Drag:SetSensibilityMultiplier(Drag._sensibility + inputObject.Position.Z)
-- 	end
-- end)
--- /E SENSIBILITY TEST ---

-- CR(`Frame`)({
-- 	AnchorPoint = Vector2.new(0.5, 0.5),
-- 	Position = UDim2.fromScale(0.5, 0.5),
-- 	Size = UDim2.fromScale(0.5, 0.5),
-- 	BackgroundTransparency = 0.6,
-- 	Parent = ScreenGui,
-- 	Button2,
-- })

-- a press only counts as a click if it never turned into a real drag
-- local IsDragged = false
-- Drag.OnDragContact:Connect(function()
-- 	IsDragged = false
-- end)
-- Drag.OnDragStarted:Connect(function()
-- 	IsDragged = true
-- end)

-- Button.Activated:Connect(function()
-- 	if IsDragged then
-- 		return
-- 	end
-- 	IgnoreInset(not IgnoreInset())
-- end)
