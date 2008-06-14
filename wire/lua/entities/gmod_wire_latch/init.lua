
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "Latch"

include('shared.lua')

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")


function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self.Entity, { "Activate" } )	
	
	self:SetOverlayText( "Weld Latch - Activated" )
	
end

function ENT:SendVars( Ent1, Ent2, Bone1, Bone2, const )

	self.Ent1 = Ent1
	self.Ent2 = Ent2
	self.Bone1 = Bone1
	self.Bone2 = Bone2
	self.Constraint = const

end

function ENT:TriggerInput(iname, value)

	if (iname == "Activate") then
	
		if ( value == 0 && self.Constraint ) then
			
			self.Constraint:Remove()
			self.Constraint = nil
			
			self:SetOverlayText( "Weld Latch - Deactivated" )
			
		end
		
		if ( value == 1 && !self.Constraint ) then
			
			self.Constraint = constraint.Weld( self.Ent1, self.Ent2, self.Bone1, self.Bone2, 0 )
			
			if ( self.Constraint ) then
				self.Constraint.Type = "" //prevents the duplicator from making this weld
			end
			
			self:SetOverlayText( "Weld Latch - Activated" )
			
		end
		
	end
	
end

 
//duplicator support (TAD2020)
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if (self.Ent1) and (self.Ent1:IsValid()) then
		info.Ent1 = self.Ent1:EntIndex()
		info.Bone1 = self.Bone1
	end
	if (self.Ent2) and (self.Ent2:IsValid()) then
		info.Ent2 = self.Ent2:EntIndex()
		info.Bone2 = self.Bone2
	end
	if (self.Constraint != nil) then
		info.Constraint = true
	end
	return info
end 

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if (info.Ent1) then
		self.Ent1 = GetEntByID(info.Ent1)
		self.Bone1 = info.Bone1
		if (!self.Ent1) then
			self.Ent1 = ents.GetByIndex(info.Ent1)
		end
	end
	if (info.Ent2) then
		self.Ent2 = GetEntByID(info.Ent2)
		self.Bone2 = info.Bone2
		if (!self.Ent2) then
			self.Ent2 = ents.GetByIndex(info.Ent2)
		end
	end
	self:TriggerInput("Activate", self.Inputs.Activate.Value)
end
 