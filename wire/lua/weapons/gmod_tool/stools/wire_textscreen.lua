--Wire text screen by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There are a few bits of code from wire digital screen here and there, mainly just
--the values to correctly format cam3d2d for the screen, and a few standard things in the stool.

TOOL.Category		= "Wire - Display"
TOOL.Name			= "Text Screen"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.Model = "models/kobilica/wiremonitorbig.mdl"

if ( CLIENT ) then
    language.Add( "Tool_wire_textscreen_name", "Text Screen Tool (Wire)" )
    language.Add( "Tool_wire_textscreen_desc", "Spawns a screen that display text." )
    language.Add( "Tool_wire_textscreen_0", "Primary: Create/Update text screen" )
	language.Add( "sboxlimit_wire_textscreens", "You've hit text screens limit!" )
	language.Add( "undone_wiretextscreen", "Undone Wire Text Screen" )

	language.Add("Tool_wire_textscreen_text1", "Text 1:")
	language.Add("Tool_wire_textscreen_text2", "Text 2:")
	language.Add("Tool_wire_textscreen_text3", "Text 3:")
	language.Add("Tool_wire_textscreen_text4", "Text 4:")
	language.Add("Tool_wire_textscreen_text5", "Text 5:")
	language.Add("Tool_wire_textscreen_text6", "Text 6:")
	language.Add("Tool_wire_textscreen_text7", "Text 7:")
	language.Add("Tool_wire_textscreen_text8", "Text 8:")
	language.Add("Tool_wire_textscreen_text9", "Text 9:")
	language.Add("Tool_wire_textscreen_text10", "Text 10:")
	language.Add("Tool_wire_textscreen_text11", "Text 12:")
	language.Add("Tool_wire_textscreen_text12", "Text 12:")
	language.Add("Tool_wire_textscreen_tsize", "Text size:")
	language.Add("Tool_wire_textscreen_tjust", "Text justification:")
	language.Add("Tool_wire_textscreen_colour", "Text colour:")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_textscreens', 20)
end
--TOOL.ClientConVar[ "model" ] = "models/kobilica/wiremonitorbig.mdl"
for i = 0, 11 do
	TOOL.ClientConVar["text"..i] = ""	
end
TOOL.ClientConVar["tsize"] = 10
TOOL.ClientConVar["tjust"] = 1
TOOL.ClientConVar["tred"] = 255
TOOL.ClientConVar["tblue"] = 255
TOOL.ClientConVar["tgreen"] = 255

local MaxTextLength = 80

cleanup.Register( "wire_textscreens" )

function TOOL:LeftClick( trace )
	if (CLIENT) then return true end
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if ( !self:GetSWEP():CheckLimit( "wire_textscreens" ) ) then return false end
	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local Smodel = self.Model

	--get stool settings
	local TextList = {}
	for i = 1, 12 do
		TextList[i] = self:GetClientInfo("text"..i)
	end
	local chrPerLine = 16 - self:GetClientInfo("tsize")
	--Msg("cpl from stool = "..tostring(chrPerLine).."\n")
	local textJust = self:GetClientInfo("tjust")
	local tRed		= math.min(self:GetClientNumber("tred"), 255)
	local tGreen	= math.min(self:GetClientNumber("tgreen"), 255)
	local tBlue		= math.min(self:GetClientNumber("tblue"), 255)
	--Msg(string.format("red = %d, blue = %d, green = %d, alpha = %d", tRed, tBlue, tGreen, tAlpha))
	--update screen
	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_textscreen" && trace.Entity.pl == ply) then
		--Msg("updateing\n")
		trace.Entity:Setup(TextList, chrPerLine, textJust, tRed, tGreen, tBlue)
		return true
	end

	Ang.pitch = Ang.pitch + 90
	--make text screen
	wire_textscreen = MakeWireTextScreen( ply, Ang, trace.HitPos, Model(self.Model), TextList, chrPerLine, textJust, tRed, tGreen, tBlue, tAlpha)
	local min = wire_textscreen:OBBMins()
	wire_textscreen:SetPos( trace.HitPos - trace.HitNormal * min.z )

	undo.Create("WireTextScreen")
		undo.AddEntity( wire_textscreen )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_textscreens", wire_textscreen )

	return true
end

if (SERVER) then

	function MakeWireTextScreen( pl, Ang, Pos, Smodel, TextList, chrPerLine, textJust, tRed, tGreen, tBlue)
		
		if ( !pl:CheckLimit( "wire_textscreens" ) ) then return false end
		local wire_textscreen = ents.Create( "gmod_wire_textscreen" )
		if (!wire_textscreen:IsValid()) then return false end
		wire_textscreen:SetModel(Smodel)
		wire_textscreen:Setup(TextList, chrPerLine, textJust, tRed, tGreen, tBlue)
		wire_textscreen:SetAngles( Ang )
		wire_textscreen:SetPos( Pos )
		wire_textscreen:Spawn()
		wire_textscreen:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			Smodel = Smodel,
			TextList = TextList,
			chrPerLine = chrPerLine,
			textJust = textJust,
			tRed = tRed,
			tGreen = tGreen,
			tBlue = tBlue,
		}
		
		table.Merge(wire_textscreen:GetTable(), ttable )
		
		pl:AddCount( "wire_textscreens", wire_textscreen )
		return wire_textscreen
	end
	duplicator.RegisterEntityClass("gmod_wire_textscreen", MakeWireTextScreen, "Ang", "Pos", "Smodel", "TextList", "chrPerLine", "textJust", "tRed", "tGreen", "tBlue")
end

function TOOL:UpdateGhostWireTextScreen( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end
	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_textscreen" || trace.Entity:IsPlayer()) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhostWireTextScreen( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_textscreen_name", Description = "#Tool_wire_textscreen_desc" })
	
--	panel:AddControl("ComboBox", {
--		Label = "#WireTextScreenTool_Model", --exist?
--		MenuButton = "0",
--
--		Options = {
--			["#Small tv"]		= { wire_textscreen_model = "models/props_lab/monitor01b.mdl" },
--			["#Plasma tv"]		= { wire_textscreen_model = "models/props/cs_office/TV_plasma.mdl" },
--			["#LCD monitor"]	= { wire_textscreen_model = "models/props/cs_office/computer_monitor.mdl" },
--			["#Monitor Big"]	= { wire_textscreen_model = "models/kobilica/wiremonitorbig.mdl" },
--			["#Monitor Small"]	= { wire_textscreen_model = "models/kobilica/wiremonitorsmall.mdl" },
--		}
--	})

	panel:AddControl("Slider", {Label = "#Tool_wire_textscreen_tsize", Description = "", Type = "Integer", Min = "1", Max = "15", Command = "wire_textscreen_tsize"})
	panel:AddControl("Slider", {Label = "#Tool_wire_textscreen_tjust", Description = "", Type = "Integer", Min = "0", Max = "2", Command = "wire_textscreen_tjust"})
	panel:AddControl("Color", {
		Label = "#Tool_wire_textscreen_colour",
		Red = "wire_textscreen_tred",
		Green = "wire_textscreen_tgreen",
		Blue = "wire_textscreen_tblue",
		ShowAlpha = "0",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text1", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text1"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text2", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text2"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text3", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text3"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text4", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text4"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text5", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text5"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text6", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text6"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text7", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text7"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text8", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text8"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text9", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text9"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text10", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text10"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text11", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text11"})
	panel:AddControl("TextBox", {Label = "#Tool_wire_textscreen_text12", MaxLength = tostring(MaxTextLength), Command = "wire_textscreen_text12"})
	
	
end
	
