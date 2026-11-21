--[[--
    GUICompatibility test & example (RunContext = Client)
    Change the Target ScreenGui's properties from the panel on the left, the pink Pointer will stay under the cursor/finger.
--]]--
--!strict

const Players = game:GetService(`Players`)
const UIS = game:GetService(`UserInputService`)
const GuiService = game:GetService(`GuiService`)

const GUICompatibility = require(`./Packages/GUICompatibility`)
const Reaction = require(`./Packages/Reaction`)
const O = Reaction.O

const PlayerGui = (Players.LocalPlayer :: Player):WaitForChild(`PlayerGui`)
const GuiInsetSize = GUICompatibility:GetGuiInsetSize()
const SafeInsetsSize = GUICompatibility:GetSafeInsetsSize()
const FullscreenAbsoluteSize = GUICompatibility:GetFullscreenAbsoluteSize()



--- 1. Target ScreenGui (the one being tested) ---
const Target = Instance.new(`ScreenGui`)
Target.Name = `Target`
Target.ResetOnSpawn = false -- constantly off
Target.ClipToDeviceSafeArea = false
Target.DisplayOrder = 1
Target.Parent = PlayerGui

-- shows the Target's area
const TargetArea = Instance.new(`Frame`)
TargetArea.Name = `Area`
TargetArea.Size = UDim2.fromScale(1, 1)
TargetArea.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
TargetArea.BackgroundTransparency = 0.85
TargetArea.BorderSizePixel = 0
TargetArea.Parent = Target

const TargetStroke = Instance.new(`UIStroke`)
TargetStroke.Color = Color3.fromRGB(60, 160, 255)
TargetStroke.Thickness = 2
TargetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
TargetStroke.Parent = TargetArea

const Pointer = Instance.new(`Frame`)
Pointer.Name = `Pointer`
Pointer.AnchorPoint = Vector2.new(0.5, 0.5)
Pointer.Size = UDim2.fromOffset(6, 6)
Pointer.BackgroundColor3 = Color3.fromRGB(255, 60, 255)
Pointer.BorderSizePixel = 0
Pointer.ZIndex = 10
Pointer.Parent = Target

const Center = Instance.new(`Frame`)
Center.Name = `Center`
Center.AnchorPoint = Vector2.one / 2
Center.Position = UDim2.fromScale(.5, .5)
Center.Size = UDim2.fromOffset(6, 6)
Center.BackgroundColor3 = Color3.fromRGB(255, 229, 60)
Center.BorderSizePixel = 2
Center.ZIndex = 10
Center.Parent = Target



--- Pointer calculation ---
const TargetOffset = GUICompatibility:TrackInputOffsetUDim2(Target)
local LastInputPosition = Vector2.zero

const function UpdatePointer()
	Pointer.Position = UDim2.fromOffset(LastInputPosition.X, LastInputPosition.Y) + TargetOffset()
end

UIS.InputChanged:Connect(function(input: InputObject)
	const userInputType = input.UserInputType
	if not (userInputType == Enum.UserInputType.MouseMovement or userInputType == Enum.UserInputType.Touch) then
		return
	end
	LastInputPosition = Vector2.new(input.Position.X, input.Position.Y)
	UpdatePointer()
end)
O(TargetOffset, UpdatePointer)



--- 2. Example ScreenGui (README example) ---
const UI = Instance.new(`ScreenGui`)
UI.Name = `Example`
UI.ResetOnSpawn = false
UI.IgnoreGuiInset = false
UI.ClipToDeviceSafeArea = false
UI.Parent = PlayerGui
const UIOffset = GUICompatibility:TrackInputOffsetUDim2(UI)

const function Label(name: string, parent: Instance): TextLabel
	const label = Instance.new(`TextLabel`)
	label.Name = name
	label.BorderSizePixel = 0
	label.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.Parent = parent
	return label
end

const safeArea = Label(`SafeArea`, UI)
safeArea.AnchorPoint = Vector2.new(.5, 1)
safeArea.Position = UDim2.fromScale(.5, 1)
safeArea.Size = UDim2.fromScale(1, 0.1)
safeArea.BackgroundColor3 = Color3.fromRGB(160, 60, 255)
safeArea.TextScaled = false
safeArea.TextSize = 14
safeArea.ZIndex = -1

