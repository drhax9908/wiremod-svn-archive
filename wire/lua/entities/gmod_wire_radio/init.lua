
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Radio"

local MODEL = Model( "models/props_lab/binderblue.mdl" )

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
	
	self.Channel = 1
	self.Transmitting = 0
	
	Radio_Register(self)
end

function ENT:Setup(channel)
	self.Channel = channel
	self.PrevOutput = nil

	self:ShowOutput(Radio_Receive(channel))
	Wire_TriggerOutput(self.Entity, "Out", Radio_Receive(channel))
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
    	Radio_Transmit(self.Channel, value)
    	self:ShowOutput(Radio_Receive(self.Channel))
	end
end

function ENT:CalcTransmit()
	return self.Inputs.A.Value or 0
end

function ENT:ReceiveRadio(value)
	self:ShowOutput(value)
	Wire_TriggerOutput(self.Entity, "Out", value)
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "(Channel " .. math.floor( self.Channel or 0 ) .. ") Transmit: " .. math.Round(self:CalcTransmit()*1000)/1000 .. " Receive: " .. value )
		self.PrevOutput = value
	end
	return value
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)

	Radio_Register(self)
end
