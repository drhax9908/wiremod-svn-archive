AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "Adv. Input"
ENT.OverlayDelay = 0.1
ENT.OverlayRandom = 0.025

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity,{"Reset"})
	self.Outputs = Wire_CreateOutputs(self.Entity,{"Out"})
end

function ENT:Setup(key_more,key_less,toggle,value_min,value_max,value_start,speed)
	self.keymore = key_more
	self.keyless = key_less
	self.toggle = (toggle == 1 || toggle == true)
	self.value_min = value_min
	self.value_max = value_max	
	self.Value = value_start
	self.value_start = value_start
	self.speed = speed
	self:ShowOutput()
	Wire_TriggerOutput(self.Entity,"Out",self.Value)
end

function ENT:TriggerInput(iname, value)
    if(iname == "Reset")then
        if(value != 0)then
            self.Value = self.value_start
            self:ShowOutput()
	        Wire_TriggerOutput(self.Entity,"Out",self.Value)
	    end
	end
end

function ENT:InputActivate(mul)
	if (self.toggle) then
		return self:Switch( !self.On, mul )
	end
	return self:Switch( true, mul )
end

function ENT:InputDeactivate( mul )
	if (self.toggle) then return true end
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
		self.Value = self.Value + self.speed * timediff * self.dir
		if (self.Value < self.value_min) then
			self.Value = self.value_min
		elseif (self.Value > self.value_max) then
			self.Value = self.value_max
		end
		self:ShowOutput()
		Wire_TriggerOutput(self.Entity,"Out",self.Value)
		self.Entity:NextThink(CurTime()+0.02)
		return true
	end
end

function ENT:ShowOutput()
	self:SetOverlayText("(" .. self.value_min .. " - " .. self.value_max .. ") = " .. self.Value)
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


function MakeWireAdvInput( pl, Pos, Ang, keymore, keyless, toggle, value_min, value_max, value_start, speed, model, Vel, aVel, frozen )
	if ( !pl:CheckLimit( "wire_adv_inputs" ) ) then return false end

	local wire_adv_input = ents.Create( "gmod_wire_adv_input" )
	if (!wire_adv_input:IsValid()) then return false end

	wire_adv_input:SetAngles( Ang )
	wire_adv_input:SetPos( Pos )
	wire_adv_input:SetModel( model or Model("models/jaanus/wiretool/wiretool_input.mdl") )
	wire_adv_input:Spawn()

	if wire_adv_input:GetPhysicsObject():IsValid() then
		local Phys = wire_adv_input:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_adv_input:Setup( keymore, keyless, toggle, value_min, value_max, value_start, speed )
	wire_adv_input:SetPlayer(pl)
	wire_adv_input.	pl = pl

	numpad.OnDown( pl, keymore, "WireAdvInput_On", wire_adv_input, 1 )
	numpad.OnUp( pl, keymore, "WireAdvInput_Off", wire_adv_input, 1 )
	
	numpad.OnDown( pl, keyless, "WireAdvInput_On", wire_adv_input, -1 )
	numpad.OnUp( pl, keyless, "WireAdvInput_Off", wire_adv_input, -1 )

	pl:AddCount( "wire_adv_inputs", wire_adv_input )
	
	return wire_adv_input
end

duplicator.RegisterEntityClass("gmod_wire_adv_input", MakeWireAdvInput, "Pos", "Ang", "keymore", "keyless", "toggle", "value_min", "value_max", "value_start", "speed", "model", "Vel", "aVel", "frozen")
