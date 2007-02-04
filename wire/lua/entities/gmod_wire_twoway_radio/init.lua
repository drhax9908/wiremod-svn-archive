
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "2W Radio"

local MODEL = Model( "models/props_lab/bindergreen.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "B", "C", "D" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "A", "B", "C", "D" })

	self.PairID = nil
	self.Other = nil
end

function ENT:Setup( channel )
	self.Channel = channel
	self.PrevOutputA = 0
	self.PrevOutputB = 0
	self.PrevOutputC = 0
	self.PrevOutputD = 0

	self:ShowOutput("update", 1)
	Wire_TriggerOutput(self.Entity, "A", Radio_Receive(channel))
	Wire_TriggerOutput(self.Entity, "B", Radio_Receive(channel))
	Wire_TriggerOutput(self.Entity, "C", Radio_Receive(channel))
	Wire_TriggerOutput(self.Entity, "D", Radio_Receive(channel))
end

function ENT:TriggerInput(iname, value)
	if (self.Other) and (self.Other:IsValid()) then
		self.Other:ReceiveRadio(iname, value)
		self:ShowOutput("update", 1)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (not self.Other) or (not self.Other:IsValid()) then
		self.Other = nil
		self.PairID = nil
	end
end

function ENT:ReceiveRadio(iname, value)
	if (iname == "A") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self.Entity, "A", value)
	elseif (iname == "B") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self.Entity, "B", value)
	elseif (iname == "C") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self.Entity, "C", value)
	elseif (iname == "D") and (self.Other) and (self.Other:IsValid()) then
		Wire_TriggerOutput(self.Entity, "D", value)
	end
	self:ShowOutput(iname, value)
end

function ENT:RadioLink(other, id)
	self.Other = other
	self.PairID = id
	
	self:ReceiveRadio("A", 0)
end


function ENT:ShowOutput(iname, value)
	local chagned
	if (iname == "A") then
		if (A ~= self.PrevOutputA) then
			self.PrevOutputA = (value or 0)
			changed = 1
		end
	elseif (iname == "B") then
		if (B ~= self.PrevOutputB) then
			self.PrevOutputB = (value or 0)
			changed = 1
		end
	elseif (iname == "C") then
		if (C ~= self.PrevOutputC) then
			self.PrevOutputC = (value or 0)
			changed = 1
		end
	elseif (iname == "D") then
		if (D ~= self.PrevOutputD) then
			self.PrevOutputD = (value or 0)
			changed = 1
		end
	elseif (iname == "update") then
		changed = 1
	end
	if (changed) then
		if self.PairID == nil then
			self:SetOverlayText( "(Not Paired) Transmit: " .. 0 )
		else
			self:SetOverlayText( "(Pair ID: " .. self.PairID .. ")\nTransmit A: " .. (self.Inputs.A.Value or 0) .. " B: " .. (self.Inputs.B.Value or 0) ..  " C: " .. (self.Inputs.C.Value or 0) ..  " D: " .. (self.Inputs.D.Value or 0) .. "\nReceive A: " .. self.PrevOutputA .. " B: " .. self.PrevOutputB .. " C: " .. self.PrevOutputC .. " D: " .. self.PrevOutputD )
		end
		
	end
end

function ENT:OnRestore()
	Wire_AdjustInputs(self.Entity, { "A", "B", "C", "D" })
	Wire_AdjustOutputs(self.Entity, { "A", "B", "C", "D" })
end
