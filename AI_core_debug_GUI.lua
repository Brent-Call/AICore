--AI_core_debug_GUI.lua
--This file contains all the GUI stuff specifically related to the debug GUI.
--This file was coded by Q.

--GUI element naming convention: for key-value pairs e.g. "Parameter: value," the parameter will be named "a" & the value will be named "b" (not the most descriptive names, but they are concise).

--=========================================================================================================--
--                                     LOCAL CONSTANTS FOR GUI CREATION
--=========================================================================================================--
local DIR_VERTICAL = "vertical" --Specifies that a frame or flow has vertical layout
local DIR_HORIZONTAL = "horizontal" --Specifies that a frame or flow has horizontal layout
local GUI_FRAME = "frame" --A type of LuaGuiElement: A box that contains other GUI elements & may have a title
local GUI_FLOW = "flow" --A type of LuaGuiElement: Similar to a frame but has no title & is invisible
local GUI_LABEL = "label" --A type of LuaGuiElement: Just a piece of text (may also have a tooltip)
local STYLE_FRAME_NO_DRAG = "non_draggable_frame" --A frame that can't be manually moved to a different place onscreen
local STYLE_FRAME_INSIDE = "inside_shallow_frame" --A frame that fits inside another frame
local STYLE_FRAME_PADDED = "inside_shallow_frame_with_padding" --An interior frame except it has padding on the border
local STYLE_FRAME_INVISIBLE = "invisible_frame_with_title" --The frame doesn't draw a border or anything, but its title is visible.
local STYLE_LABEL_TITLE = "description_title_label" --A label that is the title of a description.  For example, the "height" in "Height: 2 m"
local STYLE_LABEL_TITLE_INDENTED = "description_title_indented_label" --A label that is the subtitle of a description or title of a subdescription.
local STYLE_LABEL_VALUE = "description_value_label" --A label that is the value of a description.  For example, the "2 m" in "Height: 2 m"
local STYLE_LABEL_RED = "bold_red_label" --I kept it bold to make it easy to read.
local STYLE_LABEL_GREEN = "bold_green_label" --I kept it bold to make it easy to read.
local STYLE_SUBHEADER = "Q-AICore:stretchable_subheader_frame_with_caption" --A frame containing a header for a section of the UI
local STYLE_PADDED_FLOW = "Q-AICore:ai_core_padded_vertical_flow" --A vertical flow but with extra padding on all sides

--=========================================================================================================--
--                                         debugGUI TABLE & FUNCTIONS
--=========================================================================================================--
--The debug GUI shows basically all information there is to know about everything related to AI Cores.
--It's big & complex, & isn't designed to be easy to understand.
debugGUI = {}

--Returns a Boolean value: whether or not the player has the debug GUI open:
function debugGUI.has_GUI( player )
	return mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ] ~= nil
end

