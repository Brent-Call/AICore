--Local reference to the GUI styles object to which we're going to add new styles:
local styles = data.raw[ "gui-style" ][ "default" ]

--Draggable space widget used in the titlebar of the AI Cores GUI:
styles[ "Q-AICore:draggable_space_header" ] =
{
	type = "empty_widget_style",
	parent = "draggable_space_header",
	height = 24,
	horizontally_stretchable = "on"
}
--Horizontal flow used for the entity status widget in the AI Cores GUI:
styles[ "Q-AICore:entity_status_flow" ] =
{
	type = "horizontal_flow_style",
	parent = "status_flow",
	vertical_align = "center"
}
--A subheader frame except it's horizontally stretchable & it has a caption using the "heading-1" font:
styles[ "Q-AICore:stretchable_subheader_frame_with_caption" ] =
{
	type = "frame_style",
	parent = "subheader_frame",
	horizontally_stretchable = "on",
	title_style =
	{
		type = "label_style",
		parent = "frame_title",
		top_padding = 0,
		bottom_padding = 0,
		left_padding = 8,
		right_padding = 8
	},
	--Don't show a filler widget if the frame is stretched really far horizontally:
	use_header_filler = false
}
--A vertical flow that provides the padding.
--Intended to be used if it's inside a frame that doesn't provide its own side padding & if it's underneath a subheader.
--This type of thing occurs specifically inside the AI Cores GUI.
styles[ "Q-AICore:ai_core_padded_vertical_flow" ] =
{
	type = "vertical_flow_style",
	parent = "vertical_flow_in_entity_frame_without_side_paddings",
	top_padding = 4
}