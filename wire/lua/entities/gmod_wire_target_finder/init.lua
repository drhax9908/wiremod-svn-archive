
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Targetter"
ENT.OverlayDelay = 0

local MODEL = Model( "models/props_lab/powerbox02d.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "Hold" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end


function ENT:Setup(range, players, npcs, beacons)
	self.Range = range
	self.TargetPlayer = players
	self.TargetNPC = npcs
	self.TargetBeacon = beacons

	self:ShowOutput(false)
	Wire_TriggerOutput(self.Entity, "Out", 0)
end


function ENT:GetBeaconPos(sensor)
	if (self.Target) then
	    if (not self.Target:IsValid()) then
	        self.Target = nil
	        return self.Entity:GetPos()
	    end
	
		return self.Target:GetPos()
	end

	return self.Entity:GetPos()
end


function ENT:Think()
	self.BaseClass.Think(self)

	if (self.Inputs.Hold) and (self.Inputs.Hold.Value > 0) then
		if (self.Target) and (not self.Target:IsValid()) then
		    Wire_TriggerOutput(self.Entity, "Out", 0)
		    self.Target = nil
		end
	else
		if (self.Target) and (self.Target:IsValid()) and (self.NextTargetTime) and (CurTime() < self.NextTargetTime) then return end
		self.NextTargetTime = CurTime()+1

		local targets = ents.FindInSphere(self.Entity:GetPos(), self.Range or 10)
		local mypos = self.Entity:GetPos()

		self.Target = nil
		local mindist = self.Range+1
		for _,target in pairs(targets) do
		    local tt = nil
			if (self.TargetNPC) and (string.find(target:GetClass(),"^npc_.*")) then
				tt = target
			elseif (self.TargetPlayer) and (target:GetClass() == "player") then
				tt = target
			elseif (self.TargetBeacon) and (target:GetClass() == "gmod_wire_locator") then
				tt = target
			end

			if (tt) then
			    local dist = (tt:GetPos() - mypos):Length()
			    if (dist < mindist) then
			        mindist = dist
			        self.Target = tt
			    end
			end
		end
	end
	
	if (self.Target) then
	    self:ShowOutput(true)
	    Wire_TriggerOutput(self.Entity, "Out", 1)
	else
	    self:ShowOutput(false)
	    Wire_TriggerOutput(self.Entity, "Out", 0)
	end
end


function ENT:ShowOutput(value)
	local txt = "Target Finder - "
	if (value) then
		txt = txt .. "Targetting"
	else
		txt = txt .. "No Target"
	end
	
	if (self.Inputs.Hold) and (self.Inputs.Hold.Value > 0) then
		txt = txt .. " - Locked"
	end
	
	self:SetOverlayText(txt)
end
