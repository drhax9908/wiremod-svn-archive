
TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Water Sensor"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_watersensor_name", "Water Sensor Tool (Wire)" )
    language.Add( "Tool_wire_watersensor_desc", "Spawns a constant Water Sensor prop for use with the wire system." )
    language.Add( "Tool_wire_watersensor_0", "Primary: Create/Update Water Sensor" )
    language.Add( "WireWatersensorTool_watersensor", "Water Sensor:" )
	language.Add( "sboxlimit_wire_watersensors", "You've hit Water Sensors limit!" )
	language.Add( "undone_Wire Water Sensor", "Undone Wire Water Sensor" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_watersensors', 20)
end


TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_watersensors" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_watersensor" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_watersensors" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_watersensor = MakeWireWatersensor( ply, trace.HitPos, Ang )

	local min = wire_watersensor:OBBMins()
	wire_watersensor:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_nailer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_nailer:GetPhysicsObject():EnableCollisions( false )
		wire_nailer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_watersensor, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Water Sensor")
		undo.AddEntity( wire_watersensor )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_watersensors", wire_watersensor )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireWatersensor( pl, Pos, Ang )
		if ( !pl:CheckLimit( "wire_watersensors" ) ) then return false end
	
		local wire_watersensor = ents.Create( "gmod_wire_watersensor" )
		if (!wire_watersensor:IsValid()) then return false end

		wire_watersensor:SetAngles( Ang )
		wire_watersensor:SetPos( Pos )
		wire_watersensor:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_watersensor:Spawn()

		wire_watersensor:GetTable():SetPlayer( pl )

		local ttable = {
			pl = pl
		}

		table.Merge(wire_watersensor:GetTable(), ttable )
		
		pl:AddCount( "wire_watersensors", wire_watersensor )

		return wire_watersensor
	end
	
	duplicator.RegisterEntityClass("gmod_wire_watersensor", MakeWireWatersensor, "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireWatersensor( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_watersensor" ) then
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

	self:UpdateGhostWireWatersensor( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_watersensor_name", Description = "#Tool_wire_watersensor_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_watersensor",

		Options = {
			Default = {
			}
		},
		CVars = {
		}
	})
end

