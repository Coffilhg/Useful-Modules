# v1.0.4

- `IsFinished` now uses the built-in `FuzzyEq` method for `Vector2`, `Vector3` and `CFrame`. The previous implementation of `IsFinished` did not work properly for `CFrame` and this change is primarily aimed to fix that.
- `SetEPSILON` now clamps its input to `0 <= EPSILON <= 0.1` (`math.min(math.abs(newEPSILONValue), 0.1)`), since the built-in `FuzzyEq` would error with `"The eps value provided to FuzzyEq should be a small positive value <= 0.1"` otherwise.
- Methods on SmoothDamperMetatable are now written with the `.(self, ...)` notation instead of `:(...)`; This fixes a type error `Type Error: (79,25) Expected this to be 'a', but got 'number'` where the cause was `self._LastUpdateTime` being inferred as `_LastUpdateTime: a`

# v1.0.3
- Relicense from LGPL 3.0+ (Lesser General Public License version 3 or later) to MPL-2.0

# v1.0.2
- Changed License specification to `LGPL-3.0/?version=3.0+`, so it's compatible with concatenation at the end of `https://choosealicense.com/licenses/` (the way License specification is linked on [wally.run](https://wally.run/) when previewing a package)

# v1.0.1

## LICENSE Changes
- Transfered (Relicense) from Apache-2.0 to LGPL 3.0+ (Lesser General Public License version 3 or later)