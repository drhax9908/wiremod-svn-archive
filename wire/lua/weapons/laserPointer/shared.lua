SWEP.Author = ""
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = "Left Click to designate targets. Right click to select laser reciever."

SWEP.Spawnable = true;
SWEP.AdminSpawnable = true;

SWEP.viewModel = "models/weapons/v_pistol.mdl";
SWEP.worldModel = "models/weapons/w_pistol.mdl"; 
 
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
  
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.reciever = nil
SWEP.pointing = false

function SWEP:Initialize()
    self.pointing = false
end

function SWEP:Reload()
	
end

function SWEP:PrimaryAttack()
    //Msg("Fire\n")
    if(self.pointing)then
        self.pointing = false
    else
        self.pointing = true
    end
end

function SWEP:SecondaryAttack()
    local pos = self.Owner:GetShootPos()
    local ang = self.Owner:GetAimVector()
    local tracedata = {}
    tracedata.start = pos
    tracedata.endpos = pos + ang * 100000
    tracedata.filter = self.Owner
    local trace = util.TraceLine(tracedata)
    
    if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_las_reciever") then
        self.reciever = trace.Entity
        return true
    end
end

function SWEP:OnRemove()

end

function SWEP:Think()
    if(self.pointing && self.reciever && self.reciever:IsValid())then
        local pos = self.Owner:GetShootPos()
        local ang = self.Owner:GetAimVector()
        local tracedata = {}
        tracedata.start = pos
        tracedata.endpos = pos + ang * 100000
        tracedata.filter = self.Owner
        local trace = util.TraceLine(tracedata)
    
        local point = trace.HitPos
        Wire_TriggerOutput(self.reciever, "X", point.x)
        Wire_TriggerOutput(self.reciever, "Y", point.y)
        Wire_TriggerOutput(self.reciever, "Z", point.z)
        local recieverPos = self.reciever:GetPos()
        local length = recieverPos:Distance(point)
        Wire_TriggerOutput(self.reciever, "Dist", length)
        //Msg("Send!\n")
    end
end       