const fullAreaX = Label(`FullAreaX`, UI)
fullAreaX.AnchorPoint = Vector2.new(.5, 1)
fullAreaX.Position = UDim2.fromScale(.5, 1)
fullAreaX.BackgroundColor3 = Color3.fromRGB(255, 229, 60)
fullAreaX.TextColor3 = Color3.fromRGB(21, 21, 21)
fullAreaX.TextScaled = false
fullAreaX.TextSize = 14
fullAreaX.TextYAlignment = Enum.TextYAlignment.Top
fullAreaX.ZIndex = -2

const safeAreaYBottomLabel = Label(`SafeAreaYBottom`, UI)
safeAreaYBottomLabel.AnchorPoint = Vector2.new(.5, 0)
safeAreaYBottomLabel.Position = UDim2.fromScale(.5, 1)
safeAreaYBottomLabel.ZIndex = -1

const safeAreaYTopLabel = Label(`SafeAreaYTop`, UI)
safeAreaYTopLabel.AnchorPoint = Vector2.new(.5, 0)
safeAreaYTopLabel.Position = UDim2.fromScale(.5, 0)
safeAreaYTopLabel.ZIndex = -1

const topbarUnsafeArea = Label(`TopbarInset`, UI)
topbarUnsafeArea.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
topbarUnsafeArea.BackgroundTransparency = 0.35
topbarUnsafeArea.TextScaled = false
topbarUnsafeArea.TextSize = 13
topbarUnsafeArea.TextXAlignment = Enum.TextXAlignment.Right
topbarUnsafeArea.ZIndex = -1
const topbarSafeAreaPadding = Instance.new(`UIPadding`)
topbarSafeAreaPadding.PaddingRight = UDim.new(0, 8)
topbarSafeAreaPadding.Parent = topbarUnsafeArea

const function UpdateExample()
	const safeInsetsSize = SafeInsetsSize()
	fullAreaX.Size = UDim2.new(1, safeInsetsSize.X, 0.1, 20)
	const safeWidth = FullscreenAbsoluteSize().X
	fullAreaX.Text = `Whole screen width (ScreenInsets.None): {safeWidth + safeInsetsSize.X} px, unsafe margins: {safeInsetsSize.X} px`
	safeArea.Text = `Device safe area width (DeviceSafeInsets): {safeWidth} px`

	safeAreaYBottomLabel.Size = UDim2.new(0.1, 0, 0, safeInsetsSize.Y)
	safeAreaYBottomLabel.Text = `{safeInsetsSize.Y} px`
	
	safeAreaYTopLabel.Position = UDim2.new(.5, UIOffset().X.Offset/2, 0, -GuiInsetSize() + UIOffset().Y.Offset)
	safeAreaYTopLabel.Size = UDim2.new(0.1, 0, 0, GuiInsetSize())
	safeAreaYTopLabel.Text = `{GuiInsetSize()} px`

	const topbar = GuiService.TopbarInset
	topbarUnsafeArea.Position = UDim2.fromOffset(0, -GuiInsetSize()) + UIOffset()
	topbarUnsafeArea.Size = UDim2.fromOffset(topbar.Min.X, topbar.Height)
	topbarUnsafeArea.Text = `{topbar.Min.X} x {topbar.Height} px`
end
UpdateExample()
O(GuiInsetSize, UpdateExample)
O(UIOffset, UpdateExample)
O(SafeInsetsSize, UpdateExample)
O(FullscreenAbsoluteSize, UpdateExample)
GuiService:GetPropertyChangedSignal(`TopbarInset`):Connect(UpdateExample)



--- Control panel (its own ScreenGui, never changed) ---
const Panel = Instance.new(`ScreenGui`)
Panel.Name = `GUICompatibilityTestPanel`
Panel.ResetOnSpawn = false
Panel.DisplayOrder = 2
Panel.Parent = PlayerGui

