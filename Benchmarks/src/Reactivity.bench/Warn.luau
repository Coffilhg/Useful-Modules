--!strict
--!optimize 2
const seen = {}

return function(...)
	const message = {}
	for i = 1, select(`#`, ...) do
		table.insert(message, `{select(i, ...)}`)
	end
	const out = table.concat(message, ", ")
	if seen[out] then
        return
    end
    seen[out] = true
    warn(...)
end