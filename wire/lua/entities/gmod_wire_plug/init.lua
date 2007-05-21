
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

local MODEL = Model( "models/props_lab/tpplug.mdl" )

ENT.WireDebugName = "Plug"

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.MySocket = nil
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A","B","C","D","E","F","G","H" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "A","B","C","D","E","F","G","H" })
end

function ENT:SetValue(index,value)
	if (self.MySocket.Const) and (self.MySocket.Const:IsValid()) then
		Wire_TriggerOutput(self.Entity, index, value)
	else
		Wire_TriggerOutput(self.Entity, index, 0)
	end
	
	self:ShowOutput()
end

function ENT:OnRemove()
	self.BaseClass.Think(self)

	if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket.MyPlug = nil
	end
end

function ENT:Setup()
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	self:ShowOutput()
    if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket:SetValue(iname, value)
	end
end

function ENT:SetSocket(socket)
	self.MySocket = socket
end

function ENT:AttachedToSocket(socket)
    for i,v in pairs(self.Inputs)do
        socket:SetValue(v,v.Value)
 	end
end

function ENT:ShowOutput(value)
	self:SetOverlayText("Plug")
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
end
