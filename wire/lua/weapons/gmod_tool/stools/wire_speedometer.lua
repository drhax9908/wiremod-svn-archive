TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Speedometer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_speedometer_name", "Speedometer Tool (Wire)" )
    language.Add( "Tool_wire_speedometer_desc", "Spawns a speedometer for use with the wire system." )
    language.Add( "Tool_wire_speedometer_0", "Primary: Create/Update Speedometer" )
    language.Add( "WireSpeedometerTool_z_only", "Split X,Y,Z:" )
	language.Add( "sboxlimit_wire_speedometers", "You've hit speedometers limit!" )
	language.Add( "undone_wirespeedometer", "Undone Wire Speedometer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_speedometers', 10)
end

TOOL.ClientConVar[ "z_only" ] = "1"

TOOL.Model = "models/jaanus/wiretool/wiretool_speed.mdl"

cleanup.Register( "wire_speedometers" )

function TOOL:LeftClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local z_only = (self:GetClientNumber("z_only") ~= 0)

	// If we shot a wire_speedometer do nothing
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_speedometer" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(z_only)
		
		trace.Entity.z_only = z_only
	
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_speedometers" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_speedometer = MakeWireSpeedometer( ply, Ang, trace.HitPos, z_only )

	local min = wire_speedometer:OBBMins()
	wire_speedometer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_speedometer, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_speedometer )
		// Don't disable collision if it's not attached to anything
		wire_speedometer:GetPhysicsObject():EnableCollisions( false )
		wire_speedometer.nocollide = true
	end

	undo.Create("WireSpeedometer")
		undo.AddEntity( wire_speedometer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_speedometers", wire_speedometer )
	ply:AddCleanup( "wire_speedometers", const )
	ply:AddCleanup( "wire_speedometers", nocollide )

	return true

end

if (SERVER) then

	function MakeWireSpeedometer( pl, Ang, Pos, z_only, nocollide, Vel, aVel, frozen )

		if ( !pl:CheckLimit( "wire_speedometers" ) ) then return false end

		local wire_speedometer = ents.Create( "gmod_wire_speedometer" )
		if (!wire_speedometer:IsValid()) then return false end

		wire_speedometer:SetAngles( Ang )
		wire_speedometer:SetPos( Pos )
		wire_speedometer:SetModel( Model("models/jaanus/wiretool/wiretool_speed.mdl") )
		wire_speedometer:Spawn()

		wire_speedometer:Setup(z_only)
		wire_speedometer:SetPlayer(pl)

		if ( nocollide == true ) then wire_speedometer:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
            z_only = z_only,
			pl = pl,
			}

		table.Merge(wire_speedometer:GetTable(), ttable )

		pl:AddCount( "wire_speedometers", wire_speedometer )

		return wire_speedometer

	end

	duplicator.RegisterEntityClass("gmod_wire_speedometer", MakeWireSpeedometer, "Ang", "Pos", "z_only", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireSpeedometer( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_speedometer" || trace.Entity:IsPlayer()) then

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

	self:UpdateGhostWireSpeedometer( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_speedometer_name", Description = "#Tool_wire_speedometer_desc" })

	panel:AddControl("CheckBox", {
		Label = "#WireSpeedometerTool_z_only",
		Command = "wire_speedometer_z_only"
	})
end
