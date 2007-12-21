AddCSLuaFile( "display.lua" )

--wire_indicator
WireToolSetup.open( "indicator", "Display", "Indicator", "gmod_wire_indicator", WireToolMakeIndicator )

if ( CLIENT ) then
    language.Add( "Tool_wire_indicator_name", "Indicator Tool (Wire)" )
    language.Add( "Tool_wire_indicator_desc", "Spawns a indicator for use with the wire system." )
    language.Add( "Tool_wire_indicator_0", "Primary: Create/Update Indicator" )
    language.Add( "ToolWireIndicator_Model", "Model:" )
    language.Add( "ToolWireIndicator_a_value", "A Value:" )
    language.Add( "ToolWireIndicator_a_colour", "A Colour:" )
    language.Add( "ToolWireIndicator_b_value", "B Value:" )
    language.Add( "ToolWireIndicator_b_colour", "B Colour:" )
    language.Add( "ToolWireIndicator_Material", "Material:" )
    language.Add( "ToolWireIndicator_90", "Rotate segment 90:" )
	language.Add( "sboxlimit_gmod_wire_indicator", "You've hit indicators limit!" )
	language.Add( "undone_gmod_wire_indicator", "Undone Wire Indicator" )
	language.Add( "Cleanup_gmod_wire_indicator", "Wire Indicators" )
	language.Add( "Cleaned_gmod_wire_indicator", "Cleanedup Wire Indicators" )
end

cleanup.Register( "gmod_wire_indicator" )

if (SERVER) then
	CreateConVar('sbox_maxwire_indicators', 20)
	ModelPlug_Register("indicator")
end

TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "a" ] = "0"
TOOL.ClientConVar[ "ar" ] = "255"
TOOL.ClientConVar[ "ag" ] = "0"
TOOL.ClientConVar[ "ab" ] = "0"
TOOL.ClientConVar[ "aa" ] = "255"
TOOL.ClientConVar[ "b" ] = "1"
TOOL.ClientConVar[ "br" ] = "0"
TOOL.ClientConVar[ "bg" ] = "255"
TOOL.ClientConVar[ "bb" ] = "0"
TOOL.ClientConVar[ "ba" ] = "255"
TOOL.ClientConVar[ "rotate90" ] = "0"
TOOL.ClientConVar[ "material" ] = "models/debug/debugwhite"

function TOOL:GetGhostAngle( Ang )
	local Model = self:GetClientInfo( "model" )
	--these models get mounted differently
	if (Model == "models/props_borealis/bluebarrel001.mdl" || Model == "models/props_junk/PopCan01a.mdl") then
		return Ang + Angle(180, 0, 0)
	elseif (Model == "models/props_trainstation/trainstation_clock001.mdl" || Model == "models/segment.mdl" || Model == "models/segment2.mdl") then
		return Ang + Angle(-90, 0, (self:GetClientNumber("rotate90") * 90))
	end
	return Ang
end