--Debug function to display all force data info simultaneously:
function debugGUI.make_forces_table( player, horizFlow )
	for _, v in pairs( game.forces ) do
		local forceData = global.forceData[ v.name ]

		--If we are merging forces, the forceData could be nil until the merging process is complete; it's okay.
		if forceData ~= nil then
			local captionToUse = { "ai-core-gui.debug-force", v.name }
			if player.force == v then
				captionToUse[ 1 ] = "ai-core-gui.debug-force-current"
			end
			local outerFrame = horizFlow.add{ type = GUI_FRAME, name = v.name, caption = captionToUse, style = STYLE_FRAME_INVISIBLE, direction = DIR_VERTICAL }
			outerFrame.style.horizontally_stretchable = false
			local innerFrame = outerFrame.add{ type = GUI_FRAME, name = "inner", style = STYLE_FRAME_PADDED, direction = DIR_VERTICAL }
			innerFrame.add{ type = GUI_FLOW, name = "research", direction = DIR_HORIZONTAL }
			innerFrame.research.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-research-title" }, tooltip = { "ai-core-gui.debug-research-title-tooltip" }, style = STYLE_LABEL_TITLE }
			if v.research_enabled then
				innerFrame.research.add{ type = GUI_LABEL, name = "b", caption = { "ai-core-gui.debug-research-enabled" }, tooltip = { "ai-core-gui.debug-research-enabled-tooltip" }, style = STYLE_LABEL_GREEN }
			else
				innerFrame.research.add{ type = GUI_LABEL, name = "b", caption = { "ai-core-gui.debug-research-disabled" }, tooltip = { "ai-core-gui.debug-research-disabled-tooltip" }, style = STYLE_LABEL_RED }
			end
			innerFrame.add{ type = GUI_FLOW, name = "algorithm", direction = DIR_HORIZONTAL }
			innerFrame.algorithm.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-algorithm-title" }, tooltip = { "ai-core-gui.debug-algorithm-title-tooltip" }, style = STYLE_LABEL_TITLE }
			innerFrame.algorithm.add{ type = GUI_LABEL, name = "b", caption = forceData.algorithmLevel, tooltip = { "ai-core-gui.debug-algorithm-value-tooltip", forceData.algorithmLevel }, style = STYLE_LABEL_VALUE }
			innerFrame.add{ type = GUI_FLOW, name = "base", direction = DIR_HORIZONTAL }
			innerFrame.base.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-base-val-title" }, tooltip = { "ai-core-gui.debug-base-val-title-tooltip" }, style = STYLE_LABEL_TITLE }
			innerFrame.base.add{ type = GUI_LABEL, name = "b", caption = forceData.baseVal, tooltip = { "ai-core-gui.debug-base-val-value-tooltip" }, style = STYLE_LABEL_VALUE }
			--These numbers here show the modifiers in the GUI, & the multipliers in the tooltips.  The modifier is simply the multiplier minus 1.
			innerFrame.add{ type = GUI_FLOW, name = "ai-core-prod", direction = DIR_HORIZONTAL }
			innerFrame[ "ai-core-prod" ].add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-ai-core-title" }, tooltip = { "ai-core-gui.debug-ai-core-title-tooltip" }, forceData.aiCoreProdModifier, style = STYLE_LABEL_TITLE }
			innerFrame[ "ai-core-prod" ].add{ type = GUI_LABEL, name = "b", caption = forceData.aiCoreProdModifier, tooltip = { "ai-core-gui.debug-equivalent-multiplier-tooltip", 1 + forceData.aiCoreProdModifier }, style = STYLE_LABEL_VALUE }
			innerFrame.add{ type = GUI_FLOW, name = "tech-prod", direction = DIR_HORIZONTAL }
			innerFrame[ "tech-prod" ].add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-tech-title" }, tooltip = { "ai-core-gui.debug-tech-title-tooltip" }, style = STYLE_LABEL_TITLE }
			innerFrame[ "tech-prod" ].add{ type = GUI_LABEL, name = "b", caption = forceData.techResearchProd, tooltip = { "ai-core-gui.debug-equivalent-multiplier-tooltip", 1 + forceData.techResearchProd }, style = STYLE_LABEL_VALUE }
			innerFrame.add{ type = GUI_FLOW, name = "final-prod", direction = DIR_HORIZONTAL }
			innerFrame[ "final-prod" ].add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-final-title" }, tooltip = { "ai-core-gui.debug-final-title-tooltip" }, style = STYLE_LABEL_TITLE }
			innerFrame[ "final-prod" ].add{ type = GUI_LABEL, name = "b", caption = v.laboratory_productivity_bonus, tooltip = { "ai-core-gui.debug-equivalent-multiplier-tooltip", 1 + v.laboratory_productivity_bonus }, style = STYLE_LABEL_VALUE }
		end
	end
end

