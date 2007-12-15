TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Selection"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_selection_name", "Selection Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_selection_desc", "Spawns a selection chip for use with the wire system." )
    language.Add( "Tool_wire_gate_selection_0", "Primary: Create/Update Selection Chip" )
    language.Add( "WireGateSelectionTool_action", "Action:" )
    language.Add( "WireGateSelectionTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gate_selections", "You've hit selections chip limit!" )
	language.Add( "undone_wiregateselection", "Undone Wire Selection Chip" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gate_selections', 30)
	ModelPlug_Register("gate")
end

TOOL.ClientConVar[ "action" ] = "sin"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

cleanup.Register( "wire_gate_selections" )

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

	if ( !self:GetSWEP():CheckLimit( "wire_gate_selections" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_selection = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )
	
	local min = wire_gate_selection:OBBMins()
	wire_gate_selection:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_gate_selection, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGateSelection")
		undo.AddEntity( wire_gate_selection )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_gate_selections", wire_gate_selection )
	
	return true
	
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireGateSelection( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_selection_name", Description = "#Tool_wire_gate_selection_desc" })

	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gate_selection_noclip"
	})
	
	local Actions = {
		Label = "#WireGateSelectionTool_action",
		MenuButton = "0",
		Height = 180,
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Selection") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_selection_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)

	ModelPlug_AddToCPanel(panel, "chip", "wire_gate_selection", "#WireGateSelectionTool_model", nil, "#WireGateSelectionTool_model")
end

