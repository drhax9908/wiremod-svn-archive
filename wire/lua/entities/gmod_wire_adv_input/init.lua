AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "Adv. Input"
ENT.OverlayDelay = 0.1
ENT.OverlayRandom = 0.025

local MODEL = Model("models/jaanus/wiretool/wiretool_input.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity,{"Reset"})
	self.Outputs = Wire_CreateOutputs(self.Entity,{"Out"})
end

function ENT:Setup(key_more,key_less,toggle,value_min,value_max,value_start,speed)
	self.KeyMore = key_more
	self.KeyLess = key_less
	self.Toggle = (toggle == 1)
	self.ValueMin = value_min
	self.ValueMax = value_max	
	self.Value = value_start
	self.Value_Start = value_start
	self.Speed = speed
	self:ShowOutput()
	Wire_TriggerOutput(self.Entity,"Out",self.Value)
end

function ENT:TriggerInput(iname, value)
    if(iname == "Reset")then
        if(value != 0)then
            self.Value = self.Value_Start
            self:ShowOutput()
	        Wire_TriggerOutput(self.Entity,"Out",self.Value)
	    end
	end
end

function ENT:InputActivate(mul)
	if (self.Toggle) then
		return self:Switch( !self.On, mul )
	end
	return self:Switch( true, mul )
end

function ENT:InputDeactivate( mul )
	if (self.Toggle) then return true end
	return self:Switch( false, mul )
end

function ENT:Switch( on, mul )
	if (!self.Entity:IsValid()) then return false end
	self.On = on
	if(on) then
		self.dir = mul
	else
		self.dir = 0
	end
	return true
end

function ENT:Think()
	self.BaseClass.Think(self)
	local timediff = CurTime()-(self.LastThink or 0)
	self.LastThink = (self.LastThink or 0)+timediff
	if (self.On == true) then
		self.Value = self.Value+self.Speed*timediff*self.dir
		if (self.Value < self.ValueMin) then
			self.Value = self.ValueMin
		elseif (self.Value > self.ValueMax) then
			self.Value = self.ValueMax
		end
		self:ShowOutput()
		Wire_TriggerOutput(self.Entity,"Out",self.Value)
		self.Entity:NextThink(CurTime()+0.02)
		return true
	end
end

function ENT:ShowOutput()
	self:SetOverlayText("(" .. self.ValueMin .. " - " .. self.ValueMax .. ") = " .. self.Value)
end

local function On( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputDeactivate( mul )
end
numpad.Register( "WireAdvInput_On",On)
numpad.Register( "WireAdvInput_Off",Off)
