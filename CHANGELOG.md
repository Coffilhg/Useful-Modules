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