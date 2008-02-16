AddCSLuaFile( "io.lua" )
WireToolSetup.setCategory( "I/O" )

--wire_adv_input
WireToolSetup.open( "adv_input", "Adv. Input", "gmod_wire_adv_input", WireToolMakeAdvInput )

if CLIENT then
    language.Add( "Tool_wire_adv_input_name", "Adv. Input Tool (Wire)" )
    language.Add( "Tool_wire_adv_input_desc", "Spawns a adv. input for use with the wire system." )
    language.Add( "Tool_wire_adv_input_0", "Primary: Create/Update Adv. Input" )
    language.Add( "WireAdvInputTool_keymore", "Increase:" )
	language.Add( "WireAdvInputTool_keyless", "Decrease:" )
    language.Add( "WireAdvInputTool_toggle", "Toggle:" )
    language.Add( "WireAdvInputTool_value_min", "Minimum:" )
    language.Add( "WireAdvInputTool_value_max", "Maximum:" )
	language.Add( "WireAdvInputTool_value_start", "Start at:" )
	language.Add( "WireAdvInputTool_speed", "Change per second:" )
	language.Add( "sboxlimit_wire_adv_inputs", "You've hit wired adv input limit!" )
end
WireToolHelpers.BaseLang("Adv. Inputs")

if SERVER then
  CreateConVar('sbox_maxwire_adv_inputs',20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"
TOOL.ClientConVar = {
	keymore = "3",
	keyless = "1",
	toggle = "0",
	value_min = "0",
	value_max = "10",
	value_start = "5",
	speed = "1"
}

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keymore", Command = "wire_adv_input_keymore"})
	CPanel:AddControl( "Numpad", {Label = "#WireAdvInputTool_keyless", Command = "wire_adv_input_keyless"})
	CPanel:CheckBox("#WireAdvInputTool_toggle", "wire_adv_input_toggle")
	CPanel:NumSlider("#WireAdvInputTool_value_min", "wire_adv_input_value_min", -50, 50, 0)
	CPanel:NumSlider("#WireAdvInputTool_value_max", "wire_adv_input_value_max", -50, 50, 0)
	CPanel:NumSlider("#WireAdvInputTool_value_start", "wire_adv_input_value_start", -50, 50, 0)
	CPanel:NumSlider("#WireAdvInputTool_speed", "wire_adv_input_speed", 0.1, 50, 1)
end




--wire_adv_pod
WireToolSetup.open( "adv_pod", "Advanced Pod Controller", "gmod_wire_adv_pod", WireToolMakeAdvPod )

if CLIENT then
	language.Add("Tool_wire_adv_pod_name", "Advanced Pod Controller Tool (Wire)")
	language.Add("Tool_wire_adv_pod_desc", "Spawn/link a Wire Advanced Pod controller.")
	language.Add("Tool_wire_adv_pod_0", "Primary: Create Advanced Pod controller. Secondary: Link Advanced controller.")
	language.Add("Tool_wire_adv_pod_1", "Now select the pod to link to.")
end
WireToolHelpers.BaseLang("Adv. Pod Controllers")

if SERVER then
	ModelPlug_Register("podctrlr")
end

TOOL.NoLeftOnClass = true
TOOL.ClientConVar = {model	= "models/jaanus/wiretool/wiretool_siren.mdl"}

function TOOL:RightClick(trace)
	if (self:GetStage() == 0) and trace.Entity:GetClass() == "gmod_wire_adv_pod" then
		self.PodCont = trace.Entity
		self:SetStage(1)
		return true
	elseif self:GetStage() == 1 and trace.Entity.GetPassenger then
		self.PodCont:Setup(trace.Entity)
		self:SetStage(0)
		self.PodCont = nil
		return true
	else
		return false
	end
end

function TOOL:Reload(trace)
	self:SetStage(0)
	self.PodCont = nil
end

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "podctrlr", "wire_adv_pod", "#ToolWireIndicator_Model")
end




--wire_button
WireToolSetup.open( "button", "Button", "gmod_wire_button", WireToolMakeButton )

if CLIENT then
    language.Add( "Tool_wire_button_name", "Button Tool (Wire)" )
    language.Add( "Tool_wire_button_desc", "Spawns a button for use with the wire system." )
    language.Add( "Tool_wire_button_0", "Primary: Create/Update Button" )
    language.Add( "WireButtonTool_toggle", "Toggle:" )
    language.Add( "WireButtonTool_value_on", "Value On:" )
    language.Add( "WireButtonTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_buttons", "You've hit wired buttons limit!" )
