--!optimize 2

local CoffeeObjects = require(game.ReplicatedStorage.CoffeeObjects)

local CoffeeFolder = CoffeeObjects.CoffeeFolder
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

local n = 1_000_000

function Benchmark()
	local Folder = CoffeeFolder.strictNew({})

	local start = os.clock()

	for i = 1, n do
		Folder:GetChildren()
	end

	local stop = os.clock()

	print(`Time taken: {stop-start}s`)

	Folder:Destroy()

	return stop - start
end

task.delay(6, Benchmark)
task.delay(9, Benchmark)
task.delay(12, Benchmark)

-- @2.3.4:
--[[
  Time taken: 0.021730199921876192s
  Time taken: 0.022426399867981672s
  Time taken: 0.022109600016847253s
]]

-- @2.3.4 + rawset Methods moved to the metatable itself
--[[
  Time taken: 0.06154409982264042s
  Time taken: 0.06147149996832013s
  Time taken: 0.061221799813210964s
]]