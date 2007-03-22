
TOOL.Category		= "Wire - Display"
TOOL.Name			= "Light"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_light_name", "Light Tool (Wire)" )
    language.Add( "Tool_wire_light_desc", "Spawns a Light for use with the wire system." )
    language.Add( "Tool_wire_light_0", "Primary: Create Light" )
    language.Add( "WireLightTool_directional", "Directional Component:" )
    language.Add( "WireLightTool_radiant", "Radiant Component:" )
 	language.Add( "sboxlimit_wire_lights", "You've hit Lights limit!" )
	language.Add( "undone_wirelight", "Undone Wire Light" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_lights', 8)
end

TOOL.ClientConVar[ "directional" ] = "0"
TOOL.ClientConVar[ "radiant" ] = "0"


TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register( "wire_lights" )

function TOOL:LeftClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()

	local directional	= (self:GetClientNumber("directional") ~= 0)
	local radiant	= (self:GetClientNumber("radiant") ~= 0)

	
	// If we shot a wire_light change its settings
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_light" && trace.Entity.pl == ply ) then

		trace.Entity:Setup(directional, radiant)

		trace.Entity.directional = directional
		trace.Entity.radiant = radiant

		return true
	end

	
	if ( !self:GetSWEP():CheckLimit( "wire_lights" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_light = MakeWireLight( ply, Ang, trace.HitPos, directional, radiant )
	
	local min = wire_light:OBBMins()
	wire_light:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const, nocollide
	
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_light, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		
		// Don't disable collision if it's not attached to anything
		if ( collision == 0 ) then 
			wire_light:GetPhysicsObject():EnableCollisions( false )
			wire_light:GetTable().nocollide = true
		end
	end
	
	undo.Create("WireLight")
		undo.AddEntity( wire_light )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "wire_lights", wire_light )
	ply:AddCleanup( "wire_lights", const )
	ply:AddCleanup( "wire_lights", nocollide )
	
	return true

end

if (SERVER) then

	function MakeWireLight( pl, Ang, Pos, directional, radiant, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_lights" ) ) then return false end
	
		local wire_light = ents.Create( "gmod_wire_light" )
		if (!wire_light:IsValid()) then return false end

		wire_light:SetAngles( Ang )
		wire_light:SetPos( Pos )
		wire_light:Spawn()

		wire_light:GetTable():Setup(directional, radiant)
		wire_light:GetTable():SetPlayer(pl)

		if ( nocollide == true ) then wire_light:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl	= pl,
			directional = directional,
			radiant = radiant,
			nocollide = nocollide
			}

		table.Merge(wire_light:GetTable(), ttable )

		pl:AddCount( "wire_lights", wire_light )

		return wire_light
	end

	duplicator.RegisterEntityClass("gmod_wire_light", MakeWireLight, "Ang", "Pos", "directional", "radiant", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireLight( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_light" || trace.Entity:IsPlayer()) then
	
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
	
	self:UpdateGhostWireLight( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_light_name", Description = "#Tool_wire_light_desc" })
	
		panel:AddControl("CheckBox", {
		Label = "#WireLightTool_directional",
		Command = "wire_light_directional"
	})

		panel:AddControl("CheckBox", {
		Label = "#WireLightTool_radiant",
		Command = "wire_light_radiant"
	})

end
