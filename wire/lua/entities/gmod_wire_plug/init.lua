
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
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end

function ENT:OnRemove()
	self.BaseClass.Think(self)

	if (self.MySocket) and (self.MySocket:IsValid()) then
		self.MySocket.MyPlug = nil
	end
end

function ENT:Setup(a,ar,ag,ab,aa)
	self.A = a or 0
	self.AR = ar or 255
	self.AG = ag or 0
	self.AB = ab or 0
	self.AA = aa or 255
	self.Entity:SetColor(ar, ag, ab, aa)
	self:ShowOutput(0)
end

function ENT:TriggerInput(iname, value, iter)
	if (iname == "A") then
		self:ShowOutput(value)

		if (self.MySocket) and (self.MySocket:IsValid()) then
			self.MySocket:SetValue(value, iter)
		end
	end
end

function ENT:SetSocket(socket)
	self.MySocket = socket
end

function ENT:AttachedToSocket(socket)
	socket:SetValue(self.Inputs.A.Value)
end

function ENT:ShowOutput(value)
	if value ~= self.PrevValue then
		self:SetOverlayText(math.Round(value*1000)/1000)
		self.PrevValue = value
	end
end

function ENT:OnRestore()
	self.A = self.A or 0
	self.AR = self.AR or 255
	self.AG = self.AG or 0
	self.AB = self.AB or 0
	self.AA = self.AA or 255

    self.BaseClass.OnRestore(self)
end
