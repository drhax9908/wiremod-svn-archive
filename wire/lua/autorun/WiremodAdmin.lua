
local function BuildAdminControlPanel( Panel )
	
	Panel:AddControl( "Header", { Text = "Wire Admin Control Panel", Description = "Wire Admin Control Panel" }  )
	
	local params = {}
	params.Label = "#Max Wiremod Wheels"
	params.Type = "Integer"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_wheels"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Waypoints"
	params.Type = "Integer"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_waypoints"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Values"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_values"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Two-way Radios"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_twoway_radioes"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Turrets"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_turrets"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Target Finders"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_target_finders"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Speedometers"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_speedometers"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Spawners"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_spawners"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Emitters"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_emitters"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Simple Explosives"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_simple_explosive"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Sensors"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_sensors"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Screens"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_screens"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Relays"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_relays"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Rangers"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_rangers"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Radios"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_radioes"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Pods"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_pods"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Sockets"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_sockets"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Plugs"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_plugs"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Pixels"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_pixels"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Panels"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_panels"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Outputs"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_outputs"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Oscilloscopes"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_oscilloscopes"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Numpads"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_numpads"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Nailers"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_nailers"
	Panel:AddControl( "Slider",params)	
	
	local params = {}
	params.Label = "#Max Wiremod Locators"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_locators"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Lights"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_lights"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Lamps"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_lamps"
	Panel:AddControl( "Slider",params)	
	
	local params = {}
	params.Label = "#Max Wiremod Inputs"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_inputs"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Indicators"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_indicators"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Hoverballs"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_hoverballs"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Gyroscopes"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gyroscopes"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod GPSes"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gpss"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Gates - Trig"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gate_trigs"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Gates - Time"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gate_times"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Gates - Selection"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gate_selections"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Gates - Memory"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gate_memorys"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Gates - Logic"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gate_logics"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Gates - Comparison"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gate_logics"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Gates"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_gates"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Forcers"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_forcers"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Explosives"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_explosive"
	Panel:AddControl( "Slider",params)

	local params = {}
	params.Label = "#Max Wiremod Dual Inputs"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_dual_inputs"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Digital-Sceens"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_digitalscreens"
	Panel:AddControl( "Slider",params)	
	
	local params = {}
	params.Label = "#Max Wiremod Detonators"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_detonators"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod CPUs"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_cpus"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Buttons"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_buttons"
	Panel:AddControl( "Slider",params)
	
	local params = {}
	params.Label = "#Max Wiremod Adv. Inputs"
	params.Type = "Float"
	params.Min = "0"
	params.Max = "999"
	params.Command = "sbox_maxwire_adv_inputs"
	Panel:AddControl( "Slider",params)
end

local function AddWireAdminControlPanelMenu()
	spawnmenu.AddToolMenuOption( "Utilities", "Wire", "WireAdminControlPanel", "WireAdminControlPanel", "", "", BuildAdminControlPanel, {} )
end
hook.Add( "PopulateToolMenu", "AddAddWireAdminControlPanelMenu", AddWireAdminControlPanelMenu )
