# v0.0.1

- Patched the Default apperance not being applied at init because `:ApplyAppearance` is lazy ~ added arguments to force;
- Found the cause of ``Type Error: (1,1) Type inference failed to complete, you may see some confusing types and type errors.`` and fixed it, the fix was changing ([More info and why](<https://github.com/luau-lang/luau/issues/2663>)):
    ```luau
    local function EvaluateActiveAppearanceType(self: GreatUIButton) : AppearanceType
        if self.isHolding then
            return `Press`
        elseif self.isHovering then
            return `Hover`
        end
        return `Default`
    end
    ```
    to
    ```luau
    local function EvaluateActiveAppearanceType(self: GreatUIButton) : AppearanceType
        local isHolding, isHovering = self.isHolding, self.isHovering
        if isHolding then
            return `Press`
        elseif isHovering then
            return `Hover`
        end
        return `Default`
    end
    ```

# v0.0.0

Initial release, this is Zer0Ver!