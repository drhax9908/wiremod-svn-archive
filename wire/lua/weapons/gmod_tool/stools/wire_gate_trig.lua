
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Trig"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_trig_name", "Trig Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_trig_desc", "Spawns a trig gate for use with the wire system." )
    language.Add( "Tool_wire_gate_trig_0", "Primary: Create/Update Trig Gate" )
    language.Add( "WireGateTrigTool_action", "Action:" )
    language.Add( "WireGateTrigTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gate_trigs", "You've hit trigs gate limit!" )
	language.Add( "undone_wiregatetrig", "Undone Wire Trig Gate" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gate_trigs', 30)
end

TOOL.ClientConVar[ "action" ] = "sin"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if (SERVER) then
	ModelPlug_Register("gate")
end

cleanup.Register( "wire_gate_trigs" )

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

	if ( !self:GetSWEP():CheckLimit( "wire_gate_trigs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_trig = MakeWireGate( ply, trace.HitPos, Ang, model, action )
	
	local min = wire_gate_trig:OBBMins()
	wire_gate_trig:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_gate_trig, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_gate_trig )
		// Don't disable collision if it's not attached to anything
		wire_gate_trig:GetPhysicsObject():EnableCollisions( false )
		wire_gate_trig.nocollide = true
	end

	undo.Create("WireGateTrig")
		undo.AddEntity( wire_gate_trig )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	

	ply:AddCleanup( "wire_gate_trigs", wire_gate_trig )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGateTrig( ent, player )

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
	
	self:UpdateGhostWireGateTrig( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_trig_name", Description = "#Tool_wire_gate_trig_desc" })

	local Actions = {
		Label = "#WireGateTrigTool_action",
		MenuButton = "0",
		Height = 180,
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Trig") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_trig_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)

	ModelPlug_AddToCPanel(panel, "gate", "wire_gate_trig", "#WireGateTrigTool_model", nil, "#WireGateTrigTool_model")
end



GateActions = GateActions or {}

GateActions["sin"] = {
	group = "Trig",
	name = "Sin(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.sin(A)
	end,
	label = function(Out, A)
	    return "sin("..A.."rad) = "..Out
	end
}

GateActions["cos"] = {
	group = "Trig",
	name = "Cos(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.cos(A)
	end,
	label = function(Out, A)
	    return "cos("..A.."rad) = "..Out
	end
}

GateActions["tan"] = {
	group = "Trig",
	name = "Tan(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.tan(A)
	end,
	label = function(Out, A)
	    return "tan("..A.."rad) = "..Out
	end
}

GateActions["asin"] = {
	group = "Trig",
	name = "Asin(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.asin(A)
	end,
	label = function(Out, A)
	    return "asin("..A..") = "..Out.."rad"
	end
}

GateActions["acos"] = {
	group = "Trig",
	name = "Acos(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.acos(A)
	end,
	label = function(Out, A)
	    return "acos("..A..") = "..Out.."rad"
	end
}

GateActions["atan"] = {
	group = "Trig",
	name = "Atan(Rad)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.atan(A)
	end,
	label = function(Out, A)
	    return "atan("..A..") = "..Out.."rad"
	end
}

GateActions["sin_d"] = {
	group = "Trig",
	name = "Sin(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.sin(A)
	end,
	label = function(Out, A)
	    return "sin("..A.."deg) = "..Out
	end
}

GateActions["cos_d"] = {
	group = "Trig",
	name = "Cos(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.cos(A)
	end,
	label = function(Out, A)
	    return "cos("..A.."deg) = "..Out
	end
}

GateActions["tan_d"] = {
	group = "Trig",
	name = "Tan(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.tan(A)
	end,
	label = function(Out, A)
	    return "tan("..A.."deg) = "..Out
	end
}

GateActions["asin_d"] = {
	group = "Trig",
	name = "Asin(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.asin(A)
	end,
	label = function(Out, A)
	    return "asin("..A..") = "..Out.."deg"
	end
}

GateActions["acos_d"] = {
	group = "Trig",
	name = "Acos(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.acos(A)
	end,
	label = function(Out, A)
	    return "acos("..A..") = "..Out.."deg"
	end
}

GateActions["atan_d"] = {
	group = "Trig",
	name = "Atan(Deg)",
	inputs = { "A" },
	output = function(gate, A)
	    return math.atan(A)
	end,
	label = function(Out, A)
	    return "atan("..A..") = "..Out.."deg"
	end
}

GateActions["rad2deg"] = {
	group = "Trig",
	name = "Radians to Degrees",
	inputs = { "A" },
	output = function(gate, A)
	    return math.deg(A)
	end,
	label = function(Out, A)
	    return A.."rad = "..Out.."deg"
	end
}

GateActions["deg2rad"] = {
	group = "Trig",
	name = "Degrees to Radians",
	inputs = { "A" },
	output = function(gate, A)
	    return math.rad(A)
	end,
	label = function(Out, A)
	    return A.."deg = "..Out.."rad"
	end
}

GateActions["angdiff"] = {
	group = "Trig",
	name = "Difference(rad)",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    return math.rad(math.AngleDifference(math.deg(A), math.deg(B)))
	end,
	label = function(Out, A, B)
	    return A .. "deg - " .. B .. "deg = " .. Out .. "deg"
	end
}

GateActions["angdiff_d"] = {
	group = "Trig",
	name = "Difference(deg)",
	inputs = { "A", "B" },
	output = function(gate, A, B)
	    return math.AngleDifference(A, B)
	end,
	label = function(Out, A, B)
	    return A .. "deg - " .. B .. "deg = " .. Out .. "deg"
	end
}
