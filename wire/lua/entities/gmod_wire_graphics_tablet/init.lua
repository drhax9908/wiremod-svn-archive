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
	
	local OF = 0
	local OU = 0
	local OR = 0
	local Res = 0.1
	local RatioX = 1
	
	if self.Entity:GetModel() == "models/props_lab/monitor01b.mdl" then
		OF = 6.53
		OU = 0
		OR = 0
		Res = 0.05
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorsmall.mdl" then
		OF = 0.2
		OU = 4.5
		OR = -0.85
		Res = 0.045
	elseif self.Entity:GetModel() == "models/kobilica/wiremonitorbig.mdl" then
		OF = 0.3
		OU = 11.8
		OR = -2.35
		Res = 0.12
	elseif self.Entity:GetModel() == "models/props/cs_office/computer_monitor.mdl" then
		OF = 3.25
		OU = 15.85
		OR = -2.2
		Res = 0.085
		RatioX = 0.75
	elseif self.Entity:GetModel() == "models/props/cs_office/TV_plasma.mdl" then
		OF = 6.1
		OU = 17.05
		OR = -5.99
		Res = 0.175
		RatioX = 0.57
	end
	
	local x1 = -5.535
	local x2 = 3.5
	local y1 = 5.091
	local y2 = -4.1
	
	local ox = 5
	local oy = 5
		
	local pos
	local cx
	local cy
	local posfix_x
	local posfix_y
	
	
	
	for i,player in pairs(player.GetAll()) do
		
		local trace = {}
		trace.start = player:GetShootPos()
		trace.endpos = player:GetAimVector() * 64 + trace.start
		trace.filter = player
		local trace = util.TraceLine(trace)
		
		
		if (trace.Entity == self.Entity) then
			newOnScreen = true
			pos = self.Entity:WorldToLocal(trace.HitPos)
			
			posfix_x = math.abs(OR)
			posfix_y = math.abs(OU)
	
			local xval = (((pos.y + OR)/math.abs(posfix_x)) - x1) / (math.abs(x1) + math.abs(x2))
			local yval = 1 - (((pos.z - OU) + y1)) / (math.abs(y1) + math.abs(y2))
			xval = math.min(math.max(xval, 0), 1)
			yval = math.min(math.max(yval, 0), 1)
			
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
		
		
		--trace.start = LocalPlayer():GetShootPos()
		--trace.endpos = LocalPlayer():GetAimVector() * 64 + trace.start
		--trace.filter = LocalPlayer()
		--local trace = util.TraceLine(trace)
		
		
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
