--Wire graphics tablet  by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There may be a few bits of code from the wire panel here and there as i used it as a starting point.
--Credit to whoever created the first wire screen, from which all others seem to use the lagacy clientside drawing code (this one included)

TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Graphics Tablet"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_graphics_tablet_name", "Graphics Tablet Tool (Wire)" )
    language.Add( "Tool_wire_graphics_tablet_desc", "Spawns a grphics tablet, which outputs cursor coordinates" )
    language.Add( "Tool_wire_graphics_tablet_0", "Primary: Create/Update graphics tablet" )
	language.Add( "sboxlimit_wire_graphics_tablets", "You've hit graphics tablets limit!" )
	language.Add( "undone_wire_graphics_tablet", "Undone Wire Graphics Tablet" )
	language.Add( "Tool_wire_graphics_tablet_mode", "Output mode: -1 to 1 (ticked), 0 to 1 (unticked)" )
	language.Add("Tool_wire_graphics_tablet_createflat", "Create flat to surface:")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_graphics_tablets', 20)
end

TOOL.ClientConVar["model"] = "models/kobilica/wiremonitorbig.mdl"
TOOL.ClientConVar["outmode"] = 0
TOOL.ClientConVar["createflat"] = 1

cleanup.Register( "wire_graphics_tablets" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_graphics_tablets" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self:GetClientInfo("model")
	local gmode = (self:GetClientNumber("outmode") ~= 0)
	local CreateFlat = self:GetClientNumber("createflat")
	
	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_graphics_tablet" && trace.Entity.pl == ply) then
		trace.Entity:Setup(gmode)
		return true
	end
	
	if (CreateFlat == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	local wire_graphics_tablet = MakeWireGraphicsTablet(ply, Ang, trace.HitPos, Smodel, gmode)
	local min = wire_graphics_tablet:OBBMins()
	wire_graphics_tablet:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_graphics_tablet, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("WireGraphicsTablet")
		undo.AddEntity( wire_graphics_tablet )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_graphics_tablets", wire_graphics_tablet )

	return true
end

if (SERVER) then
	function MakeWireGraphicsTablet( pl, Ang, Pos, Smodel, gmode )
		if ( !pl:CheckLimit( "wire_graphics_tablets" ) ) then return false end
		
		local wire_graphics_tablet = ents.Create( "gmod_wire_graphics_tablet" )
		if (!wire_graphics_tablet:IsValid()) then return false end
		wire_graphics_tablet:SetModel(Smodel)

		wire_graphics_tablet:SetAngles( Ang )
		wire_graphics_tablet:SetPos( Pos )
		wire_graphics_tablet:Setup(gmode)
		wire_graphics_tablet:Spawn()
		wire_graphics_tablet:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			Smodel = Smodel,
			gmode = gmode
		}
		table.Merge(wire_graphics_tablet:GetTable(), ttable )
		pl:AddCount( "wire_graphics_tablets", wire_graphics_tablet )
		return wire_graphics_tablet
	end
	duplicator.RegisterEntityClass("gmod_wire_graphics_tablet", MakeWireGraphicsTablet, "Ang", "Pos", "Smodel", "gmode")
end

function TOOL:UpdateGhostWireGraphicsTablet( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_graphics_tablet" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	if (self:GetClientNumber("createflat") == 0) then
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
	self:UpdateGhostWireGraphicsTablet( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_graphics_tablet_name", Description = "#Tool_wire_graphics_tablet_desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Small tv"]		= { wire_graphics_tablet_model = "models/props_lab/monitor01b.mdl" },
			["#Plasma tv"]		= { wire_graphics_tablet_model = "models/props/cs_office/TV_plasma.mdl" },
			["#LCD monitor"]	= { wire_graphics_tablet_model = "models/props/cs_office/computer_monitor.mdl" },
			["#Monitor Big"]	= { wire_graphics_tablet_model = "models/kobilica/wiremonitorbig.mdl" },
			["#Monitor Small"]	= { wire_graphics_tablet_model = "models/kobilica/wiremonitorsmall.mdl" },
		}
	})
	panel:AddControl("CheckBox", {
		Label = "#Tool_wire_graphics_tablet_mode",
		Command = "wire_graphics_tablet_outmode"
	})
	panel:AddControl("Checkbox", {
		Label = "#Tool_wire_graphics_tablet_createflat",
		Command = "wire_graphics_tablet_createflat"
	})
end
	
