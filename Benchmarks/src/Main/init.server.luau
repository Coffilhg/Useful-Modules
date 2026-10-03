--!strict
--!optimize 2
-- warm up before launching benchmark

print(`Running`)

-- if it isn't running make sure the RunContext is "Server";
-- "Legacy" does not run inside of ReplicatedStorage

for i = 1, 100_000_000 do
	if i % 100_000 == 0 then
		print(`Warming up {i/100_000_000}`)
		task.wait()
	end
end

const _a = require(`./Reactivity.bench`)
warn(`Done running all benchmarks. {_a}`)