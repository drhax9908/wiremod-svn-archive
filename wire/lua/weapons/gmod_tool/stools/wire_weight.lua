TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Weight"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_weight_name", "Weight Tool (Wire)" )
    language.Add( "Tool_wire_weight_desc", "Spawns a weight." )
    language.Add( "Tool_wire_weight_0", "Primary: Create/Update weight" )
    language.Add( "WireDataWeightTool_weight", "Weight:" )
	language.Add( "sboxlimit_wire_weights", "You've hit weights limit!" )
	language.Add( "undone_Wire Weight", "Undone Wire weight" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_weights', 20)
end

TOOL.Model = "models/props_interiors/pot01a.mdl"

cleanup.Register( "wire_weights" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_weight" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_weights" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_weight = MakeWireWeight( ply, trace.HitPos, Ang )

	local min = wire_weight:OBBMins()
	wire_weight:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_weight, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Weight")
		undo.AddEntity( wire_weight )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_weights", wire_weight )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireWeight( pl, Pos, Ang )
		if ( !pl:CheckLimit( "wire_weights" ) ) then return false end
	
		local wire_weight = ents.Create( "gmod_wire_weight" )
		if (!wire_weight:IsValid()) then return false end

		wire_weight:SetAngles( Ang )
		wire_weight:SetPos( Pos )
		wire_weight:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_weight:Spawn()

		wire_weight:SetPlayer( pl )
		wire_weight.pl = pl
		
		pl:AddCount( "wire_weights", wire_weight )

		return wire_weight
	end
	
	duplicator.RegisterEntityClass("gmod_wire_weight", MakeWireWeight, "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireWeight( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_weight" ) then
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

	self:UpdateGhostWireWeight( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_weight_name", Description = "#Tool_wire_weight_desc" })
end
