AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

SWEP.Weight = 8
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Receiver = nil
SWEP.Pointing = false

function SWEP:Initialize()
    self.Pointing = false
end

function SWEP:Reload()
	
end

function SWEP:PrimaryAttack()
    Msg("Fire\n")
	self.Pointing = !self.Pointing
	Msg("self.Pointing = " .. tostring(self.Pointing) .. "\n")
	self.Weapon:SetNWBool("Active", self.Pointing)
end

function SWEP:SecondaryAttack()
	Msg("Secondary\n")
    local pos = self.Owner:GetShootPos()
    local tracedata = {}
	    tracedata.start = pos
	    tracedata.endpos = pos + self.Owner:GetAimVector() * 100000
	    tracedata.filter = self.Owner
    local trace = util.TraceLine(tracedata)
    
    if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_las_Receiver") then
        self.Receiver = trace.Entity
        return true
    end
end

function SWEP:Think()
    if(self.Pointing && self.Receiver && self.Receiver:IsValid())then
        local pos = self.Owner:GetShootPos()
        local tracedata = {}
	        tracedata.start = pos
	        tracedata.endpos = pos + self.Owner:GetAimVector() * 100000
	        tracedata.filter = self.Owner
        local trace = util.TraceLine(tracedata)
    
        local point = trace.HitPos
        Wire_TriggerOutput(self.Receiver, "X", point.x)
        Wire_TriggerOutput(self.Receiver, "Y", point.y)
        Wire_TriggerOutput(self.Receiver, "Z", point.z)
        Wire_TriggerOutput(self.Receiver, "Dist", self.Receiver:GetPos():Distance(point))
        //Msg("Send!\n")
    end
end
