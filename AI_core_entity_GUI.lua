--AI_core_entity_GUI.lua
--This file contains all the GUI stuff specifically related to the AI Core entity's GUI.
--This file was coded by Q.

--=========================================================================================================--
--                                     LOCAL CONSTANTS FOR GUI CREATION
--=========================================================================================================--
local DIR_VERTICAL = "vertical" --Specifies that a frame or flow has vertical layout
local DIR_HORIZONTAL = "horizontal" --Specifies that a frame or flow has horizontal layout
local GUI_FRAME = "frame" --A type of LuaGuiElement: A box that contains other GUI elements & may have a title
local GUI_FLOW = "flow" --A type of LuaGuiElement: Similar to a frame but has no title & is invisible
local GUI_LABEL = "label" --A type of LuaGuiElement: Just a piece of text (may also have a tooltip)
local GUI_EMPTY_WIDGET = "empty-widget" --A type of LuaGuiElement: No inherent behavior; it just exists
local GUI_ENTITY_PREVIEW = "entity-preview" --A type of LuaGuiElement: makes a live picture of a single entity against a lab tiles background
local GUI_SPRITE = "sprite" --A type of LuaGuiElement: It's just an image.
local GUI_SPRITE_BUTTON = "sprite-button" --A type of LuaGuiElement: It's a sprite that can be interacted with just like any other button
local STYLE_MACHINE_FRAME = "machine_frame" --Used to contain the entire AI Cores GUI
local STYLE_FRAME_TITLE = "frame_title" --A label used for the caption of a frame
local STYLE_DRAGGABLE_HEADER = "Q-AICore:draggable_space_header" --A widget that can be dragged to move the frame it's in
local STYLE_CLOSE_BUTTON = "close_button" --An X in the corner; click it to close the GUI
local STYLE_ENTITY_FRAME = "entity_frame" --Used for the inside of an entity GUI
local STYLE_ENTITY_STATUS = "Q-AICore:entity_status_flow" --Used to contain the widget that displays an entity's current status
local STYLE_STATUS_IMAGE = "status_image" --The icon for an entity's current status
local STYLE_SHALLOW_FRAME = "inside_shallow_frame" --It does what it's named
local STYLE_DEEP_FRAME = "deep_frame_in_shallow_frame" --It does what it's named
local STYLE_PREVIEW = "wide_entity_button" --Used for an entity preview
local STYLE_SUBHEADER = "Q-AICore:stretchable_subheader_frame_with_caption" --A subheader frame that horizontally expands to fill available space.
local STYLE_PADDED_FLOW = "Q-AICore:ai_core_padded_vertical_flow" --A vertical flow but with extra padding on all sides
local STYLE_FRAME_THAT_IS_A_BORDER = "bordered_frame" --The only visible thing in this frame is the border; used to group the contents of an inner frame
local STYLE_SECTION_TITLE = "caption_label" --Used for the title of a section, which section is delineated by a STYLE_FRAME_THAT_IS_A_BORDER
local STYLE_DESCRIPTION_TITLE = "description_title_indented_label" --A label that is the title of a description.  For example, the "height" in "Height: 2 m"
local STYLE_DESCRIPTION_VALUE = "description_value_label" --A label that is the value of a description.  For example, the "2 m" in "Height: 2 m"

--=========================================================================================================--
--                                         entityGUI TABLE & FUNCTIONS
--=========================================================================================================--

--The AI Core GUI shows a simplified subset of information that is designed to be as easy to understand as possible, while still telling players the most important bits.
--We do intentionally hide the inner workings of the mod.
entityGUI = {}

--Returns the Lua object associated with the top-level AI Core GUI element or nil if the GUI is closed.
function entityGUI.get_top_level_element( player )
	return player.gui.screen[ TOP_LEVEL_ENTITY_GUI_ELEMENT ]
end
--Returns a Boolean value: whether or not the player has the AI Core GUI open:
function entityGUI.get_has_GUI( player )
	return player.gui.screen[ TOP_LEVEL_ENTITY_GUI_ELEMENT ] ~= nil
end

