# v1.1.1

## Types Patch: `V<T>` now infers `T` from its argument
The `| any` (`Vt`) was removed from the `V` parameter, which now matches the signature the README already documents.

Before:
```luau
const function V<T>(val: T | Vt): V<T> -- Vt = any
```
After:
```luau
const function V<T>(val: T): V<T>
```

With `T | any`, the argument never constrained `T`, so `V("Hello World")` was always inferred as `V<unknown>` and you had to cast it (`V("Hello World" :: string)`) to get `V<string>`. Now `V("Hello World")` infers `V<string>` and `V(5)` infers `V<number>` without casts.

> Note: a Roblox Studio type solver bug, where Ctrl+Click (Go to Declaration) on a variable holding a `V` freezes autocomplete and the type solver, is not caused by this signature, and it still reproduces with plain `V<T>(val: T)`. This patch only removes the need for the cast, it doesn't work around that Studio bug. **[More info about the bug and similar bugs](<https://devforum.roblox.com/t/type-solver-checker-breaks-indefinitely-as-it-starts-scanning-huge-scripts-meant-for-data-and-makes-studio-closing-process-infinite/4962659/6#p-15037724-the-first-reason-for-this-has-to-do-with-go-to-declaration-ctrlclick-on-a-variable-that-holds-a-function-value-1>)**

No runtime changes.

---

# v1.1.0

## README now documents how this module works!

## C' Dependencies now reconcile instead of being destroyed & rebuilt from scratch
This speeds up the C recompute times, showing better performance compared to v1.0.0

## Other changes
- More types are now exported: `Ou`, `E<T>`, and `Reaction` (the module itself)
- Added `:Unpack()` method, returning `V, O, C, rmV, ifV, fiV` (all of the public API except the method itself)
- Simplified the exported `V<T>` type by removing its second parameter, this has either no effect or improves the type inference
- Added a comment explaining the inferred Observer parameter type.
> I've tried to make the type solver infer the type for the callback and it just didn't work at all. Making it work might sacrifice speed, simplicity and structure that there already is. Just add a `:` after the value parameter and the autocomplete suggests the correct type as the first option!

---

# v1.0.0

## Initial publish