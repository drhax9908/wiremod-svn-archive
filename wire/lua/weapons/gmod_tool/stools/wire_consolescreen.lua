TOOL.Category		= "Wire - Display"
TOOL.Name			= "Console Screen"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_consolescreen_name", "Console Screen Tool (Wire)" )
    language.Add( "Tool_wire_consolescreen_desc", "Spawns a console screen" )
    language.Add( "Tool_wire_consolescreen_0", "Primary: Create/Update screen" )
	language.Add( "sboxlimit_wire_consolescreens", "You've hit console screens limit!" )
	language.Add( "undone_wireconsolescreen", "Undone Wire Screen" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_consolescreens', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"

cleanup.Register( "wire_consolescreens" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_consolescreens" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90
	
	wire_consolescreen = MakeWireconsoleScreen( ply, Ang, trace.HitPos, Smodel )
	local min = wire_consolescreen:OBBMins()
	wire_consolescreen:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WireconsoleScreen")
		undo.AddEntity( wire_consolescreen )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_consolescreens", wire_consolescreen )

	return true
end

if (SERVER) then

	function MakeWireconsoleScreen( pl, Ang, Pos, Smodel )
		
		if ( !pl:CheckLimit( "wire_consolescreens" ) ) then return false end
		
		local wire_consolescreen = ents.Create( "gmod_wire_consolescreen" )
		if (!wire_consolescreen:IsValid()) then return false end
		wire_consolescreen:SetModel(Smodel)

		wire_consolescreen:SetAngles( Ang )
		wire_consolescreen:SetPos( Pos )
		wire_consolescreen:Spawn()
		
		wire_consolescreen:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			Smodel = Smodel,
		}
		table.Merge(wire_consolescreen:GetTable(), ttable )
		
		pl:AddCount( "wire_consolescreens", wire_consolescreen )
		
		return wire_consolescreen
	end

	duplicator.RegisterEntityClass("gmod_wire_consolescreen", MakeWireconsoleScreen, "Ang", "Pos", "Smodel")

end

function TOOL:UpdateGhostWireconsoleScreen( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_consolescreen" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWireconsoleScreen( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_consolescreen_name", Description = "#Tool_wire_consolescreen_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_consolescreen_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_consolescreen_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_consolescreen_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_consolescreen_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_consolescreen_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
end
	
