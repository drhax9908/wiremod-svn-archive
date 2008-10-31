TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Entity Marker"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_emarker_name", "Entity Marker Tool (Wire)" )
    language.Add( "Tool_wire_emarker_desc", "Spawns an Entity Marker for use with the wire system." )
    language.Add( "Tool_wire_emarker_0", "Primary: Create/Select Entity Marker, Secondary: Link Entity Marker to entity" )
	language.Add( "sboxlimit_wire_emarker", "You've hit entity marker limit!" )
	language.Add( "undone_wireemarker", "Undone Wire Entity Marker" )
else
    CreateConVar('sbox_maxwire_emarkers',30)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

cleanup.Register( "wire_emarkers" )

function TOOL:LeftClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_emarker" && trace.Entity.pl == ply ) then
		self.marker = trace.Entity
		return true
	end	
	local mark = trace.Entity
	if ( !self:GetSWEP():CheckLimit( "wire_emarkers" ) ) then return false end
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_emarker = MakeWireEmarker( ply, trace.HitPos, Ang, mark )

	local min = wire_emarker:OBBMins()
	wire_emarker:SetPos( trace.HitPos - trace.HitNormal * (min.z) )
	self.marker = wire_emarker
	local const = WireLib.Weld(self.marker, trace.Entity, trace.PhysicsBone, true)
	undo.Create("WireEmarker")
		undo.AddEntity( wire_emarker )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_emarkers", wire_emarker )

	return true
	
end

function TOOL:RightClick(trace)
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	if (!self.marker or !self.marker:IsValid()) then return false end

	if (trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_emarker" ) then
		return false
	end	
	local mark = trace.Entity

	self.marker:Setup(mark)

	return true
	
end

if SERVER then

	function MakeWireEmarker(pl, Pos, Ang, mark, Vel, aVel, frozen, nocollide )
		if (!pl:CheckLimit("wire_markers")) then return end

		local wire_emarker = ents.Create("gmod_wire_emarker")
		wire_emarker:SetPos(Pos)
		wire_emarker:SetAngles(Ang)
		wire_emarker:SetModel( Model("models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_emarker:Spawn()
		wire_emarker:Activate()
		wire_emarker:Setup(mark)
		
		wire_emarker:SetPlayer(pl)
		
		if ( nocollide == true ) then wire_light:GetPhysicsObject():EnableCollisions( false ) end
		
		local ttable = {
			pl			= pl,
			nocollide	= nocollide,
		}
		table.Merge( wire_emarker:GetTable(), ttable )

		pl:AddCount( "wire_emarkers", wire_emarker )
		
		return wire_emarker
	end

	duplicator.RegisterEntityClass("gmod_wire_emarker", MakeWireEmarker, "Pos", "Ang", "mark", "Vel", "aVel", "frozen", "nocollide")

end

function TOOL:UpdateGhostEmarker( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_emarker" ) then
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
	
	self:UpdateGhostEmarker( self.GhostEntity, self:GetOwner() )
	
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_emarker_name", Description = "#Tool_wire_emarker_desc" })
end
	
