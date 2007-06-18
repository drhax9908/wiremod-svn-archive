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

// Message
// Function taken from connas stools all credit for this function goes to him.
function SWEP:Message(Text)
	if SERVER then
		self.Owner:SendLua("GAMEMODE:AddNotify('"..Text.."', NOTIFY_GENERIC, 10)")
		self.Owner:SendLua("surface.PlaySound('ambient/water/drip"..math.random(1, 4)..".wav')")
	end
end

function SWEP:PrimaryAttack()
    Msg("Fire\n")
	self.Pointing = !self.Pointing
	Msg("self.Pointing = " .. tostring(self.Pointing) .. "\n")
	self.Weapon:SetNWBool("Active", self.Pointing)
	//self:Message("Pointing on = "..tostring(self.Pointing))
	if(self.Receiver && self.Receiver:IsValid())then
	   Wire_TriggerOutput(self.Reciever,"Active",self.Pointing)
	end
end

function SWEP:SecondaryAttack()
	Msg("Secondary\n")
    local pos = self.Owner:GetShootPos()
    local tracedata = {}
	    tracedata.start = pos
	    tracedata.endpos = pos + self.Owner:GetAimVector() * 100000
	    tracedata.filter = self.Owner
    local trace = util.TraceLine(tracedata)
    
    if (trace.Entity:GetClass() == "gmod_wire_las_reciever") then
        //Msg("Link\n")
        self.Receiver = trace.Entity
        self:Message("Linked Sucessfully")
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
