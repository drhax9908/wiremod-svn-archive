
TOOL.Category		= "Wire - Destruction"
TOOL.Name			= "Detonator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_detonator_name", "Detonator Tool (Wire)" )
    language.Add( "Tool_wire_detonator_desc", "Spawns a Detonator for use with the wire system." )
    language.Add( "Tool_wire_detonator_0", "Primary: Create/Update Detonator" )
 	language.Add( "sboxlimit_wire_detonators", "You've hit Detonators limit!" )
	language.Add( "undone_wiredetonator", "Undone Wire Detonator" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_detonators', 20)
end

TOOL.ClientConVar[ "damage" ] = "1"
TOOL.Model = "models/props_combine/breenclock.mdl"

cleanup.Register( "wire_detonators" )

function TOOL:LeftClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	local damage = self:GetClientNumber( "damage" )
	
	// If we shot a wire_detonator change its damage
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_detonator" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:GetTable():Setup(damage)
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_detonators" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local const, nocollide
	
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		wire_detonator = MakeWireDetonator( ply, Ang, trace.HitPos, trace.Entity, damage )
		local min = wire_detonator:OBBMins()
		wire_detonator:SetPos( trace.HitPos - trace.HitNormal * min.z )
		
		const = constraint.Weld( wire_detonator, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_detonator )
		
		// Don't disable collision if it's not attached to anything
		if ( collision == 0 ) then 
			wire_detonator:GetPhysicsObject():EnableCollisions( false )
			wire_detonator:GetTable().nocollide = true
		end
	else return false
	end
	
	undo.Create("WireDetonator")
		undo.AddEntity( wire_detonator )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "wire_detonators", wire_detonator )
	ply:AddCleanup( "wire_detonators", const )
	ply:AddCleanup( "wire_detonators", nocollide )
	
	return true

end

if (SERVER) then

	function MakeWireDetonator( pl, Ang, Pos, target, damage, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_detonators" ) ) then return false end
	
		local wire_detonator = ents.Create( "gmod_wire_detonator" )
		if (!wire_detonator:IsValid()) then return false end

		wire_detonator:SetAngles( Ang )
		wire_detonator:SetPos( Pos )
		wire_detonator:Spawn()

		wire_detonator:GetTable():Setup(damage)
		wire_detonator:GetTable():SetPlayer(pl)

		if ( nocollide == true ) then wire_detonator:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl	= pl,
			damage = damage,
			target = target,
			nocollide = nocollide
			}

		table.Merge(wire_detonator:GetTable(), ttable )

		pl:AddCount( "wire_detonators", wire_detonator )

		return wire_detonator
	end

	duplicator.RegisterEntityClass("gmod_wire_detonator", MakeWireDetonator, "Ang", "Pos", "target", "damage", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireDetonator( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_detonator" || trace.Entity:IsPlayer()) then
	
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireDetonator( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", { Text = "#Tool_wire_detonator_name", Description = "#Tool_wire_detonator_desc" })
	CPanel:AddControl( "Slider",  { Label	= "#Damage",
		Type	= "Integer",
		Min		= 1,
		Max		= 200,
		Command = "wire_detonator_damage" }	 
	)
end
