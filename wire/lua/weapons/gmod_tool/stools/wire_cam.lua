TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Cam Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_cam_name", "Cam Controller Tool (Wire)" )
    language.Add( "Tool_wire_cam_desc", "Spawns a constant Cam Controller prop for use with the wire system." )
    language.Add( "Tool_wire_cam_0", "Primary: Create/Update Cam Controller Secondary: Link a cam controller to a Pod." )
    language.Add( "WirecamTool_cam", "Camera Controller:" )
    language.Add( "sboxlimit_wire_cams", "You've hit Cam Controller limit!" )
    language.Add( "undone_Wire cam", "Undone Wire Cam Controller" )
    language.Add( "Cleanup_wire_cams", "Wire Cam Controllers" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_cams', 20)
end


TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register( "wire_cams" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_cameracontroller" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_cams" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_cam = MakeWireCam( ply, trace.HitPos, Ang )

	local min = wire_cam:OBBMins()
	wire_cam:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_cam, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Cam")
		undo.AddEntity( wire_cam )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_cams", wire_cam )

	return true
end

function TOOL:RightClick( trace )
	if (!trace.HitPos) then return false end
    if ( CLIENT ) then return true end
    if!(trace.Entity)then return false end
    if!(trace.Entity:IsValid())then return false end
    if (self.Oldent && trace.Entity:IsVehicle()) then
        self.Oldent.CamPod = trace.Entity;
        self.Oldent = nil;
        return true
    else
        if (trace.Entity:GetClass() == "gmod_wire_cameracontroller") then
            self.Oldent = trace.Entity;
            return true
        end
    end
end

if (SERVER) then

	function MakeWireCam( pl, Pos, Ang )
		if ( !pl:CheckLimit( "wire_cams" ) ) then return false end
	
		local wire_cam = ents.Create( "gmod_wire_cameracontroller" )
		if (!wire_cam:IsValid()) then return false end

		wire_cam:SetAngles( Ang )
		wire_cam:SetPos( Pos )
		wire_cam:SetModel( Model("models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_cam:Spawn()
		wire_cam:Setup(pl)

		wire_cam:GetTable():SetPlayer( pl )

		local ttable = {
			pl = pl
		}
		table.Merge(wire_cam:GetTable(), ttable )
		
		pl:AddCount( "wire_cams", wire_cam )

		return wire_cam
	end
	
	duplicator.RegisterEntityClass("gmod_wire_cameracontroller", MakeWireCam, "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWirecam( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_cameracontroller" ) then
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

	self:UpdateGhostWirecam( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_cam_name", Description = "#Tool_wire_cam_desc" })
end

