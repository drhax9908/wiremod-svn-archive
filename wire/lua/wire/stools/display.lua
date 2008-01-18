AddCSLuaFile( "display.lua" )

local function GetScreenAngle( self, Ang )
	if (self:GetClientNumber("createflat") == 1) then
		Ang.pitch = Ang.pitch - 90
	end
	return Ang
end


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

TOOL.ClientConVar = {
	noclip	= "0",
	model	= "models/jaanus/wiretool/wiretool_siren.mdl",
	a	= "0",
	ar	= "255",
	ag	= "0",
	ab	= "0",
	aa	= "255",
	b	= "1",
	br	= "0",
	bg	= "255",
	bb	= "0",
	ba	= "255",
	rotate90 = "0",
	material = "models/debug/debugwhite"
}

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

TOOL.ClientConVar = {
	model = "models/segment.mdl",
	ar = "70", --default: dark grey off, full red on
	ag = "70",
	ab = "70",
	aa = "255",
	br = "255",
	bg = "0",
	bb = "0",
	ba = "255",
	worldweld = "1"
}

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
TOOL.NoLeftOnClass = true

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
TOOL.NoLeftOnClass = true

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




--wire_lamp
WireToolSetup.open( "lamp", "Display", "Lamp", "gmod_wire_lamp", WireToolMakeLamp )

if ( CLIENT ) then
    language.Add( "Tool_wire_lamp_name", "Wire Lamps" )
    language.Add( "Tool_wire_lamp_desc", "Spawns a lamp for use with the wire system." )
    language.Add( "Tool_wire_lamp_0", "Primary: Create hanging lamp Secondary: Create unattached lamp" )
    language.Add( "WireLampTool_RopeLength", "Rope Length:")
    language.Add( "WireLampTool_Color", "Color:" )
    language.Add( "WireLampTool_Const", "Constraint:" )
	language.Add( "SBoxLimit_wire_lamps", "You've hit the wire lamps limit!" )
	language.Add( "undone_gmod_wire_lamp", "Undone Wire Lamp" )
    language.Add( "Cleanup_gmod_wire_lamp", "Wire Lamps" )
	language.Add( "Cleaned_gmod_wire_lamp", "Cleaned up all Wire Lamps" )
end

cleanup.Register( "gmod_wire_lamp" )

if (SERVER) then
	CreateConVar('sbox_maxwire_lamps', 10)
end

