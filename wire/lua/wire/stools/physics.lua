AddCSLuaFile( "physics.lua" )

--wire_weight
WireToolSetup.open( "weight", "Physics", "Weight", "gmod_wire_weight", WireToolMakeWeight )

if CLIENT then
    language.Add( "Tool_wire_weight_name", "Weight Tool (Wire)" )
    language.Add( "Tool_wire_weight_desc", "Spawns a weight." )
    language.Add( "Tool_wire_weight_0", "Primary: Create/Update weight" )
    language.Add( "WireDataWeightTool_weight", "Weight:" )
	language.Add( "sboxlimit_wire_weights", "You've hit weights limit!" )
end
WireToolHelpers.BaseLang("Weights")

if SERVER then
	CreateConVar('sbox_maxwire_weights', 20)
	ModelPlug_Register("weight")
end
 
TOOL.ClientConVar = {model	= "models/props_interiors/pot01a.mdl"}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakeModelSel(panel, "wire_weight")
end


