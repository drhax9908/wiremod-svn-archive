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
	ModelPlug_Register("gate")
end

TOOL.ClientConVar[ "action" ] = "sin"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

cleanup.Register( "wire_gate_trigs" )

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

	if ( !self:GetSWEP():CheckLimit( "wire_gate_trigs" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_trig = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )
	
	local min = wire_gate_trig:OBBMins()
	wire_gate_trig:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld(wire_gate_trig, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireGateTrig")
		undo.AddEntity( wire_gate_trig )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_gate_trigs", wire_gate_trig )
	
	return true
	
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

	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gate_trig_noclip"
	})
	
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

