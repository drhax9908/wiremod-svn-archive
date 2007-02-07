
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


function ENT:Setup(range, players, npcs, beacons, hoverballs, thrusters, rpgs, painttarget)
 	self.Range			= range
	self.TargetPlayer	= players
	self.TargetNPC		= npcs
	self.TargetBeacon	= beacons
	self.TargetHoverballs	= hoverballs
	self.TargetThrusters	= thrusters
	self.TargetRPGs		= rpgs
	self.PaintTarget	= painttarget
	
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
		    self.LastTarget = nil
		end
	else
		if (self.Target) and (self.Target:IsValid()) and (self.NextTargetTime) and (CurTime() < self.NextTargetTime) then return end
		self.NextTargetTime = CurTime()+1
		
		local targets = ents.FindInSphere(self.Entity:GetPos(), self.Range or 10)
		local mypos = self.Entity:GetPos()
		
		self.LastTarget = self.Target
		
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
			elseif (self.TargetRPGs) and (target:GetClass() == "rpg_missle") then
				tt = target
			elseif (self.TargetHoverballs) and (target:GetClass() == "gmod_hoverball" || target:GetClass() == "gmod_wire_hoverball") then
				tt = target
			elseif (self.TargetRPGs) and (target:GetClass() == "rpg_missile") then
				tt = target
			elseif (self.TargetThrusters) and (target:GetClass() == "gmod_thruster" || target:GetClass() == "gmod_wire_thruster") then
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
		if (self.PaintTarget) then
			if (self.LastTarget != self.Target) then //unpaint last target if it was different
				self:TargetPainter(self.LastTarget, false)
			end
			self:TargetPainter(self.Target, true) //paint current
		end
		
	    self:ShowOutput(true)
		
		Wire_TriggerOutput(self.Entity, "Out", 1)
	else
		if (self.PaintTarget) then
			self:TargetPainter(self.LastTarget, false)
		end
		
	    self:ShowOutput(false)
		
	    Wire_TriggerOutput(self.Entity, "Out", 0)
	end
end


function ENT:TargetPainter( tt, targeted )
	if tt &&						// There is a target
		tt.Entity &&				// Target has is an entity
		tt.Entity:IsValid() && 		// And it's valid
		tt.Entity:EntIndex() != 0	// And isn't worldspawn
	then
		if (targeted) then
			tt.Entity:SetColor(255, 0, 0, 255)
		else
			tt.Entity:SetColor(255, 255, 255, 255)
		end
	end
end
	

function ENT:ShowOutput(value)
	local txt = "Target Finder - "
	if (value) then
		txt = txt .. "Target Acquired"
	else
		txt = txt .. "No Target"
	end
	
	if (self.Inputs.Hold) and (self.Inputs.Hold.Value > 0) then txt = txt .. " - Locked" end

	self:SetOverlayText(txt)
end
