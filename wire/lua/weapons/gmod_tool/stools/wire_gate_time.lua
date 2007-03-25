
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Time"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_time_name", "Time Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_time_desc", "Spawns a time chip for use with the wire system." )
    language.Add( "Tool_wire_gate_time_0", "Primary: Create/Update Time Chip" )
    language.Add( "WireGateTimeTool_action", "Action:" )
    language.Add( "WireGateTimeTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gate_times", "You've hit time chips limit!" )
	language.Add( "undone_wiregatetime", "Undone Wire Time Chip" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gate_times', 30)
end

TOOL.ClientConVar[ "action" ] = "timer"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if (SERVER) then
	ModelPlug_Register("gate")
end

cleanup.Register( "wire_gate_times" )

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

	if ( !self:GetSWEP():CheckLimit( "wire_gate_times" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_time = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )
	
	local min = wire_gate_time:OBBMins()
	wire_gate_time:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_gate_time, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_gate_time:GetPhysicsObject():EnableCollisions( false )
		wire_gate_time.nocollide = true
	end

	undo.Create("WireGateTime")
		undo.AddEntity( wire_gate_time )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	

	ply:AddCleanup( "wire_gate_times", wire_gate_time )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGateTime( ent, player )

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
	
	self:UpdateGhostWireGateTime( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_time_name", Description = "#Tool_wire_gate_time_desc" })

	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_gate_time_noclip"
	})
	
	local Actions = {
		Label = "#WireGateTimeTool_action",
		MenuButton = "0",
		Height = 180,
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Time") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_time_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)

	ModelPlug_AddToCPanel(panel, "chip", "wire_gate_time", "#WireGateTimeTool_model", nil, "#WireGateTimeTool_model")
end

