
TOOL.Category		= "Wire"
TOOL.Name			= "Input (dual)"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
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
	language.Add( "undone_wiredualinput", "Undone Wire Input" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_dual_inputs', 20)
end

TOOL.ClientConVar[ "keygroup" ] = "7"
TOOL.ClientConVar[ "keygroup2" ] = "4"
TOOL.ClientConVar[ "toggle" ] = "0"
TOOL.ClientConVar[ "value_off" ] = "0"
TOOL.ClientConVar[ "value_on" ] = "1"
TOOL.ClientConVar[ "value_on2" ] = "-1"

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"

cleanup.Register( "wire_dual_inputs" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()


	// Get client's CVars
	local _keygroup			= self:GetClientNumber( "keygroup" )
	local _keygroup2			= self:GetClientNumber( "keygroup2" )
	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )
	local _value_on2			= self:GetClientNumber( "value_on2" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_dual_input" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _keygroup, _keygroup2, _toggle, _value_off, _value_on, _value_on2 )
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_dual_inputs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_dual_input = MakeWireDualInput( ply, trace.HitPos, Ang, _keygroup, _keygroup2, _toggle, _value_off, _value_on, _value_on2 )

	local min = wire_dual_input:OBBMins()
	wire_dual_input:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_dual_input, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_dual_input )
		// Don't disable collision if it's not attached to anything
		wire_dual_input:GetPhysicsObject():EnableCollisions( false )
		wire_dual_input.nocollide = true
	end

	undo.Create("WireDualInput")
		undo.AddEntity( wire_dual_input )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_dual_inputs", wire_dual_input )

	return true

end

if (SERVER) then

	function MakeWireDualInput( pl, Pos, Ang, keygroup, keygroup2, toggle, value_off, value_on, value_on2, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_dual_inputs" ) ) then return false end
	
		local wire_dual_input = ents.Create( "gmod_wire_dual_input" )
		if (!wire_dual_input:IsValid()) then return false end

		wire_dual_input:SetAngles( Ang )
		wire_dual_input:SetPos( Pos )
		wire_dual_input:SetModel( Model("models/jaanus/wiretool/wiretool_input.mdl") )
		wire_dual_input:Spawn()

		wire_dual_input:Setup( keygroup, keygroup2, toggle, value_off, value_on, value_on2 )
		wire_dual_input:SetPlayer( pl )

		numpad.OnDown( pl, keygroup, "WireDualInput_On", wire_dual_input, 1 )
		numpad.OnUp( pl, keygroup, "WireDualInput_Off", wire_dual_input, 1 )

		numpad.OnDown( pl, keygroup2, "WireDualInput_On", wire_dual_input, -1 )
		numpad.OnUp( pl, keygroup2, "WireDualInput_Off", wire_dual_input, -1 )
		
		local ttable = {
			keygroup		= keygroup,
			keygroup2		= keygroup2,
			toggle			= toggle,
			value_off		= value_off,
			value_on		= value_on,
			value_on2		= value_on2,
			pl              = pl
			}

		table.Merge(wire_dual_input, ttable )
		
		pl:AddCount( "wire_dual_inputs", wire_dual_input )

		return wire_dual_input
	end

	duplicator.RegisterEntityClass("gmod_wire_dual_input", MakeWireDualInput, "Pos", "Ang", "keygroup", "keygroup2", "toggle", "value_off", "value_on", "value_on2", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireInput( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_input" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireInput( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_dual_input_name", Description = "#Tool_wire_dual_input_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_dual_input",

		Options = {
			Default = {
				wire_dual_input_keygroup = "7",
				wire_dual_input_keygroup2 = "4",
				wire_dual_input_toggle = "0",
				wire_dual_input_value_on = "1",
				wire_dual_input_value_on = "-1",
				wire_dual_input_value_off = "0"
			}
		},

		CVars = {
			[0] = "wire_dual_input_keygroup",
			[1] = "wire_dual_input_keygroup2",
			[2] = "wire_dual_input_toggle",
			[3] = "wire_dual_input_value_on",
			[4] = "wire_dual_input_value_on2",
			[5] = "wire_dual_input_value_off"
		}
	})
	
	panel:AddControl("Numpad", {
		Label = "#WireDualInputTool_keygroup",
		Command = "wire_dual_input_keygroup",
		ButtonSize = "22"
	})
	
	panel:AddControl("Numpad", {
		Label = "#WireDualInputTool_keygroup2",
		Command = "wire_dual_input_keygroup2",
		ButtonSize = "22"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireDualInputTool_toggle",
		Command = "wire_dual_input_toggle"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireDualInputTool_value_on",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_dual_input_value_on"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireDualInputTool_value_off",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_dual_input_value_off"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireDualInputTool_value_on2",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_dual_input_value_on2"
	})
end
