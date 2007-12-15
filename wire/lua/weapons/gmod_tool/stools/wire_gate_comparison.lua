TOOL.Category		= "Wire - Control"
TOOL.Name			= "Gate - Comparison"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_comparison_name", "Comparison Gate Tool (Wire)" )
    language.Add( "Tool_wire_gate_comparison_desc", "Spawns a comparison gate for use with the wire system." )
    language.Add( "Tool_wire_gate_comparison_0", "Primary: Create/Update Comparison Gate" )
    language.Add( "WireGateComparisonTool_action", "Action:" )
    language.Add( "WireGateComparisonTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gate_comparisons", "You've hit comparison gates limit!" )
	language.Add( "undone_wiregatecomparison", "Undone Wire Comparison Gate" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gate_comparisons', 30)
	ModelPlug_Register("gate")
end

TOOL.ClientConVar[ "action" ] = "<"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

cleanup.Register( "wire_gate_comparisons" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	local action			= self:GetClientInfo( "action" )
	local noclip			= self:GetClientNumber( "noclip" ) == 1
	local model             = self:GetClientInfo( "model" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gate" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action], noclip )
		trace.Entity:GetTable().action = action
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_gate_comparisons" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_comparison = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )
	
	local min = wire_gate_comparison:OBBMins()
	wire_gate_comparison:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_gate_comparison, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGateComparison")
		undo.AddEntity( wire_gate_comparison )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_gate_comparisons", wire_gate_comparison )
	
	return true
	
end

function TOOL:UpdateGhostWireGateComparison( ent, player )

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
	
	self:UpdateGhostWireGateComparison( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_comparison_name", Description = "#Tool_wire_gate_comparison_desc" })

	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gate_comparison_noclip"
	})
	
	local Actions = {
		Label = "#WireGateComparisonTool_action",
		MenuButton = "0",
		Height = 180,
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Comparison") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_comparison_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)

	ModelPlug_AddToCPanel(panel, "gate", "wire_gate_comparison", "#WireGateComparisonTool_model", nil, "#WireGateComparisonTool_model")
end