--Returns a table with 2 values:
--	sprite--a path to a sprite icon representing the entity's status as a simple LED
--	message--a LocalisedString representing the entity's status using text
--Parameters:
--	aiCoreEntity--must either be a valid AI Core LuaEntity or nil.
function entityGUI.get_determine_entity_status( aiCoreEntity )
	if aiCoreEntity == nil then
		--If there is no AI Core, then the entity pane will be hidden anyways.  Still, we populate it for the sake of completeness.
		return { sprite = "utility/status_not_working", message = { "gui.not-available" }}
	end
	--Else, aiCoreEntity is not nil & we assume it's valid.
	if not aiCoreEntity.force.research_enabled then
		--AI Cores are programmed to do nothing if research is disabled for their force.
		return { sprite = "utility/status_not_working", message = { "entity-status.disabled" }}
	end
	if aiCoreEntity.status == defines.entity_status.no_power then
		--If the AI Core is not plugged into the network, it can't operate.
		return { sprite = "utility/status_not_working", message = { "entity-status.no-power" }}
	end
	if aiCoreEntity.status == defines.entity_status.marked_for_deconstruction then
		--Almost all entities have this status.
		return { sprite = "utility/status_not_working", message = { "entity-status.marked-for-deconstruction" }}
	end
	--Else, there is nothing preventing the AI Core from working, except maybe a low power status.  However, due
	--to how AI Cores are programmed, the game engine says they have "low power" status even when functioning as intended.
	--It would require special code to detect a true low power status for a AI Core, which code I have not written.
	--Assume the AI Core is working fine.
	return { sprite = "utility/status_working", message = { "entity-status.working" }}
end

--Formats the bonuses to a force's research in player-readable format:
--Returns a table with 3 values:
--	technology--a LocalisedString representing the productivity bonus from researched technologies only as a percentage
--	aiCore--a LocalisedString representing the productivity bonus from AI Cores only as a percentage
--	final--a LocalisedString representing the above two productivity bonuses multiplies as an additive percentage bonus
--Parameters:
--	player--a LuaPlayer.  Affects the output in 2 ways:
--		   (1) Their individual settings determine to which precision the numbers are displayed
--		   (2) Their associated force's forceData object is the object whose data is formatted by this function
function entityGUI.get_format_force_bonuses( player )
	--Create a local reference to the player's force's associated forceData table:
	local forceData = global.forceData[ player.force.name ]
	--Each player may specify however many decimal places of precision they wish to see:
	local decimalPlaces = player.mod_settings[ PER_PLAYER_PRECISION_SETTING ].value
	return {
		technology = { "format-percent", string.format( "%."..decimalPlaces.."f", 100 * forceData.techResearchProd )},
		aiCore = { "format-percent", string.format( "%."..decimalPlaces.."f", 100 * forceData.aiCoreProdModifier )},
		--We deliberately put a plus sign in front of it because it is an *additive* bonus to research productivity.
		--This is not done for the other 2 displayed bonuses because they are not additive; they are multiplicative with each other.
		final = { "format-percent", string.format( "%+."..decimalPlaces.."f", 100 * player.force.laboratory_productivity_bonus )}
	}
end

--Returns true if in the bonuses section of the AI Cores GUI, the bonus from tech is displayed separately from the bonus from AI Cores.
--Returns false if in the bonuses section of the AI Cores GUI, the bonus from AI Cores is the only bonus displayed.
function entityGUI.get_should_breakdown_bonuses( player )
	return global.forceData[ player.force.name ].techResearchProd ~= 0
end

