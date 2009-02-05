
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "EMarker"
ENT.OverlayDelay = 0

local MODEL = Model( "models/jaanus/wiretool/wiretool_siren.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, { "Entity" }, { "ENTITY" })
	self:SetOverlayText( "No Mark selected" )
end

function ENT:Setup(mark)
	self.mark = mark
	Wire_TriggerOutput(self.Entity, "Entity", self.mark)
	self:SetOverlayText( "Mark - " .. self.mark:GetClass() )
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if(self.mark && self.mark:IsValid())then
		info.Mark = self.mark:EntIndex()
	end
	return info
end 

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if (info.Mark) then
		self.mark = GetEntByID(info.Mark)
		if (!self.mark) then
			self.mark = ents.GetByIndex(info.Mark)
		end
		if(self.mark) then
			self:Setup(self.mark)
		end
	end
end 