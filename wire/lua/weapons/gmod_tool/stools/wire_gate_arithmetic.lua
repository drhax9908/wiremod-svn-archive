
TOOL.Category		= "Wire"
TOOL.Name			= "Gate - Arithmetic"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_arithmetic_name", "Arithmetic Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_arithmetic_desc", "Spawns an arithmetic gate for use with the wire system." )
    language.Add( "Tool_wire_gate_arithmetic_0", "Primary: Create/Update Arithmetic Gate" )
    language.Add( "WireGateArithmeticTool_action", "Action:" )
	language.Add( "sboxlimit_wire_gate_arithmetics", "You've hit arithmetic gates limit!" )
	language.Add( "undone_wiregatearithmetic", "Undone Wire Arithmetic Gate" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gates', 30)
end

TOOL.ClientConVar[ "action" ] = "+"

TOOL.Model = "models/jaanus/wiretool/wiretool_gate.mdl"

cleanup.Register( "wire_gate_arithmetics" )

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

	if ( !self:GetSWEP():CheckLimit( "wire_gates" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_arithmetic = MakeWireGate( ply, trace.HitPos, Ang, self.Model, action )
	
	local min = wire_gate_arithmetic:OBBMins()
	wire_gate_arithmetic:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_gate_arithmetic, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_gate_arithmetic )
		// Don't disable collision if it's not attached to anything
		wire_gate_arithmetic:GetPhysicsObject():EnableCollisions( false )
		wire_gate_arithmetic.nocollide = true
	end

	undo.Create("WireGateArithmetic")
		undo.AddEntity( wire_gate_arithmetic )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	

	ply:AddCleanup( "wire_gate_arithmetics", wire_gate_arithmetic )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGateArithmetic( ent, player )

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
	
	self:UpdateGhostWireGateArithmetic( self.GhostEntity, self:GetOwner() )
	
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_arithmetic_name", Description = "#Tool_wire_gate_arithmetic_desc" })

	local Actions = {
		Label = "#WireGateArithmeticTool_action",
		MenuButton = "0",
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Arithmetic") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_arithmetic_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)
end



GateActions = GateActions or {}

GateActions["identity"] = {
	group = "Arithmetic",
	name = "Identity (No change)",
	inputs = { "A" },
	output = function(gate, A)
	    return A
	end,
	label = function(Out, A)
	    return A.." = "..Out
	end
}

GateActions["negate"] = {
	group = "Arithmetic",
	name = "Negate",
	inputs = { "A" },
	output = function(gate, A)
	    return -A
	end,
	label = function(Out, A)
	    return "-"..A.." = "..Out
	end
}

GateActions["inverse"] = {
	group = "Arithmetic",
	name = "Inverse",
	inputs = { "A" },
	output = function(gate, A)
		if (A) and (math.abs(A) >= 0.0001) then return 1/A end
	    return 0
	end,
	label = function(Out, A)
	    return "1/"..A.." = "..Out
	end
}

GateActions["sqrt"] = {
	group = "Arithmetic",
	name = "Square Root",
	inputs = { "A" },
	output = function(gate, A)
	    return math.sqrt(math.abs(A)) // Negatives are possible, use absolute value
	end,
	label = function(Out, A)
		if ( A < 0 ) then
			return "sqrt("..A..") = i"..Out // Display as imaginary if A is negative
		else
			return "sqrt("..A..") = "..Out
		end
	end
}

GateActions["log"] = {
	group = "Arithmetic",
	name = "Log",
	inputs = { "A" },
	output = function(gate, A)
	    return math.log(A)
	end,
	label = function(Out, A)
	    return "log("..A..") = "..Out
	end
}

GateActions["log10"] = {
	group = "Arithmetic",
	name = "Log 10",
	inputs = { "A" },
	output = function(gate, A)
	    return math.log10(A)
	end,
	label = function(Out, A)
	    return "log10("..A..") = "..Out
	end
}

GateActions["abs"] = {
	group = "Arithmetic",
	name = "Absolute",
	inputs = { "A" },
	output = function(gate, A)
	    return math.abs(A)
	end,
	label = function(Out, A)
	    return "abs("..A..") = "..Out
	end
}

GateActions["sgn"] = {
	group = "Arithmetic",
	name = "Sign (-1,0,1)",
	inputs = { "A" },
	output = function(gate, A)
	    if (A > 0) then return 1 end
	    if (A < 0) then return -1 end
	    return 0
	end,
	label = function(Out, A)
	    return "sgn("..A..") = "..Out
	end
}

GateActions["floor"] = {
	group = "Arithmetic",
	name = "Floor (Round down)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.floor(A)
	end,
	label = function(Out, A)
	    return "floor("..A..") = "..Out
	end
}

GateActions["round"] = {
	group = "Arithmetic",
	name = "Round",
	inputs = { "A" },
	output = function(gate, A)
	    return math.Round(A)
	end,
	label = function(Out, A)
	    return "round("..A..") = "..Out
	end
}

GateActions["ceil"] = {
	group = "Arithmetic",
	name = "Ceiling (Round up)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.ceil(A)
	end,
	label = function(Out, A)
	    return "ceil("..A..") = "..Out
	end
}

GateActions["+"] = {
	group = "Arithmetic",
	name = "Add",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    local result = 0
	    for k,v in ipairs(arg) do
		    if (v) then result = result+v end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." + " end
		end
	    return string.sub(txt, 1, -4).." = "..Out
	end
}

GateActions["-"] = {
	group = "Arithmetic",
	name = "Subtract",
	inputs = { "A", "B" },
	colors = { Color(255, 0, 0, 255), Color(0, 0, 255, 255) },
	output = function(gate, A, B)
	    return A-B
	end,
	label = function(Out, A, B)
	    return A.." - "..B.." = "..Out
	end
}

GateActions["*"] = {
	group = "Arithmetic",
	name = "Multiply",
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	compact_inputs = 2,
	output = function(gate, ...)
	    local result = 1
	    for k,v in ipairs(arg) do
		    if (v) then result = result*v end
		end
	    return result
	end,
	label = function(Out, ...)
	    local txt = ""
	    for k,v in ipairs(arg) do
		    if (v) then txt = txt..v.." * " end
		end
	    return string.sub(txt, 1, -4).." = "..Out
	end
}

GateActions["/"] = {
	group = "Arithmetic",
	name = "Divide",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    if (math.abs(B) < 0.0001) then return 0 end
	    return A/B
	end,
	label = function(Out, A, B)
	    return A.." / "..B.." = "..Out
	end
}

GateActions["%"] = {
	group = "Arithmetic",
	name = "Modulus",
	inputs = { "A", "B" },
	output = function(gate, A, B)
		if ( B == 0 ) then return 0 end
		return math.fmod(A,B)
	end,
	label = function(Out, A, B)
		return A.." % "..B.." = "..Out
	end
}

GateActions["rand"] = {
	group = "Arithmetic",
	name = "Random",
	inputs = { "A", "B" },
	timed = true,
	output = function(gate, A, B)
	    return math.random()*(B-A)+A
	end,
	label = function(Out, A, B)
	    return "random("..A.." - "..B..") = "..Out
	end
}

GateActions["PI"] = {
	group = "Arithmetic",
	name = "PI",
	inputs = { },
	output = function(gate)
		return math.pi
	end,
	label = function(Out)
		return "PI = "..Out
	end
}

GateActions["exp"] = {
	group = "Arithmetic",
	name = "Exp",
	inputs = { "A" },
	output = function(gate, A)
	    return math.exp(A)
	end,
	label = function(Out, A)
	    return "exp("..A..") = "..Out
	end
}

GateActions["pow"] = {
    group = "Arithmetic",
    name = "Exponential Powers",
    inputs = { "A", "B" },
    output = function(gate, A, B)
        return math.pow(A, B)
    end,
    label = function(Out, A, B)
        return "pow("..A..", "..B..") = "..Out
    end
}
