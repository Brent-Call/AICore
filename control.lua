--Q's AI Core Mod
--The idea behind this mod is to provide a research productivity bonus from AI Cores.
--This mod has been tested & works correctly for multiple forces across multiple surfaces.
--For forces where research is disabled, the AI Core bonus is fixed at zero.
--This mod is compatible with most other mods that affect research productivity.  ("Probably?  I think."  --Q)
--This mod will react properly if the difficulty settings are changed mid-game.
--A third assumption is that the player won't add or remove technologies that affect research productivity in the middle of a game (it won't cause crashes but it can cause force data objects not to line up with the actual game state)

mod_gui = require( "mod-gui" )
util = require( "util" )
require( "AI_core_debug_GUI" )
require( "AI_core_entity_GUI" )
require( "Console_commands" )

--This watchlist starts each game session empty & is regenerated the first time it's needed.
--It will contain a list of all the names of technologies that have "laboratory-productivity" as an effect.
--Specifically, for a watched technology, the key is the name, and the value is the index in the effects array of the relevant modifier.
techProdWatchlist = nil

--This is the name of the LuaGuiElement representing the AI Core GUI at the topmost level.
TOP_LEVEL_ENTITY_GUI_ELEMENT = "ai-core-GUI"
AI_CORE_ENTITY = "Q-AICore:ai-core"
GUI_CLOSE_BUTTON = "ai-core-GUI-titlebar-close"
PER_PLAYER_PRECISION_SETTING = "Q-AICore:decimal-places-to-show"
GLOBAL_AI_CORES_STRENGTH_SETTING = "Q-AICore:ai-core-bonus-multiplier"

-------------------------------------------------------------------
--     Constants for use in the fomulas in the calculations:     --
-------------------------------------------------------------------

--AI Core base value is raised to this power when calculating productivity bonuses:
--It varies depending on the per-map option "Technology Difficulty"
local NORMAL_DIFFICULTY_EXPONENT = 0.45
local EXPENSIVE_DIFFICULTY_EXPONENT = 0.39
--How many joules of electricity are worth 1 unit of "base val" amount added:
local BASEVAL_PER_ENERGY = 3 / 250000;
--The "base val" decays exponentially by this much each tick.  This has the effect of limiting its maximum value.
local DECAY_RATE = 0.001
--General multiplier to the productivity bonus.  It's based on the decay rate so that if I change one value I still get other values I like.
local SCALING_CONSTANT = 0.01 / ( 0.2 / DECAY_RATE ) ^ NORMAL_DIFFICULTY_EXPONENT
--If the "base val" ever drops below this, just set it to 0:
EPSILON = 10 ^ -3
--The name of the tech to look for in the tech tree whose effect is +1 algorithm level.
--Having other techs that grant +1 algorithm level is currently not supported by this mod's logic.
local TECH_FOR_ALGORITHM_LEVEL = "Q-AICore:p-equals-np"
local AI_CORE_OPEN_SFX_PATH = "entity-open/"..AI_CORE_ENTITY
local AI_CORE_CLOSE_SFX_PATH = "entity-close/"..AI_CORE_ENTITY
--To save computing resources, we only update every this many ticks, & we stagger the forces so we only do 1 at a time:
local UPDATE_INTERVAL = 4

-------------------------------
--     Helper functions:     --
-------------------------------
function update_force_ai_core_bonus( force )
	local forceData = global.forceData[ force.name ]

	if forceData.needsTechRefresh then
		perform_tech_refresh( force )
	end

	--This formula here is the formula for multiplying modifiers:
	force.laboratory_productivity_bonus = ( 1 + forceData.aiCoreProdModifier ) * ( 1 + forceData.techResearchProd ) - 1
end

--Returns a LocalisedString "normal" or "expensive"
--If an error occurred, defaults to normal
--This is not based on the recipe difficulty, this is based on the technology difficulty
function get_technology_difficulty_as_localised_string()
	if game.difficulty_settings.technology_difficulty == defines.difficulty_settings.technology_difficulty.expensive then
		return { "technology-difficulty.expensive" }
	end
	--Else:
	return { "technology-difficulty.normal" }
end