--This function populates every data value in the AI Core GUI.
--Make sure it's empty before calling this function!
--Thanks to DaveMcW for helping with this forum post: https://forums.factorio.com/viewtopic.php?f=34&t=98713
--Note that the parameter, aiCoreEntity, is either a LuaEntity or nil.
function entityGUI.populate( player, aiCoreEntity )
	local topLevelFrame = entityGUI.get_top_level_element( player )
	--Create a local reference to the player's force's associated forceData table:
	local forceData = global.forceData[ player.force.name ]
	--The GUI displays some things differently if research is disabled:
	local researchEnabled = player.force.research_enabled

	--You're not allowed to open a AI Core that belongs to another force.
	--If you try to do so, instead you'll view your own AI Core statistics, but without any entity associated.
	--This is normally impossible, but it could happen if for instance a player changed forces.
	if aiCoreEntity ~= nil then
		if not aiCoreEntity.valid or player.force ~= aiCoreEntity.force then
			aiCoreEntity = nil
		end
	end

	--Create the titlebar & make it draggable, so the player can use it to move the window:
	local titlebar = topLevelFrame.add{ type = GUI_FLOW, name = "ai-core-GUI-titlebar", direction = DIR_HORIZONTAL }
	titlebar.drag_target = topLevelFrame
	titlebar.add{ type = GUI_LABEL, name = "ai-core-GUI-titlebar-title", caption = { "entity-name.Q-AICore:ai-core" }, ignored_by_interaction = true, style = STYLE_FRAME_TITLE }
	titlebar.add{ type = GUI_EMPTY_WIDGET, name = "ai-core-GUI-titlebar-draggable", ignored_by_interaction = true, style = STYLE_DRAGGABLE_HEADER }
	titlebar.add{ type = GUI_SPRITE_BUTTON, name = GUI_CLOSE_BUTTON, sprite = "utility/close_white", hovered_sprite = "utility/close_black", clicked_sprite = "utility/close_black", style = STYLE_CLOSE_BUTTON }

	--On the inside left of the window, display the AI Core & its status:
	topLevelFrame.add{ type = GUI_FLOW, name = "ai-core-GUI-inner", direction = DIR_HORIZONTAL }
	local innerFrameLeft = topLevelFrame[ "ai-core-GUI-inner" ].add{ type = GUI_FRAME, name = "ai-core-GUI-left", direction = DIR_VERTICAL, style = STYLE_ENTITY_FRAME, visible = aiCoreEntity ~= nil }
	innerFrameLeft.add{ type = GUI_FLOW, name = "ai-core-GUI-left-status", direction = DIR_HORIZONTAL, style = STYLE_ENTITY_STATUS }
	local status = entityGUI.get_determine_entity_status( aiCoreEntity )
	innerFrameLeft[ "ai-core-GUI-left-status" ].add{ type = GUI_SPRITE, name = "ai-core-GUI-left-status-sprite", sprite = status.sprite, style = STYLE_STATUS_IMAGE }
	innerFrameLeft[ "ai-core-GUI-left-status" ].add{ type = GUI_LABEL, name = "ai-core-GUI-left-status-label", caption = status.message }
	innerFrameLeft.add{ type = GUI_FRAME, name = "ai-core-GUI-left-deep", direction = DIR_VERTICAL, style = STYLE_DEEP_FRAME }
	innerFrameLeft[ "ai-core-GUI-left-deep" ].add{ type = GUI_ENTITY_PREVIEW, name = "ai-core-GUI-left-preview", style = STYLE_PREVIEW }.entity = aiCoreEntity
	
	--On the inside right of the window, display the cumulative effects of all AI Cores:
	local innerFrameRight = topLevelFrame[ "ai-core-GUI-inner" ].add{ type = GUI_FRAME, name = "ai-core-GUI-right", direction = DIR_VERTICAL, style = STYLE_SHALLOW_FRAME }
	innerFrameRight.add{ type = GUI_FRAME, name = "ai-core-GUI-right-subheader", caption = { "ai-core-gui.subheader" }, direction = DIR_HORIZONTAL, style = STYLE_SUBHEADER }
	innerFrameRight.add{ type = GUI_FLOW, name = "ai-core-GUI-right-flow", direction = DIR_VERTICAL, style = STYLE_PADDED_FLOW }
	local researchSection = innerFrameRight[ "ai-core-GUI-right-flow" ].add{ type = GUI_FRAME, name = "ai-core-GUI-research", direction = DIR_VERTICAL, style = STYLE_FRAME_THAT_IS_A_BORDER }
	researchSection.add{ type = GUI_LABEL, name = "ai-core-GUI-research-title", caption = { "ai-core-gui.research-title" }, style = STYLE_SECTION_TITLE }
	--Visible only if research is disabled.
	researchSection.add{ type = GUI_LABEL, name = "ai-core-GUI-research-disabled", caption = { "ai-core-gui.research-disabled" }, style = STYLE_DESCRIPTION_TITLE, visible = not researchEnabled }
	researchSection.add{ type = GUI_FLOW, name = "ai-core-GUI-research-difficulty", tooltip = { "ai-core-gui.difficulty-tooltip" }, direction = DIR_HORIZONTAL, visible = researchEnabled }
	researchSection[ "ai-core-GUI-research-difficulty" ].add{ type = GUI_LABEL, name = "ai-core-GUI-research-difficulty-title", caption = { "ai-core-gui.difficulty-title" }, ignored_by_interaction = true, style = STYLE_DESCRIPTION_TITLE }
	researchSection[ "ai-core-GUI-research-difficulty" ].add{ type = GUI_LABEL, name = "ai-core-GUI-research-difficulty-value", caption = get_technology_difficulty_as_localised_string(), ignored_by_interaction = true, style = STYLE_DESCRIPTION_VALUE }
	researchSection.add{ type = GUI_FLOW, name = "ai-core-GUI-research-algorithm", tooltip = { "ai-core-gui.algorithm-tooltip" }, direction = DIR_HORIZONTAL, visible = researchEnabled }
	researchSection[ "ai-core-GUI-research-algorithm" ].add{ type = GUI_LABEL, name = "ai-core-GUI-research-algorithm-title", caption = { "ai-core-gui.algorithm-title" }, ignored_by_interaction = true, style = STYLE_DESCRIPTION_TITLE }
	researchSection[ "ai-core-GUI-research-algorithm" ].add{ type = GUI_LABEL, name = "ai-core-GUI-research-algorithm-value", caption = forceData.algorithmLevel, ignored_by_interaction = true, style = STYLE_DESCRIPTION_VALUE }
	local bonusSection = innerFrameRight[ "ai-core-GUI-right-flow" ].add{ type = GUI_FRAME, name = "ai-core-GUI-bonus", direction = DIR_VERTICAL, style = STYLE_FRAME_THAT_IS_A_BORDER, visible = researchEnabled }
	--Format the numbers we will want as LocalisedStrings:
	local formattedBonuses = entityGUI.get_format_force_bonuses( player )
	bonusSection.add{ type = GUI_LABEL, name = "ai-core-GUI-bonus-title", caption = { "gui-bonus.laboratory-productivity" }, style = STYLE_SECTION_TITLE }
	bonusSection.add{ type = GUI_FLOW, name = "ai-core-GUI-bonus-tech", tooltip = { "ai-core-gui.bonus-tech-tooltip" }, direction = DIR_HORIZONTAL }
	bonusSection[ "ai-core-GUI-bonus-tech" ].add{ type = GUI_LABEL, name = "ai-core-GUI-bonus-tech-title", caption = { "ai-core-gui.bonus-tech-title" }, ignored_by_interaction = true, style = STYLE_DESCRIPTION_TITLE }
	bonusSection[ "ai-core-GUI-bonus-tech" ].add{ type = GUI_LABEL, name = "ai-core-GUI-bonus-tech-value", caption = formattedBonuses.technology, ignored_by_interaction = true, style = STYLE_DESCRIPTION_VALUE }
	bonusSection.add{ type = GUI_FLOW, name = "ai-core-GUI-bonus-ai-cores", tooltip = { "ai-core-gui.bonus-ai-cores-tooltip" }, direction = DIR_HORIZONTAL }
	bonusSection[ "ai-core-GUI-bonus-ai-cores" ].add{ type = GUI_LABEL, name = "ai-core-GUI-bonus-ai-cores-title", caption = { "ai-core-gui.bonus-ai-cores-title" }, ignored_by_interaction = true, style = STYLE_DESCRIPTION_TITLE }
	bonusSection[ "ai-core-GUI-bonus-ai-cores" ].add{ type = GUI_LABEL, name = "ai-core-GUI-bonus-ai-cores-value", caption = formattedBonuses.aiCore, ignored_by_interaction = true, style = STYLE_DESCRIPTION_VALUE }
	bonusSection.add{ type = GUI_FLOW, name = "ai-core-GUI-bonus-final", tooltip = { "ai-core-gui.bonus-final-tooltip" }, direction = DIR_HORIZONTAL }
	bonusSection[ "ai-core-GUI-bonus-final" ].add{ type = GUI_LABEL, name = "ai-core-GUI-bonus-final-title", caption = { "ai-core-gui.bonus-final-title" }, ignored_by_interaction = true, style = STYLE_DESCRIPTION_TITLE }
	bonusSection[ "ai-core-GUI-bonus-final" ].add{ type = GUI_LABEL, name = "ai-core-GUI-bonus-final-value", caption = formattedBonuses.final, ignored_by_interaction = true, style = STYLE_DESCRIPTION_VALUE }

	--Simplify the GUI if the player hasn't researched any techs that grant research productivity bonuses:
	if not entityGUI.get_should_breakdown_bonuses( player ) then
		bonusSection[ "ai-core-GUI-bonus-tech" ].visible = false
		bonusSection[ "ai-core-GUI-bonus-ai-cores" ].tooltip = { "ai-core-gui.bonus-ai-cores-tooltip-alone" }
		bonusSection[ "ai-core-GUI-bonus-final" ].visible = false
	end
