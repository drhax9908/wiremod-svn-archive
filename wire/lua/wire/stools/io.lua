AddCSLuaFile( "io.lua" )


--wire_adv_input
WireToolSetup.open( "adv_input", "I/O", "Adv. Input", "gmod_wire_adv_input", WireToolMakeAdvInput )

if ( CLIENT ) then
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
	language.Add( "undone_gmod_wire_adv_input", "Undone Wire Adv. Input" )
	language.Add( "Cleanup_gmod_wire_adv_input", "Wire Adv. Inputs" )
	language.Add( "Cleaned_gmod_wire_adv_input", "Cleaned Up Wire Adv. Inputs" )
end

cleanup.Register( "gmod_wire_adv_input" )

if (SERVER) then
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
	CPanel:AddControl( "Header", { Text = "#Tool_wire_adv_input_name", Description	= "#Tool_wire_adv_input_desc" }  )
	CPanel:AddControl( "Numpad",  { Label	= "#WireAdvInputTool_keymore",
		Command = "wire_adv_input_keymore",
		ButtonSize = 22	}
	)
	CPanel:AddControl( "Numpad",  { Label	= "#WireAdvInputTool_keyless",
		Command = "wire_adv_input_keyless",
		ButtonSize = 22	}
	)
	CPanel:AddControl( "CheckBox",  { Label	= "#WireAdvInputTool_toggle",
		Command = "wire_adv_input_toggle" }
	)
	CPanel:AddControl( "Slider",  { Label	= "#WireAdvInputTool_value_min",
		Type = "Float",
		Min = -50,
		Max = 50,
		Command = "wire_adv_input_value_min"
		}
	)
	CPanel:AddControl( "Slider",  { Label	= "#WireAdvInputTool_value_max",
		Type = "Float",
		Min = -50,
		Max = 50,
		Command = "wire_adv_input_value_max"
		}
	)
	CPanel:AddControl( "Slider",  { Label	= "#WireAdvInputTool_value_start",
		Type = "Float",
		Min = -50,
		Max = 50,
		Command = "wire_adv_input_value_start"
		}
	)
	CPanel:AddControl( "Slider",  { Label	= "#WireAdvInputTool_speed",
		Type = "Float",
		Min = 0.1,
		Max = 50,
		Command = "wire_adv_input_speed"
		}
	)
end




--wire_adv_pod
WireToolSetup.open( "adv_pod", "I/O", "Advanced Pod Controller", "gmod_wire_adv_pod", WireToolMakeAdvPod )

if CLIENT then
	language.Add("Tool_wire_adv_pod_name", "Advanced Pod Controller Tool (Wire)")
	language.Add("Tool_wire_adv_pod_desc", "Spawn/link a Wire Advanced Pod controller.")
	language.Add("Tool_wire_adv_pod_0", "Primary: Create Advanced Pod controller. Secondary: Link Advanced controller.")
	language.Add("Tool_wire_adv_pod_1", "Now select the pod to link to.")
	language.Add("undone_gmod_wire_adv_pod", "Undone Wire Advanced Pod Controller")
	language.Add("Cleanup_gmod_wire_adv_pod", "Wire Advanced Pod Controllers")
	language.Add("Cleaned_gmod_wire_adv_pod", "Cleaned Up Wire Advanced Pod Controllers")
end

cleanup.Register("gmod_wire_adv_pod")

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.NoLeftOnClass = true

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
	panel:AddControl("Header", { Text = "#Tool_wire_pod_name", Description = "#Tool_wire_pod_desc" })
end




--wire_button
WireToolSetup.open( "button", "I/O", "Button", "gmod_wire_button", WireToolMakeButton )

if ( CLIENT ) then
    language.Add( "Tool_wire_button_name", "Button Tool (Wire)" )
    language.Add( "Tool_wire_button_desc", "Spawns a button for use with the wire system." )
    language.Add( "Tool_wire_button_0", "Primary: Create/Update Button" )
    language.Add( "WireButtonTool_toggle", "Toggle:" )
    language.Add( "WireButtonTool_value_on", "Value On:" )
    language.Add( "WireButtonTool_value_off", "Value Off:" )
	language.Add( "sboxlimit_wire_buttons", "You've hit wired buttons limit!" )
	language.Add( "undone_gmod_wire_button", "Undone Wire Button" )
	language.Add( "Cleanup_gmod_wire_button", "Wire Buttons" )
	language.Add( "Cleaned_gmod_wire_button", "Cleaned Up Wire Buttons" )
end

cleanup.Register( "gmod_wire_button" )

if (SERVER) then
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
	panel:AddControl("Header", { Text = "#Tool_wire_button_name", Description = "#Tool_wire_button_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_button",

		Options = {
			Default = {
				wire_button_toggle = "0",
				wire_button_value_on = "1",
				wire_button_value_off = "0"
			}
		},

		CVars = {
			[0] = "wire_button_toggle",
			[1] = "wire_button_value_on",
			[2] = "wire_button_value_off"
		}
	})

	ModelPlug_AddToCPanel(panel, "button", "wire_button", "#Button_Model", nil, "#Button_Model", 6)

	panel:AddControl("CheckBox", {
		Label = "#WireButtonTool_toggle",
		Command = "wire_button_toggle"
	})

	panel:AddControl("Slider", {
		Label = "#WireButtonTool_value_on",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_button_value_on"
	})
	panel:AddControl("Slider", {
		Label = "#WireButtonTool_value_off",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_button_value_off"
	})
end





