--!strict
local SSS = game:GetService(`ServerScriptService`)
local RS = game:GetService(`ReplicatedStorage`)

-- Coffee Remote Refined ~ Server
local CRRServer = SSS.CoffeeRemotesServer
local CoffeeRemotes = require(CRRServer)
--local RemoteEvent, RemoteFunction, URemoteEvent =
--	CoffeeRemotes.RemoteEvent,
--	CoffeeRemotes.RemoteFunction,
--	CoffeeRemotes.UnreliableRemoteEvent
local RemoteEvent, RemoteFunction, URemoteEvent = CoffeeRemotes:Unpack()

-- Log the time of each test Pass/Fail with status
local Timestamps = {
	{`Script Started (✅)`, time()},
}
-- CRR -> CoffeeRemotesRefined
local PREFIX = "[CRR Test]: "

local FailCount = 0
local PassCount = 0

local function TestPass(test_txt: string, is_pass: boolean)
	local mainPrefix = --[[PREFIX .. ]]test_txt:gsub(`%|`, `\\|`)
	print(mainPrefix .. ": " .. (if is_pass == true then "PASS ✅" else "FAIL ❌"))
	table.insert(
		Timestamps,
		{
			mainPrefix .. "(" .. (if is_pass == true then "✅" else "❌") .. ")",
			time()
		}
	)
	if is_pass == true then
		PassCount += 1
	else
		FailCount += 1
	end
end

local function FindFirstChildOfClassNamed(parent: Instance, className: string, name: string): Instance?
	for _, child in parent:GetChildren() do
		local childName = child.Name
		if not (childName == name or childName:match(name)) then
			continue
		end
		if not child:IsA(className) then
			continue
		end

		return child
	end
	return nil
end

local function WaitForFirstChildOfClassNamed(parent: Instance, className: string, name: string): Instance
	local match = FindFirstChildOfClassNamed(parent, className, name)
	
	if not match then
		repeat
			task.wait()
			match = FindFirstChildOfClassNamed(parent, className, name)
		until match
	end
	
	return match :: Instance
end

-- Get Folders to test errors
local MainFolder = WaitForFirstChildOfClassNamed(
	RS,
	`Folder`,
	`CoffeeRemotesRefined$`
) :: Folder
local RemoteEventsFolder = WaitForFirstChildOfClassNamed(
	MainFolder,
	`Folder`,
	`Events`
) :: Folder
local RemoteFunctionsFolder = WaitForFirstChildOfClassNamed(
	MainFolder,
	`Folder`,
	`Functions`
) :: Folder
local UnreliableRemoteEventsFolder = WaitForFirstChildOfClassNamed(
	MainFolder,
	`Folder`,
	`UnreliableEvents`
) :: Folder

-- Create remotes for client side double-object creation warn:
RemoteEvent.new(`Dummy`)
RemoteFunction.new(`Dummy`)
URemoteEvent.new(`Dummy`)
---	---	---

local Padding = table.concat(table.create(3, `\n`), `\n`)
local KindOfs = {RemoteEvent, RemoteFunction, URemoteEvent}
local NKindOfs = #KindOfs
local AppropriateClassNamePerKindOf = {`RemoteEvent`, `RemoteFunction`, `UnreliableRemoteEvent`}
local KindOfFolders = {RemoteEventsFolder, RemoteFunctionsFolder, UnreliableRemoteEventsFolder}

local function LogKindOf(kindOfIndex: number)
	return `kindOf indexed at {kindOfIndex} ({
		type(kindOfIndex) ~= `number` and `Not a number index. FATAL ERROR❌`
		or kindOfIndex == 1 and `Event`
		or kindOfIndex == 2 and `Function`
		or kindOfIndex == 3 and `Uvent`
		or `Out of range. FATAL ERROR❌`
	}); `
end



