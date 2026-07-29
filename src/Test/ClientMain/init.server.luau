--!strict
local RS = game:GetService(`ReplicatedStorage`)
local RunS = game:GetService(`RunService`)

-- Coffee Remote Refined ~ Client
local CRRClient = RS:WaitForChild(`CoffeeRemotesClient`)
local CoffeeRemotes = require(CRRClient)
--local RemoteEvent, RemoteFunction, URemoteEvent =
--	CoffeeRemotes.RemoteEvent,
--	CoffeeRemotes.RemoteFunction,
--	CoffeeRemotes.UnreliableRemoteEvent
local RemoteEvent, RemoteFunction, URemoteEvent = CoffeeRemotes:Unpack()

local KindOfs = {RemoteEvent, RemoteFunction, URemoteEvent}
local NKindOfs = #KindOfs

local function LogKindOf(kindOfIndex: number)
	return `kindOf indexed at {kindOfIndex} ({
		type(kindOfIndex) ~= `number` and `Not a number index. FATAL ERROR❌`
		or kindOfIndex == 1 and `Event`
		or kindOfIndex == 2 and `Function`
		or kindOfIndex == 3 and `Uvent`
		or `Out of range. FATAL ERROR❌`
	}); `
end

-- Let the server complete most of the stuff, so that the output isn't mixed.
-- Or event better, let clients write to the server output!
local TestCommunication = RemoteEvent.new(`TestCommunication`)
local TestCommunicationRetrieveState = RemoteFunction.new(`TestCommunication`)
local Warn = RemoteEvent.new(`Warn`)
local Print = RemoteEvent.new(`Print`)

local IsServerReady = TestCommunicationRetrieveState:InvokeServer()

if not IsServerReady then
	TestCommunication:Wait()
end









Warn:FireServer(true, `Test #1: Non-kindOf Instance occypying a name`)
--[[
-- Old test version back when GetRemote would error in that case
local NonKindOfsErrorAmount = 0

for i, kindOf in KindOfs do
	local success, result = pcall(function()
		return kindOf.new(`GenericRemoteEventName`)
	end)
	
	if success then
		Warn:FireServer(false, `Test #1 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	if not (type(result) == `string` and (result :: string):match(`.*Found a non%-.*Instance.*already occupying the name.*in.*; Client%-Side in Shambles!`)) then
		Warn:FireServer(false, `Test #1 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end

	Print:FireServer(`Expect false, error message containing "Found a non-<kindOf> Instance..."\n\t`, success, result)

	NonKindOfsErrorAmount += 1
end

TestCommunication:FireServer(`[1] Non-kindOf Instance occypying a name`, NonKindOfsErrorAmount == NKindOfs)
--]]

-- Returns a copy without cycle table refernces and metatables
local function DeepCopyExcludingCycleTableReference(original)
	if type(original) ~= `table` then
		return original
	end

	-- Tracks tables currently on the path from the root to the current node,
	-- so we can detect and exclude cyclic references (not just dedupe them).
	local visiting = {}

	local function copy(value: any)
		if type(value) ~= `table` then
			return value
		end

		if visiting[value] then
			-- Cycle detected: exclude this reference entirely.
			return nil
		end

		visiting[value] = true

		local result = {}
		for k, v in pairs(value) do
			local newKey = copy(k)
			local newValue = copy(v)
			-- Only insert if neither key nor value was excluded due to a cycle
			if newKey ~= nil and newValue ~= nil then
				result[newKey] = newValue
			end
		end

		visiting[value] = nil -- done with this branch, allow it again on sibling branches

		return result
	end

	return copy(original)
end

local NonKindOfsSuccessAmount = 0

for i, kindOf in KindOfs do
	local success, result = pcall(function()
		return kindOf.new(`GenericRemoteEventName`)
	end)
	
	if not (success and type(result) == `table`) then
		Warn:FireServer(false, `Test #1 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	-- DeepCopyExcludingCycleTableReference is used cuz RemoteInstances are
	-- incapable of sending Tables where Cycle Table References exist; And no,
	-- CRR will no strip it for you automatically!
	Print:FireServer(`Expect true, CoffeeRemotesObject\n\t`, success, DeepCopyExcludingCycleTableReference(result))

	NonKindOfsSuccessAmount += 1
end

TestCommunication:FireServer(`[1] Non-kindOf Instance occypying a name`, NonKindOfsSuccessAmount == NKindOfs)



---[[
Warn:FireServer(true, `Test #2: Name not registered warn (~3 seconds)`)
CoffeeRemotes:SetYieldWarningTime(1.5)
local FoundRemotes = 0
for i, kindOf in KindOfs do
	task.spawn(function()
		Print:FireServer(`Expect a client-side warning: "Did you create it on the Server-Side, or is this a typo?"`)
		kindOf.new(`Typo Or Not Initialized On Server-Side Name Example`)
		FoundRemotes += 1
	end)
end

task.wait(3)
TestCommunication:FireServer(`[2] Name not registered warn`, FoundRemotes == 0)
--]]


