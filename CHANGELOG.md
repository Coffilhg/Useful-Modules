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