
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Distance"

local MODEL = Model( "models/props_lab/huladoll.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "Target" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup( xyz_mode, outdist, outbrng, gpscord, swapyz )
	self.XYZMode = xyz_mode
	self.PrevOutput = nil
	self.Value = 0
	self.OutDist = outdist
	self.OutBrng = outbrng
	self.GPSCord = gpscord
	self.SwapYZ = swapyz
	
	if !xyz_mode and !outdist and !outbrng and !gpscord then self.OutDist = true end
	
	local onames = {}
	if (outdist) then
	    table.insert(onames, "Distance")
	end
	if (xyz_mode) then
	    table.insert(onames, "X")
	    table.insert(onames, "Y")
	    table.insert(onames, "Z")
	end
	if (outbrng) then
    	table.insert(onames, "Bearing")
    	table.insert(onames, "Elevation")
	end
	if (gpscord) then
	    table.insert(onames, "World_X")
	    table.insert(onames, "World_Y")
	    table.insert(onames, "World_Z")
	end
	
	Wire_AdjustOutputs(self.Entity, onames)
	self:TriggerOutputs(0, Angle(0, 0, 0),Vector(0, 0, 0),Vector(0, 0, 0))
	self:ShowOutput()
end


function ENT:Think()
	self.BaseClass.Think(self)
	
	//if (!self.Inputs.Target.Src or !self.Inputs.Target.Src:IsValid() ) then return end
	if (!self.ToSense or !self.ToSense:IsValid() ) then	return end
	if (self.Active) then
	    local dist = 0
	    local distc = Vector(0, 0, 0)
	    local brng = Angle(0, 0, 0)
		local gpscords = Vector(0, 0, 0)
		local MyPos = self.Entity:GetPos()
		//local BeaconPos = self.Inputs["Target"].Src:GetBeaconPos(self.Entity)
		local BeaconPos = self.ToSense:GetBeaconPos(self.Entity)
		if (self.OutDist) then
			dist = (BeaconPos-MyPos):Length()
		end
		if (self.XYZMode) then
			local DeltaPos = self.Entity:WorldToLocal(BeaconPos)
			if (self.SwapYZ) then
				distc = Vector(DeltaPos.z, DeltaPos.x, -DeltaPos.y)
			else
				distc = Vector(-DeltaPos.y, DeltaPos.x, DeltaPos.z)
			end
		end
		if (self.OutBrng) then
		    local DeltaPos = self.Entity:WorldToLocal(BeaconPos)
		    brng = DeltaPos:Angle()
		end
		if (self.GPSCord) then gpscords = BeaconPos end
		
		self:TriggerOutputs(dist, brng, distc, gpscords)
		self:ShowOutput()
		
		self.Entity:NextThink(CurTime()+0.04)
		return true
	end
end


function ENT:ShowOutput()
	local txt = "Beacon Sensor"
	if (self.OutDist) then
		txt = txt .. "\nDistance = " .. math.Round(self.Outputs.Distance.Value*1000)/1000
	end
	if (self.XYZMode) then
		txt = txt .. "\nOffset = " .. math.Round(self.Outputs.X.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Y.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Z.Value*1000)/1000
	end
	if (self.OutBrng) then
		txt = txt .. "\nBearing = " .. math.Round(self.Outputs.Bearing.Value*1000)/1000 .. "," .. math.Round(self.Outputs.Elevation.Value*1000)/1000
	end
	if (self.GPSCord) then
		txt = txt .. "\nWorldPos = " .. math.Round(self.Outputs.World_X.Value*1000)/1000 .. "," .. math.Round(self.Outputs.World_Y.Value*1000)/1000 .. "," .. math.Round(self.Outputs.World_Z.Value*1000)/1000
	end

	self:SetOverlayText(txt)
end


function ENT:TriggerOutputs(dist, brng, distc, gpscords)
    if (self.OutDist) then
		Wire_TriggerOutput(self.Entity, "Distance", dist)
	end
	if (self.XYZMode) then
	    Wire_TriggerOutput(self.Entity, "X", distc.x)
	    Wire_TriggerOutput(self.Entity, "Y", distc.y)
	    Wire_TriggerOutput(self.Entity, "Z", distc.z)
	end
	if (self.GPSCord) then
	    Wire_TriggerOutput(self.Entity, "World_X", gpscords.x)
	    Wire_TriggerOutput(self.Entity, "World_Y", gpscords.y)
	    Wire_TriggerOutput(self.Entity, "World_Z", gpscords.z)
	end
	if (self.OutBrng) then
		local pitch = brng.p
		local yaw = brng.y
		
		if (pitch > 180) then pitch = pitch - 360 end
		if (yaw > 180) then yaw = yaw - 360 end
		
		Wire_TriggerOutput(self.Entity, "Bearing", -yaw)
	    Wire_TriggerOutput(self.Entity, "Elevation", -pitch)
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Target") and ( self.ToSense != self.Inputs.Target.Src ) then
		self:SetBeacon(self.Inputs.Target.Src)
	end
end

function ENT:SetBeacon(beacon)
	if (beacon) and (beacon:IsValid()) then
		self.ToSense = beacon
		self.Active = true
	else
		self.ToSense = nil
		self.Active = false
	end
end


function ENT:OnRestore()
	//this is to prevent old save breakage
	self:Setup(self.XYZMode, self.OutDist, self.OutBrng, self.GPSCord, self.SwapYZ)
	
	self.BaseClass.OnRestore(self)
end


function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.ToSense) and (self.ToSense:IsValid()) then
	    info.to_sense = self.ToSense:EntIndex()
	end

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.to_sense) then
		self:SetBeacon(GetEntByID(info.to_sense))
		if (!self.ToSense) then
			self:SetBeacon(ents.GetByIndex(info.to_sense))
		end
	end
end
