# EasySmoothDamp
Easier way to use TweenService:SmoothDamp() - keeps the required variables in a metatable!

---

## Available [Here](src/init.luau)!
- **[Wally](<https://wally.run>)** ~ ``EasySmoothDamp = "coffilhg/easysmoothdamp@1.0.0"``
<!--- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[EasySmoothDamp](<https://create.roblox.com/store/asset/114136223178149/CoffeeBaseValue>)**-->

---

## Features

- TweenService:SmoothDamp() made simpler, just for faster typing!
- When to and Why use **SmoothDamp**? Watch this tutorial by Roblox: **"[How to use SmoothDamp for smooth UX on Roblox](<https://www.youtube.com/watch?v=RYzj4TjiMyE>)"**
- Why use **EasySmoothDamp**? Keeps the Feedback values for SmoothDamp internally!

---

## Installation

Use the [previous section](README.md#L6) to obtain the Module

Require the Module:
```lua
local EasySmoothDamp = require(PathToModule)
```

---

## Roblox Example VS Roblox Example + EasySmoothDamp

**Roblox Example from "[How to use SmoothDamp for smooth UX on Roblox](<https://www.youtube.com/watch?v=RYzj4TjiMyE>)" - 50 Lines and multiple Feedback values for SmoothDamp**
```lua
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local head = script.Parent:WaitForChild("Head") :: BasePart

local cloud = script.Cloud
cloud.Parent = script.Parent -- Put cloud into the character model

-- Offset from the head
local offset = Vector3.new(0, 5, 0)

-- Feedback values for SmoothDamp:
local currentCFrame = head.CFrame + offset
local currentVelocity = Vector3.zero

local smoothTime = 0.5
local maxSpeed = nil

local function impulse()
	currentVelocity += Vector3.new(0, 10, 0)
end

local function onUpdate(dt: number)
	local targetCFrame = head.CFrame + offset
	
	currentCFrame, currentVelocity = TweenService:SmoothDamp(
		currentCFrame,
		targetCFrame,
		currentVelocity,
		smoothTime,
		maxSpeed,
		dt
	)
	
	cloud:PivotTo(currentCFrame)
end

local function onInputBegan(input: InputObject, processed: boolean)
	if processed then return end
	
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.C then
			impulse()
		end
	end
end

RunService.PreRender:Connect(onUpdate)
UserInputService.InputBegan:Connect(onInputBegan)
```

**Same as Roblox Example, but using EasySmoothDamp - 54 Lines (with more comments) and Feedback values for SmoothDamp are just hidden behind a metatable!**
```lua
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local EasySmoothDamp = require(game.ReplicatedStorage.EasySmoothDamp)

local head = script.Parent:WaitForChild("Head") :: BasePart

local cloud = script.Cloud
cloud.Parent = script.Parent -- Put cloud into the character model

-- Offset from the head
local offset = Vector3.new(0, 5, 0)

-- Feedback values for SmoothDamp:
local CloudSmoothDamper = EasySmoothDamp.new(
	head.CFrame + offset, -- currentCFrame
	head.CFrame + offset, -- targetCFrame
	Vector3.zero, -- currentVelocity
	0.5, -- smoothTime
	nil -- maxSpeed
)
-- When this is set to false
CloudSmoothDamper.IsReturnIsFinishedStateOnUpdateEnabled = false
-- SmoothDamper:Update(dt) -> returns only the currentValue (named 
-- currentCFrame for this example); This can be passed as argument
-- e.g. cloud:PivotTo(CloudSmoothDamper:Update(dt))

local function impulse()
	--currentVelocity += Vector3.new(0, 10, 0)
	CloudSmoothDamper.CurrentSpeed += Vector3.new(0, 10, 0)
end

local function onUpdate(dt: number)
	--local targetCFrame = head.CFrame + offset
	CloudSmoothDamper.CurrentGoal = head.CFrame + offset

	--currentCFrame, ... = TweenService:SmoothDamp(...)
	local currentCFrame = CloudSmoothDamper:Update(dt)

	cloud:PivotTo(currentCFrame)
end

local function onInputBegan(input: InputObject, processed: boolean)
	if processed then return end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.C then
			impulse()
		end
	end
end

RunService.PreRender:Connect(onUpdate)
UserInputService.InputBegan:Connect(onInputBegan)
```

---

## Basic Usage

- **Creating a SmoothDamper - EasySmoothDamp.new(...)**
```lua
-- Make a number go from 0 to 100

local SmoothDamper = EasySmoothDamp.new(
	-- EasySmoothDamp naming (Documentation naming) [isRequired?] {Defaults}
	0, -- CurrentValue (current) [✅] {none}
	100, -- CurrentGoal (target) [✅] {none}
	0, -- CurrentSpeed (velocity) {0, Vector2.zero, Vector3.zero, CFrame.identity}
	0.1, -- SmoothTime (smoothTime) {0.3}
	100 -- MaxSpeed (maxSpeed) {100}
)
-- type of SmoothDamper -> in this case EasySmoothDamp.SmoothDamper<number>
```

- **SmoothDamper:Update(deltaTime: number?)**
```lua
local RunService = game:GetService("RunService")
local conn = nil

-- Update the value after given DeltaTime
conn = RunService.PreRender:Connect(function(dt: number)
	local currentValue, isFinished = SmoothDamper:Update(dt)

    print(`Current Value = {currentValue}`)

    if isFinished then
        conn:Disconnect()
        -- the Value will be near 100, but not exactly!
        -- It'd be somewhere in between 100-EPSILON to 100
        print(`Done! Finished with Value = {currentValue}`)
    end
end)
```

- **Setting custom EPSILON - EasySmoothDamp.SetEPSILON(newEPSILONValue : number?)**

```lua
-- Default EPSILON is 1e-3 (0.001)

EasySmoothDamp.SetEPSILON() -- sets EPSILON back to 1e-3 (0.001)
EasySmoothDamp.SetEPSILON(0.123) -- sets EPSILON to your number (e.g. 0.123)
```

- **Don't want to use RunService, but need auto deltaTime? - Here's an example!**
```lua
-- be careful automatic deltaTime is calculated since the creation time of the SmoothDamper!
-- if you had something like a huge wait between creation of the SmoothDamper and
-- its :Update() without a specified deltaTime, don't forget to reset!

-- SmoothDamper created using EasySmoothDamp.new(...)
-- Something took multiple seconds to load, before the update loop starts (we'll simulate it)
task.wait(3)
SmoothDamper:ResetInternalTime()

-- Warning! Do NOT run this in Command Bar, EasySmoothDamp uses time(), which is
-- always zero for whenever you aren't in test mode.

while task.wait() do
    local currentValue, isFinished = SmoothDamper:Update() -- don't set deltaTime
    -- so it calculates automatically

    print(`Current Value = {currentValue}`)

    if isFinished then
        -- the Value will be near 100, but not exactly!
        -- It'd be somewhere in between 100-EPSILON to 100
        print(`Done! Finished with Value = {currentValue}`)
        break
    end
end
```

- **Want to only receive *currentValue*, but not the isFinished when using :Update?**
```lua
-- simply turn it off!
SmoothDamper.IsReturnIsFinishedStateOnUpdateEnabled = false
-- (or turn it back on by setting it back to true)
```

- **SmoothDamper:IsFinished(): boolean**
```lua
-- If you've disabled the receival of isFinished argument, you might want to
-- check it sometimes, do it using :IsFinished()

print(SmoothDamper:IsFinished()) -- false

SmoothDamper.CurrentValue = SmoothDamper.CurrentGoal

print(SmoothDamper:IsFinished()) -- true
```

---

## API

**EasySmoothDamp**
- `.new(CurrentValue : T, CurrentGoal : T, CurrentSpeed : (T)?, SmoothTime : number?, MaxSpeed : number?): SmoothDamper<T>`
> T is one of the SmoothDampSupported types - number | Vector2 | Vector3 | CFrame
> CurrentValue and CurrentGoal must be the same type
> CurrentSpeed will be automatically set to the type of CurrentValue, even if a wrong CurrentSpeed type is given (doesn't throw errors)
> CurrentValue, CurrentGoal and CurrentSpeed can only be reassigned to the same initial type T later.
- `.SetEPSILON(newEPSILONValue : number?)`
> Default EPSILON is 1e-3 (0.001); Given no newEPSILONValue applies the default.

**SmoothDamper**
- `:Update(deltaTime: number?): (T, boolean?)`
> Calls TweenService:SmoothDamp with the given deltaTime or calculates the deltaTime automatically (time since creation via .new or last :Update call)
> returns CurrentValue, and if self.IsReturnIsFinishedStateOnUpdateEnabled is true, also returns the result of :IsFinished()
- `:IsFinished(): boolean`
> Checks whether the difference between CurrentValue and CurrentGoal is less than EPSILON
- `:ResetInternalTime()`
> Resets last :Update() call time to current time()

---

## NOTES

Everytime you use `SmoothDamper:Update()`, it also does `SmoothDamper:IsFinished()` to return isFinished boolean, unless disabled by setting `SmoothDamper.IsReturnIsFinishedStateOnUpdateEnabled = false`

---

## License / License & Attribution

Licensed under the Apache License, Version 2.0.

You may use, modify, and redistribute this module freely, provided that the original copyright notice and license header at the top of the file are preserved.

See the [Apache License 2.0](LICENSE) for full terms.

<!--Attribution to all dependencies is included in [Notice](NOTICE)-->

© 2026 Coffilhg