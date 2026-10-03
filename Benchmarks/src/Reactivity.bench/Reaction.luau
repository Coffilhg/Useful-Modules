--!strict
--!optimize 2
const Reaction = require(`../Packages/Reaction`)
const Warn = require(`./Warn`)
const timeFunction = os.clock

const Benchmarks = {}

function Benchmarks.CreateSource(self: Benchmarks): number
	const s = timeFunction()
	const v = Reaction.V(0)
	const e = timeFunction()
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.ReadSource(self: Benchmarks): number
	const v = Reaction.V(0)
	const s = timeFunction()
	const _a = v()
	const e = timeFunction()
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.WriteSource(self: Benchmarks)
	const v = Reaction.V(0)
	const s = timeFunction()
	v(1)
	const e = timeFunction()
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.DestroySource(self: Benchmarks): number
	const v = Reaction.V(0)
	const s = timeFunction()
	Reaction.rmV(v)
	const e = timeFunction()
	return e - s
end

function Benchmarks.CreateObserver(self: Benchmarks): number
	const v = Reaction.V(0)
	const s = timeFunction()
	local n = 0
	const o = Reaction.O(v, function()
		n += 1
	end)
	const e = timeFunction()
	o()
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.UnseeObserver(self: Benchmarks): number
	const v = Reaction.V(0)
	local n = 0
	const o = Reaction.O(v, function()
		n += 1
	end)
	const s = timeFunction()
	o()
	const e = timeFunction()
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.WriteSourceWithNObservers(self: Benchmarks, nObservers: number?): number
	const v = Reaction.V(0)
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0
	const oo = {}
	for i = 1, no do
		table.insert(oo, Reaction.O(v, function()
			n += 1
		end))
	end
	
	const s = timeFunction()
	v(1)
	const e = timeFunction()
	
	for _, o in oo do
		o()
	end
	Reaction.rmV(v)
	
	if n ~= no then
		Warn(`Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end

function Benchmarks.CreateNObservers(self: Benchmarks, nObservers: number?): number
	const v = Reaction.V(0)
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0
	const oo = {}
	
	const s = timeFunction()
	for i = 1, no do
		table.insert(oo, Reaction.O(v, function()
			n += 1
		end))
	end
	const e = timeFunction()
	
	v(1)
	for _, o in oo do
		o()
	end
	Reaction.rmV(v)
	
	if n ~= no then
		Warn(`Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end

function Benchmarks.UnseeNObservers(self: Benchmarks, nObservers: number?): number
	const v = Reaction.V(0)
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0
	const oo = {}
	for i = 1, no do
		table.insert(oo, Reaction.O(v, function()
			n += 1
		end))
	end
	v(1)
	
	const s = timeFunction()
	for _, o in oo do
		o()
	end
	const e = timeFunction()
	
	Reaction.rmV(v)

	if n ~= no then
		Warn(`Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end



function Benchmarks.CreateDerive(self: Benchmarks): number
	const a = Reaction.V(0)
	const b = Reaction.V(0)
	const s = timeFunction()
	const v = Reaction.C(function()
		return a() + b()
	end)
	const e = timeFunction()
	Reaction.rmV(a)
	Reaction.rmV(b)
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.ReadDerive(self: Benchmarks): number
	const a = Reaction.V(3)
	const b = Reaction.V(4)
	const v = Reaction.C(function()
		return a() + b()
	end)
	const s = timeFunction()
	const _a = v()
	const e = timeFunction()
	
	const got = v()
	const expected = a() + b()
	if got ~= expected then
		Warn(`Derive did not initialize value correctly. Expected {expected}, got {got}`)
	end
	
	Reaction.rmV(a)
	Reaction.rmV(b)
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.RecomputeDerive(self: Benchmarks): number
	const a = Reaction.V(3)
	const b = Reaction.V(4)
	const v = Reaction.C(function()
		return a() + b()
	end)
	const s = timeFunction()
	b(1)
	const e = timeFunction()
	
	const got = v()
	const expected = a() + b()
	if got ~= expected then
		Warn(`Derive did not recompute or wrong. Expected {expected}, got {got}`)
	end
	
	Reaction.rmV(a)
	Reaction.rmV(b)
	Reaction.rmV(v)
	return e - s
end

function Benchmarks.DestroyDerive(self: Benchmarks): number
	const a = Reaction.V(3)
	const b = Reaction.V(4)
	const v = Reaction.C(function()
		return a() + b()
	end)
	Reaction.rmV(a)
	Reaction.rmV(b)
	const s = timeFunction()
	Reaction.rmV(v)
	const e = timeFunction()
	return e - s
end

function Benchmarks.CreateDeriveWithNDependencies(self: Benchmarks, nDependencies: number?): number
	const no = math.max(1, if type(nDependencies) == `number` then nDependencies else 1)
	const deps = {}
	for i = 1, no do
		table.insert(deps, Reaction.V(i))
	end
	
	const s = timeFunction()
	const v = Reaction.C(function()
		local sum: number = 0
		for _, dep in deps do
			sum += dep()
		end
		return sum
	end)
	const e = timeFunction()
	
	const got = v()
	const expected = (no * (no + 1)) / 2 -- simply sigma
	if got ~= expected then
		Warn(`Derive did not initialize value correctly. Expected {expected}, got {got}`)
	end
	
	Reaction.rmV(v)
	for _, dep in deps do
		Reaction.rmV(dep)
	end
	return e - s
end

function Benchmarks.RecomputeDeriveWithNDependencies(self: Benchmarks, nDependencies: number?): number
	const no = math.max(1, if type(nDependencies) == `number` then nDependencies else 1)
	const deps = {}
	for i = 1, no do
		table.insert(deps, Reaction.V(i))
	end
	
	const v = Reaction.C(function()
		local sum: number = 0
		for _, dep in deps do
			sum += dep()
		end
		return sum
	end)
	
	const firstValue = deps[1]()
	const s = timeFunction()
	deps[1](firstValue - 1)
	const e = timeFunction()

	const got = v()
	const expected = (no * (no + 1)) / 2 --[[simply sigma and minus one]] - 1
	if got ~= expected then
		Warn(`Derive did not recompute or wrong. Expected {expected}, got {got}`)
	end

	Reaction.rmV(v)
	for _, dep in deps do
		Reaction.rmV(dep)
	end
	return e - s
end

function Benchmarks.RecomputeDeriveSwitch(self: Benchmarks): number
	const a = Reaction.V(1)
	const b = Reaction.V(0)
	const c = Reaction.V(true)
	const v = Reaction.C(function()
		if c() then
			return a()
		end
		return b()
	end)
	local changesObserved: number = 0
	const o = Reaction.O(v, function()
		changesObserved += 1
	end)
	
	-- no recomputation expected
	const s1 = timeFunction()
	b(-1)
	const e1 = timeFunction()
	if changesObserved > 0 then
		Warn(`Derive recomputed without a reason [#1].`)
	end
	
	-- recomputation expected
	const s2 = timeFunction()
	a(2)
	const e2 = timeFunction()
	if v() ~= a() then
		Warn(`Derive did not recompute or wrong, but was expected to [#1].`)
	end
	
	-- recomputation expected
	const s3 = timeFunction()
	c(false)
	const e3 = timeFunction()
	if v() ~= b() then
		Warn(`Derive did not recompute or wrong, but was expected to [#2].`)
	end
	
	-- no recomputation expected
	const s4 = timeFunction()
	a(-1)
	const e4 = timeFunction()
	if changesObserved > 2 then
		Warn(`Derive recomputed without a reason [#2].`)
	end
	
	-- recomputation expected
	const s5 = timeFunction()
	b(1)
	const e5 = timeFunction()
	if v() ~= b() then
		Warn(`Derive did not recompute or wrong, but was expected to [#3].`)
	end
	
	
	
	Reaction.rmV(a)
	Reaction.rmV(b)
	Reaction.rmV(c)
	Reaction.rmV(v)
	o()
	return (e1 - s1)
		+ (e2 - s2)
		+ (e3 - s3)
		+ (e4 - s4)
		+ (e5 - s5)
end

function Benchmarks.CreateDeriveChain(self: Benchmarks): number
	const a = Reaction.V(3)
	const vs = {}
	local last = a
	const s = timeFunction()
	for i = 1, 1000 do
		const prev = last
		const v = Reaction.C(function()
			return prev() -- we cant just use last, because it's a reference
		end)
		last = v
		table.insert(vs, v)
	end
	const e = timeFunction()
	
	if last() ~= a() then
		Warn(`Derive did not initialize value correctly. Expected {a()}, got {last()}`)
	end
	
	Reaction.rmV(a)
	for _, v in vs do
		Reaction.rmV(v)
	end
	return e - s
end

function Benchmarks.RecomputeDeriveChain(self: Benchmarks): number
	const a = Reaction.V(3)
	const vs = {}
	local last = a
	for i = 1, 1000 do
		const prev = last
		const v = Reaction.C(function()
			return prev() -- we cant just use last, because it's a reference
		end)
		last = v
		table.insert(vs, v)
	end
	const s = timeFunction()
	a(1)
	const e = timeFunction()
	
	if last() ~= a() then
		Warn(`Derive did not recompute or wrong. Expected {a()}, got {last()}`)
	end
	
	Reaction.rmV(a)
	for _, v in vs do
		Reaction.rmV(v)
	end
	return e - s
end

function Benchmarks.RecomputeNDerive(self: Benchmarks, nValues: number?): number
	const a = Reaction.V(3)
	const no = math.max(1, if type(nValues) == `number` then nValues else 1)
	const vs = {}
	for i = 1, no do
		const v = Reaction.C(function()
			return a()
		end)
		table.insert(vs, v)
	end
	
	const s = timeFunction()
	a(1)
	const e = timeFunction()
	
	Reaction.rmV(a)
	for _, v in vs do
		Reaction.rmV(v)
	end
	return e - s
end

table.freeze(Benchmarks)
export type Benchmarks = typeof(Benchmarks)
return Benchmarks