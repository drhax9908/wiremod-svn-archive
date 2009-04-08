AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "DigitalScreen"

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "ConsoleScreen"

function ENT:Initialize()
	
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "PixelX", "PixelY", "PixelG", "Clk", "FillColor", "ClearRow", "ClearCol" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Memory" }) 

	self.Memory = {}

	self.PixelX = 0
	self.PixelY = 0
	self.PixelG = 0
	self.Clk = 1

	self.Width = 32
	self.Height = 32

	self.DataCache = {}
	self.DataCacheSize = 0
	self.IgnoreDataTransfer = false
end

function ENT:SetDigitalSize(w,h)
	self.Width = math.Clamp(math.floor(w),1,512)
	self.Height = math.Clamp(math.floor(h),1,512)

	self:WriteCell(1048572,self.Height)
	self:WriteCell(1048573,self.Width)
end

function ENT:SendPixel()
	if (self.Clk >= 1) && (self.PixelX >= 0) && (self.PixelX < self.Width) &&
			      (self.PixelY >= 0) && (self.PixelY < self.Height) then
		local address = self.PixelX*self.Width + self.PixelY
		self.Memory[address] = self.PixelG

		local rp = RecipientFilter()
		rp:AddAllPlayers()

		umsg.Start("digitalscreen_datamessage", rp)
			umsg.Long(self:EntIndex())
			umsg.Long(self.Clk)
			umsg.Long(1)
			umsg.Long(address)
			umsg.Float(self.PixelG)
		umsg.End()
	end
end

function ENT:ReadCell(Address)
	if (Address < 0) || (Address > 1048575) then
		return nil
	elseif (Address == 1048575) then
		return self.Clk
	elseif (Address >= 0) && (Address <= 1048574) then
		if (self.Memory[Address]) then
			return self.Memory[Address]
		else
			return 0
		end
	end
end

function ENT:FlushCache()
	if (self.DataCacheSize > 0) then
		local rp = RecipientFilter()
		rp:AddAllPlayers()
	
		umsg.Start("digitalscreen_datamessage", rp)
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
	if (Address < 0) || (Address > 1048575) then
		return false
	elseif (Address >= 0) && (Address <= 1048575) then
		if (Address == 1048575) then
			self.Clk = value
		end

		//self:ClientWriteCell(Address,value)
		
		self.DataCache[self.DataCacheSize] = {}
		self.DataCache[self.DataCacheSize].Address = Address
		self.DataCache[self.DataCacheSize].Value = value
		self.DataCacheSize = self.DataCacheSize + 1
		if (Address == 1048575) || (self.DataCacheSize > 20) then
			self:FlushCache()
			self.IgnoreDataTransfer = true
		end
		self.Memory[Address] = value
		return true
	end
end

function ENT:Think()
	if (self.IgnoreDataTransfer == true) then
		self.IgnoreDataTransfer = false
		self.Entity:NextThink(CurTime()+0.2)
	else
		self:FlushCache()
		self.Entity:NextThink(CurTime()+0.1)
	end
	return true
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
	elseif (iname == "FillColor") then
		self:WriteCell(1048574,value)
	elseif (iname == "ClearCol") then
		self:WriteCell(1048571,math.Clamp( value, 0, 31 ))
	elseif (iname == "ClearRow") then
		self:WriteCell(1048570,math.Clamp( value, 0, 31 ))
	end
end


function MakeWireDigitalScreen( pl, w, h, Ang, Pos, Smodel )
	
	if ( !pl:CheckLimit( "wire_digitalscreens" ) ) then return false end
	
	local wire_digitalscreen = ents.Create( "gmod_wire_digitalscreen" )
	if (!wire_digitalscreen:IsValid()) then return false end
	wire_digitalscreen:SetModel(Smodel)

	wire_digitalscreen:SetAngles( Ang )
	wire_digitalscreen:SetPos( Pos )
	wire_digitalscreen:Spawn()
	wire_digitalscreen:SetDigitalSize(w,h)
	
	wire_digitalscreen:SetPlayer(pl)
		
	local ttable = {
		pl = pl,
		Smodel = Smodel,
	}
	table.Merge(wire_digitalscreen:GetTable(), ttable )
	
	pl:AddCount( "wire_digitalscreens", wire_digitalscreen )
	
	return wire_digitalscreen
end

duplicator.RegisterEntityClass("gmod_wire_digitalscreen", MakeWireDigitalScreen, "w", "h", "Ang", "Pos", "Smodel")

