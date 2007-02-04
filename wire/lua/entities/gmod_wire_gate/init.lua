
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Gate"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end


function ENT:Setup( action )
	if (action) then
	    self.WireDebugName = action.name
	    
		Wire_AdjustInputs(self.Entity, action.inputs)
		if (action.outputs) then
		    Wire_AdjustOutputs(self.Entity, action.outputs)
		else
		    Wire_AdjustOutputs(self.Entity, { "Out" })
		end
		
		if (action.reset) then
		    action.reset(self)
		end
	end

	self.Action = action
	self.PrevValue = nil

    self:CalcOutput()
	self:ShowOutput()
end


function ENT:TriggerInput(iname, value, iter)
	if (self.Action) and (not self.Action.timed) then
		self:CalcOutput(iter)
		self:ShowOutput()
	end
end


function ENT:Think()
	self.BaseClass.Think(self)

	if (self.Action) and (self.Action.timed) then
		self:CalcOutput()
		self:ShowOutput()
		
		self.Entity:NextThink(CurTime()+0.02)
		return true
	end
end


function ENT:CalcOutput(iter)
	if (self.Action) and (self.Action.output) then
	    if (self.Action.outputs) then
			local result = { self.Action.output(self, unpack(self:GetActionInputs())) }
			
		    for k,v in ipairs(self.Action.outputs) do
			    Wire_TriggerOutput(self.Entity, v, result[k], iter)
		    end
	    else
	    	local value = self.Action.output(self, unpack(self:GetActionInputs())) or 0
	    	
		    Wire_TriggerOutput(self.Entity, "Out", value, iter)
		end
	end
end


function ENT:ShowOutput()
	local txt = ""

	if (self.Action) then
		txt = (self.Action.name or "No Name")
		if (self.Action.label) then
			txt = txt.."\n"..self.Action.label(self:GetActionOutputs(), unpack(self:GetActionInputs(true)))
		end
	else
	    txt = "Invalid gate!"
	end
	
	self:SetOverlayText(txt)

	return value
end


function ENT:OnRestore()
    self.Action = GateActions[self.action]
    
    self.BaseClass.OnRestore(self)
end


function ENT:GetActionInputs(round)
	local Args = {}

	if (self.Action.compact_inputs) then
	    for k,v in ipairs(self.Action.inputs) do
	        local input = self.Inputs[v]
			if (not input) then
			    Msg("Missing input! ("..v..")")
			    return {}
			end
			if (input.Src) then
				if (round) then
					table.insert(Args, math.Round(input.Value*1000)/1000)
				else
					table.insert(Args, input.Value)
				end
			end
		end
		while (table.getn(Args) < self.Action.compact_inputs) do
		    table.insert(Args, 0)
		end
	else
	    for k,v in ipairs(self.Action.inputs) do
	        local input = self.Inputs[v]
			if (not input) then
			    Msg("Missing input! ("..v..")")
			    return {}
			end
			if (input.Src) then
				if (round) then
					Args[k] = math.Round((input.Value or 0)*1000)/1000
				else
					Args[k] = (input.Value or 0)
				end
			else
			    Args[k] = 0
			end
		end
	end

	return Args
end


function ENT:GetActionOutputs()
	if (self.Action.outputs) then
	    local result = {}
	    for _,v in ipairs(self.Action.outputs) do
	        result[v] = self.Outputs[v].Value or 0
	    end
	    
	    return result
	end
	
	return self.Outputs.Out.Value or 0
end




function MakeWireGate(pl, Pos, Ang, Model, action, Vel, aVel, frozen, nocollide)
	if ( !pl:CheckLimit( "wire_gates" ) ) then return nil end

	local wire_gate = ents.Create( "gmod_wire_gate" )
	wire_gate:SetPos( Pos )
	wire_gate:SetAngles( Ang )
	wire_gate:SetModel( Model )
	wire_gate:Spawn()
	wire_gate:Activate()

	wire_gate:Setup( GateActions[action] )
	wire_gate:SetPlayer( pl )

	if (nocollide) then explosive:GetPhysicsObject():EnableCollision(false) end

	local ttable =
	{
		action      = action,
		pl			= pl,
		nocollide	= nocollide,
		description = description
	}

	table.Merge( wire_gate:GetTable(), ttable )

	pl:AddCount( "wire_gates", wire_gate )

	return wire_gate
end

duplicator.RegisterEntityClass("gmod_wire_gate", MakeWireGate, "Pos", "Ang", "Model", "action", "Vel", "aVel", "frozen")
