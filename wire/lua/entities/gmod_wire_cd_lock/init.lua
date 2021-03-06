AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

ENT.WireDebugName = "CD Lock"

//Time after loosing one disk to search for another
local NEW_DISK_WAIT_TIME = 2
local DISK_IN_SOCKET_CONSTRAINT_POWER = 5000
local DISK_IN_ATTACH_RANGE = 16

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.Const = nil
	self.Disk = nil

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Locked" })
	self:SetOverlayText("CD lock")

	self.Entity:NextThink(CurTime() + 0.25)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Think()
	self.BaseClass.Think(self)

	// If we were undiskged, reset the disk and socket to accept new ones.
	if (self.Const) and (not self.Const:IsValid()) then
		self.Const = nil
		self.Disk.Lock = nil
		self.Disk = nil
		self.NoCollideConst = nil

		Wire_TriggerOutput(self.Entity, "Locked", 0)

		self.Entity:NextThink(CurTime() + NEW_DISK_WAIT_TIME) //Give time before next grabbing a disk.
		return true
	else
		// Find entities near us
		local lockCenter = self:LocalToWorld(Vector(0, 0, 0))
		local local_ents = ents.FindInSphere(lockCenter, DISK_IN_ATTACH_RANGE)
		for key, disk in pairs(local_ents) do
			// If we find a disk, try to attach it to us
			if (disk:IsValid() && disk:GetClass() == "gmod_wire_cd_disk") then
				if (disk.Lock == nil) then
					self:AttachDisk(disk)
				end
			end
		end
	end
	self.Entity:NextThink(CurTime() + 0.25)
end

function ENT:AttachDisk(disk)
	//Position disk
	local min = disk:OBBMins()
	local max = disk:OBBMaxs()

	local newpos = self:LocalToWorld(Vector(0, 0, 0))
	local lockAng = self.Entity:GetAngles()
	disk:SetPos(newpos)
	disk:SetAngles(lockAng)
	
	self.NoCollideConst = constraint.NoCollide(self.Entity, disk, 0, 0)
	if (not self.NoCollideConst) then
		Wire_TriggerOutput(self.Entity, "Locked", 0)
		return
	end

	//Constrain together
	self.Const = constraint.Weld(self.Entity, disk, 0, 0, DISK_IN_SOCKET_CONSTRAINT_POWER, true)
	if (not self.Const) then
	    self.NoCollideConst:Remove()
	    self.NoCollideConst = nil
	    Wire_TriggerOutput(self.Entity, "Locked", 0)
	    return
	end

	//Prepare clearup incase one is removed
	disk:DeleteOnRemove(self.Const)
	self.Entity:DeleteOnRemove(self.Const)
	self.Const:DeleteOnRemove(self.NoCollideConst)

	disk.Lock = self
	self.Disk = disk
	Wire_TriggerOutput(self.Entity, "Locked", 1)
end

function ENT:OnRestore()
	Wire_Restored(self.Entity)
end

