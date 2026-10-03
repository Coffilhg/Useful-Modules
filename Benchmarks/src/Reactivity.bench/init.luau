--!strict
--!optimize 2

-- all of the modules must share same api for tests
-- modules refers to any module required as BenchmarkedModule
const BenchmarkedModule = require(`@self/Reaction`)
-- Name for output
const Prefix: string = `[Reaction] `
-- Sample amounts
const SmallTests: number = 100_000
const MediumTests: number = 10_000
const BigTests: number = 1_000

warn(`{Prefix} Started benchmark.`)
const s = os.clock()

-- optionally, a root or whatever kind of mount can
-- be created and be used as a wrap here, instead of
-- creating and tearing down one per every single
-- small measurement. (e.g. Reaction does not require
-- that, but Vide does, for Derive values)

-- root start
--- Source
local TotalTime: number = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:CreateSource()
end
print(`{Prefix} Creating source avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:ReadSource()
end
print(`{Prefix} Reading source avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:WriteSource()
end
print(`{Prefix} Writing source avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:DestroySource()
end
print(`{Prefix} Destroy source avg: {TotalTime / SmallTests}`)



--- Observer
TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:CreateObserver()
end
print(`{Prefix} Create observer avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:UnseeObserver()
end
print(`{Prefix} Unsee observer avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:WriteSourceWithNObservers(1)
end
print(`{Prefix} Observe a change using 1 observer avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, MediumTests do
	TotalTime += BenchmarkedModule:WriteSourceWithNObservers(100)
end
print(`{Prefix} Observe a change using 100 observers avg: {TotalTime / MediumTests}`)

TotalTime = 0
for i = 1, MediumTests do
	TotalTime += BenchmarkedModule:CreateNObservers(10)
end
print(`{Prefix} Create 10 observers avg: {TotalTime / MediumTests}`)

TotalTime = 0
for i = 1, MediumTests do
	TotalTime += BenchmarkedModule:UnseeNObservers(10)
end
print(`{Prefix} Unsee 10 observers avg: {TotalTime / MediumTests}`)



--- Derive
TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:CreateDerive()
end
print(`{Prefix} Creating derive avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:ReadDerive()
end
print(`{Prefix} Reading derive avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:RecomputeDerive()
end
print(`{Prefix} Recompute derive avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, SmallTests do
	TotalTime += BenchmarkedModule:DestroyDerive()
end
print(`{Prefix} Destroy derive avg: {TotalTime / SmallTests}`)

TotalTime = 0
for i = 1, MediumTests do
	TotalTime += BenchmarkedModule:CreateDeriveWithNDependencies(100)
end
print(`{Prefix} Create derive with 100 deps avg: {TotalTime / MediumTests}`)

TotalTime = 0
for i = 1, MediumTests do
	TotalTime += BenchmarkedModule:RecomputeDeriveWithNDependencies(100)
end
print(`{Prefix} Recompute derive with 100 deps avg: {TotalTime / MediumTests}`)

TotalTime = 0
for i = 1, MediumTests do
	TotalTime += BenchmarkedModule:RecomputeDeriveSwitch()
end
print(`{Prefix} Derive dynamic dependency switch scenario avg: {TotalTime / MediumTests}`)

TotalTime = 0
for i = 1, BigTests do
	TotalTime += BenchmarkedModule:CreateDeriveChain()
end
print(`{Prefix} Create derive chain (of 1000) avg: {TotalTime / BigTests}`)

TotalTime = 0
for i = 1, BigTests do
	TotalTime += BenchmarkedModule:RecomputeDeriveChain()
end
print(`{Prefix} Recompute derive chain (of 1000) avg: {TotalTime / BigTests}`)

TotalTime = 0
for i = 1, BigTests do
	TotalTime += BenchmarkedModule:RecomputeNDerive(100)
end
print(`{Prefix} Recompute 100 derived values (fan-out) avg: {TotalTime / BigTests}`)

-- root end

const e = os.clock()

warn(`{Prefix} Benchmarking complete in {e-s} seconds!`)

return e-s