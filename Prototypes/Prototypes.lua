--All prototypes in this mod will be given the prefix "Q-AICore:" to differentiate them from all other prototypes.
--The rest of the name of any given prototype will use the same naming conventions as vanilla Factorio.

--This function returns the ingredients needed to craft an AI Core in normal mode:
local function make_ai_core_ingredients_normal()
	local retVal = 
	{
		{ "lab", 5 },
		{ "low-density-structure", 50 },
		{ "processing-unit", 100 },
		{ "battery", 6 },
		{ "effectivity-module-3", 1 }
	}

	return retVal
end

--This function returns the ingredients needed to craft an AI Core in marathon mode:
local function make_ai_core_ingredients_expensive()
	local retVal = 
	{
		{ "lab", 7 },
		{ "low-density-structure", 70 },
		{ "processing-unit", 110 },
		{ "battery", 10 },
		{ "effectivity-module-3", 1 }
	}

	return retVal
end

data:extend({
{
	type = "electric-energy-interface",
	name = "Q-AICore:ai-core",
	icon = "__AICore__/Graphics/Items/ai-core.png",
	icon_size = 64,
	flags = { "placeable-player", "player-creation", "not-rotatable" },
	minable = { mining_time = 1, result = "Q-AICore:ai-core" },
	
	--Make this a high priority target for enemies:
	is_military_target = true,
	allow_run_time_change_of_is_military_target = true,

	--Energy source info:
	energy_source =
	{
		type = "electric",
		emissions_per_minute = 0,
		render_no_power_icon = true,
		render_no_network_icon = true,
		usage_priority = "secondary-input", --Same prioity as most other machines in the factory
		
		buffer_capacity = "2.5MJ",
		input_flow_limit = "500kW", --Takes 5 sec to fill up buffer entirely
		                            --This is long enough that even if the game is at max number of forces (64) if we update
							   --every 4 ticks then the buffer will not be completely full by the time of next update.
		output_flow_limit = "0W"
	},

	--Health & resistances info:
	max_health = 900,
	repair_speed_modifier = 0.5,
	dying_explosion =
	{
		{ name = "big-explosion", offset = { 2, -1.75 }},
		{ name = "big-explosion", offset = { -1, 0 }},
		{ name = "medium-explosion", offset = { 1.5, 3 }}
	},
	loot =
	{
		{ item = "low-density-structure", count_min = 3, count_max = 20 },
		{ item = "processing-unit", probability = 0.2, count_min = 1, count_max = 3 }
	},
	corpse = "medium-remnants",
	hit_visualization_box = {{ -2, -2, }, { 2,2 }},
	resistances =
	{
		{ type = "fire", percent = 60 },
		{ type = "explosion", percent = 20 },
		{ type = "impact", decrease = 6, percent = 20 },
		{ type = "acid", decrease = 3, percent = 40 },
		{ type = "electric", percent = -50 },
		{ type = "laser", decrease = 2 }
	},

	--The AI Core is a 7x7 entity.
	collision_box = {{ -3.2, -3.2 }, { 3.2, 3.2 }},
	selection_box = {{ -3.5, -3.5 }, { 3.5, 3.5 }},

	--Use the same sounds that the lab uses:
	open_sound = data.raw.lab[ "lab" ].open_sound,
	close_sound = data.raw.lab[ "lab" ].close_sound,

	picture =
	{
		layers =
		{
			{
				filename = "__AICore__/Graphics/Entities/ai-core-shadow.png",
				draw_as_shadow = true,
				width = 119,
				height = 161,
				shift = util.by_pixel( 112 + 61/2, 62/2 ),
				hr_version = nil
			},
			{
				filename = "__AICore__/Graphics/Entities/ai-core.png",
				width = 224,
				height = 224,
				hr_version = nil
			},
--This type of entity (electric-energy-iterface) does not currently support apply_runtime_tint, so we'll disable this for now
--[[
			{
				filename = "__AICore__/Graphics/Entities/ai-core-runtime-color-mask.png",
				apply_runtime_tint = true,
				width = 224,
				height = 224,
				hr_version = nil
			},
--]]
			{
				filename = "__AICore__/Graphics/Entities/ai-core-glow.png",
				draw_as_glow = true, --Will glow at night even if AI Core isn't powered.
				                     --Not realistic, but works for now.
				width = 224,
				height = 224,
				hr_version = nil
			}
		}
	},

	--Map coloring:
	friendly_map_color = { r = 0.19, g = 0.56, b = 0.75 }, --Slightly lighter blue than default
	enemy_map_color = { r = 1, g = 0.2, b = 0.2 }, --Slightly lighter red than default

	--Causes the AI Core to remove some, but not all, decoratives when placed:
	remove_decoratives = "true"
},
{
	type = "item",
	name = "Q-AICore:ai-core",
	icon = "__AICore__/Graphics/Items/ai-core.png",
	icon_size = 64,
	subgroup = data.raw.item[ "lab" ].subgroup,
	order = "z",
	place_result = "Q-AICore:ai-core",
	stack_size = 10
},
{
	type = "recipe",
	name = "Q-AICore:ai-core",
	normal =
	{
		enabled = false,
		energy_required = 6,
		ingredients = make_ai_core_ingredients_normal(),
		result = "Q-AICore:ai-core"
	},
	expensive =
	{
		enabled = false,
		energy_required = 8,
		ingredients = make_ai_core_ingredients_expensive(),
		result = "Q-AICore:ai-core"
	}
}
})