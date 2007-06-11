
TOOL.Category		= "Wire - Advanced"
TOOL.Name			= "Flash (EEPROM)"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_hdd_name", "Flash (EEPROM) tool (Wire)" )
    language.Add( "Tool_wire_hdd_desc", "Spawns flash memory. It is used for permanent storage of data (carried over sessions)" )
    language.Add( "Tool_wire_hdd_0", "Primary: Create/Update flash memory" )
	language.Add( "sboxlimit_wire_hdds", "You've hit flash memory limit!" )
	language.Add( "undone_wiredigitalscreen", "Undone Flash (EEPROM)" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_hdds', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar[ "driveid" ] = 0
TOOL.ClientConVar[ "drivecap" ] = 128

cleanup.Register( "wire_hdds" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hdd" && trace.Entity.pl == ply ) then
		trace.Entity.DriveID = self:GetClientInfo( "driveid" ) + 1 - 1
		trace.Entity.DriveCap = self:GetClientInfo( "drivecap" ) + 1 - 1
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_hdds" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90
	
	wire_hdd = MakeWirehdd( ply, Ang, self:GetClientInfo( "driveid" ),
					  self:GetClientInfo( "drivecap" ), trace.HitPos, Smodel )
	local min = wire_hdd:OBBMins()
	wire_hdd:SetPos( trace.HitPos - trace.HitNormal * min.z )

	wire_hdd.DriveID = self:GetClientInfo( "driveid" ) + 1 - 1
	wire_hdd.DriveCap = self:GetClientInfo( "drivecap" ) + 1 - 1

	local const = WireLib.Weld(wire_hdd, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wirehdd")
		undo.AddEntity( wire_hdd )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_hdds", wire_hdd )

	return true
end

if (SERVER) then

	function MakeWirehdd( pl, Ang, DriveID, DriveCap, Pos, Smodel )
		
		if ( !pl:CheckLimit( "wire_hdds" ) ) then return false end
		
		local wire_hdd = ents.Create( "gmod_wire_hdd" )
		if (!wire_hdd:IsValid()) then return false end
		wire_hdd:SetModel(Smodel)

		wire_hdd:SetAngles( Ang )
		wire_hdd:SetPos( Pos )
		wire_hdd:Spawn()

		wire_hdd:SetPlayer(pl)

		local ttable = {
			pl = pl,
			Smodel = Smodel,
			DriveID = DriveID,
			DriveCap = DriveCap,
		}

		//Dont paste this in IRC:
		//0,0XX5,5XX0,0XX5,5XXXXXX0,0XX
		//0,0XX5,5XX0,0XX5,5XX0,0XXXXXX
		//0,0XX5,5XXXXXXXXXX0,0XX
		//0,0XXXXXX5,5XX0,0XX5,5XX0,0XX
		//0,0XX5,5XXXXXX0,0XX5,5XX0,0XX
		
		table.Merge(wire_hdd:GetTable(), ttable )
		
		pl:AddCount( "wire_hdds", wire_hdd )
		
		return wire_hdd
		
	end

	duplicator.RegisterEntityClass("gmod_wire_hdd", MakeWirehdd, "Ang", "DriveID", "DriveCap", "Pos", "Smodel")

end

function TOOL:UpdateGhostWirehdd( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_hdd" || trace.Entity:IsPlayer()) then

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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWirehdd( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_hdd_name", Description = "#Tool_wire_hdd_desc" })

	panel:AddControl("Slider", {
		Label = "Drive ID",
		Type = "Integer",
		Min = "0",
		Max = "3",
		Command = "wire_hdd_driveid"
	})

	panel:AddControl("Slider", {
		Label = "Capicacity",
		Type = "Integer",
		Min = "0",
		Max = "128",
		Command = "wire_hdd_drivecap"
	})

	panel:AddControl("Label", {
		Text = "Beta testing. Report all faults to wiremod.com"
	})
	panel:AddControl("Label", {
		Text = "forums into topic in Developer's Showcase!"
	})
	panel:AddControl("Label", {
		Text = "Most of features are missing (up- & download)"
	})
end
	