warn(`{Padding} {PREFIX}Test #1: Non-kindOf Instance occypying a name`)
--[[
-- Old test version back when mkremote would error in that case
local NonKindOfsErrorAmount = 0

for i, kindOf in KindOfs do
	local occupant = Instance.new(`Folder`, KindOfFolders[i])
	occupant.Name = `GenericRemoteEventName`

	local success, result = pcall(function()
		return kindOf.new(`GenericRemoteEventName`)
	end)
	
	if success then
		warn(`Test #1 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	if not (type(result) == `string` and (result :: string):match(`.*Found a non%-.*Instance.*already occupying the name.*in.*; This will lead to challenges on the client%-side!`)) then
		warn(`Test #1 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	
	print(`Expect false, error message containing "Found a non-<kindOf> Instance..."\n\t`, success, result)
	
	NonKindOfsErrorAmount += 1
	
	-- cleanup
	-- occupant:Destroy() -- nah actually don't cleanup, keep that for client testing
end

TestPass(`[1] Non-kindOf Instance occypying a name`, NonKindOfsErrorAmount == NKindOfs)
--]]
local NonKindOfsSuccessAmount = 0

for i, kindOf in KindOfs do
	local occupant = Instance.new(`Folder`, KindOfFolders[i])
	occupant.Name = `GenericRemoteEventName`

	local success, result = pcall(function()
		return kindOf.new(`GenericRemoteEventName`)
	end)
	
	if not (success and type(result) == `table`) then
		warn(`Test #1 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end

	print(`Expect true, CoffeeRemotesObject\n\t`, success, result)

	NonKindOfsSuccessAmount += 1

	-- cleanup
	-- occupant:Destroy() -- nah actually don't cleanup, keep that for client testing
end

TestPass(`[1] Non-kindOf Instance occypying a name`, NonKindOfsSuccessAmount == NKindOfs)



warn(`{Padding} {PREFIX}Test #1.1: Appropriate-KindOf Instance occypying a name, but isn't tied to an Object`)
local AppropriateKindOfsUsedAmount = 0

for i, kindOf in KindOfs do
	local occupant = Instance.new(AppropriateClassNamePerKindOf[i])
	occupant.Name = `AppropriateRemoteInstanceKindOf`
	occupant.Parent = KindOfFolders[i]
	
	print(`\nExpect a warning: "Return the existing Instance%.$"`)

	local success, result = pcall(function()
		return (kindOf :: any).new(occupant.Name)
	end)
	
	if not success then
		warn(`Test #1.1 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	
	if not (type(result) == `table` and result[`_RI`] == occupant and result[`Remote`] == occupant) then
		warn(`Test #1.1 fail at {LogKindOf(i)}result["_RI"] (private) or result["Remote"] (public) field doesn't match the existing non-tied Instance; Success, Result received:`, success, result)
		continue
	end
	
	AppropriateKindOfsUsedAmount += 1
	
	-- cleanup
	occupant:Destroy()
end

TestPass(`[1.1] Name taken by non-Object tied Instance of appropriate kind`, AppropriateKindOfsUsedAmount == NKindOfs)



warn(`{Padding} {PREFIX}Test #2: Creating Remote of all kinds with the same name`)
-- while this is now handled by the new Test #1, this one is more explicit, so we'll keep it.
local DifferentKindsSameNameSuccessAmount = 0
local Test2RemotesCached : {[number]: CoffeeRemotes.CoffeeRemotesObject} = {}
for i, kindOf in KindOfs do
	local success, result = pcall(function()
		return kindOf.new(`SameName`)
	end)
	
	if not (success and type(result) == `table`) then
		warn(`Test #2 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	
	print(`Expect true, CoffeeRemotesObject\n\t`, success, result)
	
	Test2RemotesCached[i] = result

	DifferentKindsSameNameSuccessAmount += 1
end

TestPass(`[2] Creating Remote of all kinds with the same name`, DifferentKindsSameNameSuccessAmount == NKindOfs)



warn(`{Padding} {PREFIX}Test #3: Creating Remote of all kinds with a taken name`)
local AlreadyTakenNameSuccessAmount = 0

for i, kindOf in KindOfs do
	print(`\nExpect a warning: "Return the existing object%.$"`)
	local success, result = pcall(function()
		return kindOf.new(`SameName`)
	end)
	-- The result must be a CoffeeRemotesObject of the given kind
	if not (success and type(result) == `table`) then
		warn(`Test #3 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	-- The result must find a match in Test2RemotesCached
	if Test2RemotesCached[i] ~= result then
		warn(`Test #3 fail at {LogKindOf(i)}A new Object was created, but it was expected that an older one will be returned as the result; Success, Result received:`, success, result)
		continue
	end

	AlreadyTakenNameSuccessAmount += 1
end

TestPass(`[3] Creating Remote of all kinds with a taken name`, AlreadyTakenNameSuccessAmount == NKindOfs)



warn(`{Padding} {PREFIX}Test #4: \n\t.0 Destruction clears all of Object' Fields (makes it empty)\n\t.1 Attempt Read From Destroyed Object\n\t.2 Attempt Write To Destroyed Object\n\t.3 .Destroying Signal fires once`)
local DestorySuccess = 0
local DestroyedInstancesCantRead = 0
local DestroyedInstanceCantWrite = 0
local DestoyingSignalsReceived = 0

for i, remoteObject in Test2RemotesCached do
	local destroyingSignalReceivedTimes = 0
	print(remoteObject[`Destroying`])
	remoteObject.Destroying:Connect(function()
		destroyingSignalReceivedTimes += 1
		DestoyingSignalsReceived += 1
	end);
	
	(remoteObject :: any):Destroy()
	
	local isEmpty = true
	for k, v in remoteObject do
		isEmpty = false
		warn(`Test #4.0 fail at {LogKindOf(i)}CoffeeRemotesObject was expected to be empty after destruction, got:`, remoteObject)
		break
	end
	if isEmpty then
		DestorySuccess += 1
	end
	
	local readSuccess, readResult = pcall(function()
		return remoteObject.Destroy
	end)
	
	if type(readResult) == `string` and readResult:match(`Attempt to use destroyed CoffeeRemotesObject`) and not readSuccess then
		DestroyedInstancesCantRead += 1
	else
		warn(`Test #4.1 fail at {LogKindOf(i)}Reads Shall not be possible; readSuccess, readResult`, readSuccess, readResult)
	end
	
	local writeSuccess, writeResult = pcall(function()
		remoteObject.Destroy = true :: any
	end)
	
	if type(writeResult) == `string` and writeResult:match(`Attempt to modify destroyed CoffeeRemotesObject`) and not writeSuccess then
		DestroyedInstanceCantWrite += 1
	else
		warn(`Test #4.2 fail at {LogKindOf(i)}Writes Shall not be possible; writeSuccess, writeResult`, writeSuccess, writeResult)
	end
	
	if destroyingSignalReceivedTimes ~= 1 then
		warn(`Test #4.3 fail at {LogKindOf(i)}Expected to receive destroying signal ONCE, got {destroyingSignalReceivedTimes}`)
	end
	
	print(`Expect true, false, "Attempt to modify destroyed CoffeeRemotesObject", false, "Attempt to use destroyed CoffeeRemotesObject", 1\n\t\t`, table.concat({
		tostring(isEmpty),
		tostring(readSuccess),
		readResult,
		tostring(writeSuccess),
		writeResult,
		tostring(destroyingSignalReceivedTimes),
	}, `\n\t\t`))
end

TestPass(`[4.0] Destruction empties objects`, DestorySuccess == NKindOfs)
TestPass(`[4.1] Destroyed objects error on read`, DestroyedInstancesCantRead == NKindOfs)
TestPass(`[4.2] Destroyed objects error on write`, DestroyedInstanceCantWrite == NKindOfs)
TestPass(`[4.3] Destroying signal fires once`, DestoyingSignalsReceived == NKindOfs)



warn(`{Padding} {PREFIX}Test #5: Error creating unnamed (non-string named) Object`)
local UnnamedErrorAmount = 0

for i, kindOf in KindOfs do
	local name = nil
	
	local success, result = pcall(function()
		return (kindOf :: any).new(name)
	end)
	
	if success or type(result) ~= `string` or not (result :: string):match(`Can't create an unnamed.*! Given name: {name}`) then
		warn(`Test #5 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	
	print(`Expect false, {`Can't create an unnamed.*! Given name: {name}`}\n\t`, success, result)
	
	UnnamedErrorAmount += 1
end

TestPass(`[5] Error creating unnamed`, UnnamedErrorAmount == NKindOfs)

warn(`Now it's time to connect with the client`)
local TestCommunication = RemoteEvent.new(`TestCommunication`):SetCooldown(0)

TestCommunication:Connect(function(player: Player, test_txt: string, is_pass: boolean)
	-- UID just in case this is tested with multiple players
	TestPass(`[UID_{player.UserId}] [Client-Side] {test_txt}`, is_pass)
end)

RemoteEvent.new(`Warn`):SetCooldown(0):Connect(function(player: Player, isHeader: boolean?, ...)
	warn(`{isHeader and `{Padding} {PREFIX}` or ``}[UID_{player.UserId}] [Client-Side]`, ...)
end)
RemoteEvent.new(`Print`):SetCooldown(0):Connect(function(player: Player, ...)
	print(`[UID_{player.UserId}]`, ...)
end)

-- for all the players who join later
local TestCommunicationRetrieveState = RemoteFunction.new(`TestCommunication`):SetCooldown(0)
TestCommunicationRetrieveState.OnInvoke = function(player: Player)
	return true, { `The Server Is All Set!` }
end

TestCommunication:FireAllClients() -- let all clients know server is all set now

local FirstTester = RemoteEvent.new(`ClientCompleted`):SetCooldown(0):Wait()









warn(`{Padding} {PREFIX}Test #6: Test RemoteEventBase Class (via RemoteEvent Class; UnreliableRemoteEvent won't be tested as it's only different by descriptor)`)

local MainRemote = RemoteEvent.new(`Main`):SetCooldown(0)

type DataReceived = {
	[string]: {
		Timestamp: number,
		Payload: {any},
	}
}
local DataReceived: DataReceived = {}
local NDataReceived = 0
local TimesReceived = {}
local function CountReceived(k: string)
	local v = TimesReceived[k]
	TimesReceived[k] = (type(v) == `number` and v or 0) + 1
end

local function LogPayload(name: string, timestamp: number, payload: {[any]: any})
	CountReceived(name)
	
	if DataReceived[name] ~= nil then
		--print(`Payload "{name}" already registered, it won't be overwritten.`)
		return
	end
	
	DataReceived[name] = {
		Timestamp = timestamp,
		Payload = payload,
	}
	
	NDataReceived += 1
end


-- Payload to be sent to the client
local TestBuffer = buffer.create(4)
buffer.writeu8(TestBuffer, 2, 255)

local TestPayload = {
	`Hello World!`,
	false,
	369,
	{
		ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)),
		NumberRange.new(0, 100),
		NumberSequence.new(3, 1),
		(MainRemote :: any)[`_RI`],
	},
	Color3.fromRGB(0, 255, 0),
	`Next element shall be nil`,
	nil,
	`Previous element shall be nil`,
	TestBuffer,
}


--- Connections
local RecommendedConnection = MainRemote:Connect(function(player: Player, ...)
	--[[
	CountReceived(`Connect`)
	
	-- Might happen multiple times, unlike Once and Wait
	if DataReceived[`Connect`] ~= nil then
		return
	end
	
	local timestamp = time()
	DataReceived[`Connect`] = {
		Timestamp = timestamp,
		Payload = {player, ...},
	}
	
	NDataReceived += 1
	--]]
	local timestamp = time()
	LogPayload(`Connect`, timestamp, {player, ...})
end)

MainRemote:Once(function(player: Player, ...)
	--[[
	CountReceived(`Once`)
	
	local timestamp = time()
	DataReceived[`Once`] = {
		Timestamp = timestamp,
		Payload = {player, ...},
	}
	
	NDataReceived += 1
	--]]
	
	local timestamp = time()
	LogPayload(`Once`, timestamp, {player, ...})
end)

task.spawn(function()
	local payload = table.pack(MainRemote:Wait())
	
	-- table.pack does remove all nil entries that are otherwise visible
	-- when printing DataReceived for Once and Connect, but when comparing,
	-- a removed entry is same as nil, so there's no need to resolve this here.
	-- table.unpack will handle this too
	--payload[`n`] = nil :: any -- remove trailing generated by table.pack
	
	local timestamp = time()
	--[[
	DataReceived[`Wait`] = {
		Timestamp = timestamp,
		Payload = payload,
	}
	
	NDataReceived += 1
	--]]
	
	LogPayload(`Wait`, timestamp, {table.unpack(payload)})
end)



local s = time()
while NDataReceived < 3 and time() - s < 5 do
	task.wait()
end

if NDataReceived < 3 then
	warn(`Timeout without all three properly`)
end
-- (["Wait"]["Payload"] will have an ["n"] field at the end) -- Patched
print(`Expect each entry value ["Payload"] field identic:\n`, DataReceived)

local function Compare(t1: any, t2: any): boolean
	if t1 == t2 then -- same memory address (reference) or value
		return true
	end
	
	local type1 = type(t1)
	local type2 = type(t2)
	
	if type1 ~= type2 then
		return false
	end
	
	if type1 == "buffer" then
		return buffer.len(t1) == buffer.len(t2) and buffer.tostring(t1) == buffer.tostring(t2)
	end
	
	if type(t1) ~= `table` then
		return false --t1 == t2 -- resolved above if same
	end
	
	-- Quick way to find if there's any key mismatch
	local count1 = 0
	for _ in t1 do
		count1 += 1
	end
	local count2 = 0
	for _ in t2 do
		count2 += 1
	end
	if count1 ~= count2 then
		return false
	end
	
	for k, v in t1 do
		local v2 = t2[k]
		
		if not Compare(v, v2) then
			return false
		end
	end
	
	return true
end

local function IsPayloadIdentic(dataReceived: DataReceived): boolean
	
	local first
	for k, v in dataReceived do
		if not first then
			first = v.Payload
			continue
		end
		
		local current = v.Payload
		
		if not Compare(first, current) then
			return false
		end
	end
	
	return true
end


--warn(`Manual Review Expected; Did the test pass? Press Y/N\n(If pressing any of doesn't seem working, Studio might've overriden your keyboard language choice)`)
--local _, Input: boolean? = RegisterInput:Wait()
-- Nah just use IsPayloadIdentic

TestPass(
	`[6.0] Client->Server (Connect, Once, Wait) over RemoteEvents`,
	--not not Input
	NDataReceived == 3 and IsPayloadIdentic(DataReceived)
)

-- Test OnServerEvent reference working same way
print(MainRemote, MainRemote.OnServerEvent)
local CompatibleConnection = MainRemote.OnServerEvent:Connect(function(player: Player, ...)
	local timestamp = time()
	LogPayload(`OnServerEvent:Connect`, timestamp, {player, ...})
end)

MainRemote.OnServerEvent:Once(function(player: Player, ...)
	local timestamp = time()
	LogPayload(`OnServerEvent:Once`, timestamp, {player, ...})
end)

task.spawn(function()
	local payload = table.pack(MainRemote.OnServerEvent:Wait())
	local timestamp = time()
	LogPayload(`OnServerEvent:Wait`, timestamp, {table.unpack(payload)})
end)

-- Yes, even if we loop forever

local ChainConnection = MainRemote.OnServerEvent.OnServerEvent.OnServerEvent:Connect(function(player: Player, ...)
	local timestamp = time()
	LogPayload(`(Chain)OnServerEvent:Connect`, timestamp, {player, ...})
end)

MainRemote.OnServerEvent.OnServerEvent.OnServerEvent:Once(function(player: Player, ...)

	local timestamp = time()
	LogPayload(`(Chain)OnServerEvent:Once`, timestamp, {player, ...})
end)

task.spawn(function()
	local payload = table.pack(MainRemote.OnServerEvent.OnServerEvent.OnServerEvent:Wait())
	local timestamp = time()
	LogPayload(`(Chain)OnServerEvent:Wait`, timestamp, {table.unpack(payload)})
end)



-- Test Server->Client, then Client->Server and Server->Client
-- again to prove Once and Wait truly fire only ONE TIME

MainRemote:FireClient(FirstTester, table.unpack(TestPayload))
MainRemote:FireClient(FirstTester, table.unpack(TestPayload))
-- after validation, client will fire twice

s = time()
while NDataReceived < 9 and time() - s < 5 do
	task.wait()
end
if NDataReceived < 9 then
	warn(`Timeout without all properly catching a second client signal`)
end

TestPass(
	`[6.3] Client->Server (Connect, Once, Wait with "OnServerEvent") over RemoteEvents`,
	NDataReceived == 9
)


task.wait(0.3)
local IsValid = true
for k: string, v: number in TimesReceived do
	if k:match(`Connect`) then
		if v < 2 then -- "Connect" field will actualy have 3
			IsValid = false
			break
		end
		continue
	end

	if v ~= 1 then
		IsValid = false
		break
	end
end

print(`Expect counts >=2 for ["*Connect"], 1 for ["*Once"] and ["*Wait"]`, TimesReceived)

TestPass(
	`[6.4] Client->Server ":Once() and :Wait() truly fire only ONE TIME; :Connect() MULTIPLE"`,
	NDataReceived == 9 and IsValid
)


-- Time to test the SetCooldown
RecommendedConnection:Disconnect() -- TimesReceived[`Connect`] shall now be frozen at 3
local Aside = RemoteEvent.new(`Aside`):SetCooldown(0)

local LastReceivedTimestamp = 0
local CurrentCooldownSetting = 0
local CooldownViolations = 0

-- total received, without counting the ignored ones because of the Cooldown impelementation
local TotalReceived = 0
-- total sent, counting all the ignored ones
local TotalSent = 0
local TotalReceivedCheckpoint = 0
local Snapshots: {
	[number]: {
		TotalSent: number,
		TotalReceived: number,
		Timestamp: number,
	},
} = {}

local IsCooldownTestingComlete = false



local function IncrementTotalReceived(player: Player)
	if player ~= FirstTester then
		return
	end

	TotalReceived += 1
	
	local now = os.clock() -- this is the time operation used internally by CRR-Server
	local delta = now - LastReceivedTimestamp
	if delta < CurrentCooldownSetting then
		CooldownViolations += 1
		warn(`[Cooldown Violation!] Expected gap >= {CurrentCooldownSetting}s, got {(`%.6f`):format(delta)}s`)
	end
	-- CRR-Server does not record last use times when cooldown is 0
	-- so if cooldown was changed from 0 to something bigger
	-- it'd only start to keep track of the cooldown after the first use
	-- that's why we shall not update LastReceivedTimestamp for when the
	-- CurrentCooldownSetting <= 0
	if CurrentCooldownSetting > 0 then
		LastReceivedTimestamp = now
	end
	
	
	
	
	if TotalReceived == 301 then
		Aside:Disconnect() -- disconnect all events on Aside
		MainRemote:Disconnect() -- same here
		Aside:FireAllClients() -- tell client to stop firing

		table.insert(Snapshots, {
			TotalSent = TotalSent,
			TotalReceived = TotalReceived,
			Timestamp = time(),
		})

		IsCooldownTestingComlete = true
		return
	end
	if TotalReceived == 300 then
		local newCooldownSetting = 3
		MainRemote:SetCooldown(newCooldownSetting)
		CurrentCooldownSetting = newCooldownSetting
		print(`Cooldown updated to {CurrentCooldownSetting} (seconds); ["_Cooldown"] field = {(MainRemote :: any)[`_Cooldown`]}`)

		table.insert(Snapshots, {
			TotalSent = TotalSent,
			TotalReceived = TotalReceived,
			Timestamp = time(),
		})

		return
	end
	if TotalReceived == 200 then
		local newCooldownSetting = 0.03
		MainRemote:SetCooldown(newCooldownSetting)
		CurrentCooldownSetting = newCooldownSetting
		print(`Cooldown updated to {CurrentCooldownSetting} (seconds); ["_Cooldown"] field = {(MainRemote :: any)[`_Cooldown`]}`)

		table.insert(Snapshots, {
			TotalSent = TotalSent,
			TotalReceived = TotalReceived,
			Timestamp = time(),
		})

		return
	end
end
MainRemote:Connect(IncrementTotalReceived)

Aside:Connect(function(player: Player)
	if player ~= FirstTester then
		return
	end
	if IsCooldownTestingComlete then
		return
	end
	
	TotalSent += 1
	if TotalSent == 100 then
		-- Reconnect the event after a total Disconnect
		MainRemote:Connect(IncrementTotalReceived)
		-- now we test cooldowns
		MainRemote:SetCooldown(nil) -- shall be 0
		CurrentCooldownSetting = 0
		print(`Cooldown updated to {CurrentCooldownSetting} (seconds); ["_Cooldown"] field = {(MainRemote :: any)[`_Cooldown`]}`)
				
		local prevSnapshot = Snapshots[#Snapshots]
		local currentSnapshot = {
			TotalSent = TotalSent,
			TotalReceived = TotalReceived,
			Timestamp = time(),
		}
		table.insert(Snapshots, currentSnapshot)

		TestPass(
			`[6.6] RemoteEventBaseClass:Disconnect() works properly (disconnects all connections)`,
			prevSnapshot.TotalReceived == currentSnapshot.TotalReceived and
			prevSnapshot.TotalSent ~= currentSnapshot.TotalSent and
			TimesReceived[`OnServerEvent:Connect`] == 3 and
			TimesReceived[`(Chain)OnServerEvent:Connect`] == 3
		)
		return
	end
	if TotalSent == 1 then
		-- Freeze these TimesReceived at 3 too
		--CompatibleConnection:Disconnect()
		--ChainConnection:Disconnect()
		-- just diconnect all of them!
		MainRemote:Disconnect()
		-- the { MainRemote:Connect(IncrementTotalReceived) } connection is disconnected too!
		table.insert(Snapshots, {
			TotalSent = TotalSent,
			TotalReceived = TotalReceived,
			Timestamp = time(),
		})
		
		TestPass(
			`[6.5] Connection:Disconnect() works properly`,
			TimesReceived[`Connect`] == 3
		)
	end
end)

repeat
	task.wait(0.3)
until IsCooldownTestingComlete

print(`Snapshots: `, Snapshots)
print(`Expect 0 Cooldown violations, got: {CooldownViolations}`)

TestPass(
	`[6.7] :SetCooldown() is safe (defaults to 0) and the cooldown implementation works as intended`,
	CooldownViolations == 0
)









warn(`{Padding} {PREFIX}Test #7: Test RemoteFunction Class`)
MainRemote:Disconnect() -- Disconnect all previous Events (even though they were already disconnected after testing cooldowns)

-- this just got created, client yields until it is created
local MainFunction = RemoteFunction.new(`Main`):SetCooldown(1)




local InvocationsByClientProcessed = 0
local function MainFunctionCallback(player: Player, payload: {})
	InvocationsByClientProcessed += 1
	return true, payload
end

local function FnForTest()
	return true, {`A test function`}
end


local IsSettingInvokeCallbackAlwaysSuccessfull = true
local function SetInvokeCallbackAndTroubleshoot(
	callback: ((player: Player, ...any) -> (boolean, {}))?,
	settingViaLegacyCompatibleAPI: boolean?
): boolean
	-- if not boolean, don't set (intended)
	if settingViaLegacyCompatibleAPI == true then
		MainFunction.OnServerInvoke = callback
	elseif settingViaLegacyCompatibleAPI == false then
		MainFunction.OnInvoke = callback
	end
	
	local recommendedAPI = MainFunction.OnInvoke
	local legacyCompatibleAPI = MainFunction.OnServerInvoke
	local isValueEqual = recommendedAPI == legacyCompatibleAPI
	local isValueSet = isValueEqual and recommendedAPI == callback
	
	print(
		(`Expect OnInvoke and OnServerInvoke to be "%s" (x2 / both shall be the same), got:`):format(tostring(callback)),
		recommendedAPI,
		legacyCompatibleAPI,
		`\t is value equal on both fields: {isValueEqual}; is value actually set for both fields: {isValueSet}`
	)
	
	if not isValueSet then
		warn(`Test #7.0 fail; {
			type(settingViaLegacyCompatibleAPI) == `boolean` and
			`Setting a callback {callback} via {settingViaLegacyCompatibleAPI and `OnServerInvoke` or `OnInvoke`} field leads to a mismatch of both` or
			`The current callback was set in some way that it mismatches`
		}`)
		IsSettingInvokeCallbackAlwaysSuccessfull = false
	end
	
	return isValueEqual
end

SetInvokeCallbackAndTroubleshoot() -- check the initial nil (unset yet)
SetInvokeCallbackAndTroubleshoot(FnForTest, true)
SetInvokeCallbackAndTroubleshoot(nil, true)
SetInvokeCallbackAndTroubleshoot(FnForTest, false)
SetInvokeCallbackAndTroubleshoot(nil, false)
SetInvokeCallbackAndTroubleshoot(MainFunctionCallback, false)

TestPass(`[7.0] Writing/Reading Invoke Callback works as intended`, IsSettingInvokeCallbackAlwaysSuccessfull)


local InvocationsByClient = 0
Aside:Connect(function(player: Player)
	if player ~= FirstTester then
		return
	end
	InvocationsByClient += 1
end)

s = time()
while InvocationsByClient < 2 and time() - s < 5 do
	task.wait()
end

MainFunction.OnInvoke = nil -- now client can test RFER (doesn't exist)
-- RFER - Remote Function Exit Reasons

task.wait(2)

local IsInvokeClientFlawless = true

local SuccessOne, ResultOne = MainFunction:InvokeClient(FirstTester, TestPayload)
local IsVerifiedCopy = TestPayload ~= ResultOne and Compare(TestPayload, ResultOne)
print(
	`[First Invoke] Expect success, isVerifiedCopy to be true, true:`,
	SuccessOne,
	IsVerifiedCopy,
	`\nExpect original, copy of original, different memory reference addresses:`,
	TestPayload,
	ResultOne,
	tostring(TestPayload),
	tostring(ResultOne)
)
if not (SuccessOne and IsVerifiedCopy) then
	warn(`Test #7.3 fail at First Invoke (see message above)`)
	IsInvokeClientFlawless = false
end

local SuccessTwo, ResultTwo = MainFunction:InvokeClient(FirstTester, TestPayload)
local ExpectedResult = `OnClientInvoke Callback for name="{MainFunction.Remote.Name}" wasn't registered, but the object exists!`
print(
	`[Second Invoke] Expect success, result to be false, {"{"} {ExpectedResult} {"}"}:`,
	SuccessTwo,
	ResultTwo
)
if SuccessTwo or (not (type(ResultTwo) == `table` and (ResultTwo :: any)[1] == ExpectedResult)) then
	warn(`Test #7.3 fail at Second Invoke (see message above)`)
	IsInvokeClientFlawless = false
end

TestPass(
	`[7.3] :InvokeClient works as intended w/ RFER Messages`,
	IsInvokeClientFlawless
)









warn(`{Padding} {PREFIX}Test #8: Require Module from a non-dedicated side`)

local RequireSuccess, RequireResult = pcall(require, RS.CoffeeRemotesClient)
print(RequireSuccess, RequireResult)

TestPass(
	`[8] CoffeeRemotesClient Errors on require by Server-Sided script`,
	RequireResult == `Requested module experienced an error while loading` and not RequireSuccess
)



local PostTest8 = RemoteEvent.new(`Post8`)
PostTest8:Wait()



warn(`{Padding} {PREFIX}Test #9: Public API fields ["Remote"] and ["Destroying"] are Read-Only (Error on Write)`)

local TestedFieldNames = {`Remote`, `Destroying`}
local NTestedFieldNames = #TestedFieldNames
local AllFieldsReadOnly = 0

for i, kindOf in KindOfs do
	local remote = kindOf.new(`Test#9`)
	local unsucessfullWrites = 0
	
	for _, k in TestedFieldNames do
		print(`Expect a warning "Nothing should be stored inside a..."`)
		local originalValue = (remote :: any)[k];
		(remote :: any)[k] = nil
		
		if (remote :: any)[k] ~= originalValue then
			warn(`FATAL ERROR: Successfully wrote nil to ["{k}"] at {LogKindOf(i)}`)
			continue
		end
		unsucessfullWrites += 1
	end
	
	if unsucessfullWrites ~= NTestedFieldNames then
		continue
	end
	
	AllFieldsReadOnly += 1
end

TestPass(`[9] Public API fields ["Remote"] and ["Destroying"] are Read-Only (Error on Write)`, AllFieldsReadOnly == NKindOfs)



local PostTest9 = RemoteEvent.new(`Post9`)
PostTest9:Wait()



warn(`{Padding} {PREFIX}Test #10: Miscellaneous Tests`)
local CommunicateToNoPlayerSuccessCount = 0
local NotAPlayerDatatypes = {
	Color3.fromRGB(255, 255, 255)
}
local Test10Event = RemoteEvent.new(`Test#10`)
local Test10Function = RemoteFunction.new(`Test#10`)

for i = 1, #NotAPlayerDatatypes + 1 do
	local v = NotAPlayerDatatypes[i]
	
	local Event10Success, Event10Result = pcall(
		Test10Event.FireClient,
		Test10Event, -- self as the method expects
		v :: any, -- not Player to trigger an error (:: any to hide linter)
		-- Data to be sent:
		`Hello World`
	)

	local Function10Success, Function10Result = pcall(
		Test10Function.InvokeClient,
		Test10Function, -- self as the method expects
		v :: any, -- not Player to trigger an error (:: any to hide linter)
		-- Data to be sent:
		`Hello World`
	)
	
	print(`Expect false and an error message:\n\t{Event10Success}, {Event10Result}\n\t{Function10Success}, {Function10Result}`)
	
	if Event10Success or Function10Success then
		warn(`Test #10.0 fail at iv pair {i} = {v}, successfully called {Event10Success and `FireClient` or `InvokeClient`} with {v} as the Player argument`)
		CommunicateToNoPlayerSuccessCount += 1
	end
end

TestPass(`[10.0] Not passing a Player as first argument to FireClient and InvokeClient methods errors`, CommunicateToNoPlayerSuccessCount == 0)



local InvalidOnInvokeValue = true -- everything but nil or function
print(`[10.1] Expect warning "[OnInvoke | OnServerInvoke] must be a function (callback) or nil (to "disconnect"), got {InvalidOnInvokeValue}:"`)
local IsSettingInvalidOnInvokeIgnored = true

Test10Function.OnInvoke = InvalidOnInvokeValue :: any
if Test10Function.OnInvoke :: any == InvalidOnInvokeValue then
	warn(`Test #10.1 fail; Setting invalid value via OnInvoke succeeded`)
	IsSettingInvalidOnInvokeIgnored = false
end
Test10Function.OnServerInvoke = InvalidOnInvokeValue :: any
if Test10Function.OnServerInvoke :: any == InvalidOnInvokeValue then
	warn(`Test #10.1 fail; Setting invalid value via OnServerInvoke succeeded`)
	IsSettingInvalidOnInvokeIgnored = false
end

TestPass(
	`[10.1] Setting invalid values to OnInvoke | OnServerInvoke fields outputs a warning and ignores the write`,
	IsSettingInvalidOnInvokeIgnored
)

Test10Event:FireAllClients()
-- client does 10.2
Test10Event:Wait()





--- ENTERING THE DANGER ZONE ---
warn(`{Padding} {PREFIX}Test #11: Ensuring mkdir is safe (re-requiring the module)`)
local NewlyCreatedFolders = 0
local ReservedNames = {
	CoffeeRemotesRefined = true, -- MainFolderName
	Events = true, -- hardcoded into the module
	Functions = true, -- hardcoded into the module
	UnreliableEvents = true, -- hardcoded into the module
}
local RSDAConn: RBXScriptConnection
RSDAConn = RS.DescendantAdded:Connect(function(descendant: Instance)
	if descendant.ClassName ~= `Folder` then
		return
	end
	if not ReservedNames[descendant.Name] then
		return
	end
	
	warn(`Test #11 fail; Folder with a reserved name "{descendant.Name}" was created in {descendant.Parent and descendant.Parent:GetFullName() or `nil`}`)
	NewlyCreatedFolders += 1
end)

local CRRSCloneModule = CRRServer:Clone()
CRRSCloneModule.Name = `Test11CRRSClone`
CRRSCloneModule.Parent = script
local CRRSClone = require(script:WaitForChild(`Test11CRRSClone`)) :: typeof(CoffeeRemotes)

TestPass(
	`[11] mkdir is safe when re-requiring (no new Folders created)`,
	NewlyCreatedFolders == 0 and
	CRRSClone.RemoteEvent.new(`MadeUsingCRRSCloneAtTest#11`).Remote.Parent == RemoteEventsFolder and
	CRRSClone.RemoteFunction.new(`MadeUsingCRRSCloneAtTest#11`).Remote.Parent == RemoteFunctionsFolder and
	CRRSClone.UnreliableRemoteEvent.new(`MadeUsingCRRSCloneAtTest#11`).Remote.Parent == UnreliableRemoteEventsFolder
)
RSDAConn:Disconnect()



warn(`{Padding} {PREFIX}Test #12: Ensuring mkdir is safe (at startup with spoofed Folders)`)
print(`{PREFIX} [INFO] Cleaning up the previous Folders, no further tests shall be run except #12.`)

---[[
-- Taken from the Server Side of the Module
-- The following Three must match on Both Server and Client Side versions of the Module
local ModuleVersion: string = `V1_0_0`
local MainFolderName: string = `CoffeeRemotesRefined`
local ModuleFoldersTag: string = `CoffeeRemotesRefined_{ModuleVersion}`
--]]

local Matches = 0
for _, folder in RS:QueryDescendants(`>Folder#{MainFolderName}.{ModuleFoldersTag}[$CRRV = "{ModuleVersion}"]`) do
	folder:Destroy()
	Matches += 1
end
print(`{PREFIX} [INFO] Cleaned up, previously {Matches} used Main Folders (Only 1 is expected!)`)

local function rawmkdir(name: string, where: Instance): Folder
	local folder = Instance.new(`Folder`)

	folder.Name = name
	folder:SetAttribute(`CRRV`, ModuleVersion)
	folder:AddTag(ModuleFoldersTag)

	folder.Parent = where -- Parent after naming for compliance with Client's WaitForChild

	return folder
end

-- Spoof Pack #1
local Test12SpoofedMainFolder = rawmkdir(MainFolderName, RS)
-- spoofing a single one and it gets used! (as if already created)
local Test12SpoofedRemoteEventsFolder = rawmkdir(`Events`, Test12SpoofedMainFolder)
-- simulating a hole (it shall be resolved)
--local Test12SpoofedRemoteFunctionsFolder = rawmkdir(`Functions`, Test12SpoofedMainFolder)
-- spoofing a duplicate descendant
local Test12SpoofedUnreliableRemoteEventsFolder = rawmkdir(`UnreliableEvents`, Test12SpoofedMainFolder)
local Test12SpoofedUnreliableRemoteEventsFolderDup = rawmkdir(`UnreliableEvents`, Test12SpoofedMainFolder)

-- Spoof Pack #2
local Test12SpoofedMainFolder1 = rawmkdir(MainFolderName, RS)
-- simulating a hole (it shall be resolved)
--local Test12SpoofedRemoteEventsFolder1 = rawmkdir(`Events`, Test12SpoofedMainFolder1)
-- spoofing a duplicate descendant
local Test12SpoofedRemoteFunctionsFolder1 = rawmkdir(`Functions`, Test12SpoofedMainFolder1)
local Test12SpoofedRemoteFunctionsFolder1Dup = rawmkdir(`Functions`, Test12SpoofedMainFolder1)
-- spoofing a single one and it gets used! (as if already created)
local Test12SpoofedUnreliableRemoteEventsFolder1 = rawmkdir(`UnreliableEvents`, Test12SpoofedMainFolder1)

-- either one of the SpoofPacks will survive,
-- the other will be reparented to nil and
-- then destroyed in 180 seconds

print(`Expect two warning with "...Multiple matches found for selector:..."`)
local CRRSCloneModule12 = CRRServer:Clone()
CRRSCloneModule12.Name = `Test12CRRSClone`
CRRSCloneModule12.Parent = script
local CRRSClone12 = require(script:WaitForChild(`Test12CRRSClone`)) :: typeof(CoffeeRemotes)

local isSpoofPack1PutToUse = Test12SpoofedMainFolder.Parent ~= nil
local isSpoofPack2PutToUse = Test12SpoofedMainFolder1.Parent ~= nil
local isEitherONEPutToUse = isSpoofPack1PutToUse ~= isSpoofPack2PutToUse -- boolean xor (~=)
local isHoleResolved = false
local isEitherONEDuplicateDescendantPutToUse = false
local isExistingSpoofedPutToUse = false
local Test12DebugData = {
	[`Check if either ONE of the spoofed Main Folders was Put to use`] = {
		Note = `Only one shall be put to use and still parented, the other one shall be parented to nil and part of the warning`,
		First = {
			IsUsed = isSpoofPack1PutToUse,
			Instance = Test12SpoofedMainFolder,
		},
		Second = {
			IsUsed = isSpoofPack2PutToUse,
			Instance = Test12SpoofedMainFolder1,
		},
	}
}

if isSpoofPack1PutToUse then
	print(`{PREFIX} [INFO] Spoof pack #1 Put to Use`)
	-- check if the hole was resolved
	local folderSupposedToAppearAtHole = Test12SpoofedMainFolder:FindFirstChild(`Functions`)
	isHoleResolved = typeof(folderSupposedToAppearAtHole) == `Instance` and folderSupposedToAppearAtHole.ClassName == `Folder`
	
	Test12DebugData[`Check if the hole was resolved`] = {
		[`Folder Instance (expect a Folder named "Functions"):`] = folderSupposedToAppearAtHole,
	}
	
	-- check if either ONE of the spoofed descendants was resolved
	local isDup1PutToUse = Test12SpoofedUnreliableRemoteEventsFolder.Parent ~= nil
	local isDup2PutToUse = Test12SpoofedUnreliableRemoteEventsFolderDup.Parent ~= nil
	isEitherONEDuplicateDescendantPutToUse = isDup1PutToUse ~= isDup2PutToUse
	
	Test12DebugData[`Check if either ONE of the spoofed descendants was Put to use`] = {
		Note = `Only one shall be put to use and still parented, the other one shall be parented to nil and part of the warning`,
		First = {
			IsUsed = isDup1PutToUse,
			Instance = Test12SpoofedUnreliableRemoteEventsFolder,
		},
		Second = {
			IsUsed = isDup2PutToUse,
			Instance = Test12SpoofedUnreliableRemoteEventsFolderDup,
		},
	}
	
	-- check if the correctly spoofed single one was put to use
	--local isStillParentedRight = Test12SpoofedRemoteEventsFolder.Parent == Test12SpoofedMainFolder
	--local gotAChildAddedOnAppropriateKindOfInstanceCreation = false
	--local nameForTheTestRemoteInstance = `Test12SpoofPack#1`
	
	--Test12SpoofedRemoteEventsFolder.ChildAdded:Once(function(c)
	--	if c.Name == nameForTheTestRemoteInstance and c.ClassName == `RemoteEvent` then
	--		gotAChildAddedOnAppropriateKindOfInstanceCreation = true
	--	end
	--end)
	--CRRSClone12.RemoteEvent.new(nameForTheTestRemoteInstance)
	
	--isExistingSpoofedPutToUse = isStillParentedRight and gotAChildAddedOnAppropriateKindOfInstanceCreation
	
	-- much more elegant way to check
	isExistingSpoofedPutToUse = CRRSClone12.RemoteEvent.new(`Test12SpoofPack#1`).Remote.Parent
		== Test12SpoofedRemoteEventsFolder
	
	Test12DebugData[`Check if the correctly spoofed single one folder was put to use`] = isExistingSpoofedPutToUse
	
	
elseif isSpoofPack2PutToUse then
	print(`{PREFIX} [INFO] Spoof pack #2 Put to Use`)
	-- check if the hole was resolved
	local folderSupposedToAppearAtHole = Test12SpoofedMainFolder1:FindFirstChild(`Events`)
	isHoleResolved = typeof(folderSupposedToAppearAtHole) == `Instance` and folderSupposedToAppearAtHole.ClassName == `Folder`
	
	Test12DebugData[`Check if the hole was resolved`] = {
		[`Folder Instance (expect a Folder named "Events"):`] = folderSupposedToAppearAtHole
	}
	
	-- check if either ONE of the spoofed descendants was resolved
	local isDup1PutToUse = Test12SpoofedRemoteFunctionsFolder1.Parent ~= nil
	local isDup2PutToUse = Test12SpoofedRemoteFunctionsFolder1Dup.Parent ~= nil
	isEitherONEDuplicateDescendantPutToUse = isDup1PutToUse ~= isDup2PutToUse
	
	Test12DebugData[`Check if either ONE of the spoofed descendants was Put to use`] = {
		Note = `Only one shall be put to use and still parented, the other one shall be parented to nil and part of the warning`,
		First = {
			IsUsed = isDup1PutToUse,
			Instance = Test12SpoofedRemoteFunctionsFolder1,
		},
		Second = {
			IsUsed = isDup2PutToUse,
			Instance = Test12SpoofedRemoteFunctionsFolder1Dup,
		},
	}
	
	-- check if the correctly spoofed single one was put to use
	--local isStillParentedRight = Test12SpoofedUnreliableRemoteEventsFolder1.Parent == Test12SpoofedMainFolder1
	--local gotAChildAddedOnAppropriateKindOfInstanceCreation = false
	--local nameForTheTestRemoteInstance = `Test12SpoofPack#2`

	--Test12SpoofedUnreliableRemoteEventsFolder1.ChildAdded:Once(function(c)
	--	if c.Name == nameForTheTestRemoteInstance and c.ClassName == `RemoteEvent` then
	--		gotAChildAddedOnAppropriateKindOfInstanceCreation = true
	--	end
	--end)
	--CRRSClone12.UnreliableRemoteEvent.new(nameForTheTestRemoteInstance)
	
	--isExistingSpoofedPutToUse = isStillParentedRight and gotAChildAddedOnAppropriateKindOfInstanceCreation
	
	-- much more elegant way to check
	isExistingSpoofedPutToUse = CRRSClone12.UnreliableRemoteEvent.new(`Test12SpoofPack#2`).Remote.Parent
		== Test12SpoofedUnreliableRemoteEventsFolder1
	
	Test12DebugData[`Check if the correctly spoofed single one folder was put to use`] = isExistingSpoofedPutToUse
end

local isTest12Successfull = isEitherONEPutToUse and isHoleResolved and isEitherONEDuplicateDescendantPutToUse and isExistingSpoofedPutToUse

if isTest12Successfull then
	print(`Test #12 did not fail, but here's the debug data for reviewing:`, Test12DebugData)
else
	warn(`Test #12 failed in one of the aspects, please review:`, Test12DebugData)
end

TestPass(
	`[12] mkdir is safe (at startup with spoofed Folders)`,
	isTest12Successfull
)



--[[--
What's left untested:

- Client doing :InvokeServer and receiving (false, RFER_PlayerLeft);
	Attempted testing it in many ways, but couldn't get it to work in a single-player test.
- mkdir and mkremote tested for exact spoofing at runtime;
	That would likely fail, unless we over-engineer and introduce scroing for folders and
	checks for usage in existing remote objects. Here's a prototype of what an over-engineered
	mkdir would look like, and this doesn't even cover for remote instance spoofing yet:
--]]--
--[[--
	```luau
	--!strict
	--!optimize 2
	-- no native here, this script does NO heavy math!

	local Players = game:GetService(`Players`)
	local RunS = game:GetService(`RunService`)
	local RS = game:GetService(`ReplicatedStorage`)
	local Debris = game:GetService(`Debris`)

	-- The following Three must match on Both Server and Client Side versions of the Module
	local ModuleVersion: string = `V1_0_0` -- must be compatible with query descendants in a way that...
	local MainFolderName: string = `CoffeeRemotesRefined`
	local ModuleFoldersTag: string = `CoffeeRemotesRefined_{ModuleVersion}` -- ...this is evaluated as a SINGLE Tag
	local KindOfFolders: {[string]: KindOf} = {
		-- FolderName = KindOf that it's supposed to serve as a container for
		[`Events`] = `RemoteEvent`,
		[`Functions`] = `RemoteFunction`,
		[`UnreliableEvents`] = `UnreliableRemoteEvent`,
	}

	local IsStudio: boolean = RunS:IsStudio()
	local Prefix: string = `[CoffeeRemotes-Server {ModuleVersion}] ` -- This is only for Output

	-- Remote Function Exit Reasons (RFER)
	-- Be an oracle only if IsStudio testing, not in-game!
	-- Although only existing RemoteFunctions are there,
	-- it isn't a black box like in Legacy CoffeeRemotes.
	-- But you could add some honeypots!
	local RFER_TooQuick = {`Sending Requests Too Quickly!`}
	local RFER_NotFound = IsStudio and
		function(name: string, object: RemoteFunctionType)
			return {`OnServerInvoke/OnInvoke Callback for name="{name}" doesn't exist; Object and it's RemoteFunction Instance:`, object, rawget(object :: any, `_RI`)}
		end 
		or
		function()
			return RFER_TooQuick
		end
	local RFER_PlayerLeft = IsStudio and {`Player Has Left`} or RFER_TooQuick

	--- Default Cooldown (in seconds) between calls per EventName ---
	local RemoteEventCooldown: number = 0.03
	local RemoteFunctionCooldown: number = 0.03
	local UnreliableRemoteEventCooldown: number = 0.01

	if not RunS:IsServer() then
		error(`{Prefix} can only be required by Server-Side scripts!`)
	end



	--- Dependencies ---

	-- Signal's Source Repository: https://github.com/Data-Oriented-House/LemonSignal --
	local LemonSignal = require(RS.Packages.LemonSignal) -- or wherever it's located and whatever it's named

	--- /E Dependencies ---



	export type RemoteInstance = BaseRemoteEventSubtypes | RemoteFunction --RemoteEvent | RemoteFunction | UnreliableRemoteEvent
	export type CoffeeRemotesObject = RemoteEventType | RemoteFunctionType | UnreliableRemoteEventType
	type KindOf = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent"
	type KindOfs = "RemoteEvents" | "RemoteFunctions" | "UnreliableRemoteEvents"
	type OnInvokeCallback = (player: Player, ...any) -> (boolean, {})

	type UserId = number
	type RemoteInstanceName = string
	type CooldownRoot = {
		[UserId]: {
			[RemoteInstanceName]: number?,
		},
	}
	export type PlayerCooldowns = {
		[KindOfs]: CooldownRoot,
	}

	type ClassInstancesTable<T = RemoteInstance, U = CoffeeRemotesObject> = {
		[T]: U
	}
	type RemoteEventClassInstancesTable = ClassInstancesTable<RemoteEvent, RemoteEventType>
	type RemoteFunctionClassInstancesTable = ClassInstancesTable<RemoteFunction, RemoteFunctionType>
	type UnreliableRemoteEventClassInstancesTable = ClassInstancesTable<UnreliableRemoteEvent, UnreliableRemoteEventType>



	local PlayerCooldowns: PlayerCooldowns = {
		RemoteEvents = {},
		RemoteFunctions = {},
		UnreliableRemoteEvents = {},
	}

	-- Please make sure the name given is compatible with use in :QueryDescendants via the very unsafe #{name} part of the selector
	-- There is no safe escape implemented to make the name compatible automatically; And this shall remain such by design, there's no need to overengineer a function just to create four folders with hardcoded names (no user input).
	local function mkdir(name: string, where: Instance?): Folder
		if typeof(where) ~= `Instance` then
			where = RS
		end
		
		local folder_s = (where :: Instance):QueryDescendants(
			`>Folder#{name}.{ModuleFoldersTag}[$CRRV = "{ModuleVersion}"]`
		) :: {[number]: Folder}
		local matches = #folder_s
		-- both a tag of {ModuleFoldersTag}
		-- and an attribute CRRV = {ModuleVersion}
		-- (CRRV ~ CoffeeRemotesRefinedVersion)
		-- all this on top of the Instance being
		-- a Folder and named {name}
		
		-- if there's multiple matches, every
		-- single of them except one will be
		-- :Destroy()'ed with a warning
		
		-- most expected and the best case scenario
		if matches < 1 then
			local folder = Instance.new(`Folder`)
			
			folder.Name = name
			folder:SetAttribute(`CRRV`, ModuleVersion)
			folder:AddTag(ModuleFoldersTag)
			
			folder.Parent = where -- Parent after naming for compliance with Client's WaitForChild
			
			return folder
		end
		
		-- alright, you just cloned or re-required the module in some way
		if matches == 1 then
			return folder_s[1]
		end
		
		-- matches > 1
		-- trying to spoof folders and break everything huh?
		
		local bestFolder: Folder
		local bestFolderScore: number = -1
		
		local getFolderScore = where == RS and function(folder: Folder)
			return
				#folder:QueryDescendants(`>Events>RemoteEvent`) +
				#folder:QueryDescendants(`>Functions>RemoteFunction`) +
				#folder:QueryDescendants(`>UnreliableEvents>UnreliableRemoteEvent`)
		end or function(folder: Folder)
			return #folder:QueryDescendants(`>{KindOfFolders[folder.Name]}`) -- cut the "s" at the end of the folder name
		end
		
		local destroyedReferences = {}
		for i, folder in folder_s do
			local thisFolderScore = getFolderScore(folder)
			
			if thisFolderScore > bestFolderScore then
				if bestFolder then
					table.insert(destroyedReferences, bestFolder)
					bestFolder.Parent = nil
					Debris:AddItem(bestFolder, 180)
				end
				
				bestFolder = folder
				bestFolderScore = thisFolderScore
				continue
			end
			
			table.insert(destroyedReferences, folder)
			folder.Parent = nil
			Debris:AddItem(folder, 180)
		end
		warn(`{Prefix}Multiple matches found for selector: Folder named "{name}" with Tag {ModuleFoldersTag} and an Attribute "CRRV" equal to "{ModuleVersion}"; You have up to 180 seconds to troubleshoot them via clickable references:`, destroyedReferences)
		
		return bestFolder
	end

	local KindOfFoldersReverse: {[KindOf]: string} = {}
	for k, v in KindOfFolders do
		KindOfFoldersReverse[v] = k
	end

	local MainFolder = mkdir(MainFolderName)
	local RemoteEventsFolder = mkdir(KindOfFoldersReverse.RemoteEvent, MainFolder)
	local RemoteFunctionsFolder = mkdir(KindOfFoldersReverse.RemoteFunction, MainFolder)
	local UnreliableRemoteEventsFolder = mkdir(KindOfFoldersReverse.UnreliableRemoteEvent, MainFolder)
	
	```

--]]--
--[[--

--]]--








print(Padding)

-- Summary:

local function GetStringLengthInCharacters(str: string): number
	local n = 0
	for _ in utf8.graphemes(str) do
		n += 1
	end
	return n
end
local function NormalizeToLength(str: string, length: number): string
	local spacesToNormalize = length - GetStringLengthInCharacters(str)
	if spacesToNormalize < 1 then
		return str
	end

	return `{str}{table.concat(table.create(spacesToNormalize, " "), "")}`
end

print(PREFIX .. `Test complete! PASS ✅ = {PassCount}; FAIL ❌ = {FailCount}`)
local spacing = `\t|\t`
local temporaryLast = nil
local longestTextByCharacters = 0 -- can't be negative, so -math.huge is unnecessary
for _, stats in pairs(Timestamps) do
	local length = GetStringLengthInCharacters(table.unpack(stats) :: string) -- typecasting to only use the first element of the tuple
	if length > longestTextByCharacters then
		longestTextByCharacters = length
	end
end

local columnNames = {
	NormalizeToLength(`[ CoffeeRemotesRefined ] Test Name (✅/❌)`, longestTextByCharacters),
	`Absolute time()`,
	`Relative time()`
}
local timestampsOutput = {`|\t{table.concat(columnNames, spacing)}\t|`}
table.insert(timestampsOutput, ( (timestampsOutput[1]):gsub(`[^|]`, "-") ))
for _, stats in pairs(Timestamps) do
	local test_txt, timeSinceServerStart = table.unpack(stats)

	table.insert(
		timestampsOutput,
		`|\t{NormalizeToLength(test_txt :: string, longestTextByCharacters)}{spacing}{NormalizeToLength(
			("%.3f"):format(timeSinceServerStart :: number),
			GetStringLengthInCharacters(columnNames[2])
		)}{spacing}{NormalizeToLength(
			(temporaryLast and ("%.3f"):format(timeSinceServerStart-temporaryLast) or "none"),
			GetStringLengthInCharacters(columnNames[3])
		)}\t|`
	)

	temporaryLast = timeSinceServerStart
end
print(PREFIX .. `Test Timestamps: \n{table.concat(timestampsOutput, `\n`)}`)

if FailCount == 0 then
	print(PREFIX .. `Test PASSED ✅✅✅!`)
else
	print(PREFIX .. `Test FAILED ❌❌❌!`)
end

--[[
task.spawn(function()
	-- events dropped error; the following are not
	-- meant to be received/answered by the client
	-- this is not to be resolved by me, but by the developers
	local abc = RemoteEvent.new(`TestClientDidn'tMakeAnInstance`)
	for i = 1, 1024 do
		abc:FireClient(FirstTester, 123, true)
	end
	local def = RemoteFunction.new(`TestClientDidn'tMakeAnInstance`)
	for i = 1, 1024 do
		task.spawn(function()
			def:InvokeClient(FirstTester, 123, true)
			print("Invocation returned something")
		end)
	end
end)
--]]