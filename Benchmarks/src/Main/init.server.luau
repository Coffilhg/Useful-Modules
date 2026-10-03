--!strict
--!optimize 2
-- warm up before launching benchmark

print(`Running`)

-- if it isn't running make sure the RunContext is "Server";
-- "Legacy" does not run inside of ReplicatedStorage

for i = 1, 100_000_000 do
	if i % 100_000 == 0 then
		const p = i/100_000_000
		if p <= 0.5 or p == 1 then
			print(`Warming up {p}`)
			if p == 0.5 then
				print(`No more spam - clear the output now and wait!`)
			end
		end
		task.wait()
	end
end

const Benchmark = require(`./Reactivity.bench`)
-- Benchmark can be launched as a function.
-- The first argument mast be the result of
-- requiring a module with compatible api.
-- optionally, a root or whatever kind of mount can
-- be created and be used as a wrap here, instead of
-- creating and tearing down one per every single
-- small measurement. (e.g. Reaction does not require
-- that, but Vide does, for Derive values)



--Benchmark(require(`./Reactivity.bench/Reaction`), `[Reaction] `)

--const Vide = require(`./Packages/Vide`)
--Vide.root(function()
--	Benchmark(require(`./Reactivity.bench/Vide`), `[Vide] `)
--end)

Benchmark(require(`./Reactivity.bench/Vision`), `[Vision] `, {
	medium = 100
})