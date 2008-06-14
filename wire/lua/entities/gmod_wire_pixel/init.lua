
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Pixel"

function ENT:Initialize()
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


function MakeWirePixel( pl, Ang, Pos, Model, nocollide, Vel, aVel, frozen )
	if ( !pl:CheckLimit( "wire_pixels" ) ) then return false end
	
	local wire_pixel = ents.Create( "gmod_wire_pixel" )
	if (!wire_pixel:IsValid()) then return false end
	
	wire_pixel:SetModel( Model )
	wire_pixel:SetAngles( Ang )
	wire_pixel:SetPos( Pos )
	wire_pixel:Spawn()
	
	wire_pixel:Setup()
	wire_pixel:SetPlayer(pl)
	
	if ( nocollide == true ) then wire_pixel:SetCollisionGroup(COLLISION_GROUP_WORLD) end
	
	local ttable = {
		pl	= pl,
		nocollide = nocollide
	}
	table.Merge(wire_pixel:GetTable(), ttable )
	
	pl:AddCount( "wire_pixels", wire_pixel )
	
	return wire_pixel
end

duplicator.RegisterEntityClass("gmod_wire_pixel", MakeWirePixel, "Ang", "Pos", "Model", "nocollide", "Vel", "aVel", "frozen")