--Creates the debug GUI, which displays info for the game as a whole, for each force
--If the player already has the GUI open, recreates the GUI from scratch.
function debugGUI.create( player )
	if debugGUI.has_GUI( player ) then
		debugGUI.destroy( player )
	end
	local outerFrame = mod_gui.get_frame_flow( player ).add{ type = GUI_FRAME, name = "ai-core-debug-GUI", direction = DIR_VERTICAL, caption = { "ai-core-gui.debug-gui-title" }, style = STYLE_FRAME_NO_DRAG }
	outerFrame.add{ type = GUI_FRAME, name = "inner", style = STYLE_FRAME_INSIDE, direction = DIR_VERTICAL }
	outerFrame.inner.add{ type = GUI_FRAME, name = "subheader", caption = { "ai-core-gui.debug-subheader" }, direction = DIR_HORIZONTAL, style = STYLE_SUBHEADER }
	local innerFlow = outerFrame.inner.add{ type = GUI_FLOW, name = "inner-flow", direction = DIR_VERTICAL, style = STYLE_PADDED_FLOW }
	innerFlow.style.vertical_spacing = 0
	innerFlow.add{ type = GUI_FLOW, name = "difficulty", direction = DIR_HORIZONTAL }
	innerFlow.difficulty.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-difficulty-title" }, tooltip = { "ai-core-gui.debug-difficulty-title-tooltip" }, style = STYLE_LABEL_TITLE }
	innerFlow.difficulty.add{ type = GUI_LABEL, name = "b", caption = { "ai-core-gui.debug-difficulty-value", get_technology_difficulty_as_localised_string(), global.aiCoreFormulaExponent }, tooltip = { "ai-core-gui.debug-difficulty-value-tooltip" }, style = STYLE_LABEL_VALUE }
	innerFlow.add{ type = GUI_FLOW, name = "watchlist", direction = DIR_HORIZONTAL }
	innerFlow.watchlist.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-watchlist-title" }, tooltip = { "ai-core-gui.debug-watchlist-title-tooltip" }, style = STYLE_LABEL_TITLE }
	local watchlistSize = get_tech_prod_watchlist_size()
	if watchlistSize > 0 then
		local tooltipTable = { "", "{ " }
		for name, _ in pairs( get_tech_prod_watchlist()) do
			if #tooltipTable > 2 then
				table.insert( tooltipTable, ", " )
			end
			table.insert( tooltipTable, game.technology_prototypes[ name ].localised_name )
		end
		table.insert( tooltipTable, " }" )
		innerFlow.watchlist.add{ type = GUI_LABEL, name = "b", caption = { "ai-core-gui.debug-watchlist-value", get_tech_prod_watchlist_size()}, tooltip = tooltipTable, style = STYLE_LABEL_VALUE }
	else
		innerFlow.watchlist.add{ type = GUI_LABEL, name = "b", caption = { "ai-core-gui.debug-watchlist-empty" }, tooltip = { "ai-core-gui.debug-watchlist-empty-tooltip" }, style = STYLE_LABEL_VALUE }
	end
	innerFlow.add{ type = GUI_LABEL, name = "more", caption = { "ai-core-gui.debug-more" }, tooltip = { "ai-core-gui.debug-more-tooltip" }, style = STYLE_LABEL_TITLE_INDENTED }
	innerFlow.add{ type = GUI_FLOW, name = "strength", direction = DIR_HORIZONTAL }
	innerFlow.strength.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-strength-title" }, tooltip = { "ai-core-gui.debug-strength-title-tooltip" }, style = STYLE_LABEL_TITLE }
	innerFlow.strength.add{ type = GUI_LABEL, name = "b", caption = settings.global[ GLOBAL_AI_CORES_STRENGTH_SETTING ].value, tooltip = { "ai-core-gui.debug-strength-value-tooltip" }, style = STYLE_LABEL_VALUE }
	innerFlow.add{ type = GUI_FLOW, name = "epsilon", direction = DIR_HORIZONTAL }
	innerFlow.epsilon.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-epsilon-title" }, tooltip = { "ai-core-gui.debug-epsilon-title-tooltip" }, style = STYLE_LABEL_TITLE }
	innerFlow.epsilon.add{ type = GUI_LABEL, name = "b", caption = EPSILON, tooltip = { "ai-core-gui.debug-epsilon-value-tooltip" }, style = STYLE_LABEL_VALUE }
	innerFlow.add{ type = GUI_FLOW, name = "tracked", direction = DIR_HORIZONTAL }
	innerFlow.tracked.add{ type = GUI_LABEL, name = "a", caption = { "ai-core-gui.debug-tracked-title" }, tooltip = { "ai-core-gui.debug-tracked-title-tooltip" }, style = STYLE_LABEL_TITLE }
	innerFlow.tracked.add{ type = GUI_LABEL, name = "b", caption = global.allAICores.length, tooltip = { "ai-core-gui.debug-tracked-value-tooltip" }, style = STYLE_LABEL_VALUE }
	local horizFlow = outerFrame.add{ type = GUI_FLOW, name = "force-data-flow", direction = DIR_HORIZONTAL }
	debugGUI.make_forces_table( player, horizFlow )
end

--This updates only the part of the debug GUI that displays force-specific data, but it updates everything about that section.
--Use it when the number of forces in the game changes.  Don't use it at other times because it is computationally expensive.
--If the player doesn't have the debug GUI open, does nothing.
function debugGUI.refresh_forces_table( player )
	if not debugGUI.has_GUI( player ) then
		return
	end
	--Else, the GUI is open!
	local flow = mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ][ "force-data-flow" ]
	flow.clear();
	debugGUI.make_forces_table( player, flow );
end

