# v1.0.1

## Server-Side changes
### One-Time Calls are now possible! (fix of cooldown logic)
e.g. you had a client send a one time hello on join:
```lua
--!strict

local RS = game:GetService(`ReplicatedStorage`)
local Packages = RS:WaitForChild(`Packages`)

local CoffeeRemotes = require(Packages:WaitForChild(`CoffeeRemotesClient`))
local RemoteEvent, RemoteFunction, URemoteEvent = CoffeeRemotes:Unpack()

print(RemoteFunction.new(`Handshake`):InvokeServer())
```

but what if an exploiter did this more times?
```lua
for i = 1, 100 do
	print(RemoteFunction.new(`Handshake`):InvokeServer())
end
```

and then this is how you'd expect it to work on server (this way making it a one-time callable remote per session):
```lua
--!strict

local SSS = game:GetService(`ServerScriptService`)
local SPackages = SSS.ServerPackages

local CoffeeRemotes = require(SPackages.CoffeeRemotesServer)
local RemoteEvent, RemoteFunction, URemoteEvent = CoffeeRemotes:Unpack()

RemoteFunction.new(`Handshake`):SetCooldown(math.huge).OnInvoke = function(player: Player)
	local pName = player.Name
	print(`Player @{pName} (UID = {player.UserId}) seems to have loaded!`)
	return true, {
		`Welcome @{pName}!`
	}
end
```

but this actually wasn't quite the case in 1.0.0 and the max cooldown you could set at any time would be `math.floor(os.clock())`, because *CoffeeRemotesRefined (Server-Side)* uses `os.clock()` to handle cooldowns this way:
```lua
    -- From local function OnInvoke inside RemoteFunction.new
        local lastCallTime = playerEntry[name] or 0
		local now = os.clock()
		if now - lastCallTime < cooldownTime then
			return false, RFER_TooQuick
		end
    -- the code is mirrored to RemoteEventBaseClass too, except
    -- that it does `return` (returns nothing)
```
that can be fixed by just updating the cooldown on the very CoffeeRemoteObject to `math.floor(os.clock())` all of the time, but this is definitely a bad practice.

To fix this, the logic is changed to
```lua
        local lastCallTime = playerEntry[name]-- or 0 --(removed part)
        local now = os.clock()
		if type(lastCallTime) == `number` and now - lastCallTime < cooldownTime then -- added "type(lastCallTime) == `number` and "
			return --false, RFER_TooQuick -- that's only a return for RemoteFunction Class, RemoteEventBaseClass will not return anything as usual
		end
```

this not only makes math.huge cooldowns work as intended to achieve one-time callable remotes per session, but also gives more safety if someone changes the exposed PlayerCooldowns

this change also changes behavior for any cooldown > than current server uptime (`os.clock()`), not just `math.huge`

### Remote Function Exit Reason "PlayerLeft" improvement
Changed ``local RFER_PlayerLeft = IsStudio and {`Player Has Left`} or RFER_TooQuick`` -> ``local RFER_PlayerLeft = IsStudio and {`Player Has Left or the PlayerCooldowns[KindOf][UID] was Wiped`} or RFER_TooQuick``

## Client-Side changes
- Changed the version from 1.0.0 to 1.0.1 for compliance (`Moduleversion` constant changed to `1_0_1` too)