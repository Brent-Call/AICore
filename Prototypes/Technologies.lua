--All prototypes in this mod will be given a prefix to differentiate them from other modded prototypes.
--The rest of the name of any given prototype will use the same naming conventions as vanilla Factorio.
data:extend({
--=====================================================--
--         TECHNOLOGY TO UNLOCK AI CORES
--=====================================================--
{
	type = "technology",
	name = "Q-AICore:ai-core",
	icon = "__AICore__/Graphics/Technologies/ai-core.png",
	icon_size = 256,
	effects =
	{
		{ type = "unlock-recipe", recipe = "Q-AICore:ai-core" }
	},
	prerequisites = { "research-speed-5", "effectivity-module-3", "solar-energy", "utility-science-pack" },
	unit =
	{
		count = 3000,
		ingredients =
		{
			{ "automation-science-pack", 1 },
			{ "logistic-science-pack", 1 },
			{ "chemical-science-pack", 1 },
			{ "production-science-pack", 1 },
			{ "utility-science-pack", 1 }
		},
		time = 20
	}
},
--=====================================================--
--        TECHNOLOGY TO INCREASE ALGORITHM LEVEL
--=====================================================--
{
	type = "technology",
	name = "Q-AICore:p-equals-np",
	icon = "__AICore__/Graphics/Technologies/turing-machine.png",
	icon_size = 256,
	effects =
	{
		{ type = "nothing", effect_description = { "technology-effects.ai-core-algorithm-effectivity" }}
	},
	prerequisites = { "Q-AICore:ai-core", "space-science-pack" },
	unit =
	{
		count = 3000,
		ingredients =
		{
			{ "automation-science-pack", 1 },
			{ "logistic-science-pack", 1 },
			{ "chemical-science-pack", 1 },
			{ "production-science-pack", 1 },
			{ "utility-science-pack", 1 },
			{ "space-science-pack", 1 }
		},
		time = 120
	}
},
--===========================================================--
--        DUMMY TECHNOLOGIES TO TEST MOD FUNCTIONALITY
--===========================================================--
--[[
{
	--This technology exists exclusively to test whether or not laboratory productivity works as it should.
	type = "technology",
	name = "Q-AICore:dummy-test-0",
	icon = "__core__/graphics/questionmark.png",
	icon_size = 64,
	effects =
	{
		{ type = "laboratory-speed", modifier = 0.1 },
		{ type = "laboratory-productivity", modifier = 0.5 }
	},
	prerequisites = {},
	unit =
	{
		count = 1,
		ingredients =
		{
			{ "automation-science-pack", 1 },
		},
		time = 1
	}
},
{
	--This technology exists exclusively to test whether or not laboratory productivity works as it should.
	type = "technology",
	name = "Q-AICore:dummy-test-1",
	icon = "__core__/graphics/questionmark.png",
	icon_size = 64,
	effects =
	{
		{ type = "laboratory-productivity", modifier = 0.2 }
	},
	prerequisites = {},
	unit =
	{
		count = 1,
		ingredients =
		{
			{ "automation-science-pack", 1 },
		},
		time = 1
	}
},
{
	--This technology exists exclusively to test whether or not laboratory productivity works as it should.
	type = "technology",
	name = "Q-AICore:another-dummy-test",
	icon = "__core__/graphics/questionmark.png",
	icon_size = 64,
	effects =
	{
		{ type = "nothing", effect_description = { "technology.nothing" }},
		{ type = "laboratory-productivity", modifier = 1 },
		{ type = "nothing", effect_description = { "technology.nothing" }},
		{ type = "nothing", effect_description = { "technology.nothing" }},
		{ type = "laboratory-productivity", modifier = 1 },
		{ type = "nothing", effect_description = { "technology.nothing" }},
		{ type = "nothing", effect_description = { "technology.nothing" }},
		{ type = "laboratory-productivity", modifier = 1 }
	},
	prerequisites = {},
	unit =
	{
		count = 1,
		ingredients =
		{
			{ "automation-science-pack", 1 },
		},
		time = 1
	}
}
--]]
})