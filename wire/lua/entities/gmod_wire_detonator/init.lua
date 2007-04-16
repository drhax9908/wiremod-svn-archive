
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Detonator"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self.Entity, { "Trigger" } )
	self.Trigger = 0
end

function ENT:TriggerInput(iname, value)
	if (iname == "Trigger") then
		self:ShowOutput( value )
	end
end

function ENT:Setup(damage)
	self.Damage = damage

	self:ShowOutput( 0 )
end

function ENT:ShowOutput( Trigger )
	if ( Trigger ~= self.Trigger ) then
		self:SetOverlayText( "Detonator " .. self.damage .. " = " .. Trigger )
		self.Trigger = Trigger
		if Trigger > 0 then
			self:DoDamage()
		end
	end
end

function ENT:DoDamage()
	if self.target and self.target:IsValid() and ( self.target:Health() > 0 ) then
		if self.target:Health() <= self.Damage then
			self.target:SetHealth(0)
			self.target:Fire( "break", "", 0 )
			self.target:Fire( "kill", "", 0.2 )
		else
			self.target:SetHealth( self.target:Health() - self.Damage )
		end
	end

	local effectdata = EffectData()
	effectdata:SetOrigin( self.Entity:GetPos() )
	util.Effect( "Explosion", effectdata, true, true )
	self.Entity:Remove()
end

// Dupe info functions added by TheApathetic
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.target) && (self.target:IsValid()) then
		info.target = self.target:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.target) then
		local target = GetEntByID(info.target)
		if (!target) then
			target = ents.GetByIndex(info.target)
		end
		self.target = target
	end
end