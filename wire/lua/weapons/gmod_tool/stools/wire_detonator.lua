TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Detonator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_detonator_name", "Detonator Tool (Wire)" )
    language.Add( "Tool_wire_detonator_desc", "Spawns a Detonator for use with the wire system." )
    language.Add( "Tool_wire_detonator_0", "Primary: Create/Update Detonator" )
    language.Add( "WireDetonatorTool_model", "Model:" )
 	language.Add( "sboxlimit_wire_detonators", "You've hit Detonators limit!" )
	language.Add( "undone_wiredetonator", "Undone Wire Detonator" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_detonators', 20)
	ModelPlug_Register("detonator")
end

TOOL.ClientConVar[ "damage" ] = "1"
TOOL.ClientConVar[ "model" ] = "models/props_combine/breenclock.mdl"

cleanup.Register( "wire_detonators" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	local damage = self:GetClientNumber( "damage" )
	local model = self:GetClientInfo( "model" )
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_detonator" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:Setup(damage)
		trace.Entity.damage = damage
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_detonators" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local const = WireLib.Weld(wire_detonator, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireDetonator")
		undo.AddEntity( wire_detonator )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "wire_detonators", wire_detonator )
	ply:AddCleanup( "wire_detonators", const )
	
	return true
end

if (SERVER) then

	// "target" is now handled by TOOL:LeftClick() for STool-spawned
	// detonators and ENT:Build/ApplyDupeInfo() for duplicated ones
	// It's done this way because MakeWireDetonator() cannot distinguish whether
	// detonator was made by the STool or the duplicator; the duplicator-made
	// detonator tries to reference a non-existent target (TheApathetic)
	function MakeWireDetonator( pl, Model, Ang, Pos, damage, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_detonators" ) ) then return false end
	
		local wire_detonator = ents.Create( "gmod_wire_detonator" )
		if (!wire_detonator:IsValid()) then return false end

		wire_detonator:SetAngles( Ang )
		wire_detonator:SetPos( Pos )
		wire_detonator:SetModel(Model)
		wire_detonator:Spawn()

		wire_detonator:Setup(damage)
		wire_detonator:SetPlayer(pl)

		if ( nocollide == true ) then wire_detonator:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl	= pl,
			damage = damage,
			nocollide = nocollide
		}
		table.Merge(wire_detonator:GetTable(), ttable )

		pl:AddCount( "wire_detonators", wire_detonator )

		return wire_detonator
	end

	duplicator.RegisterEntityClass("gmod_wire_detonator", MakeWireDetonator, "Model", "Ang", "Pos", "damage", "nocollide", "Vel", "aVel", "frozen")

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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireDetonator( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_detonator_name", Description = "#Tool_wire_detonator_desc" })

	panel:AddControl( "Slider",  { Label	= "#Damage",
		Type	= "Integer",
		Min		= 1,
		Max		= 200,
		Command = "wire_detonator_damage" }	 
	)

	ModelPlug_AddToCPanel(panel, "detonator", "wire_detonator", "#WireDetonatorTool_model", nil, "#WireDetonatorTool_model")
end
