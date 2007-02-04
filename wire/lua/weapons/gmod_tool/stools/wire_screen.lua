
TOOL.Category		= "Wire"
TOOL.Name			= "Screen"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_screen_name", "Screen Tool (Wire)" )
    language.Add( "Tool_wire_screen_desc", "Spawns a screen what display values." )
    language.Add( "Tool_wire_screen_0", "Primary: Create/Update screen" )
	language.Add( "sboxlimit_wire_screens", "You've hit screens limit!" )
	language.Add( "undone_wirescreen", "Undone Wire Screen" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_screens', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"

cleanup.Register( "wire_screens" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_screens" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90
	
	wire_screen = MakeWireScreen( ply, Ang, trace.HitPos, Smodel )
	local min = wire_screen:OBBMins()
	wire_screen:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WireScreen")
		undo.AddEntity( wire_screen )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_screens", wire_screen )

	return true
end

if (SERVER) then

	function MakeWireScreen( pl, Ang, Pos, Smodel )
		
		if ( !pl:CheckLimit( "wire_screens" ) ) then return false end
		
		local wire_screen = ents.Create( "gmod_wire_screen" )
		if (!wire_screen:IsValid()) then return false end
		wire_screen:SetModel(Smodel)

		wire_screen:SetAngles( Ang )
		wire_screen:SetPos( Pos )
		wire_screen:Spawn()
		
		wire_screen:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			Smodel = Smodel,
		}
		
		table.Merge(wire_screen:GetTable(), ttable )
		
		pl:AddCount( "wire_screens", wire_screen )
		
		return wire_screen
		
	end

	duplicator.RegisterEntityClass("gmod_wire_screen", MakeWireScreen, "Ang", "Pos", "Smodel")

end

function TOOL:UpdateGhostWireScreen( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_screen" || trace.Entity:IsPlayer()) then

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

	self:UpdateGhostWireScreen( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_screen_name", Description = "#Tool_wire_screen_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_screen_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_screen_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_screen_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_screen_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_screen_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
end
	