end
WireToolHelpers.BaseLang("gmod_wire_button", "Buttons")

if SERVER then
	CreateConVar('sbox_maxwire_buttons', 20)
	ModelPlug_Register("button")
end

TOOL.ClientConVar = {
	model = "models/props_c17/clock01.mdl",
	toggle = "0",
	value_off = "0",
	value_on = "1",
	description = ""
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_button")
	ModelPlug_AddToCPanel(panel, "button", "wire_button", "#Button_Model", nil, "#Button_Model", 6)
	panel:CheckBox("#WireButtonTool_toggle", "wire_button_toggle")
	panel:NumSlider("#WireButtonTool_value_on", "wire_button_value_on", -10, 10, 1)
	panel:NumSlider("#WireButtonTool_value_off", "wire_button_value_off", -10, 10, 1)
end




--wire_adv_input
WireToolSetup.open( "dual_input", "Dual Input", "gmod_wire_dual_input", WireToolMakeDualInput )

if CLIENT then
    language.Add( "Tool_wire_dual_input_name", "Dual Input Tool (Wire)" )
    language.Add( "Tool_wire_dual_input_desc", "Spawns a daul input for use with the wire system." )
    language.Add( "Tool_wire_dual_input_0", "Primary: Create/Update Input" )
    language.Add( "WireDualInputTool_keygroup", "Key 1:" )
    language.Add( "WireDualInputTool_keygroup2", "Key 2:" )
    language.Add( "WireDualInputTool_toggle", "Toggle:" )
    language.Add( "WireDualInputTool_value_on", "Value 1 On:" )
    language.Add( "WireDualInputTool_value_on2", "Value 2 On:" )
    language.Add( "WireDualInputTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_dual_inputs", "You've hit inputs limit!" )
	language.Add( "undone_gmod_wire_dual_input", "Undone Wire Dual Input" )
	language.Add( "Cleanup_gmod_wire_dual_input", "Wire Dual Inputs" )
	language.Add( "Cleaned_gmod_wire_dual_input", "Cleaned Up Wire Dual Inputs" )
end
WireToolHelpers.BaseLang("Dual Inputs")

if SERVER then
	CreateConVar('sbox_maxwire_dual_inputs', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"
TOOL.ClientConVar = {
	keygroup = 7,
	keygroup2 = 4,
	toggle = 0,
	value_off = 0,
	value_on = 1,
	value_on2 = -1
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_dual_input")
	
	panel:AddControl("Numpad", {
		Label = "#WireDualInputTool_keygroup",
		Command = "wire_dual_input_keygroup"
	})
	
	panel:AddControl("Numpad", {
		Label = "#WireDualInputTool_keygroup2",
		Command = "wire_dual_input_keygroup2"
	})
	
	panel:CheckBox("#WireDualInputTool_toggle", "wire_dual_input_toggle")
	panel:NumSlider("#WireDualInputTool_value_on", "wire_dual_input_value_on", -10, 10, 1)
	panel:NumSlider("#WireDualInputTool_value_off", "wire_dual_input_value_off", -10, 10, 1)
	panel:NumSlider("#WireDualInputTool_value_on2", "wire_dual_input_value_on2", -10, 10, 1)
end




--wire_input
WireToolSetup.open( "input", "Numpad Input", "gmod_wire_input", WireToolMakeInput )

if CLIENT then
    language.Add( "Tool_wire_input_name", "Input Tool (Wire)" )
    language.Add( "Tool_wire_input_desc", "Spawns a input for use with the wire system." )
    language.Add( "Tool_wire_input_0", "Primary: Create/Update Input" )
    language.Add( "WireInputTool_keygroup", "Key:" )
    language.Add( "WireInputTool_toggle", "Toggle:" )
    language.Add( "WireInputTool_value_on", "Value On:" )
    language.Add( "WireInputTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_inputs", "You've hit inputs limit!" )
end
WireToolHelpers.BaseLang("Inputs")

if SERVER then
	CreateConVar('sbox_maxwire_inputs', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"
TOOL.ClientConVar = {
	keygroup = 7,
	toggle = 0,
	value_off = 0,
	value_on = 1
}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakePresetControl(panel, "wire_input")
	panel:AddControl("Numpad", {
		Label = "#WireInputTool_keygroup",
		Command = "wire_input_keygroup"
	})
	panel:CheckBox("#WireInputTool_toggle", "wire_input_toggle")
	panel:NumSlider("#WireInputTool_value_on", "wire_input_value_on", -10, 10, 1)
	panel:NumSlider("#WireInputTool_value_off", "wire_input_value_off", -10, 10, 1)
end

