--!nonstrict
--Last update of this example V2.2.0
--automatically defined types only work in --!nonstrict mode.
local CoffeeObjects = require(script.Parent.CoffeeObjects) -- or wherever it's located and whatever it's named

local CoffeeFolder = CoffeeObjects.CoffeeFolder
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

-- explicit object creation and automatically defined type
local Friend = CoffeeFolder.strictNew({
	UID = CoffeeBaseValue.strictNew(456),
	Robux = CoffeeBaseValue.strictNew(1000000),
	Name = CoffeeBaseValue.strictNew("Rich Guy"),
	Friends = CoffeeFolder.strictNew({
		CoffeeFolder.strictNew({
			UID = CoffeeBaseValue.strictNew(789),
			Robux = CoffeeBaseValue.strictNew(0),
			Name = CoffeeBaseValue.strictNew("Dummy"),
		}),
		CoffeeFolder.strictNew({
			UID = CoffeeBaseValue.strictNew(101),
			Robux = CoffeeBaseValue.strictNew(78921),
			Name = CoffeeBaseValue.strictNew("Driver"),
			CarId = CoffeeBaseValue.new(`117`)
		}),
	}),
	CarId = CoffeeBaseValue.new(`51`), -- imagine it might be either a string or number index
})

print(Friend.Friends[1].Robux.Value) -- perfect autocomplete
print(Friend.CarId) -- perfect autocomplete, but Value is not strictly defined - type solver infers it must be one of the Supported types.
print(Friend.Friends[2]) -- autocomplete has no idea there's CarId (because not every member of Friends has a CarId)! we need explicit types! It just sucks with arrays -\_(-_-)_/-


-- explicitly defined type and easier object creation
type CustomUserType = CoffeeObjects.CoffeeFolderStrict<{
	["UID"]: CoffeeObjects.CoffeeBaseValueStrict<number>,
	["Robux"]: CoffeeObjects.CoffeeBaseValueStrict<number>,
	["Name"]: CoffeeObjects.CoffeeBaseValueStrict<string>,
	["Friends"]: CoffeeObjects.CoffeeFolderStrict<{[number]: CustomUserType?}>,
	["CarId"]: CoffeeObjects.CoffeeBaseValueStrict<number | string>,
}>

local User = CoffeeFolder.new({
	UID = 123,
	Robux = 3000,
	Name = "Cool guy",
	Friends = {
		Friend
	},
	CarId = `27`
}) :: CustomUserType

print(User.UID.Value) -- now there is autocomplete for all of the typed keys! yay
print(User.CarId.Value) -- type solver knows this value is number | string! nice

-- same type inference also works for the Signals, such as .Changed:
User.Robux.Changed:Connect(function(oldValue, newValue) -- no need to manually type oldValue : number, newValue : number; Already inferred!
	local delta = newValue - oldValue
	
	if delta == 0 then
		return -- nothing really changed
	end
	
	print(`{User.Name.Value} just {delta > 0 and "earned" or "spent"} {delta} Robux!`)
end)