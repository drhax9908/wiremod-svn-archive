if ( !table.SortByMember ) then return end --pre gmod 31

if ( SERVER ) then 
	AddCSLuaFile( "autorun/WireMenus.lua" )
	return
end
//not really needed any more since gmod32, but do it anyway cause 31 required it
local function WireToolCategories()
	spawnmenu.AddToolCategory( "Main", 	"Wire - Advanced", 		"Wire - Advanced" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Beacon", 		"Wire - Beacon" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Control", 		"Wire - Control" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Data", 			"Wire - Data" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Detection", 	"Wire - Detection" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Display", 		"Wire - Display" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Holography", 	"Wire - Holography" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - I/O", 			"Wire - I/O" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Physics", 		"Wire - Physics" )
	spawnmenu.AddToolCategory( "Main", 	"Wire - Tools", 		"Wire - Tools" )
end
hook.Add( "AddToolMenuCategories", "WireToolCategories", WireToolCategories)
