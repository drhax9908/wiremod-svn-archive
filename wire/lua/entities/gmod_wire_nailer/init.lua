
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Colorer"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "Fire", "R", "G", "B", "A" })
	self.ValueR = 255
    self.ValueG = 255
    self.ValueB = 255
    self.ValueA = 255
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		if (value ~= 0) then
			 local vStart = self.Entity:GetPos()
			 local vForward = self.Entity:GetUp()
			 
			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * 2048)
				 trace.filter = { self.Entity }
			 local trace = util.TraceLine( trace ) 
			
			if (!trace.Entity) then return false end
            if (!trace.Entity:IsValid() ) then return false end
            if (trace.Entity:IsWorld()) then return false end
            if ( CLIENT ) then return true end
            trace.Entity:SetColor(self.ValueR,self.ValueG,self.ValueB,self.ValueA)
		end
	elseif(iname == "R") then
		self.ValueR = math.max(math.min(255,value),0)
	elseif(iname == "G") then
		self.ValueG = math.max(math.min(255,value),0)
	elseif(iname == "B") then
		self.ValueB = math.max(math.min(255,value),0)
	elseif(iname == "A") then
		self.ValueA = math.max(math.min(255,value),0)
	end
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Colorer" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