end

--Creates the AI Core GUI, which displays info relevant to that player specifically.
--If the player already has the GUI open, recreates the GUI from scratch.
function entityGUI.create( player, aiCoreEntity )
	if entityGUI.get_has_GUI( player ) then
		entityGUI.destroy( player )
	end
	local topLevelFrame = player.gui.screen.add{ type = GUI_FRAME, name = TOP_LEVEL_ENTITY_GUI_ELEMENT, direction = DIR_VERTICAL, style = STYLE_MACHINE_FRAME }
	--The frame is by default created in the top-left corner.  Move it right to the center of the screen:
	topLevelFrame.force_auto_center()
	entityGUI.populate( player, aiCoreEntity )
end

--Closes the AI Core GUI:
--If the player doesn't have the GUI open in the first place, does nothing.
function entityGUI.destroy( player )
	if not entityGUI.get_has_GUI( player ) then
		return
	end
	--Else, the GUI is open, so close it.
	player.gui.screen[ TOP_LEVEL_ENTITY_GUI_ELEMENT ].destroy()
end

--Updates only the entity status section of the AI Cores GUI.
--If the GUI isn't open, does nothing.  If the entity status section is hidden, does nothing.
--If the entity disappears or becomes invalid, hides that section.
function entityGUI.update_entity_status( player )
	if not entityGUI.get_has_GUI( player ) then
		return
	end
	local innerFrameLeft = entityGUI.get_top_level_element( player )[ "ai-core-GUI-inner" ][ "ai-core-GUI-left" ]
	if not innerFrameLeft.visible then
		--This means the entity became nil some time ago.  Nothing needs to be updated.
		return
	end
	--Else, the GUI is open & not hidden.
	local aiCoreEntity = innerFrameLeft[ "ai-core-GUI-left-deep" ][ "ai-core-GUI-left-preview" ].entity
	
	--If the aiCoreEntity became non-nil invalid since last update, then set it to nil:
	if aiCoreEntity ~= nil then
		if not aiCoreEntity.valid or player.force ~= aiCoreEntity.force then
			aiCoreEntity = nil
		end
	end
	--Update status info:
	local status = entityGUI.get_determine_entity_status( aiCoreEntity )
	innerFrameLeft[ "ai-core-GUI-left-status" ][ "ai-core-GUI-left-status-sprite" ].sprite = status.sprite
	innerFrameLeft[ "ai-core-GUI-left-status" ][ "ai-core-GUI-left-status-label"].caption = status.message

	--If aiCoreEntity is nil, set the preview to nil entity, then hide the entity pane.
	if aiCoreEntity == nil then
		innerFrameLeft[ "ai-core-GUI-left-deep" ][ "ai-core-GUI-left-preview" ].entity = nil
		innerFrameLeft.visible = false
		--Re-center the GUI:
		entityGUI.get_top_level_element( player ).force_auto_center()
	end
