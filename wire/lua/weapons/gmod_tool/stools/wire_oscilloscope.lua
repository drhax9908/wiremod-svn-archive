
TOOL.Category		= "Wire"
TOOL.Name			= "Oscilloscope"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_oscilloscope_name", "Oscilloscope Tool (Wire)" )
    language.Add( "Tool_wire_oscilloscope_desc", "Spawns a oscilloscope what display line graphs." )
    language.Add( "Tool_wire_oscilloscope_0", "Primary: Create/Update oscilloscope" )
	language.Add( "sboxlimit_wire_oscilloscopes", "You've hit oscilloscopes limit!" )
	language.Add( "undone_wireoscilloscope", "Undone Wire Oscilloscope" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_oscilloscopes', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"

cleanup.Register( "wire_oscilloscopes" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_oscilloscopes" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo( "model" )
	Ang.pitch = Ang.pitch + 90
	
	wire_oscilloscope = MakeWireOscilloscope( ply, Ang, trace.HitPos, Smodel )
	local min = wire_oscilloscope:OBBMins()
	wire_oscilloscope:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WireOscilloscope")
		undo.AddEntity( wire_oscilloscope )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_oscilloscopes", wire_oscilloscope )

	return true
end

if (SERVER) then

	function MakeWireOscilloscope( pl, Ang, Pos, Model )
		
		if ( !pl:CheckLimit( "wire_oscilloscopes" ) ) then return false end
		
		local wire_oscilloscope = ents.Create( "gmod_wire_oscilloscope" )
		if (!wire_oscilloscope:IsValid()) then return false end
		wire_oscilloscope:SetModel( Model )

		wire_oscilloscope:SetAngles( Ang )
		wire_oscilloscope:SetPos( Pos )
		wire_oscilloscope:Spawn()
		
		wire_oscilloscope:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
		}
		
		table.Merge(wire_oscilloscope:GetTable(), ttable )
		
		pl:AddCount( "wire_oscilloscopes", wire_oscilloscope )
		
		return wire_oscilloscope
		
	end

	duplicator.RegisterEntityClass("gmod_wire_oscilloscope", MakeWireOscilloscope, "Ang", "Pos", "Model")

end

function TOOL:UpdateGhostWireOscilloscope( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_oscilloscope" || trace.Entity:IsPlayer()) then

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

	self:UpdateGhostWireOscilloscope( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_oscilloscope_name", Description = "#Tool_wire_oscilloscope_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_oscilloscope_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_oscilloscope_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_oscilloscope_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_screen_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_screen_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
end
	
