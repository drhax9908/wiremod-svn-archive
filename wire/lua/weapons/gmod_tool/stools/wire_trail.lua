TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Trail"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_trail_name", "Trail Tool (Wire)" )
    language.Add( "Tool_wire_trail_desc", "Spawns a wired trail." )
    language.Add( "Tool_wire_trail_0", "Primary: Create/Update trail" )
    language.Add( "WireTrailTool_trail", "Trail:" )
    language.Add( "WireTrailTool_mat", "Material:" )
	language.Add( "sboxlimit_wire_trails", "You've hit trails limit!" )
	language.Add( "undone_Wire Data Transferer", "Undone Wire Trail" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_trails', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"
TOOL.ClientConVar[ "material" ] = ""

cleanup.Register( "wire_trails" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()
	local mat = self:GetClientInfo("material")

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_trail" && trace.Entity:GetTable().pl == ply ) then
	    trace.Entity.mat = mat
	    trace.Entity:Setup(mat)
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_trails" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_trail = MakeWireTrail( ply, trace.HitPos, mat, Ang )

	local min = wire_trail:OBBMins()
	wire_trail:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_trail, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Trails")
		undo.AddEntity( wire_trail )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_trails", wire_trail )

	return true
end

if (SERVER) then

	function MakeWireTrail( pl, Pos, mat, Ang )
		if ( !pl:CheckLimit( "wire_trails" ) ) then return false end
	
		local wire_trail = ents.Create( "gmod_wire_trail" )
		if (!wire_trail:IsValid()) then return false end

		wire_trail:SetAngles( Ang )
		wire_trail:SetPos( Pos )
		wire_trail:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_trail:Spawn()
		wire_trail:Setup(mat)

		wire_trail:SetPlayer( pl )
		wire_trail.pl = pl
		wire_trail.mat = mat

		pl:AddCount( "wire_trails", wire_trail )

		return wire_trail
	end
	
	duplicator.RegisterEntityClass("gmod_wire_trail", MakeWireTrail, "Pos", "mat", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireTrail( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace = util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_trail" ) then
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

	self:UpdateGhostWireTrail( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_trail_name", Description = "#Tool_wire_trail_desc" })

	panel:AddControl( "MatSelect", { Height = "2", Label = "#WireTrailTool_mat", ConVar = "wire_trail_material", Options = list.Get( "trail_materials" ), ItemWidth = 64, ItemHeight = 64 } )
end

