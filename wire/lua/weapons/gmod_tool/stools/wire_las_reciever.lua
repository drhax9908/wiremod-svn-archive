
TOOL.Category		= "Wire - Detection"
TOOL.Name			= "Laser Pointer Reciever"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_las_reciever_name", "Laser Reciever Tool (Wire)" )
    language.Add( "Tool_wire_las_reciever_desc", "Spawns a constant laser reciever prop for use with the wire system." )
    language.Add( "Tool_wire_las_reciever_0", "Primary: Create/Update Laser Reciever" )
    language.Add( "WireILaserRecieverTool_ilas_reciever", "Laser Reciever:" )
	language.Add( "sboxlimit_wire_las_recievers", "You've hit laser recievers limit!" )
	language.Add( "undone_wireigniter", "Undone Wire Laser Reciever" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_las_recievers', 20)
end


TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_las_recievers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_las_reciever" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_las_recievers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_las_reciever = MakeWireLaserReciever( ply, trace.HitPos, Ang )

	local min = wire_las_reciever:OBBMins()
	wire_las_reciever:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_nailer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_nailer:GetPhysicsObject():EnableCollisions( false )
		wire_nailer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_las_reciever, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Laser Reciever")
		undo.AddEntity( wire_las_reciever )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_las_recievers", wire_las_reciever )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireLaserReciever( pl, Pos, Ang )
		if ( !pl:CheckLimit( "wire_las_recievers" ) ) then return false end
	
		local wire_las_reciever = ents.Create( "gmod_wire_las_reciever" )
		if (!wire_las_reciever:IsValid()) then return false end

		wire_las_reciever:SetAngles( Ang )
		wire_las_reciever:SetPos( Pos )
		wire_las_reciever:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_las_reciever:Spawn()

		wire_las_reciever:GetTable():SetPlayer( pl )

		local ttable = {
			pl = pl
		}

		table.Merge(wire_las_reciever:GetTable(), ttable )
		
		pl:AddCount( "wire_las_recievers", wire_las_reciever )

		return wire_las_reciever
	end
	
	duplicator.RegisterEntityClass("gmod_wire_las_reciever", MakeWireLaserReciever, "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireLaserReciever( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_las_reciever" ) then
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

	self:UpdateGhostWireLaserReciever( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_las_reciever_name", Description = "#Tool_wire_las_reciever_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_las_reciever",

		Options = {
			Default = {
				wire_las_reciever_las_reciever = "0",
			}
		},
		CVars = {
		}
	})
end

