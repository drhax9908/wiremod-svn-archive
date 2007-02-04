
TOOL.Category		= "Wire"
TOOL.Name			= "Output"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
	language.Add( "Tool_wire_output_name", "Output Tool (Wire)" )
	language.Add( "Tool_wire_output_desc", "Spawns an output for use with the wire system." )
	language.Add( "Tool_wire_output_0", "Primary: Create/Update Output" )
	language.Add( "WireOutput_keygroup", "Key:" )
	language.Add( "sboxlimit_wire_outputs", "You've hit outputs limit!" )
	language.Add( "undone_wireoutput", "Undone Wire Output" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_outputs', 10)
end

TOOL.ClientConVar[ "keygroup" ] = "1"

TOOL.Model = "models/jaanus/wiretool/wiretool_output.mdl"

cleanup.Register( "wire_outputs" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local key 				= self:GetClientNumber( "keygroup" )

	// If we shot a wire_output do nothing
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_output" && trace.Entity.pl == ply ) then
		if (numpad.GetModifiedKey) then key = numpad.GetModifiedKey(ply, key) end
		
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_outputs" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_output = MakeWireOutput( ply, Ang, trace.HitPos, key )

	local min = wire_output:OBBMins()
	wire_output:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	const = constraint.Weld( wire_output, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0 )
	trace.Entity:DeleteOnRemove( wire_output )
	wire_output:GetPhysicsObject():EnableCollisions( false )

	undo.Create("WireOutput")
		undo.AddEntity( wire_output )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_outputs", wire_output )
	ply:AddCleanup( "wire_outputs", const )
	ply:AddCleanup( "wire_outputs", nocollide )

	return true
end

if (SERVER) then

	function MakeWireOutput( pl, Ang, Pos, key, nocollide, Vel, aVel, frozen )
		if (numpad.GetModifiedKey) then key = numpad.GetModifiedKey(pl, key) end

		if ( !pl:CheckLimit( "wire_outputs" ) ) then return false end

		local wire_output = ents.Create( "gmod_wire_output" )
		if (!wire_output:IsValid()) then return false end

		wire_output:SetAngles( Ang )
		wire_output:SetPos( Pos )
		wire_output:SetModel( Model("models/jaanus/wiretool/wiretool_output.mdl") )
		wire_output:Spawn()

		wire_output:SetPlayer(pl)
		wire_output:SetKey(key)

		local ttable = {
			key	= key,
			pl	= pl,
			}

		table.Merge(wire_output:GetTable(), ttable )

		pl:AddCount( "wire_outputs", wire_output )

		return wire_output
	end

	duplicator.RegisterEntityClass("gmod_wire_output", MakeWireOutput, "Ang", "Pos", "key", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireOutput( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_output" || trace.Entity:IsPlayer()) then

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

	self:UpdateGhostWireOutput( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_output_name", Description = "#Tool_wire_output_desc" })
	
	panel:AddControl("Numpad", {
		Label = "#WireOutput_keygroup",
		Command = "wire_output_keygroup",
		ButtonSize = "22"
	})
end
