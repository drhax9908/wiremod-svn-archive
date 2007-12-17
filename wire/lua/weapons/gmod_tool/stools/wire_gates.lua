
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
	language.Add( "undone_wiregate", "Undone wire gate" )
	language.Add( "Cleanup_wire_gate", "Cleaned up wire gate" )
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

local function f_GateLeftClick( self, trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local action			= self:GetClientInfo( "action" )
	local noclip			= self:GetClientNumber( "noclip" ) == 1
	local model             = self:GetClientInfo( "model" )

	if ( GateActions[action] == nil ) then return false end

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gate" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action], noclip )
		trace.Entity:GetTable().action = action
		return true
	end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	if ( GateActions[action].group == "Arithmetic" and !self:GetSWEP():CheckLimit( "wire_gates" ) ) then return false end
	if ( GateActions[action].group == "Comparison" and !self:GetSWEP():CheckLimit( "wire_gate_comparisons" ) ) then return false end
	if ( GateActions[action].group == "Logic" and !self:GetSWEP():CheckLimit( "wire_gate_logics" ) ) then return false end
	if ( GateActions[action].group == "Memory" and !self:GetSWEP():CheckLimit( "wire_gate_memorys" ) ) then return false end
	if ( GateActions[action].group == "Selection" and !self:GetSWEP():CheckLimit( "wire_gate_selections" ) ) then return false end
	if ( GateActions[action].group == "Time" and !self:GetSWEP():CheckLimit( "wire_gate_times" ) ) then return false end
	if ( GateActions[action].group == "Trig" and !self:GetSWEP():CheckLimit( "wire_gate_trigs" ) ) then return false end
	if ( GateActions[action].group == "Table" and !self:GetSWEP():CheckLimit( "wire_gate_duplexer" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )

	local min = wire_gate:OBBMins()
	wire_gate:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld( wire_gate, trace.Entity, trace.PhysicsBone, true )

	undo.Create("WireGate")
		undo.AddEntity( wire_gate )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_gates", wire_gate )

	return true
end

local function f_GateUpdateGhost( self, ent )

	if ( !ent or !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( self:GetOwner(), self:GetOwner():GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_gate" ) then
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

local function fGateThink( self )
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhost( self.GhostEntity )
end

local function f_GateBuildCPanel( mode, action )
	return function(panel)
		panel:AddControl("Header", { Text = "#Tool_"..mode.."_name", Description = "#Tool_"..mode.."_desc" })
		
		panel:AddControl("CheckBox", {
			Label = "#WireGatesTool_noclip",
			Command = mode.."_noclip"
		})
		
		local Actions = {
			Label = "#WireGateTool_action",
			MenuButton = "0",
			Height = 180,
			Options = {}
		}
		
		for k,v in pairs(GateActions) do
		    if(v.group == action) then
		    	Actions.Options[v.name or "No Name"] = {}
		    	Actions.Options[v.name or "No Name"][mode.."_action"] = k
			end
		end
		
		panel:AddControl("ListBox", Actions)
		
		ModelPlug_AddToCPanel(panel, "gate", mode, "#WireGateTool_model", nil, "#WireGateTool_model")
	end
end

/*****************************
	arithmetic gates stool
*****************************/
TOOL.Mode			= "wire_gate_arithmetic"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Arithmetic"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Arithmetic" )

TOOL.ClientConVar[ "action" ] = "+"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	comparison gates stool
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gate_comparison"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Comparison"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Comparison" )

TOOL.ClientConVar[ "action" ] = "<"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	duplexer gates stool
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gate_duplexer"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Duplexer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Table" )

TOOL.ClientConVar[ "action" ] = "4merge"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	logic gates stool
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gate_logic"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Logic"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Logic" )

TOOL.ClientConVar[ "action" ] = "and"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	memory gates stool
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gate_memory"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Memory"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Memory" )

TOOL.ClientConVar[ "action" ] = "latch"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	selection gates stools
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gate_selection"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Selection"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Selection" )

TOOL.ClientConVar[ "action" ] = "sin"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	time gates stool
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gate_time"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Time"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Time" )

TOOL.ClientConVar[ "action" ] = "timer"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	trig gates stool
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gate_trig"
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Trig"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink
TOOL.BuildCPanel	= f_GateBuildCPanel( TOOL.Mode, "Trig" )

TOOL.ClientConVar[ "action" ] = "sin"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

TOOL:CreateConVars()
SWEP.Tool[ TOOL.Mode ] = TOOL
TOOL = nil


/*****************************
	all gates stool
*****************************/
TOOL				= ToolObj:Create()
TOOL.Mode			= "wire_gates"
TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Gate"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.LeftClick		= f_GateLeftClick
TOOL.UpdateGhost	= f_GateUpdateGhost
TOOL.Think			= fGateThink

TOOL.ClientConVar[ "action" ] = "+"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gates_name", Description = "#Tool_wire_gates_desc" })
	
	ModelPlug_AddToCPanel(panel, "gate", "wire_gates", "#WireGatesTool_model", nil, "#WireGatesTool_model")
	
	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gates_noclip"
	})
	
	if (VERSION > 36) then
		local tree = vgui.Create( "DTree" ) --this may not work in pre-gmod2007
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
				cnode.Icon:SetImage( "gui/silkicons/newspaper" ) --oops, missing file
			end
			node.ChildNodes:SortByMember( "myname", false )
		end
	else
		for gatetype, gatefuncs in pairs(WireGatesSorted) do
			
			local Actions = {
				Label = gatetype.." Gates", //#WireGateArithmeticTool_action",
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


