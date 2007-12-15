TOOL.Category		= "Wire - Display"
TOOL.Name			= "Panel"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_panel_name", "Control Panel Tool (Wire)" )
    language.Add( "Tool_wire_panel_desc", "Spawns a panel what display values." )
    language.Add( "Tool_wire_panel_0", "Primary: Create/Update panel" )
	language.Add( "sboxlimit_wire_panels", "You've hit panels limit!" )
	language.Add( "undone_wirepanel", "Undone Wire Control Panel" )
	language.Add( "Tool_wire_panel_createflat", "Create flat to surface:" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_panels', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"
// Option to weld screen flat to surface shot (TheApathetic)
TOOL.ClientConVar[ "createflat" ] = "1"
TOOL.ClientConVar[ "weld" ] = "1"

cleanup.Register( "wire_panels" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_panels" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply			= self:GetOwner()
	local Ang			= trace.HitNormal:Angle()
	local Smodel		= self:GetClientInfo( "model" )
	local CreateFlat	= self:GetClientNumber( "createflat" )
	local weld			= self:GetClientNumber( "createflat" ) == 1
	
	// Weld panel flat to surface shot instead of perpendicular to it? (TheApathetic)
	if (CreateFlat == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	local wire_panel = MakeWirePanel( ply, Ang, trace.HitPos, Smodel )
	local min = wire_panel:OBBMins()
	wire_panel:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const
	if ( weld ) then
		// Welded to surface now (TheApathetic)
		const = WireLib.Weld(wire_panel, trace.Entity, trace.PhysicsBone, true)
	end

	undo.Create("WirePanel")
		undo.AddEntity( wire_panel )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_panels", wire_panel )

	return true
end

if (SERVER) then

	function MakeWirePanel( pl, Ang, Pos, Smodel )
		
		if ( !pl:CheckLimit( "wire_panels" ) ) then return false end
		
		local wire_panel = ents.Create( "gmod_wire_panel" )
		if (!wire_panel:IsValid()) then return false end
		wire_panel:SetModel(Smodel)

		wire_panel:SetAngles( Ang )
		wire_panel:SetPos( Pos )
		wire_panel:Spawn()
		
		wire_panel:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			Smodel = Smodel,
		}
		table.Merge(wire_panel:GetTable(), ttable )
		
		pl:AddCount( "wire_panels", wire_panel )
		
		return wire_panel
		
	end

	duplicator.RegisterEntityClass("gmod_wire_panel", MakeWirePanel, "Ang", "Pos", "Smodel")

end

function TOOL:UpdateGhostWirePanel( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_panel" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	if (self:GetClientNumber( "createflat" ) == 0) then
		Ang.pitch = Ang.pitch + 90
	end

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWirePanel( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_panel_name", Description = "#Tool_wire_panel_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_panel_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_panel_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_panel_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_panel_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_panel_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
	
	panel:AddControl( "PropSelect", {
		Label = "#WireThrusterTool_Model",
		ConVar = "wire_panel_model",
		Category = "WirePanelModels",
		Models = list.Get( "WirePanelModels" )
	})
	
	// Weld flat option (TheApathetic)
	panel:AddControl("Checkbox", {Label = "#Tool_wire_panel_createflat", Command = "wire_panel_createflat"})
	
	panel:AddControl("Checkbox", {Label = "Weld:", Command = "wire_panel_weld"})
end

