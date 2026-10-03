--!strict
--!optimize 2

-- Vision (thekingofspace/vision) benchmark module, same API as Reactivity.bench/Reaction.
-- Use as: Benchmark(require(`./Reactivity.bench/Vision`), `[Vision] `)
--
-- How Vision concepts are used here:
--   source   -> Vision.event("Name", initial, noop)         read: v.Name()   write: v.Name(x)
--   derive   -> Vision.derive("Name", compute)              dependencies are tracked through Read(name)
--   observer -> Vision.merge("Name", callback)              callbacks are bound when the vision is mounted
--   destroy  -> vision:Cleanup()
-- Every vision adopts one shared Folder (Vision.fromInstance) so that no Instances are created while benchmarking.
-- Values only exist inside a declaration, so a vision is the unit of creation and destruction.
const Vision = require(`../Packages/Vision`)
const Warn = require(`./Warn`)
const timeFunction = os.clock

const BenchScope = Vision.Scope()
const Host = Instance.new("Folder")
const HostMarker = Vision.fromInstance(Host)

const function Noop(a: any, b: any, c: any) end

-- Derives propagate recursively and every level adds one nested pcall inside Vision.
-- Luau's C-call limit is ~200, so a chain of 1000 derives overflows. Raise this at your own risk.
const ChainLength = 1000

const ChainNames: { string } = {}
for i = 1, ChainLength do
	ChainNames[i] = `D{i}`
end
const DepNames: { string } = {} -- grown on demand
const FanNames: { string } = {} -- grown on demand

const Benchmarks = {}

function Benchmarks.CreateSource(self: Benchmarks): number
	const s = timeFunction()
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("V", 0, Noop),
	})
	const e = timeFunction()
	return e - s
end

function Benchmarks.ReadSource(self: Benchmarks): number
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("V", 0, Noop),
	})
	const s = timeFunction()
	const _a = v.V()
	const e = timeFunction()
	return e - s
end

function Benchmarks.WriteSource(self: Benchmarks)
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("V", 0, Noop),
	})
	const s = timeFunction()
	v.V(1)
	const e = timeFunction()
	return e - s
end

function Benchmarks.DestroySource(self: Benchmarks): number
	-- sources work without mounting, so this is Cleanup on an unmounted vision
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("V", 0, Noop),
	})
	const s = timeFunction()
	v:Cleanup()
	const e = timeFunction()
	return e - s
end

function Benchmarks.CreateObserver(self: Benchmarks): number
	-- observers can only be bound by capturing + mounting a declaration (includes creating the source)
	local n = 0
	const s = timeFunction()
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("V", 0, Noop),
		Vision.merge("V", function()
			n += 1
		end),
	})
	v:Mount()
	const e = timeFunction()
	v:Cleanup()
	return e - s
end

function Benchmarks.UnseeObserver(self: Benchmarks): number
	local n = 0
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("V", 0, Noop),
		Vision.merge("V", function()
			n += 1
		end),
	})
	v:Mount()
	const s = timeFunction()
	v:Cleanup()
	const e = timeFunction()
	return e - s
end

