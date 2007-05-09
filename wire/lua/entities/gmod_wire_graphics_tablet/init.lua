--Wire graphics tablet  by greenarrow
--http://gmodreviews.googlepages.com/
--http://forums.facepunchstudios.com/greenarrow
--There may be a few bits of code from the wire panel here and there as i used it as a starting point.
--Credit to whoever created the first wire screen, from which all others seem to use the lagacy clientside drawing code (this one included)

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Graphics Tablet"
ENT.outputMode = 0

function ENT:OnRemove()
end

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "X", "Y", "Switch", "OnScreen" })
	self.active = false
	self.onScreen = false
	self.osVal = 0
	self.lastX = 0
	self.lastY = 0
	self.switch = 0
	self.lastActivate = CurTime()
end

function ENT:Setup(gmode)
	self.outputMode = gmode
end

function ENT:Use()
	if (CurTime() < self.lastActivate + 0.2) then return true end
	self.active = !self.active
	if (self.active) then
		self.switch = 1
	else
		self.switch = 0
	end
	Wire_TriggerOutput(self.Entity, "Switch", self.switch)
	self:ShowOutput(self.lastX, self.lastY, self.switch, self.osVal)
	self.lastActivate = CurTime()
end

function ENT:Think()
	self.BaseClass.Think(self)
	local newOnScreen = false
	
	for i,player in pairs(player.GetAll()) do
		local trace = {}
		trace.start = player:GetShootPos()
		trace.endpos = player:GetAimVector() * 64 + trace.start
		trace.filter = player
		local trace = util.TraceLine(trace)
		
		if (trace.Entity == self.Entity) then
			newOnScreen = true
			local xval = player:GetInfoNum("wire_graphics_tablet_xval", 1)
			local yval = player:GetInfoNum("wire_graphics_tablet_yval", 1)
			if (xval ~= self.lastX || yval ~= self.lastY) then
				local activeval = 0
				if (self.active) then activeval = 1 end
				if (self.outputMode) then
					xval = (xval * 2) - 1
					yval = (-yval * 2) + 1
				end
				Wire_TriggerOutput(self.Entity, "X", xval)
				Wire_TriggerOutput(self.Entity, "Y", yval)
				self:ShowOutput(self.lastX, self.lastY, self.switch, self.osVal)
				self.lastX = xval
				self.lastY = yval
			end
		end
	end

	if (newOnScreen ~= self.onScreen) then
		if (newOnScreen) then
			self.osVal = 1
		else
			self.osVal = 0
		end
		Wire_TriggerOutput(self.Entity, "OnScreen", self.osVal)
		self:ShowOutput(self.lastX, self.lastY, self.switch, self.osVal)
		self.onScreen = newOnScreen
	end
			
	self.Entity:NextThink(CurTime()+0.08)
	return true
end

function ENT:ShowOutput(xval, yval, activeval, osval)
	self:SetOverlayText(string.format("X = %f, Y = %f, Switch = %d, OnScreen = %d\n", xval, yval, activeval, osval))
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)
	Wire_AdjustOutputs(self.Entity, { "X", "Y", "Switch", "OnScreen" })
end