--This updates only the parts of the debug GUI associated with a particular force.
--Input a string containing the name of the force in question:
--If the player doesn't have the debug GUI open, does nothing.
function debugGUI.update_just_1_force( player, forceName )
	if not debugGUI.has_GUI( player ) then
		return
	end
	--Else, the GUI is open!
	local frame = mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ][ "force-data-flow" ][ forceName ].inner
	local force = game.forces[ forceName ]
	local forceData = global.forceData[ forceName ]
	--Research
	if force.research_enabled then
		frame.research.b.caption = { "ai-core-gui.debug-research-enabled" }
		frame.research.b.tooltip = { "ai-core-gui.debug-research-enabled-tooltip" }
		frame.research.b.style = STYLE_LABEL_GREEN
	else
		frame.research.b.caption = { "ai-core-gui.debug-research-disabled" }
		frame.research.b.tooltip = { "ai-core-gui.debug-research-disabled-tooltip" }
		frame.research.b.style = STYLE_LABEL_RED
	end
	--Algorithm level
	frame.algorithm.b.caption = forceData.algorithmLevel
	frame.algorithm.b.tooltip = { "ai-core-gui.debug-algorithm-value-tooltip", forceData.algorithmLevel }
	--"Base val"
	frame.base.b.caption = forceData.baseVal
	--Productivity modifier from AI Cores
	frame[ "ai-core-prod" ].b.caption = forceData.aiCoreProdModifier
	frame[ "ai-core-prod" ].b.tooltip = { "ai-core-gui.debug-equivalent-multiplier-tooltip", 1 + forceData.aiCoreProdModifier }
	--Productivity modifier from researched technologies
	frame[ "tech-prod" ].b.caption = forceData.techResearchProd
	frame[ "tech-prod" ].b.tooltip = { "ai-core-gui.debug-equivalent-multiplier-tooltip", 1 + forceData.techResearchProd }
	--Final productivity modifier
	frame[ "final-prod" ].b.caption = force.laboratory_productivity_bonus
	frame[ "final-prod" ].b.tooltip = { "ai-core-gui.debug-equivalent-multiplier-tooltip", 1 + force.laboratory_productivity_bonus }
end

--This only updates the headings in the forces table, which display only which force the player is in.
--Call this when a player switches forces.
--If the player doesn't have the debug GUI open, does nothing.
function debugGUI.update_forces_table_headings( player )
	if not debugGUI.has_GUI( player ) then
		return
	end
	local flow = mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ][ "force-data-flow" ]
	for _, v in pairs( game.forces ) do
		local captionToUse = { "ai-core-gui.debug-force", v.name }
		if player.force == v then
			captionToUse[ 1 ] = "ai-core-gui.debug-force-current"
		end
		local frameToUpdate = flow[ v.name ]
		--Due to some timing issues, it's possible that the interior frames never generated.  Avoid null errors.
		if frameToUpdate ~= nil then
			frameToUpdate.caption = captionToUse
		end
	end
end

--This only updates the part of the debug GUI that shows the strength multiplier.
--If the player doesn't have the debug GUI open, does nothing.
function debugGUI.update_strength_multiplier( player )
	if not debugGUI.has_GUI( player ) then
		return
	end
	mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ].inner[ "inner-flow" ].strength.b.caption = settings.global[ GLOBAL_AI_CORES_STRENGTH_SETTING ].value
end

--This only updates the part of the debug GUI that shows the technology difficulty.
--If the player doesn't have the debug GUI open, does nothing.
function debugGUI.update_technology_difficulty( player )
	if not debugGUI.has_GUI( player ) then
		return
	end
	mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ].inner[ "inner-flow" ].difficulty.b.caption = { "ai-core-gui.debug-difficulty-value", get_technology_difficulty_as_localised_string(), global.aiCoreFormulaExponent }
end

--This only updates the part of the debug GUI that shows the number of tracked AI cores.
--If the player doesn't have the debug GUI open, does nothing.
function debugGUI.update_tracked_cores( player )
	if not debugGUI.has_GUI( player ) then
		return
	end
	mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ].inner[ "inner-flow" ].tracked.b.caption = global.allAICores.length
end

--Closes the debug GUI:
--If the player doesn't have the debug GUI open in the first place, does nothing.
function debugGUI.destroy( player )
	if not debugGUI.has_GUI( player ) then
		return
	end
	--Else, the GUI is open, so close it.
	mod_gui.get_frame_flow( player )[ "ai-core-debug-GUI" ].destroy()
end