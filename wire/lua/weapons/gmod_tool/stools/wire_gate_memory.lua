TOOL.Category		= "Wire - Control"
TOOL.Name			= "Chip - Memory"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_gate_memory_name", "Memory Chip Tool (Wire)" )
    language.Add( "Tool_wire_gate_memory_desc", "Spawns a memory chip for use with the wire system." )
    language.Add( "Tool_wire_gate_memory_0", "Primary: Create/Update Memory Chip" )
    language.Add( "WireGateMemoryTool_action", "Action:" )
    language.Add( "WireGateMemoryTool_model", "Model:" )
	language.Add( "sboxlimit_wire_gate_memorys", "You've hit memory chips limit!" )
	language.Add( "undone_wiregatememory", "Undone Wire Memory Chip" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_gate_memorys', 30)
end

TOOL.ClientConVar[ "action" ] = "latch"
TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"

if (SERVER) then
	ModelPlug_Register("gate")
end

cleanup.Register( "wire_gate_memorys" )

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

	if ( !self:GetSWEP():CheckLimit( "wire_gate_memorys" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate_memory = MakeWireGate( ply, trace.HitPos, Ang, model, action )
	
	local min = wire_gate_memory:OBBMins()
	wire_gate_memory:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_gate_memory, trace.Entity, 0, trace.PhysicsBone, 0, true )
		trace.Entity:DeleteOnRemove( wire_gate_memory )
		// Don't disable collision if it's not attached to anything
		wire_gate_memory:GetPhysicsObject():EnableCollisions( false )
		wire_gate_memory.nocollide = true
	end

	undo.Create("WireGateMemory")
		undo.AddEntity( wire_gate_memory )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	

	ply:AddCleanup( "wire_gate_memorys", wire_gate_memory )
	
	return true
	
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

function TOOL:UpdateGhostWireGateMemory( ent, player )

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
	
	self:UpdateGhostWireGateMemory( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_gate_memory_name", Description = "#Tool_wire_gate_memory_desc" })

	local Actions = {
		Label = "#WireGateMemoryTool_action",
		MenuButton = "0",
		Options = {}
	}
	
	for k,v in pairs(GateActions) do
	    if(v.group == "Memory") then
	    	Actions.Options[v.name or "No Name"] = { wire_gate_memory_action = k }
		end
	end

	panel:AddControl("ListBox", Actions)

	ModelPlug_AddToCPanel(panel, "chip", "wire_gate_memory", "#WireGateMemoryTool_model", nil, "#WireGateMemoryTool_model")
end



GateActions = GateActions or {}

GateActions["latch"] = {
	group = "Memory",
	name = "Latch (Edge triggered)",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
		local clk = (Clk > 0)
		if (gate.PrevValue ~= clk) then
			gate.PrevValue = clk
		    if (clk) then
		        gate.LatchStore = Data
		    end
		end
	    return gate.LatchStore or 0
	end,
	reset = function(gate)
	    gate.LatchStore = 0
	    gate.PrevValue = nil
	end,
	label = function(Out, Data, Clk)
	    return "Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["dlatch"] = {
	group = "Memory",
	name = "D-Latch",
	inputs = { "Data", "Clk" },
	output = function(gate, Data, Clk)
	    if (Clk > 0) then
			gate.LatchStore = Data
		end
	    return gate.LatchStore or 0
	end,
	reset = function(gate)
	    gate.LatchStore = 0
	end,
	label = function(Out, Data, Clk)
	    return "D-Latch Data:"..Data.."  Clock:"..Clk.." = "..Out
	end
}

GateActions["srlatch"] = {
    group = "Memory",
    name = "SR-Latch",
    inputs = { "S", "R" },
    output = function(gate, S, R)
        if (S > 0) and (R <= 0) then
            gate.LatchStore = 1
        elseif (S <= 0) and (R > 0) then
            gate.LatchStore = 0
        end
        return gate.LatchStore
    end,
    reset = function(gate)
        gate.LatchStore = 0
    end,
    label = function(Out, S, R)
        return "S:"..S.." R:"..R.." == "..Out
    end
}

GateActions["toggle"] = {
    group = "Memory",
    name = "Toggle (Edge triggered)",
    inputs = { "Clk", "OnValue", "OffValue" },
    output = function(gate, Clk, OnValue, OffValue)
        local clk = (Clk > 0)
        if (gate.PrevValue ~= clk) then
            gate.PrevValue = clk
            if (clk) then
                gate.LatchStore = (not gate.LatchStore)
            end
        end
        
        if (gate.LatchStore) then return OnValue end
        return OffValue
    end,
    reset = function(gate)
        gate.LatchStore = 0
        gate.PrevValue = nil
    end,
    label = function(Out, Clk, OnValue, OffValue)
        return "Off:"..OffValue.."  On:"..OnValue.."  Clock:"..Clk.." = "..Out
    end
}

GateActions["ram8"] = {
    group = "Memory",
    name = "RAM(8 store)",
    inputs = { "Clk", "AddrRead", "AddrWrite", "Data" },
    output = function(gate, Clk, AddrRead, AddrWrite, Data )
        AddrRead = math.floor(AddrRead)
        AddrWrite = math.floor(AddrWrite)
        if (Clk > 0) then
            if (AddrWrite >= 0) and (AddrWrite < 8) then
                gate.LatchStore[AddrWrite] = Data
            end
        end
        
		if (AddrRead < 0) or (AddrRead >= 8) then return 0 end
		
        return gate.LatchStore[AddrRead] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0, 7 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrRead, AddrWrite, Data)
	    return "WriteAddr:"..math.floor(AddrWrite).."  Data:"..Data.."  Clock:"..Clk..
    	    "\nReadAddr:"..math.floor(AddrRead).." = "..Out
    end
}


GateActions["ram64"] = {
    group = "Memory",
    name = "RAM(64 store)",
    inputs = { "Clk", "AddrRead", "AddrWrite", "Data" },
    output = function(gate, Clk, AddrRead, AddrWrite, Data )
        AddrRead = math.floor(AddrRead)
        AddrWrite = math.floor(AddrWrite)
        if (Clk > 0) then
            if (AddrWrite < 64) then
                    gate.LatchStore[AddrWrite] = Data
            end
        end
        return gate.LatchStore[AddrRead] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0,63 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrRead, AddrWrite, Data)
        return "WriteAddr:"..math.floor(AddrWrite).."  Data:"..Data.."  Clock:"..Clk..
        	"\nReadAddr:"..math.floor(AddrRead).." = "..Out
    end
}


GateActions["ram64x64"] = {
    group = "Memory",
    name = "RAM(64x64 store)",
    inputs = { "Clk", "AddrReadX", "AddrReadY", "AddrWriteX", "AddrWriteY", "Data" },
    output = function(gate, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data )
        AddrReadX = math.floor(AddrReadX)
        AddrReadY = math.floor(AddrReadY)
        AddrWriteX = math.floor(AddrWriteX)
        AddrWriteY = math.floor(AddrWriteY)
        if (Clk > 0) then
            if (AddrWriteX >= 0) and (AddrWriteX < 64) or (AddrWriteY >= 0) and (AddrWriteY < 64) then
				gate.LatchStore[AddrWriteX + AddrWriteY*64] = Data
            end
        end
        
        if (AddrReadX < 0) or (AddrReadX >= 64) or (AddrReadY < 0) or (AddrReadY >= 64) then
            return 0
        end
        
        return gate.LatchStore[AddrReadX + AddrReadY*64] or 0
    end,
    reset = function(gate)
        gate.LatchStore = {}
        for i = 0,4095 do
            gate.LatchStore[i] = 0
        end
    end,
    label = function(Out, Clk, AddrReadX, AddrReadY, AddrWriteX, AddrWriteY, Data)
        return "WriteAddr:"..math.floor(AddrWriteX)..", "..math.floor(AddrWriteY).."  Data:"..Data.."  Clock:"..Clk..
        "\nReadAddr:"..math.floor(AddrReadX)..", "..math.floor(AddrReadY).." = "..Out
    end
}
