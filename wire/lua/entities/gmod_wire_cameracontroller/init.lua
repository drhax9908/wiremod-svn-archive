
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Camera Controller"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, {"Activated","X","Y","Z","Pitch","Yaw","Roll"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {"On"})
    self.Active = false
    self.CamEnt = nil
    self.CamPlayer = nil
    
    local cam = ents.Create("gmod_wire_cam")
    if (!cam:IsValid()) then return false end

	cam:SetAngles( Vector(0,0,0) )
	cam:SetPos( self:GetPos() )
	cam:SetModel( Model("models/props_junk/PopCan01a.mdl") )
	cam:SetColor(0,0,0,0)
	cam:Spawn()
	
	self.CamEnt = cam
end

function ENT:Setup(Player)
    if(Player && Player:IsValid() && Player:IsPlayer())then
        self.CamPlayer = Player
    end
end

function ENT:OnRemove()
    if(self.CamEnt && self.CamEnt:IsValid())then
        self.CamEnt:Remove()
    end
    
    if( self.Active == 1)then
        self.CamPlayer:SetViewEntity(self.CamPlayer)
    end
	Wire_Remove(self.Entity)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Activated") then
		if (value == 0) then
		  self.CamPlayer:SetViewEntity(self.CamPlayer)
		  self.Active = 0
		  Wire_TriggerOutput(self.Entity,"On",0)
		else
		  self.CamPlayer:SetViewEntity(self.CamEnt)
		  self.Active = 1
		  Wire_TriggerOutput(self.Entity,"On",1)
		end
    elseif(iname == "X")then
        local camPos = self.CamEnt:GetPos()
        camPos.x = value
        self.CamEnt:RecieveInfo(camPos,self.CamEnt.IdealAng)
    elseif(iname == "Y")then
        local camPos = self.CamEnt:GetPos()
        camPos.y = value
        self.CamEnt:RecieveInfo(camPos,self.CamEnt.IdealAng)
    elseif(iname == "Z")then
        local camPos = self.CamEnt:GetPos()
        camPos.z = value
        self.CamEnt:RecieveInfo(camPos,self.CamEnt.IdealAng)
    elseif(iname == "Pitch")then
        local camAng = self.CamEnt:GetAngles()
        camAng.p = value
        self.CamEnt:RecieveInfo(self.CamEnt.IdealPos,camAng)
    elseif(iname == "Yaw")then
        local camAng = self.CamEnt:GetAngles()
        camAng.y = value
        self.CamEnt:RecieveInfo(self.CamEnt.IdealPos,camAng)
    elseif(iname == "Roll")then
        local camAng = self.CamEnt:GetAngles()
        camAng.r = value
        self.CamEnt:RecieveInfo(self.CamEnt.IdealPos,camAng)
    end
end

function ENT:Use( activator, caller )
	if ( !activator:IsPlayer() ) then return end
	
	self.CamPlayer = activator
end

function ENT:ShowOutput()
	local text = "Wired Camera"
	self:SetOverlayText( text )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end
   