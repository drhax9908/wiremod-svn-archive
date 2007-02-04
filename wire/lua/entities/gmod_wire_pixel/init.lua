
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Pixel"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.R, self.G, self.B = 0, 0, 0
	self.Inputs = Wire_CreateInputs( self.Entity, { "Red", "Green", "Blue" } )
end


function ENT:TriggerInput(iname, value)
	local R,G,B = self.R, self.G, self.B
	if (iname == "Red") then
		R = value
	elseif (iname == "Green") then
		G = value
	elseif (iname == "Blue") then
		B = value
	end
	self:ShowOutput( R, G, B )
end

function ENT:Setup()
	self:ShowOutput( 0, 0, 0 )
end

function ENT:ShowOutput( R, G, B )
	if ( R ~= self.R or G ~= self.G or B ~= self.B ) then
		self:SetOverlayText( "Pixel: Red=" .. R .. " Green:" .. G .. " Blue:" .. B )
		self.R, self.G, self.B = R, G, B
		self.Entity:SetColor( R, G, B, 255 )
	end
end
