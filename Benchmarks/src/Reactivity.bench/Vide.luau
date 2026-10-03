--!strict
--!optimize 2

-- Vide (centau/vide) benchmark module, same API as Reactivity.bench/Reaction.
-- No roots are created here: the caller (Main bench) wraps everything in Vide.root.
-- Vide has no public way to destroy a single source / derive / effect (only whole scopes),
-- so the "destroy" benchmarks are N/A and the outer root keeps every derive/effect alive until it is destroyed.
const Vide = require(`../Packages/Vide`)
const Warn = require(`./Warn`)
const timeFunction = os.clock

const Benchmarks = {}

function Benchmarks.CreateSource(self: Benchmarks): number
	const s = timeFunction()
	const v = Vide.source(0)
	const e = timeFunction()
	return e - s
end

function Benchmarks.ReadSource(self: Benchmarks): number
	const v = Vide.source(0)
	const s = timeFunction()
	const _a = v()
	const e = timeFunction()
	return e - s
end

function Benchmarks.WriteSource(self: Benchmarks)
	const v = Vide.source(0)
	const s = timeFunction()
	v(1)
	const e = timeFunction()
	return e - s
end

function Benchmarks.DestroySource(self: Benchmarks): number
	-- N/A: Vide sources cannot be destroyed (garbage collected)
	return 0
end

function Benchmarks.CreateObserver(self: Benchmarks): number
	const v = Vide.source(0)
	const s = timeFunction()
	local n = 0
	local first = true
	Vide.effect(function()
		v()
		if first then -- effects run once on creation, observers must not
			first = false
			return
		end
		n += 1
	end)
	const e = timeFunction()
	return e - s
end

function Benchmarks.UnseeObserver(self: Benchmarks): number
	-- N/A: an effect cannot be detached without destroying its scope
	return 0
end

