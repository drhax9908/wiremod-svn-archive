
TOOL.Category		= "Wire - Data"
TOOL.Name			= "Transferer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_data_transferer_name", "Data Transferer Tool (Wire)" )
    language.Add( "Tool_wire_data_transferer_desc", "Spawns a data transferer." )
    language.Add( "Tool_wire_data_transferer_0", "Primary: Create/Update data transferer" )
    language.Add( "WireDataTransfererTool_data_transferer", "Data Transferer:" )
    language.Add( "WireDataTransfererTool_Range", "Max Range:" )
	language.Add( "sboxlimit_wire_data_transferers", "You've hit data transferers limit!" )
	language.Add( "undone_Wire Data Transferer", "Undone Wire data transferer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_transferers', 20)
end


TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "Range" ] = "25000"

cleanup.Register( "wire_data_transferers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_transferer" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_transferers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local range = self:GetClientNumber("Range")

	local wire_data_transferer = MakeWireTransferer( ply, trace.HitPos, range, Ang )

	local min = wire_data_transferer:OBBMins()
	wire_data_transferer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_nailer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_nailer:GetPhysicsObject():EnableCollisions( false )
		wire_nailer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_data_transferer, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data Transferer")
		undo.AddEntity( wire_data_transferer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_data_transferers", wire_data_transferer )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireTransferer( pl, Pos, Range, Ang )
		if ( !pl:CheckLimit( "wire_data_transferers" ) ) then return false end
	
		local wire_data_transferer = ents.Create( "gmod_wire_data_transferer" )
		if (!wire_data_transferer:IsValid()) then return false end

		wire_data_transferer:SetAngles( Ang )
		wire_data_transferer:SetPos( Pos )
		wire_data_transferer:SetModel( Model("models/jaanus/wiretool/wiretool_siren.mdl") )
		wire_data_transferer:Spawn()
		wire_data_transferer:Setup(Range)

		wire_data_transferer:GetTable():SetPlayer( pl )

		local ttable = {
		    Range = Range,
			pl = pl
		}

		table.Merge(wire_data_transferer:GetTable(), ttable )
		
		pl:AddCount( "wire_data_transferers", wire_data_transferer )

		return wire_data_transferer
	end
	
	duplicator.RegisterEntityClass("gmod_wire_data_transferer", MakeWireTransferer, "Pos", "Range", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireTransferer( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_transferer" ) then
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

	self:UpdateGhostWireTransferer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_data_transferer_name", Description = "#Tool_wire_data_transferer_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_data_transferer",

		Options = {
			Default = {
				wire_data_transferer_data_transferer = "0",
			}
		},
		CVars = {
		}
	})
	panel:AddControl("Slider", {
		Label = "#WireDataTransfererTool_Range",
		Type = "Float",
		Min = "1",
		Max = "1000000",
		Command = "wire_data_transferer_Range"
	})
end

