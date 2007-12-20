
if ( CLIENT ) then
    language.Add( "Tool_wire_gate_arithmetic_name", "Arithmetic Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_arithmetic_desc", "Spawns an arithmetic gate for use with the wire system." )
    language.Add( "Tool_wire_gate_arithmetic_0", "Primary: Create/Update Arithmetic Gate" )
	
    language.Add( "Tool_wire_gate_comparison_name", "Comparison Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_comparison_desc", "Spawns a comparison gate for use with the wire system." )
    language.Add( "Tool_wire_gate_comparison_0", "Primary: Create/Update Comparison Gate" )
	
    language.Add( "Tool_wire_gate_duplexer_name", "Duplexer Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_duplexer_desc", "Spawns a duplexer chip for use with the wire system." )
    language.Add( "Tool_wire_gate_duplexer_0", "Primary: Create/Update Duplexer Chip" )
	
    language.Add( "Tool_wire_gate_logic_name", "Logic Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_logic_desc", "Spawns a logic gate for use with the wire system." )
    language.Add( "Tool_wire_gate_logic_0", "Primary: Create/Update Logic Gate" )
	
    language.Add( "Tool_wire_gate_memory_name", "Memory Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_memory_desc", "Spawns a memory chip for use with the wire system." )
    language.Add( "Tool_wire_gate_memory_0", "Primary: Create/Update Memory Chip" )
	
    language.Add( "Tool_wire_gate_selection_name", "Selection Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_selection_desc", "Spawns a selection chip for use with the wire system." )
    language.Add( "Tool_wire_gate_selection_0", "Primary: Create/Update Selection Chip" )
	
    language.Add( "Tool_wire_gate_time_name", "Time Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_time_desc", "Spawns a time chip for use with the wire system." )
    language.Add( "Tool_wire_gate_time_0", "Primary: Create/Update Time Chip" )
	
    language.Add( "Tool_wire_gate_trig_name", "Trig Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_trig_desc", "Spawns a trig gate for use with the wire system." )
    language.Add( "Tool_wire_gate_trig_0", "Primary: Create/Update Trig Gate" )
	
    language.Add( "Tool_wire_gates_name", "Gate Tool (Wire)" )
    language.Add( "Tool_wire_gates_desc", "Spawns a gate for use with the wire system." )
    language.Add( "Tool_wire_gates_0", "Primary: Create/Update Gate" )
	
    language.Add( "WireGatesTool_action", "Action:" )
    language.Add( "WireGatesTool_noclip", "NoClip:" )
    language.Add( "WireGatesTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gates", "You've hit your gates limit!" )
	language.Add( "undone_gmod_wire_gate", "Undone wire gate" )
	language.Add( "Cleanup_gmod_wire_gate", "Cleaned up wire gate" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gates', 30)
	CreateConVar('sbox_maxwire_gate_comparisons', 30)
	CreateConVar('sbox_maxwire_gate_duplexer', 16)
	CreateConVar('sbox_maxwire_gate_logics', 30)
	CreateConVar('sbox_maxwire_gate_memorys', 30)
	CreateConVar('sbox_maxwire_gate_selections', 30)
	CreateConVar('sbox_maxwire_gate_times', 30)
	CreateConVar('sbox_maxwire_gate_trigs', 30)
	ModelPlug_Register("gate")
end

cleanup.Register( "wire_gates" )

local base_tool = {
	Category		= "Wire - Control",
	Command			= nil,
	ConfigName		= "",
	WireClass		= "gmod_wire_gate",
	LeftClick		= WireToolHelpers.LeftClick,
	ToolMakeEnt		= WireToolMakeGate,
	UpdateGhost		= WireToolHelpers.UpdateGhost,
	Think			= WireToolHelpers.Think,
	ClientConVar	= {
		noclip = "0",
		model = "models/jaanus/wiretool/wiretool_gate.mdl"
	}
}

local function openTOOL()
	TOOL = ToolObj:Create()
	table.Merge( TOOL, base_tool )
end

local function buildTOOL( s_name, s_def )
	local s_mode		= "wire_gate_"..string.lower(s_name)
	TOOL.Mode			= s_mode
	TOOL.Name			= "Gate - "..s_name
	if (CLIENT) then
		TOOL.BuildCPanel = function(panel)
			panel:AddControl("Header", { Text = "#Tool_"..s_mode.."_name", Description = "#Tool_"..s_mode.."_desc" })
			panel:AddControl("CheckBox", {
				Label = "#WireGatesTool_noclip",
				Command = s_mode.."_noclip"
			})
			local Actions = {
				Label = "#WireGateTool_action",
				MenuButton = "0",
				Height = 180,
				Options = {}
			}
			for k,v in pairs(GateActions) do
			    if(v.group == s_name) then
			    	Actions.Options[v.name or "No Name"] = {}
			    	Actions.Options[v.name or "No Name"][s_mode.."_action"] = k
				end
			end
			panel:AddControl("ListBox", Actions)
			ModelPlug_AddToCPanel(panel, "gate", s_mode, "#WireGateTool_model", nil, "#WireGateTool_model")
		end
	end
	TOOL.ClientConVar[ "action" ] = s_def
	TOOL:CreateConVars()
	SWEP.Tool[ s_mode ] = TOOL
	TOOL = nil
end


table.Merge( TOOL, base_tool )
buildTOOL( "Arithmetic", "+" )


openTOOL()
buildTOOL( "Comparison", "<" )


openTOOL()
buildTOOL( "Table", "table_8merge" )


openTOOL()
buildTOOL( "Logic", "and" )


openTOOL()
buildTOOL( "Memory", "latch" )


openTOOL()
buildTOOL( "Selection", "sin" )


openTOOL()
buildTOOL( "Time", "timer" )


openTOOL()
buildTOOL( "Trig", "sin" )


openTOOL()
TOOL.Mode			= "wire_gates"
TOOL.Name			= "Gate"
TOOL.ClientConVar[ "action" ] = "+"

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gates_name", Description = "#Tool_wire_gates_desc" })

	ModelPlug_AddToCPanel(panel, "gate", "wire_gates", "#WireGatesTool_model", nil, "#WireGatesTool_model")

	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gates_noclip"
	})

	if (VERSION > 36) then
		local tree = vgui.Create( "DTree" )
		tree:SetTall( 400 )
		panel:AddPanel( tree )

		for gatetype, gatefuncs in pairs(WireGatesSorted) do
			local node = tree:AddNode( gatetype.." Gates" )
			table.SortByMember( gatefuncs, "name", true ) --doesn't work, fix
			for k,v in pairs(gatefuncs) do
				local cnode = node:AddNode( v.name or "No Name" )
				cnode.myname = v.name
				cnode.myaction = k
				function cnode:DoClick()
					RunConsoleCommand( "wire_gates_action "..self.myaction )
				end
				cnode.Icon:SetImage( "gui/silkicons/newspaper" )
			end
			node.ChildNodes:SortByMember( "myname", false )
		end
	else
		for gatetype, gatefuncs in pairs(WireGatesSorted) do

			local Actions = {
				Label = gatetype.." Gates",
				MenuButton = "0",
				Height = 100,
				Options = {}
			}

			for k,v in pairs(gatefuncs) do
				Actions.Options[v.name or "No Name"] = { wire_gates_action = k }
			end

			panel:AddControl("ListBox", Actions)
			
		end
	end
end


base_tool = nil
