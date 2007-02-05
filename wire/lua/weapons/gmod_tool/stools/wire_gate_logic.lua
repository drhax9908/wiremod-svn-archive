
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Logic"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_logic_name", "Logic Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_logic_desc", "Spawns a logic gate for use with the wire system." )
    language.Add( "Tool_wire_gate_logic_0", "Primary: Create/Update Logic Gate" )
    language.Add( "WireGateLogicTool_action", "Action:" )
    language.Add( "WireGateLogicTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gate_logics", "You've hit logic gates limit!" )
	language.Add( "undone_wiregatelogic", "Undone Wire Logic Gate" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gate_logics', 30)
end

TOOL.ClientConVar[ "action" ] = "and"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if (SERVER) then
	ModelPlug_Register("gate")
end

cleanup.Register( "wire_gate_logics" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	

	// Get client's CVars
	local action			= self:GetClientInfo( "action" )
	local model             = self:GetClientInfo( "model" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gate" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action] )
		trace.Entity:GetTable().action = action
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gate_logics" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_logic = MakeWireGate( ply, trace.HitPos, Ang, model, action )
	
	local min = wire_gate_logic:OBBMins()
	wire_gate_logic:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_gate_logic, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_gate_logic )
		// Don't disable collision if it's not attached to anything
		wire_gate_logic:GetPhysicsObject():EnableCollisions( false )
		wire_gate_logic.nocollide = true
	end

	undo.Create("WireGateLogic")
		undo.AddEntity( wire_gate_logic )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	

	ply:AddCleanup( "wire_gate_logics", wire_gate_logic )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGateLogic( ent, player )

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
	
	self:UpdateGhostWireGateLogic( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_logic_name", Description = "#Tool_wire_gate_logic_desc" })

	local Actions = {
		Label = "#WireGateLogicTool_action",
		MenuButton = "0",
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Logic") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_logic_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)

	ModelPlug_AddToCPanel(panel, "gate", "wire_gate_logic", "#WireGateLogicTool_model", nil, "#WireGateLogicTool_model")
end



GateActions = GateActions or {}

GateActions["not"] = {
	group = "Logic",
	name = "Not (Invert)",
	inputs = { "A" },
	output = function(gate, A)
	    if (A > 0) then return 0 end
	    return 1
	end,
	label = function(Out, A)
	    return "not "..A.." = "..Out
	end
}

GateActions["and"] = {
	group = "Logic",
	name = "And (All)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v <= 0) then return 0 end
		end
	    return 1
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." and " end
		end
	    return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["or"] = {
	group = "Logic",
	name = "Or (Any)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then return 1 end
		end
	    return 0
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." or " end
		end
	    return string.sub(txt, 1, -5).." = "..Out
	end
}

GateActions["xor"] = {
	group = "Logic",
	name = "Exclusive Or (Odd)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 0
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then result = (1-result) end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." xor " end
		end
	    return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["nand"] = {
	group = "Logic",
	name = "Not And (Not All)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v <= 0) then return 1 end
		end
	    return 0
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." nand " end
		end
	    return string.sub(txt, 1, -7).." = "..Out
	end
}

GateActions["nor"] = {
	group = "Logic",
	name = "Not Or (None)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then return 0 end
		end
	    return 1
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." nor " end
		end
	    return string.sub(txt, 1, -6).." = "..Out
	end
}

GateActions["xnor"] = {
	group = "Logic",
	name = "Exclusive Not Or (Even)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
		local result = 1
	    for k,v in ipairs(arg) do
		    if (v) and (v > 0) then result = (1-result) end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." xnor " end
		end
	    return string.sub(txt, 1, -7).." = "..Out
	end
}
