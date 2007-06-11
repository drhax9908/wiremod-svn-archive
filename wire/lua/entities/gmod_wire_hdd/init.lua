AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "WireHDD"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Data" })
	self.Inputs = Wire_CreateInputs(self.Entity, { "Clk", "AddrRead", "AddrWrite", "Data" })

	self.Clk = 0
	self.AWrite = 0
	self.Data = 0

	//Hard drive id/folder id:
	self.DriveID = 0
	//Hard drive capicacity (loaded from hdd)
	self.DriveCap = 0

	self.Cache = {}
	for i = 0,63 do
		self.Cache[i] = 0
	end
	self.CachedStruct = -1
	self.SaveSteps = 0

	self:SetOverlayText( "Flash memory" )
end

function ENT:GetCap( steamid )
	if (file.Exists("WireFlash\\"..steamid.."\\"..self.DriveID.."\\_structure.txt" )) then
		local temp = file.Read("WireFlash\\"..steamid.."\\"..self.DriveID.."\\_structure.txt")
		if (tonumber(temp)) then
			self.DriveCap = tonumber(temp)
			self:SetOverlayText( "Flash memory - "..self.DriveCap.."kb" )
		end
	else
		file.Write("WireFlash\\"..steamid.."\\"..self.DriveID.."\\_structure.txt", self.DriveCap)
	end

	if ((!SinglePlayer()) && (self.DriveCap > 256)) then
		self.DriveCap = 256
	end

	//Create all files if needed
	//for i = 0,self.DriveCap*1024/64 do
	//	if (!file.Exists("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..i..".txt")) then
	//		file.Write("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..i..".txt","")
	//	end
	//end
end

function ENT:ReadCell( Address )
	if ((self.DriveID < 0) || (!SinglePlayer() && (self.DriveID >= 4))) then
		return nil
	end

	local player = self:GetOwner( )
	if (player:IsValid()) then
		local steamid = player:SteamID()
		steamid = string.gsub(steamid, ":", "_")
		self:GetCap(steamid)

		if ((Address < self.DriveCap * 1024) && (Address >= 0)) then
			local cachestruct = math.floor(Address / 64)
			local cacheaddr = math.floor(Address) % 64
			
			if (cachestruct == self.CachedStruct) then
				return self.Cache[cacheaddr]
			else
				//Cache sector
				if (!file.Exists("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..cachestruct..".txt")) then
					file.Write("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..cachestruct..".txt","")
				end
				local tempval = string.Explode("\n",file.Read("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..cachestruct..".txt"))
				for i = 0,63 do
					if ((tempval[i+1]) && (tonumber(tempval[i+1]))) then
						self.Cache[i] = tempval[i+1]
					else
						self.Cache[i] = 0
					end
				end			

				self.CachedStruct = cachestruct
				return self.Cache[cacheaddr]
			end
		else
			return nil
		end
	else
		return nil
	end
end

function ENT:WriteCell( Address, value )
	if ((self.DriveID < 0) || (!SinglePlayer() && (self.DriveID >= 4))) then
		return false
	end

	local player = self.pl
	if (player:IsValid()) then
		local steamid = player:SteamID()
		steamid = string.gsub(steamid, ":", "_")
		self:GetCap(steamid)

		if ((Address < self.DriveCap * 1024) && (Address >= 0)) then
			local cachestruct = math.floor(Address / 64)
			local cacheaddr = math.floor(Address) % 64
			
			if (cachestruct == self.CachedStruct) then
				self.Cache[cacheaddr] = value
				self.SaveSteps = self.SaveSteps + 1
			else
				if (self.CachedStruct != -1) then
					local tempstr = ""
					for i = 0,63 do
						tempstr = tempstr..self.Cache[i].."\n"
					end
					file.Write("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..self.CachedStruct..".txt",tempstr)
				end
				self.SaveSteps = 0

				//Cache sector
				if (!file.Exists("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..cachestruct..".txt")) then
					file.Write("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..cachestruct..".txt","")
				end
				local tempval = string.Explode("\n",file.Read("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..cachestruct..".txt"))
				for i = 0,63 do
					if ((tempval[i+1]) && (tonumber(tempval[i+1]))) then
						self.Cache[i] = tempval[i+1]
					else
						self.Cache[i] = 0
					end
				end			

				self.CachedStruct = cachestruct
				
				self.Cache[cacheaddr] = value
				self.SaveSteps = self.SaveSteps + 1
			end
			//Save
			//FIXME: Improve saving
			if (self.SaveSteps > 32) then
				local tempstr = ""
				for i = 0,63 do
					tempstr = tempstr..self.Cache[i].."\n"
				end
				file.Write("WireFlash\\"..steamid.."\\"..self.DriveID.."\\"..self.CachedStruct..".txt",tempstr)
				self.SaveSteps = 0
			end

			return true
		else
			return false
		end
	else
		return false
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Clk") then
		self.Clk = value
	elseif (iname == "AddrRead") then
		local val = self:ReadCell(value)
		if (val) then
			Wire_TriggerOutput(self.Entity, "Data", val)
		end
	elseif (iname == "AddrWrite") then
		self.AWrite = value
		if (self.Clk >= 1) then
			self:WriteCell(self.AWrite, self.Data)
		end
	elseif (iname == "Data") then
		self.Data = value
		if (self.Clk >= 1) then
			self:WriteCell(self.AWrite, self.Data)
		end
	end
end
