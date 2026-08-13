--!optimize 2
local RS = game:GetService(`ReplicatedStorage`)
local CoffeeObjects = require(RS.CoffeeObjects)

local CoffeeFolder = CoffeeObjects.CoffeeFolder
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

local n: number = 5_0_000
local MainFolder = CoffeeFolder.new()

local TimeSpentCoolingDown = 0
local startTime = os.clock()

for i = 1, n do
	local ChildFolder = CoffeeFolder.new()
	for m = 1, 30 do
		ChildFolder:Insert(
			CoffeeBaseValue.new(math.random())
		)
	end
	MainFolder:Insert(ChildFolder)
	if i % 1_000 == 0 then
		-- to avoid "Script timeout: exhausted allowed execution time"
		TimeSpentCoolingDown += task.wait(0.1)
	end
end

local endTime = os.clock()

print(`Done creating {n} Folders with 30 Children each in {endTime-startTime}s (Time spent cooling down = {TimeSpentCoolingDown}); Now check the memory usage!`)
-- Search for CoffeeObjectsMemory on Server-Side in developer console (use f9 or say /console in chat)


-- @2.3.4: 1498.272 MB -- forgot to write down
-- @2.3.4 + rawset Methods moved to the metatable itself: 1486.064 MB (Done creating 50000 Folders with 30 Children each in 10.528351600049064s (Time spent cooling down = 7.676657499996509); Now check the memory usage!)

-- that doesnt look like much changes, re-testing!
-- @2.3.4: 1498.272 MB (Done creating 50000 Folders with 30 Children each in 10.49553079996258s (Time spent cooling down = 7.455751099994814); Now check the memory usage!)
-- @2.3.4 Tested again: 1498.272 MB (Done creating 50000 Folders with 30 Children each in 10.943361099809408s (Time spent cooling down = 7.766120799993587); Now check the memory usage!)
-- @2.3.4 + rawset Methods moved to the metatable itself: 1486.005 MB (Done creating 50000 Folders with 30 Children each in 11.408013199921697s (Time spent cooling down = 8.280732199995327); Now check the memory usage!)
-- @2.3.4 + rawset Methods moved to the metatable itself Tested again: 1486.064 MB (Done creating 50000 Folders with 30 Children each in 10.805651099886745s (Time spent cooling down = 7.582408400006898); Now check the memory usage!)