function TOOL:GetGhostMin( min )
	local Model = self:GetClientInfo( "model" )
	--these models are different
	if (Model == "models/props_trainstation/trainstation_clock001.mdl" || Model == "models/segment.mdl" || Model == "models/segment2.mdl") then
		return min.x
	end
	return min.z
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_indicator_name", Description = "#Tool_wire_indicator_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_indicator",

		Options = {
			["#Default"] = {
				wire_indicator_a = "0",
				wire_indicator_ar = "255",
				wire_indicator_ag = "0",
				wire_indicator_ab = "0",
				wire_indicator_aa = "255",
				wire_indicator_b = "1",
				wire_indicator_br = "0",
				wire_indicator_bg = "255",
				wire_indicator_bb = "0",
				wire_indicator_ba = "255",
				wire_indicator_model = "models/jaanus/wiretool/wiretool_siren.mdl",
				wire_indicator_material = "models/debug/debugwhite",
				wire_indicator_rotate90 = "0"
				
			}
		},

		CVars = {
			[0] = "wire_indicator_a",
			[1] = "wire_indicator_ar",
			[2] = "wire_indicator_ag",
			[3] = "wire_indicator_ab",
			[4] = "wire_indicator_aa",
			[5] = "wire_indicator_b",
			[6] = "wire_indicator_br",
			[7] = "wire_indicator_bg",
			[8] = "wire_indicator_bb",
			[9] = "wire_indicator_ba",
			[10] = "wire_indicator_model",
			[11] = "wire_indicator_material",
			[12] = "wire_indicator_rotate90"
		}
	})

	panel:AddControl("Slider", {
		Label = "#ToolWireIndicator_a_value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_indicator_a"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_a_colour",
		Red = "wire_indicator_ar",
		Green = "wire_indicator_ag",
		Blue = "wire_indicator_ab",
		Alpha = "wire_indicator_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("Slider", {
		Label =	"#ToolWireIndicator_b_value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_indicator_b"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireIndicator_b_colour",
		Red = "wire_indicator_br",
		Green = "wire_indicator_bg",
		Blue = "wire_indicator_bb",
		Alpha = "wire_indicator_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	
	ModelPlug_AddToCPanel(panel, "indicator", "wire_indicator", "#ToolWireIndicator_Model", nil, "#ToolWireIndicator_Model")
	
	panel:AddControl("ComboBox", {
		Label = "#ToolWireIndicator_Material",
		MenuButton = "0",

		Options = {
			["Matte"]	= { wire_indicator_material = "models/debug/debugwhite" },
			["Shiny"]	= { wire_indicator_material = "models/shiny" },
			["Metal"]	= { wire_indicator_material = "models/props_c17/metalladder003" }
		}
	})
	
	panel:AddControl("CheckBox", {
		Label = "#ToolWireIndicator_90",
		Command = "wire_indicator_rotate90"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_indicator_noclip"
	})
	
end




--wire_7seg
WireToolSetup.open( "7seg", "Display", "7 Segment Display", "gmod_wire_indicator", WireToolMake7Seg )

TOOL.GhostAngle = Angle(90, 0, 0)
TOOL.GhostMin = "x"

if ( CLIENT ) then
    language.Add( "Tool_wire_7seg_name", "7-Segment Display Tool" )
    language.Add( "Tool_wire_7seg_desc", "Spawns 7 indicators for numeric display with the wire system." )
    language.Add( "Tool_wire_7seg_0", "Primary: Create display/Update Indicator" )
    language.Add( "ToolWire7Seg_a_colour", "Off Colour:" )
	language.Add( "ToolWire7Seg_b_colour", "On Colour:" )
	language.Add( "ToolWire7SegTool_worldweld", "Allow weld to world:" )
	language.Add( "undone_wire7seg", "Undone 7-Segment Display" )
end

TOOL.ClientConVar[ "model" ] = "models/segment.mdl"
TOOL.ClientConVar[ "ar" ] = "70" --default: dark grey off, full red on
TOOL.ClientConVar[ "ag" ] = "70" 
TOOL.ClientConVar[ "ab" ] = "70"
TOOL.ClientConVar[ "aa" ] = "255"
TOOL.ClientConVar[ "br" ] = "255"
TOOL.ClientConVar[ "bg" ] = "0"
TOOL.ClientConVar[ "bb" ] = "0"
TOOL.ClientConVar[ "ba" ] = "255"
TOOL.ClientConVar[ "worldweld" ] = "1"

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_7seg_name", Description = "#Tool_wire_7seg_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_7seg",

		Options = {
			["#Default"] = {
				wire_7seg_ar = "255",
				wire_7seg_ag = "0",
				wire_7seg_ab = "0",
				wire_7seg_aa = "255",
				wire_7seg_br = "79",
				wire_7seg_bg = "79",
				wire_7seg_bb = "79",
				wire_7seg_ba = "255"
			}
		},

		CVars = {
			[0] = "wire_7seg_ar",
			[1] = "wire_7seg_ag",
			[2] = "wire_7seg_ab",
			[3] = "wire_7seg_aa",
			[4] = "wire_7seg_br",
			[5] = "wire_7seg_bg",
			[6] = "wire_7seg_bb",
			[7] = "wire_7seg_ba"
		}
	})
	
	panel:AddControl("Color", {
		Label = "#ToolWire7Seg_a_colour",
		Red = "wire_7seg_ar",
		Green = "wire_7seg_ag",
		Blue = "wire_7seg_ab",
		Alpha = "wire_7seg_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	
	panel:AddControl("Color", {
		Label = "#ToolWire7Seg_b_colour",
		Red = "wire_7seg_br",
		Green = "wire_7seg_bg",
		Blue = "wire_7seg_bb",
		Alpha = "wire_7seg_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("ComboBox", {
		Label = "#ToolWireIndicator_Model",
		MenuButton = "0",

		Options = {
			["Medium 7-seg bar"]	= { wire_7seg_model = "models/segment2.mdl" },
			["Small 7-seg bar"]		= { wire_7seg_model = "models/segment.mdl" },
		}
	})
	
	panel:AddControl("CheckBox", {
		Label = "#ToolWire7SegTool_worldweld",
		Command = "wire_7seg_worldweld"
	})
	
end




--wire_consolescreen
WireToolSetup.open( "consolescreen", "Display", "Console Screen", "gmod_wire_consolescreen", WireToolMakeConsoleScreen )

if ( CLIENT ) then
    language.Add( "Tool_wire_consolescreen_name", "Console Screen Tool (Wire)" )
    language.Add( "Tool_wire_consolescreen_desc", "Spawns a console screen" )
    language.Add( "Tool_wire_consolescreen_0", "Primary: Create/Update screen" )
	language.Add( "sboxlimit_wire_consolescreens", "You've hit console screens limit!" )
	language.Add( "undone_gmod_wire_consolescreen", "Undone Wire Screen" )
	language.Add( "Cleanup_gmod_wire_consolescreen", "Wire Screens" )
	language.Add( "Cleaned_gmod_wire_consolescreen", "Cleaned up wire screens" )
end

cleanup.Register( "gmod_wire_consolescreen" )

if (SERVER) then
	CreateConVar('sbox_maxwire_consolescreens', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_consolescreen_name", Description = "#Tool_wire_consolescreen_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_consolescreen_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_consolescreen_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_consolescreen_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_consolescreen_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_consolescreen_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
end




--wire_digitalscreen
WireToolSetup.open( "digitalscreen", "Display", "Digital Screen", "gmod_wire_digitalscreen", WireToolMakeDigitalScreen )

if ( CLIENT ) then
    language.Add( "Tool_wire_digitalscreen_name", "Digital Screen Tool (Wire)" )
    language.Add( "Tool_wire_digitalscreen_desc", "Spawns a digital screen, which can be used to draw pixel by pixel. Resoultion is 32x32!" )
    language.Add( "Tool_wire_digitalscreen_0", "Primary: Create/Update screen" )
	language.Add( "sboxlimit_wire_digitalscreens", "You've hit digital screens limit!" )
	language.Add( "undone_gmod_wire_digitalscreen", "Undone Wire Screen" )
	language.Add( "Cleanup_gmod_wire_digitalscreen", "Wire Screens" )
	language.Add( "Cleaned_gmod_wire_digitalscreen", "Cleaned Up Wire Screens" )
end

cleanup.Register( "gmod_wire_digitalscreen" )

if (SERVER) then
	CreateConVar('sbox_maxwire_digitalscreens', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_digitalscreen_name", Description = "#Tool_wire_digitalscreen_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_digitalscreen_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_digitalscreen_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_digitalscreen_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_digitalscreen_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_digitalscreen_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
end










-- Holography--

--wire_holoemitter
WireToolSetup.open( "holoemitter", "Holography", "Emitter", "gmod_wire_holoemitter", WireToolMakeEmitter )

if( CLIENT ) then
	language.Add( "Tool_wire_holoemitter_name", "Holographic Emitter Tool (Wire)" )
	language.Add( "Tool_wire_holoemitter_desc", "The emitter required for holographic projections" )
	language.Add( "Tool_wire_holoemitter_0", "Primary: Create emitter      Secondary: Link emitter" )
	language.Add( "Tool_wire_holoemitter_1", "Select the emitter point to link to." )
	language.Add( "Tool_wire_holoemitter_showbeams", "Show beam" )
	language.Add( "Tool_wire_holoemitter_size", "Point size" )
	language.Add( "Tool_wire_holoemitter_minimum_fade_rate", "CLIENT: Minimum Fade Rate - Applyed to all holoemitters" )
	language.Add( "sboxlimit_wire_holoemitters", "You've hit the holoemitters limit!" )
	language.Add( "undone_gmod_wire_holoemitter", "Undone Wire Holoemitter" )
	language.Add( "Cleanup_gmod_wire_holoemitter", "Wire Holoemitters" )
	language.Add( "Cleaned_gmod_wire_holoemitter", "Cleaned Up Wire Holoemitters" )
end

cleanup.Register( "gmod_wire_holoemitter" )

if( SERVER ) then CreateConVar( "sbox_maxwire_holoemitters", 30 ) end

TOOL.ClientConVar["r"]	= "255"
TOOL.ClientConVar["g"]	= "255"
TOOL.ClientConVar["b"]	= "255"
TOOL.ClientConVar["a"]	= "255"
TOOL.ClientConVar["showbeams"]	= "1"
TOOL.ClientConVar["size"]	= "4"

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"
TOOL.Emitter = nil
TOOL.NoGhostOn = { "gmod_wire_hologrid" }
TOOL.AllowLeftOnClass = true

function TOOL:RightClick( tr )
	if( !tr.HitNonWorld || tr.Entity:GetClass() != "gmod_wire_holoemitter" ) then return false end
	if( CLIENT ) then return true end
	
	self.Emitter = tr.Entity
	
	return true
end

function TOOL.BuildCPanel( panel )
	// add header.
	panel:AddControl(
		"Header",
		{
			Text 		= "#Tool_wire_holoemitter_name",
			Description 	= "#Tool_wire_holoemitter_desc",
		}
	)
	
	// show beams.
	panel:AddControl(
		"Checkbox",
		{
			Label = "#Tool_wire_holoemitter_showbeams",
			Command = "wire_holoemitter_showbeams",
		}
	)
	
	// point size
	panel:AddControl(
		"Slider",
		{
			Label = "#Tool_wire_holoemitter_size",
			Type = "Float",
			Min = "1",
			Max = "32",
			Command = "wire_holoemitter_size",
		}
	)
	
	// add color picker.
	panel:AddControl(
		"Color",
		{
			Label 	= "Color",
			Red 	= "wire_holoemitter_r",
			Green 	= "wire_holoemitter_g",
			Blue 	= "wire_holoemitter_b",
			Alpha 	= "wire_holoemitter_a",
			ShowAlpha	= "1",
			ShowHSV		= "1",
			ShowRGB		= "1",
			Multiplier	= "255",
		}
	)
	if(not SinglePlayer( )) then
		// Minimum Faderate
		panel:AddControl(
			"Slider",
			{
				Label = "#Tool_wire_holoemitter_minimum_fade_rate",
				Type = "Float",
				Min = "0.1",
				Max = "100",
				Command = "cl_wire_holoemitter_minfaderate",
			}
		)
	end
end




--wire_hologrid
WireToolSetup.open( "hologrid", "Holography", "Grid", "gmod_wire_hologrid", WireToolMakeHoloGrid )

if( CLIENT ) then
	language.Add( "Tool_wire_hologrid_name", "Holographic Grid Tool (Wire)" )
	language.Add( "Tool_wire_hologrid_desc", "The grid to aid in holographic projections" )
	language.Add( "Tool_wire_hologrid_0", "Primary: Create grid" )
	language.Add( "sboxlimit_wire_hologrids", "You've hit the hologrids limit!" )
	language.Add( "undone_gmod_wire_hologrid", "Undone Wire hologrid" )
	language.Add( "Cleanup_gmod_wire_hologrid", "Wire hologrids" )
	language.Add( "Cleaned_gmod_wire_hologrid", "Cleaned Up Wire hologrids" )
end

cleanup.Register( "gmod_wire_hologrid" )

if( SERVER ) then CreateConVar( "sbox_maxwire_hologrids", 30 ) end

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.NoGhostOn = { "sbox_maxwire_holoemitters" }

function TOOL.BuildCPanel( panel )
	// add header.
	panel:AddControl(
		"Header",
		{
			Text 		= "#Tool_wire_hologrid_name",
			Description 	= "#Tool_wire_hologrid_desc",
		}
	)
end






