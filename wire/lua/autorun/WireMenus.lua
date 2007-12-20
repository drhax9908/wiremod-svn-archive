if ( VERSION < 31 ) then return end --pre gmod 31 = fail
Msg("=== Loading Wire Menus ===\n")

if ( SERVER ) then 
	AddCSLuaFile( "autorun/WireMenus.lua" )
end



WireToolHelpers = {}

function WireToolHelpers.LeftClick( self, trace )
	if ( not trace.HitPos or trace.Entity:IsPlayer() or trace.Entity:IsNPC() ) then return false end
	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local ent = self:ToolMakeEnt( trace, ply )
	if ( ent == true ) then return true end
	if ( ent == nil or ent == false or not ent:IsValid() ) then return false end

	local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )

	undo.Create( self.WireClass )
		undo.AddEntity( ent )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( self.WireClass, ent )

	return true
end

function WireToolHelpers.UpdateGhost( self, ent )

	if ( !ent or !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == self.WireClass ) then
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

function WireToolHelpers.Think( self )
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhost( self.GhostEntity )
end




if (SERVER) then return end

CreateClientConVar( "wiremovetoolstotab", "0", true, false )

local function WireTab()
	local mmenu = "Main"
	if GetConVarNumber("wiremovetoolstotab") == 1 then
		spawnmenu.AddToolTab( "Wire", "Wire" )
		mmenu = "Wire"
	end
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Advanced", 		"Wire - Advanced" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Beacon", 		"Wire - Beacon" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Control", 		"Wire - Control" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Data", 			"Wire - Data" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Detection", 	"Wire - Detection" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Display", 		"Wire - Display" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Holography", 	"Wire - Holography" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - I/O", 			"Wire - I/O" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Physics", 		"Wire - Physics" )
	spawnmenu.AddToolCategory( mmenu, 	"Wire - Tools", 		"Wire - Tools" )
end
hook.Add( "AddToolMenuTabs", "WireTab", WireTab)


//not really needed any more since gmod32, but do it anyway cause 31 required it
local function WireToolCategories()
	if GetConVarNumber("wiremovetoolstotab") == 1 then
		local oldspawnmenuAddToolMenuOption = spawnmenu.AddToolMenuOption
		function spawnmenu.AddToolMenuOption( tab, category, itemname, text, command, controls, cpanelfunction, TheTable )
			if ( tab == "Main" and "wire" == string.lower( string.Left(category, 4) ) ) then tab = "Wire" end
			oldspawnmenuAddToolMenuOption( tab, category, itemname, text, command, controls, cpanelfunction, TheTable )
		end
	end
end
hook.Add( "AddToolMenuCategories", "WireToolCategories", WireToolCategories)


 