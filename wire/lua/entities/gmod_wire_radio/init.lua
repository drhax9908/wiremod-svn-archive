
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Radio"

local MODEL = Model( "models/props_lab/binderblue.mdl" )

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "B", "C", "D",	"Channel"})
	self.Outputs = Wire_CreateOutputs(self.Entity, { "A", "B", "C", "D" })
	
	self.Channel = 1
	self.Transmitting = 0
	
	Radio_Register(self)
end

function ENT:Setup(channel)
	channel = math.floor(channel)
	self.Channel = channel
	self.PrevOutput = nil

	self:ShowOutput(Radio_Receive(channel))
end

function ENT:TriggerInput(iname, value)
	if (iname == "A" || iname == "B" || iname == "C" || iname == "D") then
		self.Inputs[iname].Value = value
    	Radio_Transmit(self.Channel, self.Inputs.A.Value or 0,self.Inputs.B.Value or 0,self.Inputs.C.Value or 0,self.Inputs.D.Value or 0)
		self:ShowOutput(self.Outputs.A.Value or 0,self.Outputs.B.Value or 0,self.Outputs.C.Value or 0,self.Outputs.D.Value or 0)
	end
	if (iname == "Channel") then
		self.Channel = math.floor(value)
		self:ShowOutput(Radio_Receive(self.Channel))
	end
end

function ENT:ReceiveRadio(A,B,C,D)
	self:ShowOutput(A,B,C,D)
end

function ENT:ShowOutput(A,B,C,D)
	Wire_TriggerOutput(self.Entity,"A",A)
	Wire_TriggerOutput(self.Entity,"B",B)
	Wire_TriggerOutput(self.Entity,"C",C)
	Wire_TriggerOutput(self.Entity,"D",D)
	self:SetOverlayText( "(Channel " .. self.Channel .. ") Transmit A: " .. (self.Inputs.A.Value or 0) .. " B: " .. (self.Inputs.B.Value or 0) ..  " C: " .. (self.Inputs.C.Value or 0) ..  " D: " .. (self.Inputs.D.Value or 0) .. "\nReceive A: " .. (self.Outputs.A.Value or 0) .. " B: " .. (self.Outputs.B.Value or 0) ..  " C: " .. (self.Outputs.C.Value or 0) ..  " D: " .. (self.Outputs.D.Value or 0) )
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)

	Radio_Register(self)
end
