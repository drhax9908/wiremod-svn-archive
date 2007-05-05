
TOOL.Category		= "Wire - Data"
TOOL.Name			= "Store"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_data_store_name", "Data Store Tool (Wire)" )
    language.Add( "Tool_wire_data_store_desc", "Spawns a data store." )
    language.Add( "Tool_wire_data_store_0", "Primary: Create/Update data store" )
    language.Add( "WireDataStoreTool_data_store", "Data Store:" )
	language.Add( "sboxlimit_wire_data_stores", "You've hit data stores limit!" )
	language.Add( "undone_wire_data_store", "Undone Wire data store" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_stores', 20)
end


TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_data_stores" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_store" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_stores" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_data_store = MakeWireStore( ply, trace.HitPos, Ang )

	local min = wire_data_store:OBBMins()
	wire_data_store:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_nailer, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_nailer:GetPhysicsObject():EnableCollisions( false )
		wire_nailer:GetTable().nocollide = true
	end*/
	local const = WireLib.Weld(wire_data_store, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Data Store")
		undo.AddEntity( wire_data_store )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_data_stores", wire_data_store )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireStore( pl, Pos, Ang )
		if ( !pl:CheckLimit( "wire_data_stores" ) ) then return false end
	
		local wire_data_store = ents.Create( "gmod_wire_data_store" )
		if (!wire_data_store:IsValid()) then return false end

		wire_data_store:SetAngles( Ang )
		wire_data_store:SetPos( Pos )
		wire_data_store:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_data_store:Spawn()

		wire_data_store:GetTable():SetPlayer( pl )

		local ttable = {
			pl = pl
		}

		table.Merge(wire_data_store:GetTable(), ttable )
		
		pl:AddCount( "wire_data_stores", wire_data_store )

		return wire_data_store
	end
	
	duplicator.RegisterEntityClass("gmod_wire_data_store", MakeWireStore, "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireStore( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_store" ) then
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

	self:UpdateGhostWireStore( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_data_store_name", Description = "#Tool_wire_data_store_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_data_store",

		Options = {
			Default = {
				wire_data_store_data_store = "0",
			}
		},
		CVars = {
		}
	})
end

