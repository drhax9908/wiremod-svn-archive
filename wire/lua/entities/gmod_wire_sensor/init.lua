
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

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup(xyz_mode, outdist, outbrng)
	self.XYZMode = xyz_mode
	self.PrevOutput = nil
	self.Value = 0
	self.OutDist = outdist
	self.OutBrng = outbrng
	
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

	Wire_AdjustOutputs(self.Entity, onames)
	self:TriggerOutputs(0, Angle(0, 0, 0),Vector(0, 0, 0))
	self:ShowOutput()
end

function ENT:Think()
	self.BaseClass.Think(self)

	if( !self.ToSense or !self.ToSense:IsValid() ) then	return end
	if (self.Active) then
	    local dist = 0
	    local distc = Vector(0, 0, 0)
	    local brng = Angle(0, 0, 0)
		local MyPos = self.Entity:GetPos()
		local BeaconPos = self.ToSense:GetBeaconPos(self.Entity)
		if (self.OutDist) then
			dist = (BeaconPos-MyPos):Length()
		end
		if (self.XYZMode) then
			local DeltaPos = self.Entity:WorldToLocal(BeaconPos)
			distc = Vector(-DeltaPos.y, DeltaPos.x, DeltaPos.z)
		end
		if (self.OutBrng) then
		    local DeltaPos = self.Entity:WorldToLocal(BeaconPos)
		    brng = DeltaPos:Angle()
		end

		self:TriggerOutputs(dist, brng, distc)
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

	self:SetOverlayText(txt)
end


function ENT:TriggerOutputs(dist, brng, distc)
    Wire_TriggerOutput(self.Entity, "Distance", dist)
    Wire_TriggerOutput(self.Entity, "X", distc.x)
    Wire_TriggerOutput(self.Entity, "Y", distc.y)
    Wire_TriggerOutput(self.Entity, "Z", distc.z)
	
	local pitch = brng.p
	local yaw = brng.y
	
	if (pitch > 180) then pitch = pitch - 360 end
	if (yaw > 180) then yaw = yaw - 360 end

    Wire_TriggerOutput(self.Entity, "Bearing", -yaw)
    Wire_TriggerOutput(self.Entity, "Elevation", -pitch)
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


function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.ToSense) and (self.ToSense:IsValid()) then
	    info.to_sense = self.ToSense:EntIndex()
	end

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID, GetConstByID)

	if (info.to_sense) then
	    self.ToSense = GetEntByID(info.to_sense)
	end
end
