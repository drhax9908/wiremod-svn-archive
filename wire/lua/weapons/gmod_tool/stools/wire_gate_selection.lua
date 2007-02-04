
TOOL.Category		= "Wire"
TOOL.Name			= "Chip - Selection"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_selection_name", "Selection Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_selection_desc", "Spawns a selection chip for use with the wire system." )
    language.Add( "Tool_wire_gate_selection_0", "Primary: Create/Update Selection Chip" )
    language.Add( "WireGateSelectionTool_action", "Action:" )
	language.Add( "sboxlimit_wire_gate_selections", "You've hit selections chip limit!" )
	language.Add( "undone_wiregateselection", "Undone Wire Selection Chip" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gate_selections', 30)
end

TOOL.ClientConVar[ "action" ] = "sin"

TOOL.Model = "models/jaanus/wiretool/wiretool_gate.mdl"

cleanup.Register( "wire_gate_selections" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	

	// Get client's CVars
	local action			= self:GetClientInfo( "action" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gate" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action] )
		trace.Entity:GetTable().action = action
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gate_selections" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_selection = MakeWireGate( ply, trace.HitPos, Ang, self.Model, action )
	
	local min = wire_gate_selection:OBBMins()
	wire_gate_selection:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_gate_selection, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_gate_selection )
		// Don't disable collision if it's not attached to anything
		wire_gate_selection:GetPhysicsObject():EnableCollisions( false )
		wire_gate_selection.nocollide = true
	end

	undo.Create("WireGateSelection")
		undo.AddEntity( wire_gate_selection )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	

	ply:AddCleanup( "wire_gate_selections", wire_gate_selection )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGateSelection( ent, player )

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

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireGateSelection( self.GhostEntity, self:GetOwner() )
	
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_selection_name", Description = "#Tool_wire_gate_selection_desc" })

	local Actions = {
		Label = "#WireGateSelectionTool_action",
		MenuButton = "0",
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Selection") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_selection_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)
end



GateActions = GateActions or {}

GateActions["min"] = {
	group = "Selection",
	name = "Minimum (Smallest)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    return math.min(unpack(arg))
	end,
	label = function(Out, ...)
	    local txt = "min("
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v..", " end
		end
	    return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["max"] = {
	group = "Selection",
	name = "Maximum (Largest)",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    return math.max(unpack(arg))
	end,
	label = function(Out, ...)
	    local txt = "max("
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v..", " end
		end
	    return string.sub(txt, 1, -3)..") = "..Out
	end
}

GateActions["minmax"] = {
    group = "Selection",
    name = "Value Range",
    inputs = { "Min", "Max", "Value" },
    output = function(gate, Min, Max, Value)
        local temp = Min
        if Min > Max then
          Min = Max
          Max = temp
        end
        if Value < Min then return Min end
        if Value > Max then return Max end
        return Value
    end,
    label = function(Out, Min, Max, Value)
        local temp = Min
        if Min > Max then
          Min = Max
          Max = temp
        end
        return "Min: "..Min.."  Max: "..Max.."  Value: "..Value.." = "..Out
    end
}

GateActions["if"] = {
	group = "Selection",
	name = "If Then Else",
	inputs = { "A", "B", "C" },
	output = function(gate, A, B, C)
	    if (A) and (A > 0) then return B end
	    return C
	end,
	label = function(Out, A, B, C)
	    return "if "..A.." then "..B.." else "..C.." = "..Out
	end
}

GateActions["select"] = {
	group = "Selection",
	name = "Select (Choice)",
	inputs = { "Choice", "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Choice, ...)
		local idx = math.floor(Choice)
	    if (idx > 0) and (idx <= 8) then
			return arg[idx]
		end
	    
		return 0
	end,
	label = function(Out, Choice)
	    return "Select Choice:"..Choice.." Out:"..Out
	end
}

GateActions["router"] = {
	group = "Selection",
	name = "Router",
	inputs = { "Path", "Data" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Path, Data)
	    local result = { 0, 0, 0, 0, 0, 0, 0, 0 }

		local idx = math.floor(Path)
	    if (idx > 0) and (idx <= 8) then
			result[idx] = Data
		end
	    
	    return unpack(result)
	end,
	label = function(Out, Path, Data)
	    return "Router Path:"..Path.." Data:"..Data
	end
}


local SegmentInfo = {
	None = { 0, 0, 0, 0, 0, 0, 0 },
	[0] = { 1, 1, 1, 1, 1, 1, 0 },
	[1] = { 0, 1, 1, 0, 0, 0, 0 },
	[2] = { 1, 1, 0, 1, 1, 0, 1 },
	[3] = { 1, 1, 1, 1, 0, 0, 1 },
	[4] = { 0, 1, 1, 0, 0, 1, 1 },
	[5] = { 1, 0, 1, 1, 0, 1, 1 },
	[6] = { 1, 0, 1, 1, 1, 1, 1 },
	[7] = { 1, 1, 1, 0, 0, 0, 0 },
	[8] = { 1, 1, 1, 1, 1, 1, 1 },
	[9] = { 1, 1, 1, 1, 0, 1, 1 },
}

GateActions["7seg"] = {
	group = "Selection",
	name = "7 Segment Decoder",
	inputs = { "A", "Clear" },
	outputs = { "A", "B", "C", "D", "E", "F", "G" },
	output = function(gate, A, Clear)
	    if (Clear > 0) then return unpack(SegmentInfo.None) end

		local idx = math.fmod(math.abs(math.floor(A)), 10)
	    return unpack(SegmentInfo[idx]) -- same as: return SegmentInfo[idx][1], SegmentInfo[idx][2], ...
	end,
	label = function(Out, A)
	    return "7-Seg In:" .. A .. " Out:" .. Out.A .. Out.B .. Out.C .. Out.D .. Out.E .. Out.F .. Out.G
	end
}
