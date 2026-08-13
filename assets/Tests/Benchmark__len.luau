local CoffeeObjects = require(game.ServerScriptService.CoffeeObjects)

local CoffeeFolder = CoffeeObjects.CoffeeFolder
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

local n = 1_000_000

function Benchmark()
	local ArrayForTesting = CoffeeFolder.strictNew({
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),

		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),

		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
		CoffeeBaseValue.strictNew(math.random(1, 100)),
	})

	-- 30 elements

	local start = tick()
	local result = 0

	for i = 1, n do
		if #ArrayForTesting == 30 then
			result += 1
		end
	end

	local stop = tick()

	print(`Total verifications with exact length 30: {result}; Should be equal to '{n}'\ntime taken: {stop-start}s`)
	
	ArrayForTesting:Destroy()
	
	return stop - start
end

local total = 0
local iterations = 100
task.spawn(function()
	for i = 1, iterations do
		total += Benchmark()
		if i % 10 == 0 then
			task.wait(1) -- don't remove this for safe in-console/test usage
		end
	end
	print(`Average Benchmark time: {total/iterations}s`)
end)