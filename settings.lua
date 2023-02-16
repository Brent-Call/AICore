data:extend({
--Determines to which precision numbers in the AI Cores GUI will be displayed.
--Each player can change their individual setting at any time.
{
	type = "int-setting",
	name = "Q-AICore:decimal-places-to-show",
	setting_type = "runtime-per-user",
	default_value = 3,
	allowed_values = { 1, 2, 3, 4, 5, 6, 7, 8 }
},
--Multiplies the strength of the bonus from AI Cores.
--Affects all forces on the map.
{
	type = "int-setting",
	name = "Q-AICore:ai-core-bonus-multiplier",
	setting_type = "runtime-global",
	default_value = 10,
	minimum_value = 1,
	maximum_value = 100
}
})