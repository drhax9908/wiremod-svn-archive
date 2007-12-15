TOOL.Category		= "Wire - Display"
TOOL.Name			= "Screen"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_screen_name", "Screen Tool (Wire)" )
    language.Add( "Tool_wire_screen_desc", "Spawns a screen that display values." )
    language.Add( "Tool_wire_screen_0", "Primary: Create/Update screen" )
	language.Add( "sboxlimit_wire_screens", "You've hit screens limit!" )
	language.Add( "undone_wirescreen", "Undone Wire Screen" )

	// Extra stuff for Wire Screen (TheApathetic)
	language.Add("Tool_wire_screen_singlevalue", "Only one value:")
	language.Add("Tool_wire_screen_singlebigfont", "Use bigger font for single-value screen:")
	language.Add("Tool_wire_screen_texta", "Text A:")
	language.Add("Tool_wire_screen_textb", "Text B:")
	
	//left alignment  and floor options (TAD2020)
	language.Add("Tool_wire_screen_leftalign", "Left alignment:")
	language.Add("Tool_wire_screen_floor", "Floor screen value:")
	
	// Weld flat option (TheApathetic)
	language.Add("Tool_wire_screen_createflat", "Create flat to surface:")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_screens', 20)
end

TOOL.ClientConVar[ "model" ] = "models/props_lab/monitor01b.mdl"

// Extra stuff for Wire Screen (TheApathetic)
TOOL.ClientConVar["singlevalue"] = "0"
TOOL.ClientConVar["singlebigfont"] = "1"
TOOL.ClientConVar["texta"] = "Value A"
TOOL.ClientConVar["textb"] = "Value B"
TOOL.ClientConVar["createflat"] = "1"
//left alignment  and floor options (TAD2020)
TOOL.ClientConVar["leftalign"] = "0"
TOOL.ClientConVar["floor"] = "0"

local MaxTextLength = 20

cleanup.Register( "wire_screens" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_screens" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply		= self:GetOwner()
	local Ang		= trace.HitNormal:Angle()
	local Smodel	= self:GetClientInfo( "model" )

	// Extra stuff for Wire Screen (TheApathetic)
	local SingleValue	= self:GetClientNumber("singlevalue") == 1
	local SingleBigFont	= self:GetClientNumber("singlebigfont") == 1
	local TextA			= self:GetClientInfo("texta")
	local TextB			= self:GetClientInfo("textb")
	local LeftAlign		= self:GetClientNumber("leftalign") == 1
	local Floor			= self:GetClientNumber("floor") == 1
	local CreateFlat		= self:GetClientNumber("createflat")

	// Check to update screen if necessary (TheApathetic)
	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_screen" && trace.Entity.pl == ply) then
		trace.Entity:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor)
		
		trace.Entity.SingleValue	= SingleValue
		trace.Entity.SingleBigFont	= SingleBigFont
		trace.Entity.TextA			= TextA
		trace.Entity.TextB 			= TextB
		trace.Entity.LeftAlign 		= LeftAlign
		trace.Entity.Floor	 		= Floor
		return true
	end

	// Make screens spawn flat on props instead of perpendicular to them (TheApathetic)
	if (CreateFlat == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	local wire_screen = MakeWireScreen( ply, Ang, trace.HitPos, Smodel, SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor )
	local min = wire_screen:OBBMins()
	wire_screen:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	// Screens are now welded to the respective surface (TheApathetic)
	local const = WireLib.Weld(wire_screen, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireScreen")
		undo.AddEntity( wire_screen )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_screens", wire_screen )

	return true
end

if (SERVER) then

	function MakeWireScreen( pl, Ang, Pos, Smodel, SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor )
		
		if ( !pl:CheckLimit( "wire_screens" ) ) then return false end
		
		local wire_screen = ents.Create( "gmod_wire_screen" )
		if (!wire_screen:IsValid()) then return false end
		wire_screen:SetModel(Smodel)
		wire_screen:SetAngles( Ang )
		wire_screen:SetPos( Pos )
		wire_screen:Spawn()
		
		wire_screen:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor)
		
		wire_screen:SetPlayer(pl)
			
		local ttable = {
			pl				= pl,
			Smodel			= Smodel,
			SingleValue		= SingleValue,
			SingleBigFont	= SingleBigFont,
			TextA			= TextA,
			TextB			= TextB,
			LeftAlign		= LeftAlign,
			Floor			= Floor
		}
		table.Merge(wire_screen:GetTable(), ttable )
		
		pl:AddCount( "wire_screens", wire_screen )
		
		return wire_screen
		
	end

	duplicator.RegisterEntityClass("gmod_wire_screen", MakeWireScreen, "Ang", "Pos", "Smodel", "SingleValue", "SingleBigFont", "TextA", "TextB", "LeftAlign", "Floor")

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
	// Make screens spawn flat on props instead of perpendicular to them (TheApathetic)
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
	
	panel:AddControl( "PropSelect", {
		Label = "#WireThrusterTool_Model",
		ConVar = "wire_screen_model",
		Category = "WireScreenModels",
		Models = list.Get( "WirePanelModels" )
	})
	
	// Extra stuff for Wire Screen (TheApathetic)
	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_singlevalue", Command = "wire_screen_singlevalue"})
	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_singlebigfont", Command = "wire_screen_singlebigfont"})
	
	//left alignment  and floor options (TAD2020)
	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_leftalign", Command = "wire_screen_leftalign"})
	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_floor", Command = "wire_screen_floor"})

	panel:AddControl("TextBox", {Label = "#Tool_wire_screen_texta", MaxLength = tostring(MaxTextLength), Command = "wire_screen_texta"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_screen_textb", MaxLength = tostring(MaxTextLength), Command = "wire_screen_textb"})
	
	// Weld flat option (TheApathetic)
	panel:AddControl("Checkbox", {Label = "#Tool_wire_screen_createflat", Command = "wire_screen_createflat"})
end
	

list.Set( "WireScreenModels", "models/props_lab/monitor01b.mdl", {} )
list.Set( "WireScreenModels", "models/props/cs_office/TV_plasma.mdl", {} )
list.Set( "WireScreenModels", "models/props/cs_office/computer_monitor.mdl", {} )
list.Set( "WireScreenModels", "models/kobilica/wiremonitorbig.mdl", {} )
list.Set( "WireScreenModels", "models/kobilica/wiremonitorsmall.mdl", {} )
