AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "DigitalScreen"

function ENT:Initialize()
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "PixelX", "PixelY", "PixelG", "Clk", "RowClk", "ColClk", "FullClk" })

	for i = 0, 1023 do
		self.Entity:SetNetworkedFloat("DispData"..i,0.0)
	end

end

function ENT:Use()
end

function ENT:TriggerInput(iname, value)
	if (iname == "PixelX") then
		self:SetDisplayPixelX( string.format("%.2f", value) )
	elseif (iname == "PixelY") then
		self:SetDisplayPixelY( string.format("%.2f", value) )
	elseif (iname == "PixelG") then
		self:SetDisplayPixelG( string.format("%.2f", value) )
	elseif (iname == "Clk") then
		self:SetDisplayClk( value )
	elseif (iname == "RowClk") then
		self:SetDisplayRowClk( value )
	elseif (iname == "ColClk") then
		self:SetDisplayColClk( value )
	elseif (iname == "FullClk") then
		self:SetDisplayFullClk( value )
	end
end
