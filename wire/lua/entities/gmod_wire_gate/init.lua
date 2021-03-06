
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Gate"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end


function ENT:Setup( action, noclip )
	if (action) then
	    self.WireDebugName = action.name
	    
		WireLib.AdjustSpecialInputs(self.Entity, action.inputs, action.inputtypes )
		if (action.outputs) then
			WireLib.AdjustSpecialOutputs(self.Entity, action.outputs, action.outputtypes)
		else
			//Wire_AdjustOutputs(self.Entity, { "Out" })
			WireLib.AdjustSpecialOutputs(self.Entity, { "Out" }, action.outputtypes)
		end
		
		if (action.reset) then
		    action.reset(self)
		end
	end
	
	if (noclip) then
		self.Entity:SetCollisionGroup( COLLISION_GROUP_WORLD )
	end
	
	self.Action = action
	self.PrevValue = nil
	
	//self.Action.inputtypes = self.Action.inputtypes or {}
	
    self:CalcOutput()
	self:ShowOutput()
end


function ENT:OnInputWireLink(iname, itype, src, oname, otype)
	if (self.Action) and (self.Action.OnInputWireLink) then
		self.Action.OnInputWireLink(self, iname, itype, src, oname, otype)
	end
end

function ENT:OnOutputWireLink(oname, otype, dst, iname, itype)
	if (self.Action) and (self.Action.OnOutputWireLink) then
		self.Action.OnOutputWireLink(self, oname, otype, dst, iname, itype)
	end
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

function ENT:ReadCell(Address)
	if (self.Action) && (self.Action.ReadCell) then
		return self.Action:ReadCell(self,Address)
	else
		return nil
	end
end

function ENT:WriteCell(Address,value)
	if (self.Action) && (self.Action.WriteCell) then
		return self.Action:WriteCell(self,Address,value)
	else
		return false
	end
end

function ENT:ShowOutput()
	local txt = ""

	if (self.Action) then
		txt = (self.Action.name or "No Name")
		if (self.Action.label) then
			txt = txt.."\n"..self.Action.label(self:GetActionOutputs(), unpack(self:GetActionInputs(Wire_EnableGateInputValues)))
		end
	else
	    txt = "Invalid gate!"
	end
	
	self:SetOverlayText(txt)
end


function ENT:OnRestore()
    self.Action = GateActions[self.action]
    
    self.BaseClass.OnRestore(self)
end


function ENT:GetActionInputs(as_names)
	local Args = {}

	if (self.Action.compact_inputs) then
	    for k,v in ipairs(self.Action.inputs) do
	        local input = self.Inputs[v]
			if (not input) then
			    Msg("Missing input! ("..v..")")
			    return {}
			end

		    if (input.Src) and (input.Src:IsValid()) then
				if (as_names) then
					table.insert(Args, input.Src.WireName or input.Src.WireDebugName or v)
				else
					table.insert(Args, input.Value)
				end
			end
		end

		while (#Args < self.Action.compact_inputs) do
			if (as_names) then
			    table.insert(Args, self.Action.inputs[#Args+1] or "*Not enough inputs*")
			else
			    //table.insert( Args, WireLib.DT[ (self.Action.inputtypes[#Args+1] or "NORMAL") ].Zero )
			    table.insert( Args, WireLib.DT[ self.Inputs[ self.Action.inputs[#Args+1] ].Type ].Zero )
			end
		end
	else
	    for k,v in ipairs(self.Action.inputs) do
	        local input = self.Inputs[v]
			if (not input) then
			    Msg("Missing input! ("..v..")")
			    return {}
			end
			
			if (as_names) then
				if (input.Src) and (input.Src:IsValid()) then
					Args[k] = input.Src.WireName or input.Src.WireDebugName or v
				else
					Args[k] = v
				end
			else
				if (input.Src) and (input.Src:IsValid()) then
					//Args[k] = ( input.Value or WireLib.DT[ (self.Action.inputtypes[k] or "NORMAL") ].Zero )
					Args[k] = ( input.Value or WireLib.DT[ self.Inputs[v].Type ].Zero )
				else
					//Args[k] = WireLib.DT[ (self.Action.inputtypes[k] or "NORMAL") ].Zero
				    Args[k] = WireLib.DT[ self.Inputs[v].Type ].Zero
				end
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




function MakeWireGate(pl, Pos, Ang, Model, action, noclip, frozen, nocollide)
	if ( !pl:CheckLimit( "wire_gates" ) ) then return nil end

	local wire_gate = ents.Create( "gmod_wire_gate" )
	wire_gate:SetPos( Pos )
	wire_gate:SetAngles( Ang )
	wire_gate:SetModel( Model )
	wire_gate:Spawn()
	wire_gate:Activate()

	wire_gate:Setup( GateActions[action], noclip )
	wire_gate:SetPlayer( pl )

	if wire_gate:GetPhysicsObject():IsValid() then
		wire_gate:GetPhysicsObject():EnableMotion(!frozen)
	end
	if nocollide == true or noclip ==true then 
		wire_gate:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	local ttable = {
		pl			= pl,
		action      = action,
		noclip		= noclip,
		nocollide	= nocollide
	}
	table.Merge( wire_gate:GetTable(), ttable )

	pl:AddCount( "wire_gates", wire_gate )
	pl:AddCleanup( "gmod_wire_gate", wire_gate )
	
	return wire_gate
end
duplicator.RegisterEntityClass("gmod_wire_gate", MakeWireGate, "Pos", "Ang", "Model", "action", "noclip", "frozen", "nocollide")
