--[[
	This is stool code, 
		These are used by the Wired tools' LeftClick to make/update ents,
		the part after trace check and before welding/undo/cleanup creation.
]]--


function WireToolMakeGate( self, trace, ply )
	local action	= self:GetClientInfo( "action" )
	local noclip	= self:GetClientNumber( "noclip" ) == 1
	local model		= self:GetClientInfo( "model" )

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
	
	return wire_gate
end


include( "sv_detection.lua" )
include( "sv_display.lua" )
include( "sv_io.lua" )
include( "sv_physics.lua" )
