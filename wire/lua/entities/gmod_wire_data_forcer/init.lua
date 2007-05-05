AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "DataForcer"
ENT.OverlayDelay = 0

ValueOn = 1

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
	self.Inputs = Wire_CreateInputs(self.Entity, { "Force" })
	self.target = nil
	self.forcing = false
end

function ENT:OnRemove()
	self.ValueOn = nil
	self.target = nil
	gmod_tool.stool.wire_data_forcer.Firstlink = nil
	Msg("Removed.")
end



function ENT:TriggerInput(iname, value)
	if (iname == "Force") then
	   if(self.forcing == true)then
	       self.forcing = false
	   else
	       self.forcing = true
	   end
	end
	return true
end


function ENT:Think()
	self.BaseClass.Think(self)
	if(self.target && self.target.Entity:IsValid() && self.forcing )then
		for i,v in pairs(self.Entity.Inputs)do
            if(i != "Force")then
	           Wire_TriggerOutput(self.target.Entity, i, v)
            end
	    end
	end
		self.Entity:NextThink(CurTime()+0.05)
		return true
end

function ENT:Setup(target)
	self.target = target
	local outs = {};
	outs = self.target.Entity.Outputs
	Wire_AdjustOutputs(self.Entity,outs)
	outs["Force"] = 0
	Wire_AdjustInputs(self.Entity,outs)
	self:ShowOutput()
end


function ENT:ShowOutput()
	self:SetOverlayText("Data Forcer")
end
