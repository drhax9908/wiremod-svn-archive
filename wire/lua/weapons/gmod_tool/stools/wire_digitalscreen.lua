
TOOL.Category		= "Wire - Display"
TOOL.Name			= "Digital Screen"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_digitalscreen_name", "Digital Screen Tool (Wire)" )
    language.Add( "Tool_wire_digitalscreen_desc", "Spawns a digital screen, which can be used to draw pixel by pixel. Resoultion is 32x32!" )
    language.Add( "Tool_wire_digitalscreen_0", "Primary: Create/Update screen" )
	language.Add( "sboxlimit_wire_digitalscreens", "You've hit digital screens limit!" )
	language.Add( "undone_wiredigitalscreen", "Undone Wire Screen" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_digitalscreens', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"

cleanup.Register( "wire_digitalscreens" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_digitalscreens" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90
	
	wire_digitalscreen = MakeWireDigitalScreen( ply, Ang, trace.HitPos, Smodel )
	local min = wire_digitalscreen:OBBMins()
	wire_digitalscreen:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WireDigitalScreen")
		undo.AddEntity( wire_digitalscreen )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_digitalscreens", wire_digitalscreen )

	return true
end

if (SERVER) then

	function MakeWireDigitalScreen( pl, Ang, Pos, Smodel )
		
		if ( !pl:CheckLimit( "wire_digitalscreens" ) ) then return false end
		
		local wire_digitalscreen = ents.Create( "gmod_wire_digitalscreen" )
		if (!wire_digitalscreen:IsValid()) then return false end
		wire_digitalscreen:SetModel(Smodel)

		wire_digitalscreen:SetAngles( Ang )
		wire_digitalscreen:SetPos( Pos )
		wire_digitalscreen:Spawn()
		
		wire_digitalscreen:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			Smodel = Smodel,
		}
		
		table.Merge(wire_digitalscreen:GetTable(), ttable )
		
		pl:AddCount( "wire_digitalscreens", wire_digitalscreen )
		
		return wire_digitalscreen
		
	end

	duplicator.RegisterEntityClass("gmod_wire_digitalscreen", MakeWireDigitalScreen, "Ang", "Pos", "Smodel")

end

function TOOL:UpdateGhostWireDigitalScreen( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_digitalscreen" || trace.Entity:IsPlayer()) then

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

	self:UpdateGhostWireDigitalScreen( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_digitalscreen_name", Description = "#Tool_wire_digitalscreen_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_digitalscreen_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_digitalscreen_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_digitalscreen_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_digitalscreen_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_digitalscreen_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
end
	
