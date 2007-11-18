
TOOL.Category		= "Wire - Tools"
TOOL.Name			= "Gate"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gates_name", "Arithmetic Gate Tool (Wire)" )
    language.Add( "Tool_wire_gates_desc", "Spawns an arithmetic gate for use with the wire system." )
    language.Add( "Tool_wire_gates_0", "Primary: Create/Update Arithmetic Gate" )
    language.Add( "WireGatesTool_action", "Action:" )
    language.Add( "WireGatesTool_noclip", "NoClip:" )
    language.Add( "WireGatesTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gates", "You've hit arithmetic gates limit!" )
	language.Add( "undone_wiregate", "Undone Wire Gate" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gates', 30)
end

TOOL.ClientConVar[ "action" ] = "+"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if (SERVER) then
	ModelPlug_Register("gate")
end

cleanup.Register( "wire_gates" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	// Get client's CVars
	local action	= self:GetClientInfo( "action" )
	local noclip	= self:GetClientNumber( "noclip" ) == 1
	local model		= self:GetClientInfo( "model" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gate" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action], noclip )
		trace.Entity:GetTable().action = action
		return true
	end

	if ( GateActions[action].group == "Arithmetic" and !self:GetSWEP():CheckLimit( "wire_gates" ) ) then return false end
	if ( GateActions[action].group == "Comparison" and !self:GetSWEP():CheckLimit( "wire_gate_comparisons" ) ) then return false end
	if ( GateActions[action].group == "Logic" and !self:GetSWEP():CheckLimit( "wire_gate_logics" ) ) then return false end
	if ( GateActions[action].group == "Memory" and !self:GetSWEP():CheckLimit( "wire_gate_memorys" ) ) then return false end
	if ( GateActions[action].group == "Selection" and !self:GetSWEP():CheckLimit( "wire_gate_selections" ) ) then return false end
	if ( GateActions[action].group == "Time" and !self:GetSWEP():CheckLimit( "wire_gate_times" ) ) then return false end
	if ( GateActions[action].group == "Trig" and !self:GetSWEP():CheckLimit( "wire_gate_trigs" ) ) then return false end
	if ( GateActions[action].group == "Table" and !self:GetSWEP():CheckLimit( "wire_gate_duplexer" ) ) then return false end
	
	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )
	
	local min = wire_gate:OBBMins()
	wire_gate:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_gate, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGate")
		undo.AddEntity( wire_gate )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_gates", wire_gate )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGates( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
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

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireGates( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gates_name", Description = "#Tool_wire_gates_desc" })
	
	ModelPlug_AddToCPanel(panel, "gate", "wire_gates", "#WireGatesTool_model", nil, "#WireGatesTool_model")
	
	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gates_noclip"
	})
	
	/*for gatetype, gatefuncs in pairs(WireGatesSorted) do
		
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
		
	end*/
	
	--this may not work in pre-gmod2007
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
			cnode.Icon:SetImage( "gui/silkicons/newspaper" ) --oops, missing file
		end
		node.ChildNodes:SortByMember( "myname", false )
	end
	
end

