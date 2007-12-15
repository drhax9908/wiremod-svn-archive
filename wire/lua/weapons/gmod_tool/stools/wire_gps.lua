TOOL.Category		= "Wire - Detection"
TOOL.Name			= "GPS"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gps_name", "GPS Tool (Wire)" )
    language.Add( "Tool_wire_gps_desc", "Spawns a gps for use with the wire system." )
    language.Add( "Tool_wire_gps_0", "Primary: Create/Update GPS" )
	language.Add( "sboxlimit_wire_gpss", "You've hit gpss limit!" )
	language.Add( "undone_wiregps", "Undone Wire GPS" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gpss', 10)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_speed.mdl"

cleanup.Register( "wire_gpss" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	// If we shot a wire_gps do nothing
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gps" && trace.Entity.pl == ply ) then
		trace.Entity:Setup()
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gpss" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_gps = MakeWireGPS( ply, Ang, trace.HitPos )

	local min = wire_gps:OBBMins()
	wire_gps:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_gps, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGPS")
		undo.AddEntity( wire_gps )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_gpss", wire_gps )

	return true
end

if (SERVER) then

	function MakeWireGPS( pl, Ang, Pos, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_gpss" ) ) then return false end

		local wire_gps = ents.Create( "gmod_wire_gps" )
		if (!wire_gps:IsValid()) then return false end

		wire_gps:SetAngles( Ang )
		wire_gps:SetPos( Pos )
		wire_gps:SetModel( Model("models/jaanus/wiretool/wiretool_speed.mdl") )
		wire_gps:Spawn()

		wire_gps:Setup()
		wire_gps:SetPlayer(pl)
		wire_gps.pl = pl

		if ( nocollide == true ) then wire_gps:GetPhysicsObject():EnableCollisions( false ) end

		pl:AddCount( "wire_gpss", wire_gps )

		return wire_gps
	end

	duplicator.RegisterEntityClass("gmod_wire_gps", MakeWireGPS, "Ang", "Pos", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireGPS( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_gps" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWireGPS( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gps_name", Description = "#Tool_wire_gps_desc" })
end
