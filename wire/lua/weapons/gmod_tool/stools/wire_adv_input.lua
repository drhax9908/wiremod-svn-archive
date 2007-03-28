
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Adv. Input"
TOOL.Command		= nil
TOOL.ConfigName		= ""

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
	language.Add( "sboxlimit_wire_adv_inputs", "You've hit adv_inputs limit!" )
	language.Add( "undone_wireadv_input", "Undone Wire Adv. Input" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_adv_inputs',20)
end

TOOL.ClientConVar[ "keymore" ] = "3"
TOOL.ClientConVar[ "keyless" ] = "1"
TOOL.ClientConVar[ "toggle" ] = "0"
TOOL.ClientConVar[ "value_min" ] = "0"
TOOL.ClientConVar[ "value_max" ] = "10"
TOOL.ClientConVar[ "value_start" ] = "5"
TOOL.ClientConVar[ "speed" ] = "1"

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"

cleanup.Register( "wire_adv_inputs" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()


	// Get client's CVars
	local _keymore			= self:GetClientNumber( "keymore" )
	local _keyless			= self:GetClientNumber( "keyless" )
	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_min		= self:GetClientNumber( "value_min" )
	local _value_max		= self:GetClientNumber( "value_max" )
	local _value_start		= self:GetClientNumber( "value_start" )
	local _speed			= self:GetClientNumber( "speed" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_adv_input" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _keymore, _keyless, _toggle, _value_min, _value_max, _value_start, _speed )
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_adv_inputs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_adv_input = MakeWireAdvInput( ply, trace.HitPos, Ang, _keymore, _keyless, _toggle, _value_min, _value_max, _value_start, _speed )

	local min = wire_adv_input:OBBMins()
	wire_adv_input:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	// Don't weld to world
	/*local const, nocollide
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_adv_input, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_adv_input:GetPhysicsObject():EnableCollisions( false )
		wire_adv_input.nocollide = true
	end*/
	local const = WireLib.Weld(wire_adv_input, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireInput")
		undo.AddEntity( wire_adv_input )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_adv_inputs", wire_adv_input )

	return true

end

if (SERVER) then

	function MakeWireAdvInput( pl, Pos, Ang, keymore, keyless, toggle, value_min, value_max, value_start, speed, Vel, aVel, frozen )
	
		if ( !pl:CheckLimit( "wire_adv_inputs" ) ) then return false end
	
		local wire_adv_input = ents.Create( "gmod_wire_adv_input" )
		if (!wire_adv_input:IsValid()) then return false end

		wire_adv_input:SetAngles( Ang )
		wire_adv_input:SetPos( Pos )
		wire_adv_input:SetModel( Model("models/jaanus/wiretool/wiretool_input.mdl") )
		wire_adv_input:Spawn()

		wire_adv_input:Setup( keymore, keyless, toggle, value_min, value_max, value_start, speed )
		wire_adv_input:SetPlayer( pl )

		numpad.OnDown( pl, keymore, "WireAdvInput_On", wire_adv_input, 1 )
		numpad.OnUp( pl, keymore, "WireAdvInput_Off", wire_adv_input, 1 )
		
		numpad.OnDown( pl, keyless, "WireAdvInput_On", wire_adv_input, -1 )
		numpad.OnUp( pl, keyless, "WireAdvInput_Off", wire_adv_input, -1 )

		local ttable = {
			keymore			= keymore,
			keyless			= keyless,
			toggle			= toggle,
			value_min		= value_min,
			value_max		= value_max,
			value_start		= value_start,
			speed			= speed,
			pl              = pl
			}

		table.Merge(wire_adv_input:GetTable(), ttable )
		
		pl:AddCount( "wire_adv_inputs", wire_adv_input )

		return wire_adv_input
		
	end

	duplicator.RegisterEntityClass("gmod_wire_adv_input", MakeWireAdvInput, "Pos", "Ang", "keymore", "keyless", "toggle", "value_min", "value_max", "value_start", "speed", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireInput( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_adv_input" ) then
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

function TOOL.BuildCPanel( CPanel )
	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool_wire_adv_input_name", Description	= "#Tool_wire_adv_input_desc" }  )
	// Change Togglers
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
