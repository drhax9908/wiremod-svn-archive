TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Wired Numpad"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_numpad_name", "Wired Numpad Tool (Wire)" )
    language.Add( "Tool_wire_numpad_desc", "Spawns a numpad input for use with the wire system." )
    language.Add( "Tool_wire_numpad_0", "Primary: Create/Update Numpad" )
    language.Add( "WireNumpadTool_toggle", "Toggle:" )
    language.Add( "WireNumpadTool_value_on", "Value On:" )
    language.Add( "WireNumpadTool_value_off", "Value Off:" )
    language.Add( "sboxlimit_wire_numpad", "You've hit wired numpads limit!" )
    language.Add( "undone_wirenumpad", "Undone Wire Numpad" )
    language.Add( "Cleanup_wire_numpads", "Wire Numpads" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_numpads', 20)
end

TOOL.ClientConVar[ "toggle" ] = "0"
TOOL.ClientConVar[ "value_off" ] = "0"
TOOL.ClientConVar[ "value_on" ] = "1"

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"

cleanup.Register( "wire_numpads" )

function TOOL:LeftClick( trace )
	
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_numpad" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _toggle, _value_off, _value_on )
		trace.Entity.toggle = _toggle
		trace.Entity.value_off = _value_off
		trace.Entity.value_on = _value_on
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_numpads" ) ) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_numpad = MakeWireNumpad( ply, trace.HitPos, Ang, _toggle, _value_off, _value_on )
	
	local min = wire_numpad:OBBMins()
	wire_numpad:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_numpad, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireNumpad")
		undo.AddEntity( wire_numpad )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_numpads", wire_numpad )
	
	return true
	
end

if (SERVER) then
	
	function MakeWireNumpad( pl, Pos, Ang, toggle, value_off, value_on, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_numpads" ) ) then return false end
		
		local wire_numpad = ents.Create( "gmod_wire_numpad" )
		if (!wire_numpad:IsValid()) then return false end
		
		wire_numpad:SetAngles( Ang )
		wire_numpad:SetPos( Pos )
		wire_numpad:SetModel( Model("models/jaanus/wiretool/wiretool_input.mdl") )
		wire_numpad:Spawn()
		
		wire_numpad:Setup(toggle, value_off, value_on )
		wire_numpad:SetPlayer( pl )
		
		for k = 1, 17 do
			numpad.OnDown( pl, k-1, "WireNumpad_On", wire_numpad, k )
			numpad.OnUp( pl, k-1, "WireNumpad_Off", wire_numpad, k )
		end
		
		local ttable = {
			toggle			= toggle,
			value_off		= value_off,
			value_on		= value_on,
			pl              = pl
		}
		table.Merge(wire_numpad, ttable )
		
		pl:AddCount( "wire_numpads", wire_numpad )
		
		return wire_numpad
	end
	
	duplicator.RegisterEntityClass("gmod_wire_numpad", MakeWireNumpad, "Pos", "Ang", "toggle", "value_off", "value_on", "Vel", "aVel", "frozen")
	
end

function TOOL:UpdateGhostWireNumpad( ent, player )
	
	if ( !ent || !ent:IsValid() ) then return end
	
	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_numpad" ) then
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

	self:UpdateGhostWireNumpad( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_numpad_name", Description = "#Tool_wire_numpad_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_numpad",
		
		Options = {
			Default = {
				wire_numpad_toggle = "0",
				wire_numpad_value_on = "1",
				wire_numpad_value_off = "0"
			}
		},
		
		CVars = {
			[0] = "wire_numpad_toggle",
			[1] = "wire_numpad_value_on",
			[2] = "wire_numpad_value_off"
		}
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireNumpadTool_toggle",
		Command = "wire_numpad_toggle"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireNumpadTool_value_on",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_numpad_value_on"
	})
	panel:AddControl("Slider", {
		Label = "#WireNumpadTool_value_off",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_numpad_value_off"
	})
end
