AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "AddressBus"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" })
	self.Inputs = Wire_CreateInputs(self.Entity, { "Memory1", "Memory2", "Memory3", "Memory4" })

	self.Memory = {}
	self.MemStart = {}
	self.MemEnd = {}
	for i = 1,4 do
		self.Memory[i] = nil
		self.MemStart[i] = 0
		self.MemEnd[i] = 0
	end
end

/*function ENT:Think()
	self.BaseClass.Think(self)
end*/

function ENT:ReadCell( Address )
	for i = 1,4 do
		if (Address >= self.MemStart[i]) && (Address <= self.MemEnd[i]) then
			if (self.Memory[i]) && (self.Memory[i].ReadCell) then
				local val = self.Memory[i]:ReadCell( Address - self.MemStart[i] )
				if (val) then
					return val
				else
					return 0
				end
			else
				return 0
			end
		end
	end
	return nil
end

function ENT:WriteCell( Address, value )
	local res = false
	for i = 1,4 do
		if (Address >= self.MemStart[i]) && (Address <= self.MemEnd[i]) then
			if (self.Memory[i]) && (self.Memory[i].WriteCell) then
				self.Memory[i]:WriteCell( Address - self.MemStart[i], value )
			end
			res = true
		end
	end
	return res
end

function ENT:TriggerInput(iname, value)
	if (iname == "Memory1") then
		self.Memory[1] = self.Inputs.Memory1.Src
	elseif (iname == "Memory2") then
		self.Memory[2] = self.Inputs.Memory2.Src
	elseif (iname == "Memory3") then
		self.Memory[3] = self.Inputs.Memory3.Src
	elseif (iname == "Memory4") then
		self.Memory[4] = self.Inputs.Memory4.Src
	end
end