function Benchmarks.WriteSourceWithNObservers(self: Benchmarks, nObservers: number?): number
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0
	const decl: { any } = {
		HostMarker,
		Vision.event("V", 0, Noop),
	}
	for i = 1, no do
		table.insert(decl, Vision.merge("V", function()
			n += 1
		end))
	end
	const v = BenchScope:Capture(decl)
	v:Mount()
	n = 0 -- mounting calls every handler once with the initial value

	const s = timeFunction()
	v.V(1)
	const e = timeFunction()

	v:Cleanup()

	if n ~= no then
		Warn(`[{script.Name}] Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end

function Benchmarks.CreateNObservers(self: Benchmarks, nObservers: number?): number
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0

	const s = timeFunction()
	const decl: { any } = {
		HostMarker,
		Vision.event("V", 0, Noop),
	}
	for i = 1, no do
		table.insert(decl, Vision.merge("V", function()
			n += 1
		end))
	end
	const v = BenchScope:Capture(decl)
	v:Mount()
	const e = timeFunction()

	n = 0
	v.V(1)
	v:Cleanup()

	if n ~= no then
		Warn(`[{script.Name}] Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end

function Benchmarks.UnseeNObservers(self: Benchmarks, nObservers: number?): number
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0
	const decl: { any } = {
		HostMarker,
		Vision.event("V", 0, Noop),
	}
	for i = 1, no do
		table.insert(decl, Vision.merge("V", function()
			n += 1
		end))
	end
	const v = BenchScope:Capture(decl)
	v:Mount()
	n = 0
	v.V(1)

	const s = timeFunction()
	v:Cleanup()
	const e = timeFunction()

	if n ~= no then
		Warn(`[{script.Name}] Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end



function Benchmarks.CreateDerive(self: Benchmarks): number
	const decl: { any } = {
		HostMarker,
		Vision.event("A", 0, Noop),
		Vision.event("B", 0, Noop),
	}
	-- a derive only gets its value and dependencies when the vision is mounted
	const s = timeFunction()
	table.insert(decl, Vision.derive("D", function(_, Read)
		return Read("A") + Read("B")
	end))
	const v = BenchScope:Capture(decl)
	v:Mount()
	const e = timeFunction()
	v:Cleanup()
	return e - s
end

function Benchmarks.ReadDerive(self: Benchmarks): number
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("A", 3, Noop),
		Vision.event("B", 4, Noop),
		Vision.derive("D", function(_, Read)
			return Read("A") + Read("B")
		end),
	})
	v:Mount()
	const s = timeFunction()
	const _a = v.D()
	const e = timeFunction()

	const got = v.D()
	const expected = v.A() + v.B()
	if got ~= expected then
		Warn(`[{script.Name}] Derive did not initialize value correctly. Expected {expected}, got {got}`)
	end

	v:Cleanup()
	return e - s
end

function Benchmarks.RecomputeDerive(self: Benchmarks): number
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("A", 3, Noop),
		Vision.event("B", 4, Noop),
		Vision.derive("D", function(_, Read)
			return Read("A") + Read("B")
		end),
	})
	v:Mount()
	-- Vision derives are eager: the write below includes recomputing D
	const s = timeFunction()
	v.B(1)
	const e = timeFunction()

	const got = v.D()
	const expected = v.A() + v.B()
	if got ~= expected then
		Warn(`[{script.Name}] Derive did not recompute or wrong. Expected {expected}, got {got}`)
	end

	v:Cleanup()
	return e - s
end

function Benchmarks.DestroyDerive(self: Benchmarks): number
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("A", 3, Noop),
		Vision.event("B", 4, Noop),
		Vision.derive("D", function(_, Read)
			return Read("A") + Read("B")
		end),
	})
	v:Mount()
	const s = timeFunction()
	v:Cleanup()
	const e = timeFunction()
	return e - s
end

function Benchmarks.CreateDeriveWithNDependencies(self: Benchmarks, nDependencies: number?): number
	const no = math.max(1, if type(nDependencies) == `number` then nDependencies else 1)
	for i = #DepNames + 1, no do
		DepNames[i] = `Dep{i}`
	end
	const decl: { any } = { HostMarker }
	for i = 1, no do
		table.insert(decl, Vision.event(DepNames[i], i, Noop))
	end

	const s = timeFunction()
	table.insert(decl, Vision.derive("Sum", function(_, Read)
		local sum: number = 0
		for i = 1, no do
			sum += Read(DepNames[i])
		end
		return sum
	end))
	const v = BenchScope:Capture(decl)
	v:Mount()
	const e = timeFunction()

	const got = v.Sum()
	const expected = (no * (no + 1)) / 2 -- simply sigma
	if got ~= expected then
		Warn(`[{script.Name}] Derive did not initialize value correctly. Expected {expected}, got {got}`)
	end

	v:Cleanup()
	return e - s
end

function Benchmarks.RecomputeDeriveWithNDependencies(self: Benchmarks, nDependencies: number?): number
	const no = math.max(1, if type(nDependencies) == `number` then nDependencies else 1)
	for i = #DepNames + 1, no do
		DepNames[i] = `Dep{i}`
	end
	const decl: { any } = { HostMarker }
	for i = 1, no do
		table.insert(decl, Vision.event(DepNames[i], i, Noop))
	end
	table.insert(decl, Vision.derive("Sum", function(_, Read)
		local sum: number = 0
		for i = 1, no do
			sum += Read(DepNames[i])
		end
		return sum
	end))
	const v = BenchScope:Capture(decl)
	v:Mount()

	const first = v.Dep1
	const firstValue = first()
	const s = timeFunction()
	first(firstValue - 1)
	const e = timeFunction()

	const got = v.Sum()
	const expected = (no * (no + 1)) / 2 --[[simply sigma and minus one]] - 1
	if got ~= expected then
		Warn(`[{script.Name}] Derive did not recompute or wrong. Expected {expected}, got {got}`)
	end

	v:Cleanup()
	return e - s
end

function Benchmarks.RecomputeDeriveSwitch(self: Benchmarks): number
	local changesObserved: number = 0
	const v = BenchScope:Capture({
		HostMarker,
		Vision.event("A", 1, Noop),
		Vision.event("B", 0, Noop),
		Vision.event("C", true, Noop),
		Vision.derive("D", function(_, Read)
			if Read("C") then
				return Read("A")
			end
			return Read("B")
		end),
		Vision.merge("D", function()
			changesObserved += 1
		end),
	})
	v:Mount()
	changesObserved = 0 -- mounting calls every handler once with the initial value

	-- no recomputation expected
	const s1 = timeFunction()
	v.B(-1)
	const e1 = timeFunction()
	if changesObserved > 0 then
		Warn(`[{script.Name}] Derive recomputed without a reason [#1].`)
	end

	-- recomputation expected
	const s2 = timeFunction()
	v.A(2)
	const e2 = timeFunction()
	if v.D() ~= v.A() then
		Warn(`[{script.Name}] Derive did not recompute or wrong, but was expected to [#1].`)
	end

	-- recomputation expected
	const s3 = timeFunction()
	v.C(false)
	const e3 = timeFunction()
	if v.D() ~= v.B() then
		Warn(`[{script.Name}] Derive did not recompute or wrong, but was expected to [#2].`)
	end

	-- no recomputation expected
	const s4 = timeFunction()
	v.A(-1)
	const e4 = timeFunction()
	if changesObserved > 2 then
		Warn(`[{script.Name}] Derive recomputed without a reason [#2].`)
	end

	-- recomputation expected
	const s5 = timeFunction()
	v.B(1)
	const e5 = timeFunction()
	if v.D() ~= v.B() then
		Warn(`[{script.Name}] Derive did not recompute or wrong, but was expected to [#3].`)
	end

	v:Cleanup()
	return (e1 - s1)
		+ (e2 - s2)
		+ (e3 - s3)
		+ (e4 - s4)
		+ (e5 - s5)
end

function Benchmarks.CreateDeriveChain(self: Benchmarks): number
	const decl: { any } = {
		HostMarker,
		Vision.event("A", 3, Noop),
	}

	const s = timeFunction()
	for i = 1, ChainLength do
		const prev = if i == 1 then "A" else ChainNames[i - 1]
		table.insert(decl, Vision.derive(ChainNames[i], function(_, Read)
			return Read(prev)
		end))
	end
	const v = BenchScope:Capture(decl)
	v:Mount()
	const e = timeFunction()

	const last = (v :: any)[ChainNames[ChainLength]]()
	if last ~= v.A() then
		Warn(`[{script.Name}] Derive did not initialize value correctly. Expected {v.A()}, got {last}`)
	end

	v:Cleanup()
	return e - s
end

function Benchmarks.RecomputeDeriveChain(self: Benchmarks): number
	const decl: { any } = {
		HostMarker,
		Vision.event("A", 3, Noop),
	}
	for i = 1, ChainLength do
		const prev = if i == 1 then "A" else ChainNames[i - 1]
		table.insert(decl, Vision.derive(ChainNames[i], function(_, Read)
			return Read(prev)
		end))
	end
	const v = BenchScope:Capture(decl)
	v:Mount()

	const s = timeFunction()
	v.A(1)
	const e = timeFunction()

	const last = (v :: any)[ChainNames[ChainLength]]()
	if last ~= v.A() then
		Warn(`[{script.Name}] Derive did not recompute or wrong. Expected {v.A()}, got {last}`)
	end

	v:Cleanup()
	return e - s
end

function Benchmarks.RecomputeNDerive(self: Benchmarks, nValues: number?): number
	const no = math.max(1, if type(nValues) == `number` then nValues else 1)
	for i = #FanNames + 1, no do
		FanNames[i] = `Fan{i}`
	end
	const decl: { any } = {
		HostMarker,
		Vision.event("A", 3, Noop),
	}
	for i = 1, no do
		table.insert(decl, Vision.derive(FanNames[i], function(_, Read)
			return Read("A")
		end))
	end
	const v = BenchScope:Capture(decl)
	v:Mount()

	const s = timeFunction()
	v.A(1)
	const e = timeFunction()

	v:Cleanup()
	return e - s
end

table.freeze(Benchmarks)
export type Benchmarks = typeof(Benchmarks)
return Benchmarks