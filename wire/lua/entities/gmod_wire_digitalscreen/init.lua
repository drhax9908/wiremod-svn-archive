AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "DigitalScreen"

function ENT:Initialize()
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "PixelX", "PixelY", "PixelG", "Clk" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" }) 

	self.Memory = {}

	for i = 0, 1023 do
		self.Memory[i] = 0
	end

	self.PixelX = 0
	self.PixelY = 0
	self.PixelG = 0
	self.Clk = 0
end

function ENT:Use()
end

function ENT:SendPixel()
	if (self.Clk >= 1) && (self.PixelX >= 0) && (self.PixelX <= 32) &&
			      (self.PixelY >= 0) && (self.PixelY <= 32) then
		local address = math.floor(self.PixelY)*32+math.floor(self.PixelX)
		self.Memory[address] = self.PixelG 

		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("digitalscreen_datamessage", rp)
			umsg.Long( self:EntIndex() )
			umsg.Long( address )
			umsg.Float( self.PixelG )
		umsg.End()
		Msg("DSCR - sent pixel "..address.." wait for reply\n")
	end
end

function ENT:ReadCell( Address )
	if (Address < 0) || (Address > 1024) then
		return nil
	elseif (Address == 1024) then
		return self.Clk
	elseif (Address >= 0) && (Address <= 1023) then
		return self.Memory[Address]
	end
end

function ENT:WriteCell( Address, value )
	if (Address < 0) || (Address > 1024) then
		return false
	elseif (Address == 1024) then
		self.Clk = value
		return true
	elseif (Address >= 0) && (Address <= 1023) then
		if (self.Clk >= 1) then
			self.Memory[Address] = value

			local rp = RecipientFilter()
			rp:AddAllPlayers()
	
			umsg.Start("digitalscreen_datamessage", rp)
				umsg.Long( self:EntIndex() )
				umsg.Long( Address )
				umsg.Float( value )
			umsg.End()
			Msg("DSCR2 - sent pixel "..Address.." wait for reply\n")
			return true
		else
			return false
		end
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "PixelX") then
		self.PixelX = value
		self:SendPixel()
	elseif (iname == "PixelY") then
		self.PixelY = value
		self:SendPixel()
	elseif (iname == "PixelG") then
		self.PixelG = value
		self:SendPixel()
	elseif (iname == "Clk") then
		self.Clk = value
		self:SendPixel()
	end
end
