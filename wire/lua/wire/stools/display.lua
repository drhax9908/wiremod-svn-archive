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



