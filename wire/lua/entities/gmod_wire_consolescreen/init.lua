AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "ConsoleScreen"

function ENT:Initialize()
	
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "CharX", "CharY", "Char", "CharParam", "Clk", "Reset" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" }) 

	self.Memory = {}

	for i = 0, 2047 do
		self.Memory[i] = 0
	end

	self.CharX = 0
	self.CharY = 0
	self.Char = 0
	self.CharParam = 0
	self.Clk = 1

	self.DataCache = {}
	self.DataCacheSize = 0
	self.IgnoreDataTransfer = false
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
			umsg.Long(self:EntIndex())
			umsg.Long(self.Clk)
			umsg.Long(1)
			umsg.Long(address*2)
			umsg.Float(self.Char)
		umsg.End()

		self.Memory[address*2+1] = self.CharParam

		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("consolescreen_datamessage", rp)
			umsg.Long(self:EntIndex())
			umsg.Long(self.Clk)
			umsg.Long(1)
			umsg.Long(address*2+1)
			umsg.Float(self.CharParam)
		umsg.End()
	end
end

function ENT:ReadCell(Address)
	if (Address < 0) || (Address > 2047) then
		return nil
	elseif (Address == 2047) then
		return self.Clk
	elseif (Address >= 0) && (Address <= 2046) then
		if (Address == 2022) then
			return WireGPU_Monitors[self.Entity:GetModel()].RatioX
		end

		return self.Memory[Address]
	end
end

function ENT:FlushCache()
	if (self.DataCacheSize > 0) then
		local rp = RecipientFilter()
		rp:AddAllPlayers()
	
		umsg.Start("consolescreen_datamessage", rp)
		umsg.Long(self:EntIndex())
		umsg.Long(self.Clk)
		umsg.Long(self.DataCacheSize)

		for i=0,self.DataCacheSize-1 do
			umsg.Long(self.DataCache[i].Address)
			umsg.Float(self.DataCache[i].Value)
		end

		self.DataCacheSize = 0
		umsg.End()
	end
end

function ENT:WriteCell(Address, value)
	if (Address < 0) || (Address > 2047) then
		return false
	elseif (Address >= 0) && (Address <= 2047) then
		if (Address == 2047) then
			self.Clk = value
		end

		//if (Address < 1080) then
		self:ClientWriteCell(Address,value)
		//end

		if (Address >= 1080) or (self.Memory[Address] != value) then
			self.DataCache[self.DataCacheSize] = {}
			self.DataCache[self.DataCacheSize].Address = Address
			self.DataCache[self.DataCacheSize].Value = value
			self.DataCacheSize = self.DataCacheSize + 1
			if (Address == 2047) || (self.DataCacheSize > 20) then
				self:FlushCache()
				self.IgnoreDataTransfer = true
			end
		end
		self.Memory[Address] = value

		//else
		//	local rp = RecipientFilter()
		//	rp:AddAllPlayers()

		//	umsg.Start("consolescreen_datamessage", rp)
		//		umsg.Long(self:EntIndex())
		//		umsg.Long(self.Clk)
		//		umsg.Long(1)
		//		umsg.Long(Address)
		//		umsg.Float(value)
		//	umsg.End()
		//end
		return true
	end
end

function ENT:Think()
	if (self.IgnoreDataTransfer == true) then
		self:FlushCache()
		self.IgnoreDataTransfer = false
		self.Entity:NextThink(CurTime()+0.1)
	else
		self.Entity:NextThink(CurTime()+0.05)
	end
	return true
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
		self:WriteCell(2041,0)
		self:WriteCell(2046,0)
		self:WriteCell(2042,0)
	end
end

function ENT:ClientWriteCell(address, value)
	if (address == 2037) then
		local delta = value
		local low = math.floor(math.Clamp(self.Memory[2031],0,17))
		local high = math.floor(math.Clamp(self.Memory[2032],0,17))
		if (delta > 0) then
			for j = low,high do
				for i = 29,delta do
					self.Memory[j*60+i*2] = self.Memory[j*60+i*2-delta*2]
					self.Memory[j*60+i*2+1] = self.Memory[j*60+i*2+1-delta*2]
				end
			end
			for j = low,high do
				for i = 0, delta-1 do
					self.Memory[j*60+i*2] = 0
					self.Memory[j*60+i*2+1] = 0
				end
			end
		else
			delta = -delta
			for j = low,high do
				for i = 0,29-delta do
					self.Memory[j*60+i*2] = self.Memory[j*60+i*2+delta*2]
					self.Memory[j*60+i*2+1] = self.Memory[j*60+i*2+1+delta*2]
				end
			end
			for j = low,high do
				for i = 29-delta+1,29 do
					self.Memory[j*60+i*2] = 0
					self.Memory[j*60+i*2+1] = 0
				end
			end
		end
	end
	if (address == 2038) then
		local delta = value
		local low = math.floor(math.Clamp(self.Memory[2033],0,29))
		local high = math.floor(math.Clamp(self.Memory[2034],0,29))
		if (delta > 0) then
			for j = low, high-delta do
				for i = 0, 59 do
					self.Memory[j*60+i] = self.Memory[(j+delta)*60+i]
				end
			end
			for j = high-delta+1,high do
				for i = 0, 59 do
						self.Memory[j*60+i] = 0
				end
			end
		else
			delta = -delta
			for j = high,delta do
				for i = 0, 59 do
					self.Memory[j*60+i] = self.Memory[(j-delta)*60+i]
				end
			end
			for j = delta+1,low do
				for i = 0, 59 do
					self.Memory[j*60+i] = 0
				end
			end
		end
	end
	if (address == 2039) then
		for i = 0, 59 do
			self.Memory[value*60+i] = 0
		end
	end
	if (address == 2040) then
		for i = 0, 17 do
			self.Memory[i*60+value] = 0
		end
	end
	if (address == 2041) then
		for i = 0, 18*30*2 do 
			self.Memory[i] = 0
		end
	end
end


function MakeWireconsoleScreen(pl, Ang, Pos, Smodel)

	if (!pl:CheckLimit("wire_consolescreens")) then return false end
	
	local wire_consolescreen = ents.Create("gmod_wire_consolescreen")
	if (!wire_consolescreen:IsValid()) then return false end
	wire_consolescreen:SetModel(Smodel)

	wire_consolescreen:SetAngles(Ang)
	wire_consolescreen:SetPos(Pos)
	wire_consolescreen:Spawn()
	
	wire_consolescreen:SetPlayer(pl)
		
	local ttable = {
		pl = pl,
		Smodel = Smodel,
	}
	table.Merge(wire_consolescreen:GetTable(), ttable)
	
	pl:AddCount("wire_consolescreens", wire_consolescreen)
	
	return wire_consolescreen
end

duplicator.RegisterEntityClass("gmod_wire_consolescreen", MakeWireconsoleScreen, "Ang", "Pos", "Smodel")
