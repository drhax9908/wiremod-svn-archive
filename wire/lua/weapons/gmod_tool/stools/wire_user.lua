
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "User"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_user_name", "User Tool (Wire)" )
    language.Add( "Tool_wire_user_desc", "Spawns a constant user prop for use with the wire system." )
    language.Add( "Tool_wire_user_0", "Primary: Create/Update User" )
    language.Add( "WireUserTool_user", "User:" )
    language.Add( "WireUserTool_Range", "Max Range:" )
	language.Add( "sboxlimit_wire_users", "You've hit Users limit!" )
	language.Add( "undone_Wire User", "Undone Wire User" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_users', 20)
end


TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "Range" ] = "200"

cleanup.Register( "wire_users" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_user" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_users" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
    local range = self:GetClientNumber("Range")

	local wire_user = MakeWireUser( ply, trace.HitPos, range, Ang )

	local min = wire_user:OBBMins()
	wire_user:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_nailer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_nailer:GetPhysicsObject():EnableCollisions( false )
		wire_nailer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_user, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire User")
		undo.AddEntity( wire_user )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_users", wire_user )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireUser( pl, Pos, Range, Ang )
		if ( !pl:CheckLimit( "wire_users" ) ) then return false end
	
		local wire_user = ents.Create( "gmod_wire_user" )
		if (!wire_user:IsValid()) then return false end

		wire_user:SetAngles( Ang )
		wire_user:SetPos( Pos )
		wire_user:SetModel( Model("models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_user:Spawn()
		wire_user:Setup(Range)

		wire_user:GetTable():SetPlayer( pl )

		local ttable = {
		    outColor = outColor,
		    Range = Range,
			pl = pl
		}

		table.Merge(wire_user:GetTable(), ttable )
		
		pl:AddCount( "wire_users", wire_user )

		return wire_user
	end
	
	duplicator.RegisterEntityClass("gmod_wire_user", MakeWireUser, "Pos", "Range", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireUser( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_user" ) then
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

	self:UpdateGhostWireUser( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_user_name", Description = "#Tool_wire_user_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_user",

		Options = {
			Default = {
			}
		},
		CVars = {
		}
	})
	panel:AddControl("Slider", {
		Label = "#WireUserTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_user_Range"
	})
end
