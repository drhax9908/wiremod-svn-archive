
TOOL.Category		= "Wire - Display"
TOOL.Name			= "Pixel"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_pixel_name", "Pixel Tool (Wire)" )
    language.Add( "Tool_wire_pixel_desc", "Spawns a Pixel for use with the wire system." )
    language.Add( "Tool_wire_pixel_0", "Primary: Create Pixel" )
 	language.Add( "sboxlimit_wire_pixels", "You've hit Pixels limit!" )
	language.Add( "undone_wirepixel", "Undone Wire Pixel" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_pixels', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register( "wire_pixels" )

function TOOL:LeftClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	// If we shot a wire_pixel change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_pixel" && trace.Entity:GetTable().pl == ply ) then
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_pixels" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_pixel = MakeWirePixel( ply, Ang, trace.HitPos )
	
	local min = wire_pixel:OBBMins()
	wire_pixel:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const, nocollide
	
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_pixel, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_pixel )
		
		// Don't disable collision if it's not attached to anything
		if ( collision == 0 ) then 
			wire_pixel:GetPhysicsObject():EnableCollisions( false )
			wire_pixel:GetTable().nocollide = true
		end
	end
	
	undo.Create("WirePixel")
		undo.AddEntity( wire_pixel )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "wire_pixels", wire_pixel )
	ply:AddCleanup( "wire_pixels", const )
	ply:AddCleanup( "wire_pixels", nocollide )
	
	return true

end

if (SERVER) then

	function MakeWirePixel( pl, Ang, Pos, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_pixels" ) ) then return false end
	
		local wire_pixel = ents.Create( "gmod_wire_pixel" )
		if (!wire_pixel:IsValid()) then return false end

		wire_pixel:SetAngles( Ang )
		wire_pixel:SetPos( Pos )
		wire_pixel:Spawn()

		wire_pixel:GetTable():Setup()
		wire_pixel:GetTable():SetPlayer(pl)

		if ( nocollide == true ) then wire_pixel:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			pl	= pl,
			nocollide = nocollide
			}

		table.Merge(wire_pixel:GetTable(), ttable )

		pl:AddCount( "wire_pixels", wire_pixel )

		return wire_pixel
	end

	duplicator.RegisterEntityClass("gmod_wire_pixel", MakeWirePixel, "Ang", "Pos", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWirePixel( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_pixel" || trace.Entity:IsPlayer()) then
	
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
	
	self:UpdateGhostWirePixel( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_pixel_name", Description = "#Tool_wire_pixel_desc" })
end
