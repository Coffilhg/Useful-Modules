# v0.0.0

- Added `isBrPreserved` argument, `false` by default - treats all `<br>` and like tags as usual text to apply gradient to, effectively saving you from it breaking the RichText formatting by Roblox. If you want to keep it however, pass `true` and enjoy seeing the plain text full of `<font color=...>` tags for every character!
- Stack will search nearest instead of oldest tag to be closed.
- Cases with multiple keypoints at the same time (especially at `0` producing NaN) are now handled.
- Added RawAPI for access to the Raw API - only use it if you know what you're doing (and made some of the types exported to comply with this addition)
- Minor changes like unified logic for grapheme pushing, all variables declared as `local`/`const`, etc.

# pre-publish

- first ever publicly revealed at https://github.com/Coffilhg/Useful-Modules/blob/ServerMessages/src/ServerMessages.luau
- later rescripted to use `utf8.graphemes` and easier to understand + minor ai assistance to prevent edge cases appears at https://github.com/Coffilhg/CoffeeMixer/blob/main/src/Main/RichGradient.luau