function Benchmarks.WriteSourceWithNObservers(self: Benchmarks, nObservers: number?): number
	const v = Vide.source(0)
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0
	for i = 1, no do
		local first = true
		Vide.effect(function()
			v()
			if first then
				first = false
				return
			end
			n += 1
		end)
	end

	const s = timeFunction()
	v(1)
	const e = timeFunction()

	if n ~= no then
		Warn(`[{script.Name}] Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end

function Benchmarks.CreateNObservers(self: Benchmarks, nObservers: number?): number
	const v = Vide.source(0)
	const no = math.max(1, if type(nObservers) == `number` then nObservers else 1)
	local n = 0

	const s = timeFunction()
	for i = 1, no do
		local first = true
		Vide.effect(function()
			v()
			if first then
				first = false
				return
			end
			n += 1
		end)
	end
	const e = timeFunction()

	v(1)

	if n ~= no then
		Warn(`[{script.Name}] Not all observers have captured the write. {no} expected, {n} captured`)
	end
	return e - s
end

function Benchmarks.UnseeNObservers(self: Benchmarks, nObservers: number?): number
	-- N/A: see UnseeObserver
	return 0
end



function Benchmarks.CreateDerive(self: Benchmarks): number
	const a = Vide.source(0)
	const b = Vide.source(0)
	const s = timeFunction()
	const v = Vide.derive(function()
		return a() + b()
	end)
	const e = timeFunction()
	return e - s
end

function Benchmarks.ReadDerive(self: Benchmarks): number
	const a = Vide.source(3)
	const b = Vide.source(4)
	const v = Vide.derive(function()
		return a() + b()
	end)
	const s = timeFunction()
	const _a = v()
	const e = timeFunction()

	const got = v()
	const expected = a() + b()
	if got ~= expected then
		Warn(`[{script.Name}] Derive did not initialize value correctly. Expected {expected}, got {got}`)
	end

	return e - s
end

function Benchmarks.RecomputeDerive(self: Benchmarks): number
	const a = Vide.source(3)
	const b = Vide.source(4)
	const v = Vide.derive(function()
		return a() + b()
	end)
	const s = timeFunction()
	b(1)
	const e = timeFunction()

	const got = v()
	const expected = a() + b()
	if got ~= expected then
		Warn(`[{script.Name}] Derive did not recompute or wrong. Expected {expected}, got {got}`)
	end

	return e - s
end

function Benchmarks.DestroyDerive(self: Benchmarks): number
	-- N/A: Vide derives cannot be destroyed individually
	return 0
end

function Benchmarks.CreateDeriveWithNDependencies(self: Benchmarks, nDependencies: number?): number
	const no = math.max(1, if type(nDependencies) == `number` then nDependencies else 1)
	const deps: {Vide.Source<number>} = {}
	for i = 1, no do
		table.insert(deps, Vide.source(i))
	end

	const s = timeFunction()
	const v = Vide.derive(function()
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
		Warn(`[{script.Name}] Derive did not initialize value correctly. Expected {expected}, got {got}`)
	end

	return e - s
end

function Benchmarks.RecomputeDeriveWithNDependencies(self: Benchmarks, nDependencies: number?): number
	const no = math.max(1, if type(nDependencies) == `number` then nDependencies else 1)
	const deps: {Vide.Source<number>} = {}
	for i = 1, no do
		table.insert(deps, Vide.source(i))
	end

	const v = Vide.derive(function()
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
		Warn(`[{script.Name}] Derive did not recompute or wrong. Expected {expected}, got {got}`)
	end

	return e - s
end

function Benchmarks.RecomputeDeriveSwitch(self: Benchmarks): number
	const a = Vide.source(1)
	const b = Vide.source(0)
	const c = Vide.source(true)
	const v = Vide.derive(function()
		if c() then
			return a()
		end
		return b()
	end)
	local changesObserved: number = 0
	local first = true
	Vide.effect(function()
		v()
		if first then
			first = false
			return
		end
		changesObserved += 1
	end)

	-- no recomputation expected
	const s1 = timeFunction()
	b(-1)
	const e1 = timeFunction()
	if changesObserved > 0 then
		Warn(`[{script.Name}] Derive recomputed without a reason [#1].`)
	end

	-- recomputation expected
	const s2 = timeFunction()
	a(2)
	const e2 = timeFunction()
	if v() ~= a() then
		Warn(`[{script.Name}] Derive did not recompute or wrong, but was expected to [#1].`)
	end

	-- recomputation expected
	const s3 = timeFunction()
	c(false)
	const e3 = timeFunction()
	if v() ~= b() then
		Warn(`[{script.Name}] Derive did not recompute or wrong, but was expected to [#2].`)
	end

	-- no recomputation expected
	const s4 = timeFunction()
	a(-1)
	const e4 = timeFunction()
	if changesObserved > 2 then
		Warn(`[{script.Name}] Derive recomputed without a reason [#2].`)
	end

	-- recomputation expected
	const s5 = timeFunction()
	b(1)
	const e5 = timeFunction()
	if v() ~= b() then
		Warn(`[{script.Name}] Derive did not recompute or wrong, but was expected to [#3].`)
	end

	return (e1 - s1)
		+ (e2 - s2)
		+ (e3 - s3)
		+ (e4 - s4)
		+ (e5 - s5)
end

function Benchmarks.CreateDeriveChain(self: Benchmarks): number
	const a = Vide.source(3)
	local last: () -> number = a
	const s = timeFunction()
	for i = 1, 1000 do
		const prev = last
		last = Vide.derive(function()
			return prev() -- we cant just use last, because it's a reference
		end)
	end
	const e = timeFunction()

	if last() ~= a() then
		Warn(`[{script.Name}] Derive did not initialize value correctly. Expected {a()}, got {last()}`)
	end

	return e - s
end

function Benchmarks.RecomputeDeriveChain(self: Benchmarks): number
	const a = Vide.source(3)
	local last: () -> number = a
	for i = 1, 1000 do
		const prev = last
		last = Vide.derive(function()
			return prev() -- we cant just use last, because it's a reference
		end)
	end
	const s = timeFunction()
	a(1)
	const e = timeFunction()

	if last() ~= a() then
		Warn(`[{script.Name}] Derive did not recompute or wrong. Expected {a()}, got {last()}`)
	end

	return e - s
end

function Benchmarks.RecomputeNDerive(self: Benchmarks, nValues: number?): number
	const a = Vide.source(3)
	const no = math.max(1, if type(nValues) == `number` then nValues else 1)
	for i = 1, no do
		Vide.derive(function()
			return a()
		end)
	end

	const s = timeFunction()
	a(1)
	const e = timeFunction()

	return e - s
end

table.freeze(Benchmarks)
export type Benchmarks = typeof(Benchmarks)
return Benchmarks