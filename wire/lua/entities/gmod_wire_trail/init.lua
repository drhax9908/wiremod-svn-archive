
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Trail"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, {"Set", "Length","StartSize","EndSize","R","G","B","A"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {})
    self.R = 0
    self.G = 0
    self.B = 0
    self.A = 0
    self.Length = 0
    self.StartSize = 0
    self.EndSize = 0
    self.Material = ""
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(Material)
    self.Material = Material
end

function ENT:SetTrails( Player, Entity, Data )

	if ( Entity.SToolTrail ) then
	
		Entity.SToolTrail:Remove()
		Entity.SToolTrail = nil
	
	end
	
	if ( Data.StartSize == 0 ) then
	
		Data.StartSize = 0.0001;
		
	end

	local trail_entity = util.SpriteTrail( Entity,  //Entity
											0,  //iAttachmentID
											Data.Color,  //Color
											false, // bAdditive
											Data.StartSize, //fStartWidth
											Data.EndSize, //fEndWidth
											Data.Length, //fLifetime
											1 / ((Data.StartSize+Data.EndSize) * 0.5), //fTextureRes
											Data.Material .. ".vmt" ) //strTexture
	
	Entity.SToolTrail = trail_entity
end

function ENT:TriggerInput(iname, value)
	if (iname == "Set") then
		if (value ~= 0) then
		  self:SetTrails( self:GetOwner(), self.Entity, { Color = Color( self.R, self.G, self.B, self.A ), 
																	Length = self.Length, 
																	StartSize = self.StartSize, 
																	EndSize = self.EndSize,
																	Material = self.Material } )
		end
    elseif(iname == "Length")then
        self.Length = value
    elseif(iname == "StartSize")then
        self.StartSize = value
    elseif(iname == "EndSize")then
        self.EndSize = value
    elseif(iname == "R")then
        self.R = value
    elseif(iname == "G")then
        self.G = value
    elseif(iname == "B")then
        self.B = value
    elseif(iname == "A")then
        self.A = value
    end
end

function ENT:ShowOutput()
	local text = "Trail"
	self:SetOverlayText( text )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end
   