
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Camera"

function ENT:Initialize()
    self.IdealPos = self:GetPos()
    self.IdealAng = self:GetAngles()
end

function ENT:Think()
    if(self:GetPos() != self.IdealPos)then
        self:SetPos(self.IdealPos)
    end
    if(self:GetAngles() != self.IdealAng)then
        self:SetAng(self.IdealAng)
    end
    if(self:GetColor() != Color(0,0,0,0))then
        self:SetColor(0,0,0,0)
    end
    self:NextThink(CurTime()+0.1)
end

function ENT:RecieveInfo(Pos,Ang)
    self.IdealPos = Pos
    self:SetPos(Pos)
    self.IdealAng = Ang
    self:SetAngles(Ang)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end
   