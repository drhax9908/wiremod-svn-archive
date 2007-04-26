
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Colorer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_colorer_name", "Colorer Tool (Wire)" )
    language.Add( "Tool_wire_colorer_desc", "Spawns a constant colorer prop for use with the wire system." )
    language.Add( "Tool_wire_colorer_0", "Primary: Create/Update Colorer" )
    language.Add( "WireColorerTool_colorer", "Colorer:" )
    language.Add( "WireColorerTool_outColor", "Output Color:" )
	language.Add( "sboxlimit_wire_colorers", "You've hit Colorers limit!" )
	language.Add( "undone_wire_Colorer", "Undone Wire Colorer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_colorers', 20)
end


TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "outColor" ] = "0"

cleanup.Register( "wire_colorers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_colorer" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_colorers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
    local outColor = (self:GetClientNumber( "outColor" ) ~= 0)

	local wire_colorer = MakeWireColorer( ply, trace.HitPos, outColor, Ang )

	local min = wire_colorer:OBBMins()
	wire_colorer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_nailer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_nailer:GetPhysicsObject():EnableCollisions( false )
		wire_nailer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_colorer, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Colorer")
		undo.AddEntity( wire_colorer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_colorers", wire_colorer )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireColorer( pl, Pos, outColor, Ang )
		if ( !pl:CheckLimit( "wire_colorers" ) ) then return false end
	
		local wire_colorer = ents.Create( "gmod_wire_colorer" )
		if (!wire_colorer:IsValid()) then return false end

		wire_colorer:SetAngles( Ang )
		wire_colorer:SetPos( Pos )
		wire_colorer:SetModel( Model("models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_colorer:Spawn()
		wire_colorer:Setup(outColor)

		wire_colorer:GetTable():SetPlayer( pl )

		local ttable = {
		    outColor = outColor,
			pl = pl
		}

		table.Merge(wire_colorer:GetTable(), ttable )
		
		pl:AddCount( "wire_colorers", wire_colorer )

		return wire_colorer
	end
	
	duplicator.RegisterEntityClass("gmod_wire_colorer", MakeWireColorer, "Pos", "outColor", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireColorer( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_colorer" ) then
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

	self:UpdateGhostWireColorer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_colorer_name", Description = "#Tool_wire_colorer_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_colorer",

		Options = {
			Default = {
				wire_colorer_outColor = "0",
			}
		},
		CVars = {
		  [0] = "wire_colorer_outColor"
		}
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireColorerTool_outColor",
		Command = "wire_colorer_outColor"
	})
end

