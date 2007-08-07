
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Arithmetic"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_arithmetic_name", "Arithmetic Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_arithmetic_desc", "Spawns an arithmetic gate for use with the wire system." )
    language.Add( "Tool_wire_gate_arithmetic_0", "Primary: Create/Update Arithmetic Gate" )
    language.Add( "WireGateArithmeticTool_action", "Action:" )
    language.Add( "WireGateArithmeticTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gate_arithmetics", "You've hit arithmetic gates limit!" )
	language.Add( "undone_wiregatearithmetic", "Undone Wire Arithmetic Gate" )
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

cleanup.Register( "wire_gate_arithmetics" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	// Get client's CVars
	local action			= self:GetClientInfo( "action" )
	local noclip			= self:GetClientNumber( "noclip" ) == 1
	local model             = self:GetClientInfo( "model" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gate" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action], noclip )
		trace.Entity:GetTable().action = action
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gates" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_arithmetic = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )
	
	local min = wire_gate_arithmetic:OBBMins()
	wire_gate_arithmetic:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_gate_arithmetic, trace.Entity, trace.PhysicsBone, true)

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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireGateArithmetic( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_arithmetic_name", Description = "#Tool_wire_gate_arithmetic_desc" })

	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gate_arithmetic_noclip"
	})
	
	local Actions = {
		Label = "#WireGateArithmeticTool_action",
		MenuButton = "0",
		Height = 180,
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Arithmetic") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_arithmetic_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)
	
	ModelPlug_AddToCPanel(panel, "gate", "wire_gate_arithmetic", "#WireGateArithmeticTool_model", nil, "#WireGateArithmeticTool_model")
end

