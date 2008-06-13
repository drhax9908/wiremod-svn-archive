TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Wired Keyboard"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_keyboard_name", "Wired Keyboard Tool (Wire)" )
    language.Add( "Tool_wire_keyboard_desc", "Spawns a keyboard input for use with the hi-speed wire system." )
    language.Add( "Tool_wire_keyboard_0", "Primary: Create/Update Keyboard" )
    language.Add( "sboxlimit_wire_keyboard", "You've hit wired keyboards limit!" )
    language.Add( "undone_wirekeyboard", "Undone Wire Keyboard" )
    language.Add( "Cleanup_wire_keyboards", "Wire Keyboards" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_keyboards', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"

cleanup.Register( "wire_keyboards" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_keyboard" && trace.Entity.pl == ply ) then
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_keyboards" ) ) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_keyboard = MakeWireKeyboard( ply, trace.HitPos, Ang, _toggle, _value_off, _value_on )
	
	local min = wire_keyboard:OBBMins()
	wire_keyboard:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_keyboard, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireKeyboard")
		undo.AddEntity( wire_keyboard )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_keyboards", wire_keyboard )
	
	return true
	
end

if (SERVER) then
	
	function MakeWireKeyboard( pl, Pos, Ang, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_keyboards" ) ) then return false end
		
		local wire_keyboard = ents.Create( "gmod_wire_keyboard" )
		if (!wire_keyboard:IsValid()) then return false end
		
		wire_keyboard:SetAngles( Ang )
		wire_keyboard:SetPos( Pos )
		wire_keyboard:SetModel( Model("models/jaanus/wiretool/wiretool_input.mdl") )
		wire_keyboard:Spawn()
		
		wire_keyboard:SetPlayer( pl )
		wire_keyboard.pl = pl
		
		pl:AddCount( "wire_keyboards", wire_keyboard )
		
		return wire_keyboard
	end
	
	duplicator.RegisterEntityClass("gmod_wire_keyboard", MakeWireKeyboard, "Pos", "Ang", "Vel", "aVel", "frozen")
	
end

function TOOL:UpdateGhostWireKeyboard( ent, player )
	
	if ( !ent || !ent:IsValid() ) then return end
	
	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_keyboard" ) then
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

	self:UpdateGhostWireKeyboard( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_keyboard_name", Description = "#Tool_wire_keyboard_desc" })
end
