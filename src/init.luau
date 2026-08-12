--[[--
    Arrangement V2.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/Arrangement
    Stars are appreciated!
--]]--
--!strict
--!optimize 2

local Arrangement = {}

type ArrangementKey = any
type ArrangementId = number

type Arrangements = {[ArrangementKey]: ArrangementId}
type ReverseArrangements = {[ArrangementId]: ArrangementKey}

type GetKeyByIndexMethod<self> = (self: self, index: ArrangementId) -> (ArrangementKey?)
type RemoveArrangementByKeyMethod<self> = (self: self, key: ArrangementKey) -> ()
type RemoveArrangementByIndexMethod<self> = (self: self, index: ArrangementId) -> ()

type MethodNames = "GetKeyByIndex" | "RemoveArrangementByKey" | "RemoveArrangementByIndex"
type ArrangementMethods<self> = GetKeyByIndexMethod<self> | RemoveArrangementByKeyMethod<self> | RemoveArrangementByIndexMethod<self>

-- type solver is not ready for this...
--[=[--
type _a = {}
type _r = {}
export type Arrangement = setmetatable<{
	read _a: setmetatable<_a, {
		__index: (self: _r, key: ArrangementKey) -> (ArrangementId),
		__newindex: (self: _a, key: ArrangementKey, value: any) -> (),
	}>,
	read _r: setmetatable<_r, {
		__index: (self: _r, index: ArrangementId) -> (ArrangementKey?),
	}>,
}, {
	read GetKeyByIndex: GetKeyByIndexMethod<Arrangement>,
	read RemoveArrangementByKey: RemoveArrangementByKeyMethod<Arrangement>,
	read RemoveArrangementByIndex: RemoveArrangementByIndexMethod<Arrangement>,
	read __index: (
		self: Arrangement,
		key: ArrangementKey | MethodNames
	) -> (
		ArrangementId | ArrangementMethods<Arrangement>
	),
	read __newindex: (self: Arrangement, key: ArrangementKey, value: any) -> (),
}>
--]=]--

export type ArrangementV2 = { -- a simpler definition of Arrangement (above)
	read _a: {
		[ArrangementKey]: ArrangementId,
	},
	read _r: {
		read [ArrangementId]: ArrangementKey,
	},
	read GetKeyByIndex: GetKeyByIndexMethod<ArrangementV2>,
	read RemoveArrangementByKey: RemoveArrangementByKeyMethod<ArrangementV2>,
	read RemoveArrangementByIndex: RemoveArrangementByIndexMethod<ArrangementV2>,
	[ArrangementKey]: ArrangementId,
}



local ArrangementMetatable = {}
function ArrangementMetatable.__index(
	self: ArrangementV2,
	key: ArrangementKey | MethodNames
): ArrangementId | ArrangementMethods<ArrangementV2>
	local Method = rawget(ArrangementMetatable, key)
	if Method then
		return Method :: ArrangementMethods<ArrangementV2>
	end
	
	return self._a[key] :: ArrangementId
end
function ArrangementMetatable.__newindex(self: ArrangementV2, key: ArrangementKey, value: any)
	if value ~= nil then
		return
	end

	self:RemoveArrangementByKey(key)
end
function ArrangementMetatable.GetKeyByIndex(self: ArrangementV2, index: ArrangementId): ArrangementKey?
	return self._r[index]
end
function ArrangementMetatable.RemoveArrangementByKey(self: ArrangementV2, key: ArrangementKey)
	if key == nil then -- exception [nil] is always tied to 0 (by imagination, so it doesn't actually use memory)
		return
	end
	
	self._a[key] = nil
end
function ArrangementMetatable.RemoveArrangementByIndex(self: ArrangementV2, index: ArrangementId)
	if index == 0 then -- exception 0 is always tied to [nil] (by imagination, so it doesn't actually use memory)
		return
	end
	
	self:RemoveArrangementByKey(self:GetKeyByIndex(index))
end
table.freeze(ArrangementMetatable)




function Arrangement.new()
	local count: number = 0
	local arrangements: Arrangements = {} -- [key] = number; arrangements
	local reverseArrangements: ReverseArrangements = {} -- [number] = key; reversed (arrangements reversed to be an array)
	
	local WriteProxyToArrangements = setmetatable(
		{},
		{
			__index = function(_, key: ArrangementKey): ArrangementId
				-- We can't run `arrangements[nil] = index`
				-- it errors with "table index is nil", so
				-- ArrangementKey [nil] is an exception and always 0
				if key == nil then
					return 0
				end
				
				local index: ArrangementId? = arrangements[key]
				if index == nil then
					count += 1
					index = count
					
					reverseArrangements[index] = key
					arrangements[key] = index
				end
				return index :: ArrangementId
			end,
			__newindex = function(_, key: ArrangementKey, value: any)
				-- you can only wipe values to free up memory
				-- You must be sure nothing in the game uses (remembers)
				-- this key-number pair, otherwise expect
				-- hard to track bugs
				if value ~= nil then
					return
				end
				
				local index = arrangements[key]
				if index then
					reverseArrangements[index] = nil
					arrangements[key] = nil
				end
			end,
		}
	)
	local ReadProxyToReverseArrangements = table.freeze(setmetatable(
		{},
		{
			__index = function(_, index: ArrangementId): ArrangementKey?
				if index == 0 then
					return nil
				end
				return reverseArrangements[index]
			end,
		}
	))
	
	local self = {
		_a = WriteProxyToArrangements,
		_r = ReadProxyToReverseArrangements,
	}
	setmetatable(self, ArrangementMetatable)
	table.freeze(self)
	
	return self :: ArrangementV2
end

table.freeze(Arrangement)

return Arrangement