
TOOL.Category		= "Wire - Beacon"
TOOL.Name			= "Beacon Sensor"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_sensor_name", "Beacon Sensor Tool (Wire)" )
    language.Add( "Tool_wire_sensor_desc", "Returns distance and/or bearing to a beacon" )
    language.Add( "Tool_wire_sensor_0", "Primary: Create Sensor    Secondary: Link Sensor" )
	language.Add( "Tool_wire_sensor_1", "Click on the beacon to link to." )
    language.Add( "WireSensorTool_xyz_mode", "Split X,Y,Z:" )
    language.Add( "WireSensorTool_outdist", "Ouput distance:" )
    language.Add( "WireSensorTool_outbrng", "Output bearing:" )
	language.Add( "sboxlimit_wire_sensors", "You've hit sensors limit!" )
	language.Add( "undone_wiresensor", "Undone Wire Sensor" )
end

if (SERVER) then
  CreateConVar('sbox_maxwire_sensors',30)
end

TOOL.ClientConVar[ "xyz_mode" ] = "0"
TOOL.ClientConVar[ "outdist" ] = "1"
TOOL.ClientConVar[ "outbrng" ] = "0"

TOOL.Model = "models/props_lab/huladoll.mdl"

TOOL.SelectingPeer = false
TOOL.FirstPeer = nil

cleanup.Register( "wire_sensors" )

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()

	local xyz_mode = (self:GetClientNumber("xyz_mode") ~= 0)
	local outdist = (self:GetClientNumber("outdist") ~= 0)
	local outbrng = (self:GetClientNumber("outbrng") ~= 0)

	if (self:GetStage() == 1) then
		if ( trace.Entity:IsValid() && trace.Entity.GetBeaconPos ) then
			self.Sensor:SetBeacon(trace.Entity)
			self:SetStage(0)
			return true
		end
		
		return
	end

	if ( !self:GetSWEP():CheckLimit( "wire_sensors" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_sensor = MakeWireSensor( ply, trace.HitPos, Ang, xyz_mode, outdist, outbrng )

	local min = wire_sensor:OBBMins()
	wire_sensor:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const, nocollide = constraint.Weld( wire_sensor, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_sensor )
		// Don't disable collision if it's not attached to anything
		wire_sensor:GetPhysicsObject():EnableCollisions( false )
		wire_sensor.nocollide = true
	end
	
	undo.Create("WireSensor")
		undo.AddEntity( wire_sensor )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	
	ply:AddCleanup( "wire_sensors", wire_sensor )
	ply:AddCleanup( "wire_sensors", const )
	ply:AddCleanup( "wire_sensors", nocollide )

	return true
end

function TOOL:RightClick(trace)
	if (self:GetStage() ~= 0) then return self:LeftClick(trace) end

	if (trace.Entity:IsValid()) and (trace.Entity:GetClass() == "gmod_wire_sensor") and (trace.Entity.pl == self:GetOwner()) then
		self:SetStage(1)
		self.Sensor = trace.Entity
		return true
	end
end

if SERVER then

	function MakeWireSensor(pl, Pos, Ang, xyz_mode, outdist, outbrng, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_sensors" ) ) then return nil end

		local wire_sensor = ents.Create( "gmod_wire_sensor" )
		wire_sensor:SetPos( Pos )
		wire_sensor:SetAngles( Ang )
		wire_sensor:SetModel( Model("models/props_lab/huladoll.mdl") )
		wire_sensor:Spawn()
		wire_sensor:Activate()
		
		wire_sensor:Setup(xyz_mode, outdist, outbrng)
		wire_sensor:SetPlayer( pl )

		local ttable = 
		{
            xyz_mode	= xyz_mode,
            outdist		= outdist,
			outbrng		= outbrng,
			pl			= pl,
		}
		
		table.Merge( wire_sensor:GetTable(), ttable )

		pl:AddCount( "wire_sensors", wire_sensor )
		
		return wire_sensor
	end

	duplicator.RegisterEntityClass("gmod_wire_sensor", MakeWireSensor, "Pos", "Ang", "xyz_mode", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireSensor( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_sensor" || trace.Entity:GetClass() == "gmod_wire_beacon" ) then
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
	
	self:UpdateGhostWireSensor( self.GhostEntity, self:GetOwner() )
	
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool_wire_sensor_name", Description	= "#Tool_wire_sensor_desc" }  )

	panel:AddControl("CheckBox", {
		Label = "#WireSensorTool_xyz_mode",
		Command = "wire_sensor_xyz_mode"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireSensorTool_outdist",
		Command = "wire_sensor_outdist"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireSensorTool_outbrng",
		Command = "wire_sensor_outbrng"
	})
end
