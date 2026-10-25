const Players = game:GetService(`Players`)

const CreateInstance = require(`./Packages/CreateInstance`)
const CreateInstanceReaction = require(`./Packages/CreateInstanceReaction`)
const CreateInstanceCoffee = require(`./Packages/CreateInstanceCoffee`)
const GreatUIDrag = require(`./Packages/GreatUIDrag`)
const CameraController = require(`./Packages/CameraController`)
const GUICompatibility = require(`./Packages/GUICompatibility`)
const CoffeeObjects = require(`./Packages/CoffeeObjects`)
const Reaction = require(`./Packages/Reaction`)

const Create = CreateInstance.Create
const CreateCoffee = CreateInstanceCoffee.Create
const CreateReaction = CreateInstanceReaction.Create
const CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue
const V, _, C = Reaction:Unpack()

const PlayerGui = (Players.LocalPlayer :: Player):WaitForChild(`PlayerGui`)



--- Camera: a Part at (10, 10, 0) looking towards (0, 3, 0)
const CameraPart = Create(`Part`)({
	Name = `CameraPart`,
	Anchored = true,
	CanCollide = false,
	Transparency = 1,
	Size = Vector3.one,
	CFrame = CFrame.lookAt(Vector3.new(10, 10, 0), Vector3.new(0, 3, 0)),
	Parent = workspace,
})

CameraController:BindToPart(CameraPart)



--- GUI
-- toggled on every click of the TextButton below
const IgnoreInset = CoffeeBaseValue.new(true)

const ScreenGui = CreateCoffee(`ScreenGui`)({
	Name = `SillyTestGui`,
	IgnoreGuiInset = IgnoreInset, -- while true, the bar below covers the TopBar
	ResetOnSpawn = false,
	Parent = PlayerGui,
})

-- GuiInsetSize (number) -> derived CoffeeBaseValues the bar's Size and Text follow
const GuiInsetSize = GUICompatibility:GetGuiInsetSize()
const InsetBarSize = CoffeeBaseValue.new(UDim2.new(1, 0, 0, GuiInsetSize.Value))
const InsetBarText = CoffeeBaseValue.new(`GuiInset: {GuiInsetSize.Value}px`)
GuiInsetSize.Changed:Connect(function(_, newInset)
	InsetBarSize.Value = UDim2.new(1, 0, 0, newInset)
	InsetBarText.Value = `GuiInset: {newInset}px`
end)

CreateCoffee(`TextLabel`)({
	Name = `InsetBar`,
	BackgroundColor3 = Color3.fromRGB(255, 170, 0),
	BackgroundTransparency = 0.6,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0.5,
	Size = InsetBarSize,
	Text = InsetBarText,
	Parent = ScreenGui,
})



--- Draggable TextButton showing its own position
const PosX = V(0)
const PosY = V(0)
const PositionText = C(function()
	return `X: {math.round(PosX())}, Y: {math.round(PosY())}`
end)

const Button = CreateReaction(`TextButton`)({
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

const Drag = GreatUIDrag(Button, Button)
Drag.OnPositionChanged:Connect(function(x, y)
	PosX(x)
	PosY(y)
end)

-- a press only counts as a click if it never turned into a real drag
local WasDragged = false
Drag.OnDragContact:Connect(function()
	WasDragged = false
end)
Drag.OnDragStarted:Connect(function()
	WasDragged = true
end)

Button.Activated:Connect(function()
	if WasDragged then
		return
	end
	IgnoreInset.Value = not IgnoreInset.Value
end)
