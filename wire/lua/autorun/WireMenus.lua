if ( !table.SortByMember ) then return end --pre gmod 31
Msg("=== Loading Wire Menus ===\n")

if ( SERVER ) then 
	AddCSLuaFile( "autorun/WireMenus.lua" )
	return
end

CreateClientConVar( "wiremovetoolstotab", "0", true, false )

local function WireTab()
	if LocalPlayer():GetInfo("wiremovetoolstotab") == "1" then
		spawnmenu.AddToolTab( "Wire", "Wire" )
	end
end
hook.Add( "AddToolMenuTabs", "WireTab", WireTab)


//not really needed any more since gmod32, but do it anyway cause 31 required it
local function WireToolCategories()
	if LocalPlayer():GetInfo("wiremovetoolstotab") == "1" then
		local oldspawnmenuAddToolMenuOption = spawnmenu.AddToolMenuOption
		function spawnmenu.AddToolMenuOption( tab, category, itemname, text, command, controls, cpanelfunction, TheTable )
			if ( tab == "Main" and "wire" == string.lower( string.Left(category, 4) ) ) then tab = "Wire" end
			oldspawnmenuAddToolMenuOption( tab, category, itemname, text, command, controls, cpanelfunction, TheTable )
		end
	else
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
end
hook.Add( "AddToolMenuCategories", "WireToolCategories", WireToolCategories)


// Add the wire tools to the wire tab
/*local function AddWireSToolsToWireMenu()
	if LocalPlayer():GetInfo("wiremovetoolstotab") != "1" then
		local TOOLS_LIST
		for k,v in pairs(weapons.GetList()) do
			if v.Tool then
				TOOLS_LIST = v.Tool
				break
			end
		end
		//add to tab
		for ToolName, TOOL in pairs( TOOLS_LIST ) do
			if ( TOOL.AddToMenu != false ) then
				if ( "wire" == string.lower( string.Left(TOOL.Category, 4) ) ) then
					spawnmenu.AddToolMenuOption( "Wire",
											TOOL.Category or "New Category", 
											"wiretab_" .. ToolName,
											TOOL.Name or "#"..ToolName, 
											TOOL.Command or "gmod_tool "..ToolName, 
											TOOL.ConfigName or ToolName,
											TOOL.BuildCPanel )
				end
			end
		end
	end
end
hook.Add( "PopulateToolMenu", "AddWireSToolsToWireMenu", AddWireSToolsToWireMenu )*/
 