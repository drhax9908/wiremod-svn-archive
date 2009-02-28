AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Button"
ENT.OverlayDelay = 0
ENT.OutputEntID = false
ENT.EntIDToOutput = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	if (self.PrevUser) and (self.PrevUser:IsValid()) then return end
	if(self.OutputEntID)then self.EntIDToOutput = ply:EntIndex() end
	if (self:IsOn()) then
		if (self.toggle) then self:Switch(false) end
		
		return
	end

	self:Switch(true)
	self.PrevUser = ply
end

function ENT:Think()
	self.BaseClass.Think(self)

	if ( self:IsOn() ) then
		if (not self.PrevUser)
		or (not self.PrevUser:IsValid())
		or (not self.podpress and not self.PrevUser:KeyDown(IN_USE))
		or (self.podpress and not self.PrevUser:KeyDown( IN_ATTACK )) then
		    if (not self.toggle) then
				self:Switch(false)
			end
			
			self.PrevUser = nil
			self.podpress = nil
		end

		self.Entity:NextThink(CurTime()+0.05)
		return true
	end
end

function ENT:Setup(toggle, value_off, value_on, entity)
	self.toggle = toggle
	self.value_off = value_off
	self.value_on = value_on
	self.Value = value_off
	self:SetOn( false )

	self:ShowOutput(self.value_off)
	Wire_TriggerOutput(self.Entity, "Out", self.value_off)

	if(entity)then
	Wire_AdjustOutputs(self.Entity, { "Out", "EntID" })
	Wire_TriggerOutput(self.Entity, "EntID", 0)
	self.OutputEntID=true
	else
	Wire_AdjustOutputs(self.Entity, { "Out" })
	self.OutputEntID=false
	end
end

function ENT:Switch(on)
	if (not self.Entity:IsValid()) then return end

	self:SetOn( on )

	if (on) then
		self:ShowOutput(self.value_on)
		self.Value = self.value_on
	else
		self:ShowOutput(self.value_off)
		self.Value = self.value_off
		if(self.OutputEntID)then self.EntIDToOutput=0 end
	end

	Wire_TriggerOutput(self.Entity, "Out", self.Value)
	if(self.OutputEntID)then Wire_TriggerOutput(self.Entity, "EntID", self.EntIDToOutput) end
	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "(" .. self.value_off .. " - " .. self.value_on .. ") = " .. value )
end


function MakeWireButton( pl, Model, Pos, Ang, toggle, value_off, value_on, description, entity, Vel, aVel, frozen )
	if ( !pl:CheckLimit( "wire_buttons" ) ) then return false end

	local wire_button = ents.Create( "gmod_wire_button" )
	if (!wire_button:IsValid()) then return false end

	wire_button:SetModel(Model)
	wire_button:SetAngles(Ang)
	wire_button:SetPos(Pos)
	wire_button:Spawn()

	if wire_button:GetPhysicsObject():IsValid() then
		local Phys = wire_button:GetPhysicsObject()
		Phys:EnableMotion(!frozen)
	end

	wire_button:Setup(toggle, value_off, value_on, entity )
	wire_button:SetPlayer(pl)
	wire_button.pl = pl
	
	pl:AddCount( "wire_buttons", wire_button )

	return wire_button
end

duplicator.RegisterEntityClass("gmod_wire_button", MakeWireButton, "Model", "Pos", "Ang", "toggle", "value_off", "value_on", "description", "entity", "Vel", "aVel", "frozen" )