--Returns 0.18 in expensive technology difficulty or 0.39 in normal technology difficulty
function get_ai_core_internal_calculation_exponent()
	if game.difficulty_settings.technology_difficulty == defines.difficulty_settings.technology_difficulty.expensive then
		return EXPENSIVE_DIFFICULTY_EXPONENT
	end
	--Else:
	return NORMAL_DIFFICULTY_EXPONENT
end

--Call this function every few ticks.  This is the function that's the meat of our algorithm.
--It updates the internal values for the AI Cores, then updates the force's productivity modifier based on that.
--It accounts for AI Cores on all existing surfaces.
--For forces where research is disabled, the AI Core bonus is fixed at zero.
function update_internal_values( forceData )
	local force = game.forces[ forceData.forceName ]

	--Only loop through each AI Core if that force has research enabled:
	if force.research_enabled then
		--Number of ticks since we last updated for this force:
		local ticksSinceLastUpdate = UPDATE_INTERVAL * #game.forces
		--This value shows up a few times in the calculations:
		--The D is for Decay rate, and the T is for Time as measured in ticks
		local dt = DECAY_RATE * ticksSinceLastUpdate

		--Amount of baseVal produced since last update:
		local amountAdded = 0

		--NEW VERSION (hopefully faster?)
		for k, v in pairs( global.allAICores ) do
			--One of the keys is "length", so skip that!  Only go with numerical keys, because those values are LuaEntities:
			if type( k ) == "number" then
				if v.valid then
					--We only care about things for OUR force.
					if v.force == force then
						--Add amount added based on energy in the buffer, then remove energy from the buffer:
						amountAdded = amountAdded + v.energy * BASEVAL_PER_ENERGY
						v.energy = 0
					end
				else
					--This table entry is invalid!  Remove it from the list as it's just garbage now.
					--Removing something from a table while iterating is safe, it turns out.
					remove_ai_core( k )
				end
			end
		end


		--Factor in the algorithm level:
		amountAdded = amountAdded * forceData.algorithmLevel

		--Shoutouts to a friend of mine for helping me solve the differential equation to get this.
		--We set the new baseVal to be what we would get after ( UPDATE_INTERVAL * #game.forces ) ticks of continuous production and decay.
		--The math to get to this is a bit complicated as it requires solving a differential equation.
		forceData.baseVal = ( forceData.baseVal - amountAdded / dt ) * math.exp( -dt ) + amountAdded / dt
		
		--Prevent baseVal from getting super small:
		if forceData.baseVal < EPSILON then
			forceData.baseVal = 0
		end
		--Prevent baseVal from ever going negative:
		forceData.baseVal = math.max( 0, forceData.baseVal );
		forceData.aiCoreProdModifier = SCALING_CONSTANT * settings.global[ GLOBAL_AI_CORES_STRENGTH_SETTING ].value * forceData.baseVal ^ global.aiCoreFormulaExponent;
	else
		--Research is disabled for this force, so all accumulated AI Core bonus will be erased.
		forceData.baseVal = 0
		forceData.aiCoreProdModifier = 0
	end

	--Set the laboratory productivity bonus in the LuaForce object according to the modifier from AI Cores:
	update_force_ai_core_bonus( force )
end

--Input a LuaForce to this function.  It returns a number representing the algorithm level (based on researched technologies):
function get_algorithm_level( force )
	--We use some logical operators to convert a boolean into a number:
	return 1 + ( force.technologies[ TECH_FOR_ALGORITHM_LEVEL ].researched and 1 or 0 )
end

--This function loops through all technology prototypes & collects the ones that have "laboratory-productivity" as an effect:
--An implicit assumption is that no technology will have 2 effects of the same type.
--Postcondition: techProdWatchlist is GUARANTEED to be a table
--               Each element of techProdWatchList is a key-value pair where the key is the internal ID of the technology on the watchlist,
--               & the value is the amount of modifier it grants.
function build_tech_prod_watchlist()
	techProdWatchlist = {}
	for techName, techPrototype in pairs( game.technology_prototypes ) do
		--Loop through all effects of this tech & see if it affects lab productivity:
		for _, modifier in pairs( techPrototype.effects ) do
			if modifier.type == "laboratory-productivity" then
				--Create a new entry for this tech if none exists:
				if type( techProdWatchlist[ techName ]) ~= "number" then
					techProdWatchlist[ techName ] = 0
				end
				--Add the effects together.  This way, if a tech has one effect multiple times (don't ask me why that would
				--be the case), it is counted as a single tech with its cumulative effect.
				techProdWatchlist[ techName ] = techProdWatchlist[ techName ] + modifier.modifier
			end
		end
	end
end

--This function is used by the debug GUI to output a list of technologies to look out for:
--Specifically, this one returns the number of elements in the table techProdWatchlist.
--Builds the table if necessary
function get_tech_prod_watchlist_size()
	if type( techProdWatchlist ) ~= "table" then
		build_tech_prod_watchlist()
	end
	--Now, techProdWatchlist is guaranteed to be a table.
	--table_size is a function provided by the Factorio Lua environment, implemented in C++
	return table_size( techProdWatchlist )
end

--This function is used by the debug GUI to output a list of technologies to look out for:
--Specifically, this one returns techProdWatchlist itself.  Builds the table if necessary.
function get_tech_prod_watchlist()
	if type( techProdWatchlist ) ~= "table" then
		build_tech_prod_watchlist()
	end
	--Now, techProdWatchlist is guaranteed to be a table
	return techProdWatchlist
end

--Returns the total laboratory research productivity modifier from all researched technologies.
--Parameters:
--	force--LuaForce
function get_research_productivity_from_technologies( force )
	local totalModifier = 0
	if type( techProdWatchlist ) ~= "table" then
		build_tech_prod_watchlist()
	end
	--At this point, our list is built.

	--Now go through every researched tech for our force & see if it's one we care about, then count!
	for name, modifier in pairs( techProdWatchlist ) do
		if force.technologies[ name ].researched then
			totalModifier = totalModifier + modifier
		end
	end
	return totalModifier
end

--Refreshes the technology state for a forceData object, then sets needsTechRefresh to false.
--Parameters:
--	force--LuaForce
function perform_tech_refresh( force )
	global.forceData[ force.name ].algorithmLevel = get_algorithm_level( force )
	global.forceData[ force.name ].techResearchProd = get_research_productivity_from_technologies( force )
	global.forceData[ force.name ].needsTechRefresh = false
end

--Adds an AI Core to the list that's tracked internally.
--Parameters:
--	aiCore--the LuaEntity corresponding to this AI Core.
function add_ai_core( aiCore )
	if type( aiCore ) ~= "table" then
		error( "Error in add_ai_core( aiCore ): table expected, got "..type( aiCore ))
	end
	if not aiCore.valid then
		error( "Error in add_ai_core( aiCore ): the AI core passed to the function was not valid" )
	end
	if aiCore.name ~= AI_CORE_ENTITY then
		error( "Error in add_ai_core( aiCore ): the entity passed to the function was not an AI core" )
	end


	--Get a unique registration number from the global script object:
	--What's cool is that registration persists through save/load cycles & registration is global among all mods:
	--Yep, & we save a pointer to the AI Core in our global table:
	local regNumber = script.register_on_entity_destroyed( aiCore )
	if global.allAICores[ regNumber ] == nil then
		global.allAICores[ regNumber ] = aiCore
		global.allAICores.length = global.allAICores.length + 1
	end
end

--Removes an AI Core from the list that's tracked internally.
--Parameters:
--	regNumber--the registration number of any LuaEntity that was destroyed.
--			 Notably, when we get a registration number from on_entity_destroyed, we don't have to check
--			 if it's from an AI Core or a biter from another mod, because this algorithm doesn't throw errors
--			 when it tries to delete a nonexistent entry.
function remove_ai_core( regNumber )
	if global.allAICores[ regNumber ] ~= nil then
		global.allAICores[ regNumber ] = nil
		global.allAICores.length = global.allAICores.length - 1
	end
end

---------------------------------
--     Force Data objects:     --
---------------------------------

--These objects store the AI Core values separately.
--The purpose of these is to keep data for each force separate.
--Note that global constants & formula parameters are stored directly in the global table
--Base val: Internal value calculated directly from the AI Cores.
--AI Core prod. modifier: This value is the lab productivity bonus applied to the force.
--Algorithm level: Multiplies how much "base val" each AI Core produces.  Increases with research.
--Tech research prod: This value stores the amount of research productivity gained from technologies.
--Needs tech refresh: If true, we will recalculate the 
--Force name: (string) the name of the LuaForce this table is associated with.  Each force is guaranteed to have a unique name.

--Pass as arguments to this function a the LuaForce representing the actual force itself:
function create_force_data_object( force )
	if type( force ) ~= "table" then
		error( "Error in function create_force_data_object(...): argument passed was of type "..type( force ).." instead of table" )
	end
	return { baseVal = 0, aiCoreProdModifier = 0, algorithmLevel = get_algorithm_level( force ),
		    techResearchProd = get_research_productivity_from_technologies( force ), needsTechRefresh = false, forceName = force.name }
end

--Pass as arguments to this function strings representing the names of the forces involved.
--The function accesses global.forceData to merge source into destination, then delete the source data object.
function merge_force_data_objects( sourceName, destinationName )
	if type( sourceName ) ~= "string" then
		error( "Error in function merge_force_data_objects(...): argument passed was of type "..type( sourceName ).." instead of string" )
	end
	if type( destinationName ) ~= "string" then
		error( "Error in function merge_force_data_objects(...): argument passed was of type "..type( destinationName ).." instead of string" )
	end
	--Add the baseVals together:
	global.forceData[ destinationName ].baseVal = global.forceData[ destinationName ].baseVal + global.forceData[ sourceName ].baseVal
	--aiCoreProdModifier will update in a couple of ticks.  Don't worry about it.
	--algorithmLevel does not change because technologies are NOT copied over when forces change.
	--For that same reason, techResearchProd & needsTechRefresh don't change.
	--Obviously, forceName does not change because forces are not being renamed here.
	global.forceData[ sourceName ] = nil
end

--=========================================================================================================--
--                  AT THE BEGINNING OF THE GAME, INITIALIZE INTERNAL VALUES FOR EACH FORCE
--=========================================================================================================--
--At the beginning of the game, there will be 3 forces: player, neutral, & enemy.
--During the initialization stage, set up all the global variables we're going to want:
script.on_init( function()
	--AI Cores are separate for each force:
	--In this table, the keys are the names of each force & the values are force data tables:
	global.forceData = {}
	--This value is based entirely on the game's technology difficulty (NOT recipe difficulty or technology price multiplier):
	global.aiCoreFormulaExponent = get_ai_core_internal_calculation_exponent()

	for _, v in pairs( game.forces ) do
		global.forceData[ v.name ] = create_force_data_object( v )
	end

	--We want to stagger force updates, so we store the index of the next force to update here:
	global.nextForceIndex = 1

	--This table will contain all AI Cores that obey this mod's logic.
	--If an AI Core isn't in this list, it won't produce any "base val" for its force, nor will it consume
	--electricity continuously like AI Cores are supposed to.
	--Although the keys will be numbers, this is NOT an array so normal length calculations won't work on it.
	--That's why this table keeps track of its own length.
	global.allAICores = { length = 0 }
end )

--=========================================================================================================--
--                  ONCE EVERY <UPDATE_INTERVAL> TICKS, UPDATE A FORCE'S RESEARCH PRODUCTIVITY BONUS & GUIS.
--                                CYCLE THROUGH EACH FORCE THIS WAY
--=========================================================================================================--
--the updates are staggered so we only update 1 force every UPDATE_INTERVAL ticks.
script.on_nth_tick( UPDATE_INTERVAL, function( event )
	--We're going to do the next force in the list:
	global.nextForceIndex = global.nextForceIndex + 1
	if global.nextForceIndex > #game.forces then
		global.nextForceIndex = 1
	end

	--Do it!  Update data just for the one force:
	local force = game.forces[ global.nextForceIndex ] --Could be nil if a force is deleted by merging
	if force ~= nil then
		local name = force.name
		local data = global.forceData[ name ] --Could be nil for a tick while merging forces
		if data ~= nil then
			--We need to update the entity status because calling update_internal_values sets the entity's electric energy to 0,
			--which would confuse the entity into thinking it had no power.  So update before then, when the entity still has energy.
			for _, v in pairs( force.players ) do
				entityGUI.update_entity_status( v )
			end
			update_internal_values( data )
			for _, v in pairs( force.players ) do
				entityGUI.update_research_enabled_except_entity_status( v )--There is no event for when this would change, so we must check every update tick.
				entityGUI.update_bonus_values( v )
			end
			for _, v in pairs( game.players ) do
				debugGUI.update_just_1_force( v, name )
				debugGUI.update_tracked_cores( v )
			end
		end
	end
end )

--=========================================================================================================--
--                      DYNAMICALLY UPDATE GUIS & INTERNAL VALUES WHEN TECHS ARE RESEARCHED
--                                OR UNRESEARCHED OR WHEN TECHNOLOGY EFFECTS ARE RESET
--=========================================================================================================--
--One of the technologies affects how powerful AI Cores are.
--Any time that technology is researched or unresearched, update our forceData.
script.on_event({ defines.events.on_research_finished, defines.events.on_research_reversed, defines.events.on_technology_effects_reset }, function( event )
	--Different events are structured differently, but we want to respond equally to any of these 3:
	local force = event.force or event.research.force

	--Update internal values associated with the force whose tech was finished or reversed:
	perform_tech_refresh( force )

	--Update debug GUI for all players:
	for _, v in pairs( game.players ) do
		debugGUI.update_just_1_force( v, force.name )
	end
	--Update (only relevant sections of the GUI) for each player on that force:
	for _, v in pairs( force.players ) do
		entityGUI.update_algorithm_level( v )
		entityGUI.update_bonus_values( v )
	end
end )

--=========================================================================================================--
--                      DYNAMICALLY UPDATE GUIS & INTERNAL VALUES WHEN FORCES ARE CREATED
--=========================================================================================================--
script.on_event( defines.events.on_force_created, function( event )
	--Take the new force & use it to create a new forceData object:
	local force = event.force
	global.forceData[ force.name ] = create_force_data_object( force )
	
	--Update the debug GUI for every player, since the debug GUI lists all forces:
	for _, v in pairs( game.players ) do
		debugGUI.refresh_forces_table( v )
	end
end )

--=========================================================================================================--
--                        DYNAMICALLY UPDATE INTERNAL VALUES WHEN FORCES ARE MERGED
--=========================================================================================================--
--As of Factorio 1.1.32, the only way to delete a force is to merge it into another force.
--When forces are merged, the source's AI Cores & "base val" are added to whatever is already present in the destination.
--We will wait to update the GUI until the merge is complete.
--The productivity modifier for the destination force will not be updated until a few ticks from now (whenever the on_nth_tick event triggers)
script.on_event( defines.events.on_forces_merging, function( event )
	--Merge the source forceData object into the destination forceData object.  Then delete the source one.
	merge_force_data_objects( event.source.name, event.destination.name )
end )

--=========================================================================================================--
--                        DYNAMICALLY UPDATE GUIS WHEN FORCES ARE MERGED
--=========================================================================================================--
script.on_event( defines.events.on_forces_merged, function( event )
	--Update the debug GUI for every player, since the debug GUI lists all forces:
	for _, v in pairs( game.players ) do
		debugGUI.refresh_forces_table( v )
	end

	--Repopulate the AI Cores GUI for all players involved in the merger:
	for _, v in pairs( event.destination.players ) do
		entityGUI.repopulate( v )
	end
end )

--=========================================================================================================--
--                        DYNAMICALLY UPDATE GUIS WHEN A PLAYER SWITCHES FORCES
--=========================================================================================================--
script.on_event( defines.events.on_player_changed_force, function( event )
	local playerWhoSwitchedForces = game.players[ event.player_index ]
	debugGUI.update_forces_table_headings( playerWhoSwitchedForces )
	entityGUI.repopulate( playerWhoSwitchedForces )
end )

--=========================================================================================================--
--                        DYNAMICALLY UPDATE THE AI CORE GUI WHEN A PLAYER
--                              CHANGES THEIR DISPLAY SETTINGS
--                        DYNAMICALLY UPDATE THE DEBUG GUI WHEN GLOBAL SETTINGS CHANGE
--=========================================================================================================--
script.on_event( defines.events.on_runtime_mod_setting_changed, function( event )
	if event.setting == GLOBAL_AI_CORES_STRENGTH_SETTING then
		--Update the debug GUI for all players, but only the part of the GUI that contains the setting that was changed.
		for _, v in pairs( game.players ) do
			debugGUI.update_strength_multiplier( v )
		end
	end
	if event.player_index == nil or event.setting ~= PER_PLAYER_PRECISION_SETTING then
		--It wasn't the 1 setting we actually care about.
		return
	end
	--Else, a player changed settings!
	--Update only the part of their GUI that's affected by those settings.
	entityGUI.update_bonus_values( game.players[ event.player_index ])
end )


--=========================================================================================================--
--                      DYNAMICALLY UPDATE INTERNAL VALUES WHENEVER THE GAME'S DIFFICULTY CHANGES
--=========================================================================================================--
script.on_event( defines.events.on_difficulty_settings_changed, function( event )
	--This value is based entirely on the game's technology difficulty (NOT recipe difficulty or technology price multiplier):
	global.aiCoreFormulaExponent = get_ai_core_internal_calculation_exponent()

	--In the next major tick-based update, all of the values for each force will be adjusted to use the new difficulty setting.
	--But, we can update some values right now.
	for _, v in pairs( game.players ) do
		debugGUI.update_technology_difficulty( v )
		entityGUI.update_technology_difficulty( v )
	end
end )

--=========================================================================================================--
--                              WHEN A PLAYER OPENS THE GUI OF AN AI CORE,
--                          REPLACE THAT GUI WITH A CUSTOM GUI MADE BY THIS MOD
--=========================================================================================================--
script.on_event( defines.events.on_gui_opened, function( event )
	if event.gui_type == defines.gui_type.entity and event.entity.name == AI_CORE_ENTITY then
		local player = game.players[ event.player_index ]
		entityGUI.create( player, event.entity )
		player.play_sound{ path = AI_CORE_OPEN_SFX_PATH }
		player.opened = entityGUI.get_top_level_element( player )
	end
end )

--=========================================================================================================--
--                           WHEN A PLAYER WANTS TO CLOSE THE AI CORE GUI,
--                             CALL THE FUNCTION THAT ACTUALLY CLOSES IT
--=========================================================================================================--
script.on_event( defines.events.on_gui_click, function( event )
	if event.element.name == GUI_CLOSE_BUTTON then
		local player = game.players[ event.player_index ]
		entityGUI.destroy( player )
		player.play_sound{ path = AI_CORE_CLOSE_SFX_PATH }
	end
end )
script.on_event( defines.events.on_gui_closed, function( event )
	if event.gui_type == defines.gui_type.custom and event.element.name == TOP_LEVEL_ENTITY_GUI_ELEMENT then
		local player = game.players[ event.player_index ]
		entityGUI.destroy( player )
		player.play_sound{ path = AI_CORE_CLOSE_SFX_PATH }
	end
end )

--=========================================================================================================--
--                        KEEP TRACK OF AI CORES WHENEVER ONE IS CREATED OR DESTROYED
--=========================================================================================================--
--Create an EventFilter object that works for all the events we care about:
local SHARED_FILTER = {{ filter = "name", name = AI_CORE_ENTITY }}

--Called when a player builds an entity:
script.on_event( defines.events.on_built_entity, function( event )
	add_ai_core( event.created_entity )
end, SHARED_FILTER )

--Called when the map editor clones an area onto another area:
script.on_event( defines.events.on_entity_cloned, function( event )
	add_ai_core( event.destination )
end, SHARED_FILTER )

--Called when a Construction Robot builds an entity:
script.on_event( defines.events.on_robot_built_entity, function( event )
	add_ai_core( event.created_entity )
end, SHARED_FILTER )

--Called when a piece of Lua code builds an entity & allows other mods to know about it:
script.on_event( defines.events.script_raised_built, function( event )
	add_ai_core( event.entity )
end, SHARED_FILTER )

--Called when an entity is destroyed for any reason.
--This is not the only place we keep track of whether entities are valid or not;
--we will also remove invalid entries as we come across them when iterating through global.allAICores
script.on_event( defines.events.on_entity_destroyed, function( event )
	remove_ai_core( event.registration_number )
end )