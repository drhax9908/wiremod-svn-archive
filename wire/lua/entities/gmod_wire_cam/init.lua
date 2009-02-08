
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

function ENT:RecieveInfo(In,Val)
	if(In == "X")then
		self.IdealPos.x = Val
		self:SetPos(self.IdealPos)
	elseif(In == "Y")then
		self.IdealPos.y = Val
		self:SetPos(self.IdealPos)
	elseif(In == "Z")then
		self.IdealPos.z = Val
		self:SetPos(self.IdealPos)
	elseif(In == "Position")then
		self.IdealPos = Val
		self:SetPos(self.IdealPos)
	elseif(In == "Pitch")then
		self.IdealAng.p = Val
		self:SetAngles(self.IdealAng)
	elseif(In == "Roll")then
		self.IdealAng.r = Val
		self:SetAngles(self.IdealAng)
	elseif(In == "Yaw")then
		self.IdealAng.y = Val
		self:SetAngles(self.IdealAng)
	elseif(In == "Direction")then
		self.IdealAng = Val:Normalize():Angle()
		self:SetAngles(self.IdealAng)
	end    
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end
   