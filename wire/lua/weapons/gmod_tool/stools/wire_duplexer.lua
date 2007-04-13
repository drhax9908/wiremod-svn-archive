//Based on SatriAli  Multiple datatype support tools
TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Duplexer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_duplexer_name", "Duplexer Chip Tool (Wire)" )
    language.Add( "Tool_wire_duplexer_desc", "Spawns a duplexer chip for use with the wire system." )
    language.Add( "Tool_wire_duplexer_0", "Primary: Create/Update Duplexer Chip" )
    language.Add( "WireDuplexerTool_action", "Action:" )
    language.Add( "WireDuplexerTool_model", "Model:" )
	language.Add( "sboxlimit_wire_duplexer", "You've hit duplexer chip limit!" )
	language.Add( "undone_wireduplexer", "Undone Wire Duplexer Chip" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_duplexer', 16)
end

TOOL.ClientConVar[ "action" ] = "4merge"
TOOL.ClientConVar[ "noclip" ] = "0"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if (SERVER) then
	ModelPlug_Register("gate")
end

cleanup.Register( "wire_duplexer" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	

	// Get client's CVars
	local action			= self:GetClientInfo( "action" )
	local model             = self:GetClientInfo( "model" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_duplexer" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action] )
		trace.Entity:GetTable().action = action
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_duplexer" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_duplexer = MakeWireDuplexer( ply, trace.HitPos, Ang, model, action )
	
	local min = wire_duplexer:OBBMins()
	wire_duplexer:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_duplexer, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireDuplexer")
		undo.AddEntity( wire_duplexer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	

	ply:AddCleanup( "wire_duplexer", wire_duplexer )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGateTable( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_duplexer" ) then
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
	
	self:UpdateGhostWireGateTable( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:ClearControls()
	
	panel:AddControl("Header", { Text = "#Tool_wire_duplexer_name", Description = "#Tool_wire_duplexer_desc" })
	
	panel:AddControl("CheckBox", {
		Label = "#WireGatesTool_noclip",
		Command = "wire_duplexer_noclip"
	})
	
	local Actions = {
		Label = "#WireDuplexerTool_action",
		MenuButton = "0",
		Height = 180,
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Table") then
	    	Actions.Options[v.name or "No Name"] = { wire_duplexer_action = k }
		end
	end
	
	panel:AddControl("ListBox", Actions)
	
	ModelPlug_AddToCPanel(panel, "chip", "wire_duplexer", "#WireDuplexerTool_model", nil, "#WireDuplexerTool_model")
end


GateActions["table_4merge"] = {
	group = "Table",
	name = "4x merger",
	timed = true,
	inputs = { "A", "B", "C", "D" },
	outputs = { "Tbl" },
	outputtypes = { "TABLE" },
	output = function(gate, A, B, C, D)
		if A then return { A, B, C, D }
		else return {}
		end
	end,
}

GateActions["table_4split"] = {
	group = "Table",
	name = "4x splitter",
	timed = true,
	inputs = { "Tbl" },
	inputtypes = { "TABLE" },
	outputs = { "A", "B", "C", "D" },
	output = function(gate, Tbl)
		if Tbl then return unpack( Tbl )
		else return 0,0,0,0
		end
	end,
}

GateActions["table_8merge"] = {
	group = "Table",
	name = "8x merger",
	timed = true,
	inputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	outputs = { "Tbl" },
	outputtypes = { "TABLE" },
	output = function(gate, A, B, C, D, E, F, G, H)
		if A then return { A, B, C, D, E, F, G, H }
		else return {}
		end
	end,
}

GateActions["table_8split"] = {
	group = "Table",
	name = "8x splitter",
	timed = true,
	inputs = { "Tbl" },
	inputtypes = { "TABLE" },
	outputs = { "A", "B", "C", "D", "E", "F", "G", "H" },
	output = function(gate, Tbl)
		if Tbl then return unpack( Tbl )
		else return 0,0,0,0,0,0,0,0
		end
	end,
}

GateActions["table_8duplexer"] = {
	group = "Table",
	name = "8x duplexer",
	timed = true,
	inputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	inputtypes = { "BIDIRTABLE" },
	outputs = { "Tbl", "A", "B", "C", "D", "E", "F", "G", "H" },
	outputtypes = { "BIDIRTABLE" },
	output = function(gate, Tbl, A, B, C, D, E, F, G, H)
		local t,v = {0,0,0,0,0,0,0,0}, {}
		if Tbl then t = Tbl end
		if A then v = { A, B, C, D, E, F, G, H } end
		return v, unpack( t )
	end,
}

GateActions["table_valuebyidx"] = {
	group = "Table",
	name = "Value retriever",
	timed = true,
	inputs = { "Tbl", "Index" },
	inputtypes = { "TABLE" },
	outputs = { "Data" },
	output = function(gate, Tbl, idx)
		if Tbl && idx && Tbl[idx] then return Tbl[idx]
		else return 0
		end
	end,
}