Warn:FireServer(true, `Test #3: \n\t0. Creating Remote of all kinds with a taken name\n\t\t\t(we'll create the same one twice to simulate this)\n\t.1 Public ["Remote"] field and Private ["_RI"] are the same Instance`)
local AlreadyTakenNameSuccessAmount = 0
local Test3RemotesCached = {}

for i, kindOf in KindOfs do
	local creationIteration0 = kindOf.new(`Dummy`)
	
	table.insert(Test3RemotesCached, creationIteration0)
	
	Print:FireServer(`\nExpect a client-side warning: "Return the existing object%.$"`)
	task.wait(0.3) -- let the print travel (over the network) so all of the output looks inline organized
	local success, result = pcall(function()
		return kindOf.new(`Dummy`)
	end)
	
	-- The result must be a CoffeeRemotesObject of the given kind
	if not (success and type(result) == `table`) then
		Warn:FireServer(`Test #3.0 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end
	
	-- The result must match the creationIteration0
	if creationIteration0 ~= result then
		Warn:FireServer(`Test #3.0 fail at {LogKindOf(i)}A new Object was created, but it was expected that an older one will be returned as the result; Success, Result received:`, success, result)
		continue
	end
	
	AlreadyTakenNameSuccessAmount += 1
end

TestCommunication:FireServer(`[3.0] Creating Remote of all kinds with a taken name`, AlreadyTakenNameSuccessAmount == NKindOfs)

local PublicAndPrivateFieldsMatching = 0
for i, remoteObject in Test3RemotesCached do
	local public = remoteObject[`Remote`]
	local private = remoteObject[`_RI`]
	
	if public ~= private then
		Warn:FireServer(`Test #3.1 fail at {LogKindOf(i)}Public and Private Remote Instance fields return different values; public, private:`, public, private)
		continue
	end
	
	PublicAndPrivateFieldsMatching += 1
end

TestCommunication:FireServer(`[3.1] Public ["Remote"] field and Private ["_RI"] are the same Instance`, PublicAndPrivateFieldsMatching == NKindOfs)



Warn:FireServer(true, `Test #4: \n\t.0 Destruction clears all of Object' Fields (makes it empty)\n\t.1 Attempt Read From Destroyed Object\n\t.2 Attempt Write To Destroyed Object\n\t.3 .Destroying Signal fires once`)
local DestorySuccess = 0
local DestroyedInstancesCantRead = 0
local DestroyedInstanceCantWrite = 0
local DestoyingSignalsReceived = 0

for i, remoteObject in Test3RemotesCached do
	local destroyingSignalReceivedTimes = 0
	remoteObject.Destroying:Connect(function()
		destroyingSignalReceivedTimes += 1
		DestoyingSignalsReceived += 1
	end);
	
	(remoteObject :: any):Destroy()

	local isEmpty = true
	for k, v in remoteObject do
		isEmpty = false
		Warn:FireServer(false, `Test #4.0 fail at {LogKindOf(i)}CoffeeRemotesObject was expected to be empty after destruction, got:`, remoteObject)
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
		Warn:FireServer(false, `Test #4.1 fail at {LogKindOf(i)}Reads Shall not be possible; readSuccess, readResult`, readSuccess, readResult)
	end

	local writeSuccess, writeResult = pcall(function()
		remoteObject.Destroy = true :: any
	end)

	if type(writeResult) == `string` and writeResult:match(`Attempt to modify destroyed CoffeeRemotesObject`) and not writeSuccess then
		DestroyedInstanceCantWrite += 1
	else
		Warn:FireServer(false, `Test #4.2 fail at {LogKindOf(i)}Writes Shall not be possible; writeSuccess, writeResult`, writeSuccess, writeResult)
	end
	
	if destroyingSignalReceivedTimes ~= 1 then
		Warn:FireServer(false, `Test #4.3 fail at {LogKindOf(i)}Expected to receive destroying signal ONCE, got {destroyingSignalReceivedTimes}`)
	end

	Print:FireServer(`Expect true, false, "Attempt to modify destroyed CoffeeRemotesObject", false, "Attempt to use destroyed CoffeeRemotesObject", 1\n\t\t`, table.concat({
		tostring(isEmpty),
		tostring(readSuccess),
		readResult,
		tostring(writeSuccess),
		writeResult,
		tostring(destroyingSignalReceivedTimes),
	}, `\n\t\t`))
end

TestCommunication:FireServer(`[4.0] Destruction empties objects`, DestorySuccess == NKindOfs)
TestCommunication:FireServer(`[4.1] Destroyed objects error on read`, DestroyedInstancesCantRead == NKindOfs)
TestCommunication:FireServer(`[4.2] Destroyed objects error on write`, DestroyedInstanceCantWrite == NKindOfs)
TestCommunication:FireServer(`[4.3] Destroying signal fires once`, DestoyingSignalsReceived == NKindOfs)



Warn:FireServer(true, `Test #5: Error creating unnamed (non-string named) Object`)
local UnnamedErrorAmount = 0

for i, kindOf in KindOfs do
	local name = nil

	local success, result = pcall(function()
		return (kindOf :: any).new(name)
	end)

	if success or type(result) ~= `string` or not (result :: string):match(`Can't create an unnamed.*! Given name: {name}`) then
		Warn:FireServer(false, `Test #5 fail at {LogKindOf(i)}Success, Result received:`, success, result)
		continue
	end

	Print:FireServer(`Expect false, {`Can't create an unnamed.*! Given name: {name}`}\n\t`, success, result)

	UnnamedErrorAmount += 1
end

TestCommunication:FireServer(`[5] Error creating unnamed`, UnnamedErrorAmount == NKindOfs)





-- Client-Only tests complete, Now the communication between!
RemoteEvent.new(`ClientCompleted`):FireServer()



local MainRemote = RemoteEvent.new(`Main`)

-- Before sending the test payload, get ready to receive some back!

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
		--Print:FireServer(`Payload "{name}" already registered, it won't be overwritten.`)
		return
	end

	DataReceived[name] = {
		Timestamp = timestamp,
		Payload = payload,
	}

	NDataReceived += 1
end

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



--- Connections
local RecommendedConnection = MainRemote:Connect(function(...)
	local timestamp = time()
	LogPayload(`Connect`, timestamp, {...})
end)

MainRemote:Once(function(...)
	local timestamp = time()
	LogPayload(`Once`, timestamp, {...})
end)

task.spawn(function()
	local payload = table.pack(MainRemote:Wait())
	local timestamp = time()
	LogPayload(`Wait`, timestamp, {table.unpack(payload)})
end)

--- Test OnClientEvent reference working same way
local CompatibleConnection = MainRemote.OnClientEvent:Connect(function(...)
	local timestamp = time()
	LogPayload(`OnClientEvent:Connect`, timestamp, {...})
end)

MainRemote.OnClientEvent:Once(function(...)
	local timestamp = time()
	LogPayload(`OnClientEvent:Once`, timestamp, {...})
end)

task.spawn(function()
	local payload = table.pack(MainRemote.OnClientEvent:Wait())
	local timestamp = time()
	LogPayload(`OnClientEvent:Wait`, timestamp, {table.unpack(payload)})
end)

--- And repeated "infinitely" too
local ChainConnection = MainRemote.OnClientEvent.OnClientEvent.OnClientEvent:Connect(function(...)
	local timestamp = time()
	LogPayload(`(Chain)OnClientEvent:Connect`, timestamp, {...})
end)

MainRemote.OnClientEvent.OnClientEvent.OnClientEvent:Once(function(...)
	local timestamp = time()
	LogPayload(`(Chain)OnClientEvent:Once`, timestamp, {...})
end)

task.spawn(function()
	local payload = table.pack(MainRemote.OnClientEvent.OnClientEvent.OnClientEvent:Wait())
	local timestamp = time()
	LogPayload(`(Chain)OnClientEvent:Wait`, timestamp, {table.unpack(payload)})
end)





local TestBuffer = buffer.create(4)
buffer.writeu8(TestBuffer, 1, 255)

local TestPayload = {
	`Divergent datatypes`,
	true,
	123,
	{
		Vector3.zero,
		CFrame.identity,
		UDim2.fromOffset(123, 256),
		(MainRemote :: any)[`_RI`],
	},
	Color3.fromRGB(255, 255, 255),
	`Next element shall be nil`,
	nil,
	`Previous element shall be nil`,
	TestBuffer,
}

MainRemote:FireServer(table.unpack(TestPayload))
-- after validation, server will fire twice

local s = time()
while NDataReceived < 9 and time() - s < 5 do
	task.wait()
end

if NDataReceived < 9 then
	Warn:FireServer(false, `Timeout without all properly catching a server signal`)
end

Print:FireServer(`Expect each entry value ["Payload"] field identic (You only have to check Connect, Once and Wait fields):\n`, DataReceived)

TestCommunication:FireServer(
	`[6.1] Server->Client (Connect, Once, Wait; "OnClientEvent" Included) over RemoteEvents`,
	NDataReceived == 9 and IsPayloadIdentic(DataReceived)
)



task.wait(0.3)
local IsValid = true
for k: string, v: number in TimesReceived do
	if k:match(`Connect`) then
		if v ~= 2 then
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

Print:FireServer(`Expect counts 2 for ["*Connect"], 1 for ["*Once"] and ["*Wait"]`, TimesReceived)
TestCommunication:FireServer(
	`[6.2] Server->Client ":Once() and :Wait() truly fire only ONE TIME; :Connect() MULTIPLE"`,
	NDataReceived == 9 and IsValid
)



MainRemote:FireServer(table.unpack(TestPayload))
MainRemote:FireServer(table.unpack(TestPayload))



local Aside = RemoteEvent.new(`Aside`)
Print:FireServer(`Client will now start firing twice at a time at a rate of task.wait()`)
task.wait(0.6)

local IsLooping = true

task.spawn(function()
	Aside:Wait()
	IsLooping = false
end)

local ClientTotalSent = 0
local w = task.wait
local function LogClientTotalSent()
	print(`Total sent by client: {ClientTotalSent}`)
end

while IsLooping and w() do
	-- Fire twice (stress test to reveal race conditions if any)
	MainRemote:FireServer()
	Aside:FireServer()
	
	MainRemote:FireServer()
	Aside:FireServer()
	
	ClientTotalSent += 2
	if ClientTotalSent % 50 == 0 then
		LogClientTotalSent()
	end
end
LogClientTotalSent()









local MainFunction = RemoteFunction.new(`Main`)
local IsTest7InProgress = true

task.wait(0.3)

local IsStudio: boolean = RunS:IsStudio()

local function MainFunctionCallback(payload: {})
	MainFunction.OnInvoke = nil -- wipe it so server can get the sole RFER
	-- of client side right after getting a successfull invocation
	
	task.delay(1, function()
		IsTest7InProgress = false
	end)
	
	return true, payload
end

local function FnForTest()
	return true, {`A test function`}
end


local IsSettingInvokeCallbackAlwaysSuccessfull = true
local function SetInvokeCallbackAndTroubleshoot(
	callback: ((...any) -> (boolean, {}))?,
	settingViaLegacyCompatibleAPI: boolean?
): boolean
	-- if not boolean, don't set (intended)
	if settingViaLegacyCompatibleAPI == true then
		MainFunction.OnClientInvoke = callback
	elseif settingViaLegacyCompatibleAPI == false then
		MainFunction.OnInvoke = callback
	end

	local recommendedAPI = MainFunction.OnInvoke
	local legacyCompatibleAPI = MainFunction.OnClientInvoke
	local isValueEqual = recommendedAPI == legacyCompatibleAPI
	local isValueSet = isValueEqual and recommendedAPI == callback

	Print:FireServer(
		(`Expect OnInvoke and OnClientInvoke to be "%s" (x2 / both shall be the same), got:`):format(tostring(callback)),
		tostring(recommendedAPI), -- functions get nullified over remotes
		tostring(legacyCompatibleAPI), -- functions get nullified over remotes
		`\t is value equal on both fields: {isValueEqual}; is value actually set for both fields: {isValueSet}`
	)

	if not isValueSet then
		Warn:FireServer(
			false,
			`Test #7.1 fail; {
				type(settingViaLegacyCompatibleAPI) == `boolean` and
				`Setting a callback {callback} via {settingViaLegacyCompatibleAPI and `OnClientInvoke` or `OnInvoke`} field leads to a mismatch of both` or
				`The current callback was set in some way that it mismatches`
			}`
		)
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

TestCommunication:FireServer(
	`[7.1] Writing/Reading Invoke Callback works as intended`,
	IsSettingInvokeCallbackAlwaysSuccessfull
)




-- Message is the first element of a tuple/array returned when success is false
local ExpectedMessages = {
	RFER_TooQuick = `Sending Requests Too Quickly!`,
}
ExpectedMessages[`RFER_NotFound`] = IsStudio and 
	`OnServerInvoke/OnInvoke Callback for name="{MainFunction.Remote.Name}" doesn't exist; Object and it's RemoteFunction Instance:` or
	ExpectedMessages[`RFER_TooQuick`]



local IsInvokeServerFlawless = true

local SuccessOne, ResultOne = MainFunction:InvokeServer(TestPayload)
local IsVerifiedCopy = TestPayload ~= ResultOne and Compare(TestPayload, ResultOne)
Print:FireServer(
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
	Warn:FireServer(false, `Test #7.2 fail at First Invoke (see message above)`)
	IsInvokeServerFlawless = false
end
Aside:FireServer()

local SuccessTwo, ResultTwo = MainFunction:InvokeServer(TestPayload)
local ExpectedResultOne = ExpectedMessages[`RFER_TooQuick`]
Print:FireServer(
	`[Second Invoke] Expect success, result to be false, {"{"} {ExpectedResultOne} {"}"}:`,
	SuccessTwo,
	ResultTwo
)
if SuccessTwo or (not (type(ResultTwo) == `table` and (ResultTwo :: any)[1] == ExpectedResultOne)) then
	Warn:FireServer(false, `Test #7.2 fail at Second Invoke (see message above)`)
	IsInvokeServerFlawless = false
end
Aside:FireServer()

task.wait(1)

local SuccessThree, ResultThree = MainFunction:InvokeServer(TestPayload)
local ExpectedResultTwo = ExpectedMessages[`RFER_NotFound`]
Print:FireServer(
	`[Third Invoke] Expect success, result to be false, {"{"} {ExpectedResultTwo} {"}"}:`,
	SuccessThree,
	ResultThree
)
if SuccessThree or (not (type(ResultThree) == `table` and (ResultThree :: any)[1] == ExpectedResultTwo)) then
	Warn:FireServer(false, `Test #7.2 fail at Third Invoke (see message above)`)
	IsInvokeServerFlawless = false
end

TestCommunication:FireServer(
	`[7.2] :InvokeServer works as intended w/ cooldowns and RFER Messages`,
	IsInvokeServerFlawless
)






while IsTest7InProgress do
	task.wait()
end

-- Client has got a copy of the ServerSide module parented directly under itself
local CRRServer = script:FindFirstChild(`CoffeeRemotesServer`)
if CRRServer then
	local RequireSuccess, RequireResult = pcall(require, CRRServer)
	print(RequireSuccess, RequireResult)
	TestCommunication:FireServer(
		`[8] CoffeeRemotesServer Errors on require by Client-Sided script`,
		RequireResult == `Requested module experienced an error while loading` and not RequireSuccess
	)
else
	Warn:FireServer(false, `[8] Can't test whether CoffeeRemotesServer Errors on require by Client-Sided script`)
end

local PostTest8 = RemoteEvent.new(`Post8`)
PostTest8:FireServer()



local PostTest9 = RemoteEvent.new(`Post9`) -- yields until server completes #9
local TestedFieldNames = {`Remote`, `Destroying`}
local NTestedFieldNames = #TestedFieldNames
local AllFieldsReadOnly = 0

for i, kindOf in KindOfs do
	local remote = kindOf.new(`Test#9`)
	local unsucessfullWrites = 0

	for _, k in TestedFieldNames do
		Print:FireServer(`Expect a warning "Nothing should be stored inside a..."`)
		task.wait(0.3) -- let the print travel (over the network) so all of the output looks inline organized
		local originalValue = (remote :: any)[k];
		(remote :: any)[k] = nil

		if (remote :: any)[k] ~= originalValue then
			Warn:FireServer(false, `FATAL ERROR: Successfully wrote nil to ["{k}"] at {LogKindOf(i)}`)
			continue
		end
		unsucessfullWrites += 1
	end

	if unsucessfullWrites ~= NTestedFieldNames then
		continue
	end

	AllFieldsReadOnly += 1
end

TestCommunication:FireServer(`[9] Public API fields ["Remote"] and ["Destroying"] are Read-Only (Error on Write)`, AllFieldsReadOnly == NKindOfs)
PostTest9:FireServer()



local Test10Event = RemoteEvent.new(`Test#10`)
Test10Event:Wait()



local Test10Function = RemoteFunction.new(`Test#10`)
local InvalidOnInvokeValue = true -- everything but nil or function
Print:FireServer(`[10.2] Expect warning "[OnInvoke | OnClientInvoke] must be a function (callback) or nil (to "disconnect"), got {InvalidOnInvokeValue}:"`)
local IsSettingInvalidOnInvokeIgnored = true

task.wait()

Test10Function.OnInvoke = InvalidOnInvokeValue :: any
if Test10Function.OnInvoke :: any == InvalidOnInvokeValue then
	warn(`Test #10.1 fail; Setting invalid value via OnInvoke succeeded`)
	IsSettingInvalidOnInvokeIgnored = false
end
Test10Function.OnClientInvoke = InvalidOnInvokeValue :: any
if Test10Function.OnClientInvoke :: any == InvalidOnInvokeValue then
	warn(`Test #10.1 fail; Setting invalid value via OnClientInvoke succeeded`)
	IsSettingInvalidOnInvokeIgnored = false
end

TestCommunication:FireServer(
	-- Message differs in wording from 10.1 to reduce the character count and make the summary table more readable
	`[10.2] Writing invalid values to OnInvoke | OnClientInvoke fields -> warn + ignore write`,
	IsSettingInvalidOnInvokeIgnored
)



Print:FireServer(`[10.3] Sending Tables with Cycle Table Reference present in them errors`)
--[[

-- Tables with cycle table references present in them
-- will error when sent over network via RemoteInstances
-- CoffeeRemotesRefined is not responsible for handling this
-- Why? Because imagine every single :FireServer and :InvokeServer
-- would check every argument for cycle table references
-- that wouldn't be very optimized...

--]]
local TableWithCycleReference = {}
TableWithCycleReference.HelloWorld = TableWithCycleReference
local TablesCannotBeCyclicErrorCount = 0
local Test10Point3CoffeeRemoteObjects: {[number]: CoffeeRemotes.CoffeeRemotesObject} = {}

for i, kindOf in KindOfs do
	local remote = kindOf.new(`Dummy`) -- objects by this name were destroyed back in test #4 (no warnings are expected)
	
	Test10Point3CoffeeRemoteObjects[i] = remote
	
	local success, result = pcall(
		i == 2 and
		(remote :: CoffeeRemotes.RemoteFunctionType | any).InvokeServer or
		(remote :: CoffeeRemotes.RemoteEventBaseType | any).FireServer,
		remote, -- self
		TableWithCycleReference
	)
	
	if success or result ~= `tables cannot be cyclic` then
		Warn:FireServer(false, `Test #10.3 fail at {LogKindOf(i)}; Successfully sent Table with Cycle References to the server or received an unexpected error message:`, success, result)
		continue
	end
	
	Print:FireServer(`Expect false, "tables cannot be cyclic"\n\t`, success, result)
	TablesCannotBeCyclicErrorCount += 1
end

TestCommunication:FireServer(
	`[10.3] Sending Tables with Cycle Table References yields errors`,
	TablesCannotBeCyclicErrorCount == NKindOfs
)



Warn:FireServer(true, `[10.4] Ensuring GetRemote is safe - returns the same CoffeeRemotesObject even if the Remote Instance was reparented elsewhere before creation and parented back whilst creation was wait yielding`)

local ClientSidedGetRemoteIsSafe = true

for i, remote in Test10Point3CoffeeRemoteObjects do
	local remoteInstance = remote.Remote
	local previousParent = remoteInstance.Parent
	remoteInstance.Parent = nil -- parent elsewhere
	
	task.delay(0.3, function()
		remoteInstance.Parent = previousParent -- reparent back
	end)
	
	Print:FireServer(`\nExpect a client-side warning: "Return the existing object%.$"`)
	-- this starts yielding (waiting), then the delayed above happens
	local sameRemoteObject = KindOfs[i].new(`{remoteInstance.Name}`)
	-- now it is expected to return the same CoffeeRemoteObject (and yield a warning)
	
	local isTheSame = remote == sameRemoteObject
	Print:FireServer(`Expect both CoffeeRemoteObjects equal (true), got {isTheSame}`)
	
	if not isTheSame then
		Warn:FireServer(
			false,
			`Test #10.4 fail at {LogKindOf(i)}The CoffeeRemoteObject created is not the same memory reference as expected, got:\n\taddress | table\n\t`,
			tostring(remote),
			DeepCopyExcludingCycleTableReference(remote),
			tostring(sameRemoteObject),
			DeepCopyExcludingCycleTableReference(sameRemoteObject)
		)
		ClientSidedGetRemoteIsSafe = false
		continue
	end
end

TestCommunication:FireServer(`[10.4] Client-Side GetRemote is safe`, ClientSidedGetRemoteIsSafe)



Test10Event:FireServer() -- we're all done!
-- no further tests shall be conducted on the client-side;
-- If you're adding any, please, before test #12 runs on the server-side!