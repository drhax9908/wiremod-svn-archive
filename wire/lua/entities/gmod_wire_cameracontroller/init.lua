
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Camera Controller"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self.Entity, {"On"})
    self.Active = false
    self.OriginalOwner = nil
    self.CamEnt = nil
    self.CamPlayer = nil
    self.CamPod = nil
    self.ZoomAmount = 0
    self.OriginalFOV = 0
    self.Static = 0
end

function ENT:Setup(Player,Static)
    if(Player && Player:IsValid() && Player:IsPlayer())then
        self.CamPlayer = Player
        self.OriginalOwner = Player
        self.OriginalFOV = self.CamPlayer:GetFOV()
    end
    
    if(Static == 0)then
        local cam = ents.Create("gmod_wire_cam")
        if (!cam:IsValid()) then return false end

	   cam:SetAngles( Vector(0,0,0) )
	   cam:SetPos( self:GetPos() )
	   cam:SetModel( Model("models/props_junk/PopCan01a.mdl") )
	   cam:SetColor(0,0,0,0)
	   cam:Spawn()
	
	   self.CamEnt = cam
        self.Inputs = Wire_CreateInputs(self.Entity, {"Activated","Zoom","X","Y","Z","Pitch","Yaw","Roll"})
	else
	   local cam = ents.Create("prop_physics")
        if (!cam:IsValid()) then return false end

	   cam:SetAngles( Vector(0,0,0) )
	   cam:SetPos( self:GetPos()+Vector(0,0,64) )
	   cam:SetModel( Model("models/dav0r/camera.mdl") )
	   cam:Spawn()
	
	   self.CamEnt = cam
	   	self.Inputs = Wire_CreateInputs(self.Entity, {"Activated","Zoom"})
	   self.Static = 1
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
		  self.CamPlayer:SetFOV(self.OrginialFOV,0.01)
		  self.Active = 0
		  Wire_TriggerOutput(self.Entity,"On",0)
		else
		  if(self.CamPod ~= nil)then
		      if(self.CamPod:GetPassenger() ~= nil && self.CamPod:GetPassenger():IsValid())then
			     self.CamPlayer = self.CamPod:GetPassenger()
			  else
			     self.CamPlayer = self.OriginalOwner
              end
          end
		  self.CamPlayer:SetViewEntity(self.CamEnt)
		  self.CamPlayer:SetFOV(self.ZoomAmount,0.01)
		  self.Active = 1
		  Wire_TriggerOutput(self.Entity,"On",1)
		end
	elseif(iname == "Zoom")then
	   self.ZoomAmount = math.Clamp(value,1,self.OriginalFOV)
	   if(self.Active == 1)then
		  self.CamPlayer:SetFOV(self.ZoomAmount,0.01)
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

function ENT:ShowOutput()
	local text = "Wired Camera"
	self:SetOverlayText( text )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end
