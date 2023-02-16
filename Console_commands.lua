--Console_commands.lua
--Contains just the console commands for Q's AI Core Mod.
--In the past there were 2 console commands, but that number has since changed.
--This file was coded by Q.

--The path to the sound that is used for console messages:
local CONSOLE_SFX_PATH = "utility/console_message"

--=========================================================================================================--
--                          CONSOLE COMMAND FOR DEVELOPERS TO VIEW AI CORE DEBUG INFO,
--                 WHICH IS HIGHLY DETAILED SINCE IT CONTAINS ALL INFORMATION RELEVANT TO AI CORES
--=========================================================================================================--

--This is the command to open the debug GUI.  If the debug GUI is already open, this command closes the GUI instead.
--Although this command is only meant for debug purposes, I'll leave it in the game anyways
--on the off chance that someone needs the information to locate a bug.
commands.add_command( "ai-core-debug", { "command-help.ai-core-debug" }, function( params )
	if type( params.player_index ) ~= "number" then
		error( "Error in command \"ai-core-debug\": expected player_index to be a number, but it wasn't a number." )
		return
	end
	if type( debugGUI ) ~= "table" then
		error( "Error in command \"ai-core-debug\": debugGUI table not loaded!" )
		return
	end
	--Else, we have a valid player, so save a reference to them:
	local player = game.players[ params.player_index ]

	--If the player has the GUI open, destroy the GUI.  Otherwise, create the GUI.
	if debugGUI.has_GUI( player ) then
		debugGUI.destroy( player )
	else
		debugGUI.create( player )
	end
	player.play_sound{ path = CONSOLE_SFX_PATH }
end )