TOOL.GhostAngle = Angle(180, 0, 0)
TOOL.Model = "models/props_wasteland/prison_lamp001c.mdl"
TOOL.ClientConVar = {
	ropelength = "64",
	ropematerial = "cable/rope",
	r = "255",
	g = "255",
	b = "255",
	const = "rope",
	texture = "effects/flashlight001"
}

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_lamp_name", Description = "#Tool_wire_lamp_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = 1,
		Folder = "wire_lamp",

		Options = {
			["#Default"] = {
				wire_lamp_ropelength = "64",
				wire_lamp_ropematerial = "cable/rope",
				wire_lamp_texture		=		"effects/flashlight001",
				wire_lamp_r = "0",
				wire_lamp_g = "0",
				wire_lamp_b = "0"
			}
		},

		CVars = {
			[0] = "wire_lamp_ropelength",
			[1] = "wire_lamp_ropematerial",
			[2] = "wire_lamp_r",
			[3] = "wire_lamp_g",
			[4] = "wire_lamp_b",
			[5] = "wire_texture",
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireLampTool_RopeLength",
		Type = "Float",
		Min = "4",
		Max = "400",
		Command = "wire_lamp_ropelength"
	})

	panel:AddControl("Color", {
		Label = "#WireLampTool_Color",
        Red	= "wire_lamp_r",
		Green = "wire_lamp_g",
		Blue = "wire_lamp_b",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("ComboBox", {
		Label = "#WireLampTool_Const",
		Options = {
			["Rope"]	= { wire_lamp_const = "rope" },
			["Weld"]	= { wire_lamp_const = "weld" },
			["None"]	= { wire_lamp_const = "none" },
		}
	})

	local MatSelect = panel:MatSelect( "wire_lamp_texture", nil, true, 0.33, 0.33 )

	for k, v in pairs( list.Get( "LampTextures" ) ) do
		MatSelect:AddMaterial( v.Name or k, k )
	end
end




--wire_light
WireToolSetup.open( "light", "Display", "Light", "gmod_wire_light", WireToolMakeLight )

if ( CLIENT ) then
    language.Add( "Tool_wire_light_name", "Light Tool (Wire)" )
    language.Add( "Tool_wire_light_desc", "Spawns a Light for use with the wire system." )
    language.Add( "Tool_wire_light_0", "Primary: Create Light" )
    language.Add( "WireLightTool_directional", "Directional Component:" )
    language.Add( "WireLightTool_radiant", "Radiant Component:" )
 	language.Add( "sboxlimit_wire_lights", "You've hit Lights limit!" )
	language.Add( "undone_gmod_wire_light", "Undone Wire Light" )
	language.Add( "Cleanup_gmod_wire_light", "Wire Lights" )
	language.Add( "Cleaned_gmod_wire_light", "Cleaned Up Wire Lights" )
end

cleanup.Register( "gmod_wire_light" )

if (SERVER) then
	CreateConVar('sbox_maxwire_lights', 8)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar = {
	directional = "0",
	radiant = "0"
}

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_light_name", Description = "#Tool_wire_light_desc" })
	
		panel:AddControl("CheckBox", {
		Label = "#WireLightTool_directional",
		Command = "wire_light_directional"
	})

		panel:AddControl("CheckBox", {
		Label = "#WireLightTool_radiant",
		Command = "wire_light_radiant"
	})

end




--wire_oscilloscope
WireToolSetup.open( "oscilloscope", "Display", "Oscilloscope", "gmod_wire_oscilloscope", WireToolMakeOscilloscope )

if ( CLIENT ) then
    language.Add( "Tool_wire_oscilloscope_name", "Oscilloscope Tool (Wire)" )
    language.Add( "Tool_wire_oscilloscope_desc", "Spawns a oscilloscope what display line graphs." )
    language.Add( "Tool_wire_oscilloscope_0", "Primary: Create/Update oscilloscope" )
	language.Add( "sboxlimit_wire_oscilloscopes", "You've hit oscilloscopes limit!" )
	language.Add( "undone_gmod_wire_oscilloscope", "Undone Wire Oscilloscope" )
	language.Add( "Cleanup_gmod_wire_oscilloscope", "Wire Oscilloscopes" )
	language.Add( "Cleaned_gmod_wire_oscilloscope", "Cleaned Up Wire Oscilloscopes" )
end

cleanup.Register( "gmod_wire_oscilloscope" )

if (SERVER) then
	CreateConVar('sbox_maxwire_oscilloscopes', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"
TOOL.NoLeftOnClass = true

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_oscilloscope_name", Description = "#Tool_wire_oscilloscope_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_oscilloscope_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_oscilloscope_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_oscilloscope_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_oscilloscope_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_oscilloscope_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
end




--wire_panel
WireToolSetup.open( "panel", "Display", "Panel", "gmod_wire_panel", WireToolMakePanel )

if ( CLIENT ) then
    language.Add( "Tool_wire_panel_name", "Control Panel Tool (Wire)" )
    language.Add( "Tool_wire_panel_desc", "Spawns a panel what display values." )
    language.Add( "Tool_wire_panel_0", "Primary: Create/Update panel" )
	language.Add( "sboxlimit_wire_panels", "You've hit panels limit!" )
	language.Add( "Tool_wire_panel_createflat", "Create flat to surface:" )
	language.Add( "undone_gmod_wire_panel", "Undone Wire Control Panel" )
	language.Add( "Cleanup_gmod_wire_panel", "Wire Control Panels" )
	language.Add( "Cleaned_gmod_wire_panel", "Cleaned Up Wire Control Panels" )
end

cleanup.Register( "gmod_wire_panel" )

if (SERVER) then
	CreateConVar('sbox_maxwire_panels', 20)
end

TOOL.GetGhostAngle = GetScreenAngle
TOOL.ClientConVar = {
	model = "models/props_lab/monitor01b.mdl",
	createflat = "1",
	weld = "1"
}
TOOL.NoLeftOnClass = true

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_panel_name", Description = "#Tool_wire_panel_desc" })

	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",

		Options = {
			["#Small tv"]		= { wire_panel_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_panel_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_panel_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_panel_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_panel_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})

	panel:AddControl( "PropSelect", {
		Label = "#WireThrusterTool_Model",
		ConVar = "wire_panel_model",
		Category = "WirePanelModels",
		Models = list.Get( "WireScreenModels" ),
		Height = 2
	})

	panel:AddControl("Checkbox", {Label = "#Tool_wire_panel_createflat", Command = "wire_panel_createflat"})

	panel:AddControl("Checkbox", {Label = "Weld:", Command = "wire_panel_weld"})
end




--wire_pixel
WireToolSetup.open( "pixel", "Display", "Pixel", "gmod_wire_panel", WireToolMakePixel )

if ( CLIENT ) then
    language.Add( "Tool_wire_pixel_name", "Pixel Tool (Wire)" )
    language.Add( "Tool_wire_pixel_desc", "Spawns a Pixel for use with the wire system." )
    language.Add( "Tool_wire_pixel_0", "Primary: Create Pixel" )
    language.Add( "WirePixelTool_model", "Model:" )
 	language.Add( "sboxlimit_wire_pixels", "You've hit Pixels limit!" )
	language.Add( "undone_gmod_wire_panel", "Undone Wire Pixel" )
	language.Add( "Cleanup_gmod_wire_panel", "Wire Pixels" )
	language.Add( "Cleaned_gmod_wire_panel", "Cleaned Up Wire Pixels" )
end

cleanup.Register( "gmod_wire_panel" )

if (SERVER) then
	CreateConVar('sbox_maxwire_pixels', 20)
	ModelPlug_Register("pixel")
end

TOOL.ClientConVar = {
	noclip = "0",
	model = "models/jaanus/wiretool/wiretool_siren.mdl"
}

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_pixel_name", Description = "#Tool_wire_pixel_desc" })
	
	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_pixel_noclip"
	})
	
	ModelPlug_AddToCPanel(panel, "pixel", "wire_pixel", "#WirePixelTool_model", nil, "#WirePixelTool_model")
end




--wire_screen
WireToolSetup.open( "screen", "Display", "Screen", "gmod_wire_screen", WireToolMakeScreen )

if ( CLIENT ) then
    language.Add( "Tool_wire_screen_name", "Screen Tool (Wire)" )
    language.Add( "Tool_wire_screen_desc", "Spawns a screen that display values." )
    language.Add( "Tool_wire_screen_0", "Primary: Create/Update screen" )
	language.Add("Tool_wire_screen_singlevalue", "Only one value:")
	language.Add("Tool_wire_screen_singlebigfont", "Use bigger font for single-value screen:")
	language.Add("Tool_wire_screen_texta", "Text A:")
	language.Add("Tool_wire_screen_textb", "Text B:")
	language.Add("Tool_wire_screen_leftalign", "Left alignment:")
	language.Add("Tool_wire_screen_floor", "Floor screen value:")
	language.Add("Tool_wire_screen_createflat", "Create flat to surface:")
	language.Add( "sboxlimit_wire_screens", "You've hit screens limit!" )
	language.Add( "undone_gmod_wire_screen", "Undone Wire Screen" )
	language.Add( "Cleanup_gmod_wire_screen", "Wire Screens" )
	language.Add( "Cleaned_gmod_wire_screen", "Cleaned Up Wire Screens" )
end

cleanup.Register( "gmod_wire_screen" )

if (SERVER) then
	CreateConVar('sbox_maxwire_screens', 20)
end

TOOL.GetGhostAngle = GetScreenAngle
TOOL.ClientConVar = {
	model = "models/props_lab/monitor01b.mdl",
	singlevalue = "0",
	singlebigfont = "1",
	texta = "Value A",
	textb = "Value B",
	createflat = "1",
	leftalign = "0",
	floor = "0"
}

local MaxTextLength = 20

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_screen_name", Description = "#Tool_wire_screen_desc" })

	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_screen_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_screen_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_screen_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_screen_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_screen_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})

	panel:AddControl( "PropSelect", {
		Label = "#WireThrusterTool_Model",
		ConVar = "wire_screen_model",
		Category = "",
		Models = list.Get( "WireScreenModels" ),
		Height = 2
	})

	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_singlevalue", Command = "wire_screen_singlevalue"})
	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_singlebigfont", Command = "wire_screen_singlebigfont"})

	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_leftalign", Command = "wire_screen_leftalign"})
	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_floor", Command = "wire_screen_floor"})

	panel:AddControl("TextBox", {Label = "#Tool_wire_screen_texta", MaxLength = tostring(MaxTextLength), Command = "wire_screen_texta"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_screen_textb", MaxLength = tostring(MaxTextLength), Command = "wire_screen_textb"})

	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_createflat", Command = "wire_screen_createflat"})
end




--wire_soundemitter
WireToolSetup.open( "soundemitter", "Display", "Sound Emitter", "gmod_wire_soundemitter", WireToolMakeSoundEmitter )

if ( CLIENT ) then
    language.Add( "Tool_wire_soundemitter_name", "Sound Emitter Tool (Wire)" )
    language.Add( "Tool_wire_soundemitter_desc", "Spawns a sound emitter for use with the wire system." )
    language.Add( "Tool_wire_soundemitter_0", "Primary: Create/Update Sound Emitter" )
    language.Add( "WireEmitterTool_sound", "Sound:" )
    language.Add( "WireEmitterTool_collision", "Collision:" )
    language.Add( "WireEmitterTool_model", "Model:" )
	language.Add( "sboxlimit_wire_soundemitters", "You've hit soundemitters limit!" )
	language.Add( "undone_gmod_wire_soundemitter", "Undone Wire Soundemitter" )
	language.Add( "Cleanup_gmod_wire_soundemitter", "Wire Soundemitters" )
	language.Add( "Cleaned_gmod_wire_soundemitter", "Cleaned Up Wire Soundemitters" )
end

cleanup.Register( "gmod_wire_soundemitter" )

if (SERVER) then
	CreateConVar('sbox_maxwire_emitters', 10)
	ModelPlug_Register("speaker")
end

TOOL.ClientConVar = {
	sound = "common/warning.wav",
	collision = "0",
	model = "models/cheeze/wires/speaker.mdl"
}

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_soundemitter_name", Description = "#Tool_wire_soundemitter_desc" })
		
	panel:AddControl("ComboBox", {
		Label = "#WireEmitterTool_sound",
		MenuButton = "1", -- Don't remove that "MenuButton = 1" again please. Without that, we can't save our sounds, we added manually @aVoN
		Folder = "wire_soundemitter",
		Options = list.Get( "WireSounds" ),
	})

	panel:AddControl("TextBox", {
		Label = "#WireEmitterTool_sound",
		Command = "wire_soundemitter_sound",
		MaxLength = "200"
	})

	panel:AddControl("CheckBox", { Label = "#WireEmitterTool_collision", Command = "wire_emitter_collision" })

	ModelPlug_AddToCPanel(panel, "speaker", "wire_soundemitter", "#WireEmitterTool_model", nil, "#WireEmitterTool_model")
end




--wire_textscreen
--Wire text screen by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
WireToolSetup.open( "textscreen", "Display", "Text Screen", "gmod_wire_textscreen", WireToolMakeTextScreen )

TOOL.Model = "models/kobilica/wiremonitorbig.mdl"

if ( CLIENT ) then
    language.Add( "Tool_wire_textscreen_name", "Text Screen Tool (Wire)" )
    language.Add( "Tool_wire_textscreen_desc", "Spawns a screen that display text." )
    language.Add( "Tool_wire_textscreen_0", "Primary: Create/Update text screen" )
	language.Add( "sboxlimit_wire_textscreens", "You've hit text screens limit!" )
	language.Add( "undone_gmod_wire_textscreen", "Undone Wire Text Screen" )
	language.Add( "Cleanup_gmod_wire_textscreen", "Wire Text Screens" )
	language.Add( "Cleaned_gmod_wire_textscreen", "Cleaned Up Wire Text Screens" )

	language.Add("Tool_wire_textscreen_text1", "Text 1:")
	language.Add("Tool_wire_textscreen_text2", "Text 2:")
	language.Add("Tool_wire_textscreen_text3", "Text 3:")
	language.Add("Tool_wire_textscreen_text4", "Text 4:")
	language.Add("Tool_wire_textscreen_text5", "Text 5:")
	language.Add("Tool_wire_textscreen_text6", "Text 6:")
	language.Add("Tool_wire_textscreen_text7", "Text 7:")
	language.Add("Tool_wire_textscreen_text8", "Text 8:")
	language.Add("Tool_wire_textscreen_text9", "Text 9:")
	language.Add("Tool_wire_textscreen_text10", "Text 10:")
	language.Add("Tool_wire_textscreen_text11", "Text 12:")
	language.Add("Tool_wire_textscreen_text12", "Text 12:")
	language.Add("Tool_wire_textscreen_tsize", "Text size:")
	language.Add("Tool_wire_textscreen_tjust", "Text justification:")
	language.Add("Tool_wire_textscreen_colour", "Text colour:")

	language.Add("Tool_wire_textscreen_ninputs", "Number of inputs:")

	language.Add("Tool_wire_textscreen_createflat", "Create flat to surface:")
	language.Add("Tool_wire_textscreen_defaulton", "Force show text (make wires optional):")
end

cleanup.Register( "gmod_wire_textscreen" )

if (SERVER) then
	CreateConVar('sbox_maxwire_textscreens', 20)
end

TOOL.GetGhostAngle = GetScreenAngle
TOOL.ClientConVar = {
	tsize = 10,
	tjust = 1,
	tred = 255,
	tblue = 255,
	tgreen = 255,
	ninputs = 3,
	defaulton = 1,
	createflat = 1
}
for i = 1, 12 do
	TOOL.ClientConVar["text"..i] = ""	
end

local TSMaxTextLength = "80"

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_textscreen_name", Description = "#Tool_wire_textscreen_desc" })

	panel:AddControl("Slider", {Label = "#Tool_wire_textscreen_tsize", Description = "", Type = "Integer", Min = "1", Max = "15", Command = "wire_textscreen_tsize"})
	panel:AddControl("Slider", {Label = "#Tool_wire_textscreen_tjust", Description = "", Type = "Integer", Min = "0", Max = "2", Command = "wire_textscreen_tjust"})
	panel:AddControl("Slider", {Label = "#Tool_wire_textscreen_ninputs", Description = "", Type = "Integer", Min = "1", Max = "10", Command = "wire_textscreen_ninputs"})
	panel:AddControl("Color", {
		Label = "#Tool_wire_textscreen_colour",
		Red = "wire_textscreen_tred",
		Green = "wire_textscreen_tgreen",
		Blue = "wire_textscreen_tblue",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	panel:AddControl("Checkbox", {Label = "#Tool_wire_textscreen_createflat", Command = "wire_textscreen_createflat"})
	panel:AddControl("Checkbox", {Label = "#Tool_wire_textscreen_defaulton", Command = "wire_textscreen_defaulton"})

	for i = 1, 12 do
		panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text"..i, MaxLength = TSMaxTextLength, Command = "wire_textscreen_text"..i})
	end
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

TOOL.ClientConVar ={
	r	= "255",
	g	= "255",
	b	= "255",
	a	= "255",
	showbeams	= "1",
	size	= "4"
}

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"
TOOL.Emitter = nil
TOOL.NoGhostOn = { "gmod_wire_hologrid" }

function TOOL:RightClick( tr )
	if( !tr.HitNonWorld || tr.Entity:GetClass() != "gmod_wire_holoemitter" ) then return false end
	if( CLIENT ) then return true end
	
	self.Emitter = tr.Entity
	
	return true
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool_wire_holoemitter_name", Description = "#Tool_wire_holoemitter_desc", } )

	panel:AddControl( "Checkbox", {
		Label = "#Tool_wire_holoemitter_showbeams",
		Command = "wire_holoemitter_showbeams",
	})

	panel:AddControl( "Slider", {
		Label = "#Tool_wire_holoemitter_size",
		Type = "Float",
		Min = "1",
		Max = "32",
		Command = "wire_holoemitter_size",
	})

	panel:AddControl( "Color", {
		Label 	= "Color",
		Red 	= "wire_holoemitter_r",
		Green 	= "wire_holoemitter_g",
		Blue 	= "wire_holoemitter_b",
		Alpha 	= "wire_holoemitter_a",
		ShowAlpha	= "1",
		ShowHSV		= "1",
		ShowRGB		= "1",
		Multiplier	= "255",
	})

	if(not SinglePlayer( )) then
		panel:AddControl( "Slider", {
			Label = "#Tool_wire_holoemitter_minimum_fade_rate",
			Type = "Float",
			Min = "0.1",
			Max = "100",
			Command = "cl_wire_holoemitter_minfaderate",
		})
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
TOOL.NoLeftOnClass = true

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", {Text = "#Tool_wire_hologrid_name", Description = "#Tool_wire_hologrid_desc", } )
end


