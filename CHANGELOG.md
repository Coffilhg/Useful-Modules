# v1.0.5
- Made all string and default library calls "obvious" to the compiler (according to **[https://luau.org/performance/#specialized-builtin-function-calls](<https://luau.org/performance/#specialized-builtin-function-calls>)**: "so calling `string.byte` is more efficient than `s:byte`")
- Improved `TostringColor3` - now capable of optimizing `Color3:ToHex()` values and `FromstringColor3` - now in full parity with `Color3.fromHex()` allowing 3 or 6 digit hexadecimals, with or without `#` at the start + redundant pcall removed
- Detection of the Encoded values is now faster - instead of `string.match`'ing the `PrefixMatchPattern`, it now does a `string.sub` to confirm the start mathces `EncodePrefix`, then `string.byte` to make sure the **Minified Roblox Datatype prefix code** is present, lastly `string.byte` to confirm second next character is `(` (`40`), confirming the following structure: `{EncodePrefix}{T - Minified Roblox Datatype prefix code}(`
- `TryDecode` now expects a **number** received from `string.byte` as the `datatype` argument. Also fixed "Content" detection to it's Minified Roblox Datatype prefix code defined in the top comment. All of `RobloxDatatypeCallbacksDecode` keys now wrapped in `string.byte`. Yet it's all still compatible with the previous versions!

# v1.0.4
- Optimized the code by adding `local` keyword everywhere it was missing and romoved all `pairs`/`ipairs`
- Added `table.freeze` on the module table to make it secure and read-only
- Fixed a typo in `CoffeeParser` type definition
- Global variables are now all in PascalCase
- Optimized `Round`

# v1.0.3
- Added `SupportedTypes` lookup table for runtime type validation.
- Added `SupportedTypesDebugMessage` for convenient debug output.
- For use example of the two above, see CoffeeObjects@2.3.3 or later.
> (The two were actually just a result of moving some logic from CoffeeObjects after it already became dependent on the CoffeeParser)

# v1.0.2
- `wally-package-types` doesn't recognise **const** keyword
- all **const** keyword usage cases replaced with **local**

# v1.0.1
- Hotfix precisionFormatter variable was missing
- Better **[compare.luau](tests/compare.luau)**
- Updated on Wally

# v1.0.0

## CoffeeParser Release ~ Wally Publish
- More optimized Decode behavior
- Constant variables now use const keywprd for declaration
- Compatible with the prefious version.
- First version published to Wally.

---

# v0.9.5

## CoffeeParser Alpha ~ Minify the datatype prefix codes
- Encode now uses 1 byte long characters instead of a full Datatype name
- Those characters can be seen in a dictionary comment on top (search for: `--	Minified Roblox Datatype prefix codes:`)
- This will allow for more optimized and predictable Decode behavior
- Incompatible with data Encoded in previous version - Encoded data of previous version can't be reliably Decoded with this version.