end

--Updates everything in the AI Cores GUI that cares about whether or not research is enabled,
--except for things in the entity status section.  Of course, does nothing if the GUI isn't open.
function entityGUI.update_research_enabled_except_entity_status( player )
	if not entityGUI.get_has_GUI( player ) then
		return
	end
	--Create all the local references to data we'll use multiple times:
	local rightFlow = entityGUI.get_top_level_element( player )[ "ai-core-GUI-inner" ][ "ai-core-GUI-right" ][ "ai-core-GUI-right-flow" ]
	local researchSection = rightFlow[ "ai-core-GUI-research" ]
	local researchEnabled = player.force.research_enabled

	--Set different LuaGuiElements to be visible/hidden based on researchEnabled:
	researchSection[ "ai-core-GUI-research-disabled" ].visible = not researchEnabled
	researchSection[ "ai-core-GUI-research-difficulty" ].visible = researchEnabled
	researchSection[ "ai-core-GUI-research-algorithm" ].visible = researchEnabled
	rightFlow[ "ai-core-GUI-bonus" ].visible = researchEnabled
end

--Updates the bonuses section of the AI Cores GUI.  Doesn't hide/unhide that section (that's done by the function
--entityGUI.update_research_enabled_except_entity_status( player )) but can hide/unhide certain things in the section
--such as splitting the bonuses into 3 rows or merging into 1.
--Note that this doesn't recalculate anything, it only updates the values displayed based on the associated forceData object.
--Of course, does nothing if the GUI isn't open.
function entityGUI.update_bonus_values( player )
	if not entityGUI.get_has_GUI( player ) then
		return
	end
	--Create a local reference to a LuaGuiElement that is the parent of the elements we'll be working with:
	local bonusSection = entityGUI.get_top_level_element( player )[ "ai-core-GUI-inner" ][ "ai-core-GUI-right" ][ "ai-core-GUI-right-flow" ][ "ai-core-GUI-bonus" ]
	--Format the numbers we will want as LocalisedStrings:
	local formattedBonuses = entityGUI.get_format_force_bonuses( player )

	bonusSection[ "ai-core-GUI-bonus-tech" ][ "ai-core-GUI-bonus-tech-value" ].caption = formattedBonuses.technology
	bonusSection[ "ai-core-GUI-bonus-ai-cores" ][ "ai-core-GUI-bonus-ai-cores-value" ].caption = formattedBonuses.aiCore
	bonusSection[ "ai-core-GUI-bonus-final" ][ "ai-core-GUI-bonus-final-value" ].caption = formattedBonuses.final

	--Expand the GUI if the player HAS researched any techs that grant research productivity bonuses.
	--Simplify the GUI if the player hasn't researched any techs that grant research productivity bonuses.
	if entityGUI.get_should_breakdown_bonuses( player ) then
		bonusSection[ "ai-core-GUI-bonus-tech" ].visible = true
		bonusSection[ "ai-core-GUI-bonus-ai-cores" ].tooltip = { "ai-core-gui.bonus-ai-cores-tooltip" }
		bonusSection[ "ai-core-GUI-bonus-final" ].visible = true
	else
		bonusSection[ "ai-core-GUI-bonus-tech" ].visible = false
		bonusSection[ "ai-core-GUI-bonus-ai-cores" ].tooltip = { "ai-core-gui.bonus-ai-cores-tooltip-alone" }
		bonusSection[ "ai-core-GUI-bonus-final" ].visible = false
	end
