--[[--
    Reaction V1.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/Reaction
    Stars are appreciated!
--]]--

--!strict
--!optimize 2

const Reaction = {}
const Reactions: {[V<Vt>]: El} = {}
const Cells: {[V<Vt>]: {[number]: {pos: number?}}} = {}
const HyperReactions: {[thread]: {[V<Vt>]: true}} = {} -- internal, read&write reactions
const Cleanups: {[V<Vt>]: () -> ()} = {}
const DestroyedFn = function() end

type Vt = any
export type V<T> = (T?, true?) -> (T)
type Ou = () -> () --Observer: unsee
type E<T> = (T, true?) -> () -- Event (or can also be called a reaction)
type El = {[number]: E<Vt>} -- Event List

-- Value ("Source")
const function V<T>(val: T | Vt): V<T>
	const reactions: El = {}

	const function value(...)
		const hyperReactions = HyperReactions[coroutine.running()]

		if type(hyperReactions) == `table` then
			hyperReactions[value] = true
		end

		if select(`#`, ...) > 0 then
			val = select(1, ...)
			const snapshot = table.clone(reactions)
			for _, reaction in snapshot do
				reaction(val)
			end
		end
		return val
	end

	Reactions[value] = reactions
	Cells[value] = {}

	return value
end
Reaction.V = V

-- remove Value (":Destroy Source")
const function rmV<T>(V: V<T>)
	const cleanup = Cleanups[V]
	if type(cleanup) == `function` then
		cleanup()
	end
	Cleanups[V] = nil

	const reactions: El = Reactions[V]
	if type(reactions) == `table` then
		const val = V()

		const snapshot = table.clone(reactions)
		for _, reaction in snapshot do
			reaction(val, true)
		end
	end

	Reactions[V] = nil
	-- Cells must be always nil'lified after Reactions
	Cells[V] = nil
end
Reaction.rmV = rmV

-- if Value (returns whether you can still use (add new) observers on the value)
const function ifV<T>(V: V<T>): boolean
	return type(Reactions[V]) == `table`
end
Reaction.ifV = ifV

-- fi Value (returns whether you the value was removed ("Destroyed") using rmV)
-- why does this exist? So that you won't have to do `not Reaction.ifV` (not is
-- an additional operation and this module aims to be as fast&memory efficient as possible)
const function fiV<T>(V: V<T>): boolean
	return type(Reactions[V]) ~= `table`
end
Reaction.fiV = fiV

-- Observe ("Effect")
-- e - event
const function O<T>(V: V<T>, e: E<T>): Ou
	const reactions: El = Reactions[V]
	const cells = Cells[V]

	if type(reactions) ~= `table` then
		return DestroyedFn
	end

	const cell: {pos: number?} = {pos = nil}

	const unsee: Ou = function()
		-- here remove (or swap if ordered)
		--reactions[e] = nil -- unordered
		const pos = cell.pos
		if not pos then
			return
		end
		cell.pos = nil

		const last = #reactions
		if pos ~= last then
			const mvCell = cells[last]
			if mvCell then
				mvCell.pos = pos
			end

			reactions[pos] = reactions[last]
			cells[pos] = mvCell
		end
		reactions[last] = nil
		cells[last] = nil
	end

	-- here add
	--reactions[e] = true -- unordered
	const pos = #reactions + 1
	reactions[pos] = e
	cells[pos] = cell
	cell.pos = pos


	return unsee
end
Reaction.O = O

-- Copy ("Derive")
-- c - copyFn
-- copyFn must never depend on task.spawn'ed (or alike) results unless you yield them
-- and return synchronously (e.g. U can safely use RemoteFunctions, because they yield!)
const function C<T>(c: () -> (T)): V<T>
	const thread = coroutine.running()
	const dependencies: {[V<Vt>]: true} = {}
	HyperReactions[thread] = dependencies
	const initial = c()
	HyperReactions[thread] = nil
	const value = V(initial)

	const heads = {}
	local destroyed = false
	Cleanups[value] = function()
		destroyed = true
		for headOs in heads do
			for oo in headOs do
				oo()
			end
		end
	end

	const function processDeps()
		const Os = {} -- "Observer"s
		heads[Os] = true
		for dependency in dependencies do
			if destroyed then
				break
			end
			dependencies[dependency] = nil
			if fiV(dependency) then
				-- don't create a function closures, if dependency was rmVed
				-- i.e. Reaction.O is still capable of creating an unsee fn
				-- for rmVed Values; This continue prevents that, saves memory
				continue
			end

			local o: Ou
			o = O(dependency, function(_, isDestroyed)
				heads[Os] = nil
				for oo in Os do
					-- oo -> other or this observer
					oo()
				end
				if destroyed or isDestroyed then
					return
				end

				const t = coroutine.running()
				HyperReactions[t] = dependencies
				const i = c()
				HyperReactions[t] = nil
				processDeps(dependencies)
				value(i)
			end)
			Os[o] = true
		end
	end
	processDeps(dependencies)

	return value
end
Reaction.C = C

table.freeze(Reaction)
return Reaction