const List = Instance.new(`Frame`)
List.Name = `List`
List.Position = UDim2.fromOffset(12, 4)
List.Size = UDim2.fromOffset(300, 0)
List.AutomaticSize = Enum.AutomaticSize.Y
List.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
List.BackgroundTransparency = 0.15
List.BorderSizePixel = 0
List.Parent = Panel

const Layout = Instance.new(`UIListLayout`)
Layout.Padding = UDim.new(0, 2)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = List

const ListPadding = Instance.new(`UIPadding`)
ListPadding.PaddingTop = UDim.new(0, 6)
ListPadding.PaddingBottom = UDim.new(0, 6)
ListPadding.PaddingLeft = UDim.new(0, 8)
ListPadding.PaddingRight = UDim.new(0, 8)
ListPadding.Parent = List

local NextLayoutOrder = 0
const function Row(className: "TextButton" | "TextLabel"): TextButton | TextLabel
	NextLayoutOrder += 1
	const row = Instance.new(className) :: TextButton | TextLabel
	row.LayoutOrder = NextLayoutOrder
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundColor3 = if className == `TextButton` then Color3.fromRGB(55, 55, 70) else Color3.fromRGB(25, 25, 30)
	row.BackgroundTransparency = if className == `TextButton` then 0 else 1
	row.BorderSizePixel = 0
	row.TextColor3 = Color3.new(1, 1, 1)
	row.TextSize = 14
	row.Font = Enum.Font.Code
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = List
	return row
end

-- A button that cycles through the options of a Target property
const function Select<T>(propertyName: string, options: {T}, toText: (T) -> string)
	const button = Row(`TextButton`) :: TextButton
	const function refresh()
		button.Text = ` {propertyName}: {toText((Target :: any)[propertyName])}`
	end
	button.Activated:Connect(function()
		const current = (Target :: any)[propertyName]
		const index = table.find(options, current) or 0
		;(Target :: any)[propertyName] = options[index % #options + 1]
	end)
	Target:GetPropertyChangedSignal(propertyName):Connect(refresh)
	refresh()
end

const function EnumName(item: EnumItem): string
	return item.Name
end

const Title = Row(`TextLabel`)
Title.Text = `Target ScreenGui (click to change)`
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16

Select(`ScreenInsets`, Enum.ScreenInsets:GetEnumItems(), EnumName)
Select(`IgnoreGuiInset`, {false, true}, tostring)
Select(`SafeAreaCompatibility`, Enum.SafeAreaCompatibility:GetEnumItems(), EnumName)
Select(`ClipToDeviceSafeArea`, {false, true}, tostring)

const AbsolutePositionLabel = Row(`TextLabel`)
const AbsoluteSizeLabel = Row(`TextLabel`)
const InsetLabel = Row(`TextLabel`)
const PointerLabel = Row(`TextLabel`)

const function RefreshAbsolute()
	AbsolutePositionLabel.Text = ` AbsolutePosition: {Target.AbsolutePosition}`
	AbsoluteSizeLabel.Text = ` AbsoluteSize: {Target.AbsoluteSize}`
end
Target:GetPropertyChangedSignal(`AbsolutePosition`):Connect(RefreshAbsolute)
Target:GetPropertyChangedSignal(`AbsoluteSize`):Connect(RefreshAbsolute)
RefreshAbsolute()

O(GuiInsetSize, function(inset: number)
	InsetLabel.Text = ` GuiInsetSize(): {inset}`
end)
InsetLabel.Text = ` GuiInsetSize(): {GuiInsetSize()}`

Pointer:GetPropertyChangedSignal(`Position`):Connect(function()
	PointerLabel.Text = ` Pointer offset: {Pointer.Position.X.Offset}, {Pointer.Position.Y.Offset}`
end)
PointerLabel.Text = ` Pointer offset: -`

const TargetOffsetLabel = Row(`TextLabel`)
const function RefreshTargetOffset()
	const offset = TargetOffset()
	TargetOffsetLabel.Text = ` TargetOffset(): {offset.X.Offset}, {offset.Y.Offset}`
end
O(TargetOffset, RefreshTargetOffset)
RefreshTargetOffset()
