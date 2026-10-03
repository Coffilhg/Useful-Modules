--!strict
--!optimize 2

-- Sample amounts
const SmallTests: number = 100_000
const MediumTests: number = 10_000
const BigTests: number = 1_000

-- all of the modules must share same api for tests
-- modules refers to any module required/passed as BenchmarkedModule
const BenchmarksStructure = require(`@self/Reaction`)

return function(
	benchmarkedModule: typeof(BenchmarksStructure),
	prefix: string, -- Name for output
	stops: {
		small: number?,
		medium: number?,
		big: number?
	}?
)
	const st = if type(stops) == `table` then stops else {}
	const smallStop: number = if type(st.small) == `number` then st.small else -1
	const mediumStop: number = if type(st.medium) == `number` then st.medium else -1
	const bigStop: number = if type(st.big) == `number` then st.big else -1
	warn(`{prefix} Started benchmark.`)
	const s = os.clock()
	
	--- Source
	local TotalTime: number = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:CreateSource()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Creating source avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:ReadSource()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Reading source avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:WriteSource()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Writing source avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:DestroySource()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Destroy source avg: {TotalTime / SmallTests}`)



	--- Observer
	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:CreateObserver()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Create observer avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:UnseeObserver()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Unsee observer avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:WriteSourceWithNObservers(1)
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Observe a change using 1 observer avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, MediumTests do
		TotalTime += benchmarkedModule:WriteSourceWithNObservers(100)
		if mediumStop > 0 and i % mediumStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Observe a change using 100 observers avg: {TotalTime / MediumTests}`)

	TotalTime = 0
	for i = 1, MediumTests do
		TotalTime += benchmarkedModule:CreateNObservers(10)
		if mediumStop > 0 and i % mediumStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Create 10 observers avg: {TotalTime / MediumTests}`)

	TotalTime = 0
	for i = 1, MediumTests do
		TotalTime += benchmarkedModule:UnseeNObservers(10)
		if mediumStop > 0 and i % mediumStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Unsee 10 observers avg: {TotalTime / MediumTests}`)



	--- Derive
	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:CreateDerive()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Creating derive avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:ReadDerive()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Reading derive avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:RecomputeDerive()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Recompute derive avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, SmallTests do
		TotalTime += benchmarkedModule:DestroyDerive()
		if smallStop > 0 and i % smallStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Destroy derive avg: {TotalTime / SmallTests}`)

	TotalTime = 0
	for i = 1, MediumTests do
		TotalTime += benchmarkedModule:CreateDeriveWithNDependencies(100)
		if mediumStop > 0 and i % mediumStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Create derive with 100 deps avg: {TotalTime / MediumTests}`)

	TotalTime = 0
	for i = 1, MediumTests do
		TotalTime += benchmarkedModule:RecomputeDeriveWithNDependencies(100)
		if mediumStop > 0 and i % mediumStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Recompute derive with 100 deps avg: {TotalTime / MediumTests}`)

	TotalTime = 0
	for i = 1, MediumTests do
		TotalTime += benchmarkedModule:RecomputeDeriveSwitch()
		if mediumStop > 0 and i % mediumStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Derive dynamic dependency switch scenario avg: {TotalTime / MediumTests}`)

	TotalTime = 0
	for i = 1, BigTests do
		TotalTime += benchmarkedModule:CreateDeriveChain()
		if bigStop > 0 and i % bigStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Create derive chain (of 1000) avg: {TotalTime / BigTests}`)

	TotalTime = 0
	for i = 1, BigTests do
		TotalTime += benchmarkedModule:RecomputeDeriveChain()
		if bigStop > 0 and i % bigStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Recompute derive chain (of 1000) avg: {TotalTime / BigTests}`)

	TotalTime = 0
	for i = 1, BigTests do
		TotalTime += benchmarkedModule:RecomputeNDerive(100)
		if bigStop > 0 and i % bigStop == 0 then
			task.wait()
		end
	end
	print(`{prefix} Recompute 100 derived values (fan-out) avg: {TotalTime / BigTests}`)

	-- root end

	const e = os.clock()

	warn(`{prefix} Benchmarking complete in {e-s} seconds!`)
	
	return e-s
end