AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "ConsoleScreen"

function ENT:Initialize()
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "CharX", "CharY", "Char", "CharParam", "Clk", "Reset" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" }) 

	self.Memory = {}

	for i = 0, 2048 do
		self.Memory[i] = 0
	end

	self.CharX = 0
	self.CharY = 0
	self.Char = 0
	self.CharParam = 0
	self.Clk = 0
	
	//self.CursorEnabled = 0
	//self.CursorX = 0
	//self.CursorY = 0
	//self.CursorSize = 0.25
end

function ENT:Use()
end

function ENT:SendPixel()
	if (self.Clk >= 1) && (self.CharX >= 0) && (self.CharX < 30) &&
			      (self.CharY >= 0) && (self.CharY < 18) then
		local address = math.floor(self.CharY)*30+math.floor(self.CharX)
		self.Memory[address*2] = self.Char

		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("consolescreen_datamessage", rp)
			umsg.Long( self:EntIndex() )
			umsg.Long( self.Clk )
			umsg.Long( address*2 )
			umsg.Float( self.Char )
		umsg.End()

		self.Memory[address*2+1] = self.CharParam

		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("consolescreen_datamessage", rp)
			umsg.Long( self:EntIndex() )
			umsg.Long( self.Clk )
			umsg.Long( address*2+1 )
			umsg.Float( self.CharParam )
		umsg.End()
	end
end

function ENT:ReadCell( Address )
	if (Address < 0) || (Address > 2048) then
		return nil
	elseif (Address == 2048) then
		return self.Clk
	elseif (Address >= 0) && (Address <= 2047) then
		return self.Memory[Address]
	end
end

function ENT:WriteCell( Address, value )
	if (Address < 0) || (Address > 2048) then
		return false
	elseif (Address >= 0) && (Address <= 2048) then
		if (Address == 2048) then
			self.Clk = value
		end

		self.Memory[Address] = value

		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("consolescreen_datamessage", rp)
			umsg.Long( self:EntIndex() )
			umsg.Long( self.Clk )
			umsg.Long( Address )
			umsg.Float( value )
		umsg.End()
		return true
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "CharX") then
		self.CharX = value
		self:SendPixel()
	elseif (iname == "CharY") then
		self.CharY = value
		self:SendPixel()
	elseif (iname == "Char") then
		self.Char = value
		self:SendPixel()
	elseif (iname == "CharParam") then
		self.CharParam = value
		self:SendPixel()
	elseif (iname == "Clk") then
		self.Clk = value
		self:SendPixel()
	elseif (iname == "Reset") then
		self:WriteCell(2042,0)
		self:WriteCell(2047,0)
		self:WriteCell(2043,0)
	end
end
