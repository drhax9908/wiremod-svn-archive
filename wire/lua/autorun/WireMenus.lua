if ( VERSION < 31 ) then return end --pre gmod 31 = fail
Msg("=== Loading Wire Menus ===\n")

if (SERVER) then
	AddCSLuaFile( "autorun/WireMenus.lua" )
	return
 end

local usetab = CreateClientConVar( "cl_wire_usetab", "1", true, false )

local function WireTab()
	local mmenu = "Main"
	if usetab:GetBool() then
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
	if usetab:GetBool() then
		local oldspawnmenuAddToolMenuOption = spawnmenu.AddToolMenuOption
		function spawnmenu.AddToolMenuOption( tab, category, itemname, text, command, controls, cpanelfunction, TheTable )
			if ( tab == "Main" and "wire" == string.lower( string.Left(category, 4) ) ) then tab = "Wire" end
			oldspawnmenuAddToolMenuOption( tab, category, itemname, text, command, controls, cpanelfunction, TheTable )
		end
	end
end
hook.Add( "AddToolMenuCategories", "WireToolCategories", WireToolCategories)


 