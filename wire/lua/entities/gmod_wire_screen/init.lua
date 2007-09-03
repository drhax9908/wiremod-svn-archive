AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Screen"

ENT.ValueA = 0
ENT.ValueB = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "B" })
end

function ENT:Think()
	if self.ValueA then
		self:SetDisplayA( self.ValueA )
		self.ValueA = nil
	end
	
	if self.ValueB then
		self:SetDisplayB( self.ValueB )
		self.ValueB = nil
	end
	
	self:NextThink(CurTime() + 0.05)
	return true
end

function ENT:Use()
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		self.ValueA = value
	elseif (iname == "B") then
		self.ValueB = value
	end
end

function ENT:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor)
	// Extra stuff for Wire Screen (TheApathetic)
	self:SetTextA(TextA)
	self:SetTextB(TextB)
	self:SetSingleBigFont(SingleBigFont)
	
	//LeftAlign (TAD2020)
	self:SetLeftAlign(LeftAlign)
	//Floor (TAD2020)
	self:SetFloor(Floor)
	
	// Put it here to update inputs if necessary (TheApathetic)
	self:SetSingleValue(SingleValue)
end
