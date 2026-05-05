# v1.0.0
- Hotfix precisionFormatter variable was missing
- Better **[compare.luau](tests/compare.luau)**

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