end

--Updates the technology difficulty displayed in the AI Cores GUI.  Does nothing else.
--Of course, does nothing if the GUI isn't open.
function entityGUI.update_technology_difficulty( player )
	if not entityGUI.get_has_GUI( player ) then
		return
	end
	entityGUI.get_top_level_element( player )[ "ai-core-GUI-inner" ][ "ai-core-GUI-right" ][ "ai-core-GUI-right-flow" ][ "ai-core-GUI-research" ][ "ai-core-GUI-research-difficulty" ][ "ai-core-GUI-research-difficulty-value" ].caption = get_technology_difficulty_as_localised_string()
end

--Updates the algorithm level displayed in the AI Cores GUI.  Does nothing else.
--Of course, does nothing if the GUI isn't open.
function entityGUI.update_algorithm_level( player )
	if not entityGUI.get_has_GUI( player ) then
		return
	end
	entityGUI.get_top_level_element( player )[ "ai-core-GUI-inner" ][ "ai-core-GUI-right" ][ "ai-core-GUI-right-flow" ][ "ai-core-GUI-research" ][ "ai-core-GUI-research-algorithm" ][ "ai-core-GUI-research-algorithm-value" ].caption = global.forceData[ player.force.name ].algorithmLevel
end

--If the AI Cores GUI was open, clears it & recreates it from scratch.  If possible, preserves which entity was open.
--Does nothing if the GUI isn't open.
function entityGUI.repopulate( player )
	if not entityGUI.get_has_GUI( player ) then
		return
	end
	local topLevelFrame = entityGUI.get_top_level_element( player )
	--Save a reference to the LuaEntity that was opened:
	local aiCoreEntity = topLevelFrame[ "ai-core-GUI-inner" ][ "ai-core-GUI-left" ][ "ai-core-GUI-left-deep" ][ "ai-core-GUI-left-preview" ].entity
	
	topLevelFrame.clear()
	topLevelFrame.force_auto_center()
	entityGUI.populate( player, aiCoreEntity )
end