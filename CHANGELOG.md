# v0.2.0
Applies to all three packages (CreateInstance, CreateInstanceCoffee, CreateInstanceReaction).

### Added
- `Apply(instance)(props)`: the same as `Create`, but applies the props to an Instance that already exists, of any class (creatable or not, e.g. `workspace` or a `PlayerGui`). Its props are typed from the Instance's own type, so it needs no ClassName list at all. It was originally duplicated to comply with types, but we cast them at the end so it was smart to deduplicate it;
- `Properties` (the type function behind the props autocomplete) is now exported: `CreateInstance.Properties<Part>` (during previous release exporting type functions was not implemented in luau)
- New dependency: **[ClassNameTypePairsClientInGameCreatableExtended](<https://github.com/Coffilhg/ClassNameTypePairsClientInGameCreatableExtended>)** (`@*`)

### Changed
- `Create`'s className autocomplete (and its returned type) now come from ClassNameTypePairsClientInGameCreatableExtended, so it only shows ClassNames that `Instance.new` accepts (constrained to only client-side in-game), instead of all ~920 ClassNames (most of them abstract classes and services that error in `Instance.new`).
- `Create(className)` is now `Apply(Instance.new(className))`, so every package has a single props loop.
- `:Unpack()` now returns `Create, Apply`
- CreateInstanceReaction: Reaction version update `1.1.0` -> `1.1.1` (`V("text")` now infers `V<string>` without a cast)

### Removed
- The ClassNameTypePairs dependency, now replaced by ClassNameTypePairsClientInGameCreatableExtended. `Create` only needs the creatable ClassNames, and `Apply` takes its types from the Instance itself.
> A `ClassTypeOf` type function that looked the ClassName up in both CNTPs was tried during development and dropped before release: the type solver reduced `Properties<ClassTypeOf<...>>` to `never`, so a wrong prop only showed *"`{ Anchored: number }` is not a subtype of `never`"* instead of naming the property.
>
> **Verdict:** plain `index<CreatableClassNames, ClassNameGeneric>` it is.
- `CreateMissing` superseeded by Apply (different behaviour however); It's still possible to make your own CreateMissing:
```luau
-- Whether to use the list of all class names - CNTP, or only client in game creatable class names - CCI is up to you
type ClassNames = CNTP.ClassNameTypePairs
type ClassName = keyof<ClassNames>

type CreateMissing = (Instance?) -> <ClassNameGeneric>(ClassNameGeneric | ClassName | "") -> (
	-- which CreateInstance Variant is used is up to you
	(CreateInstance.Properties<index<ClassNames, ClassNameGeneric>>) -> index<ClassNames, ClassNameGeneric>
)

const CreateMissing = function(existing: Instance?)
	const function create(className: string) -- Actual type is `ClassNameGeneric | ClassName | ""`
		const isValid: boolean = typeof(existing) == `Instance` and existing.ClassName == className
		const instance: Instance = if isValid then existing :: Instance else Instance.new(className)
		-- whether to apply either way or only if not isValid is up to you
		if isValid then
			return function()
				return instance
			end
		end
		-- which CreateInstance Variant is used is up to you
		return CreateInstance.Apply(instance)
	end
	return create
end :: CreateMissing
-- easiest way to make this typed and work is by typecasting

CreateMissing(game.Workspace)("Workspace") {
	-- would error if Workspace is missing btw (cuz Instance.new("Workspace") errors)
}
```

---

# v0.1.1
## No changes to the code
## Dependency indexing patch for rotriever
(wally works fine with v0.1.0 and is same as v0.1.1)

# v0.1.0
## Initial Release
## Rotriever packages have turned out to index ClassNameTypePairs dependency wrong