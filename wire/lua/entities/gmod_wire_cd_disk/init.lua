AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

ENT.WireDebugName = "CD"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
//	self.Entity:SetModel(MODEL)
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	self.DiskMemory = {}
	self.Precision = 1 //1 unit
	self.IRadius = 12 //units

	//Use Z axis for Sector address
	//Use XY radius for Track address
	//Use Z height for Stack address
	self:Setup()
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	info.Precision = self.Precision
	info.IRadius = self.IRadius
	info.DiskMemory = self.DiskMemory

	return info
end


function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	self.Precision = info.Precision
	self.IRadius = info.IRadius
	self.DiskMemory = info.DiskMemory
	self:Setup()
end

function ENT:Setup()
	local min = self:OBBMins()
	local max = self:OBBMaxs()

	self.Precision = math.floor(math.Clamp(self.Precision,1,64))
	self.IRadius = math.max(self.IRadius,0)

	self.StackStartHeight = -min.z

	self.DiskStacks = math.floor((max.z - min.z) / self.Precision)+1
	self.DiskTracks = math.floor(0.5*math.min(max.x - min.x,max.y - min.y) / self.Precision)

	self.DiskSectors = 0
	self.TrackSectors = {}
	self.FirstTrack = math.floor((self.IRadius) / self.Precision)
	for i=self.FirstTrack,self.DiskTracks-1 do
		self.TrackSectors[i] = self.DiskSectors
		self.DiskSectors = self.DiskSectors + math.floor(2*3.1415926*i) + 1
	end

	self.DiskVolume = self.DiskSectors*self.DiskStacks
	self.BytesPerBlock = 512//*self.Precision
	self.DiskSize = self.DiskSectors*self.BytesPerBlock

//	print("Precision: "..(self.Precision))
//	print("H: "..(max.z - min.z))
//	print("R: "..(0.5*((max.x - min.x)^2+(max.y - min.y)^2)^0.5))
//	print("Disk stacks: "..self.DiskStacks)
//	print("Disk tracks: "..self.DiskTracks)
//	print("Disk sectors total: "..self.DiskSectors)
//	print("Disk volume "..self.DiskVolume)

	self:ShowOutput()
end

function ENT:ShowOutput()
	self:SetOverlayText("CD disk\nEffective size (per stack): "..self.DiskSize.." bytes ("..math.floor(self.DiskSize/1024).." kb)\n"..
			    "Tracks: "..self.DiskTracks.."\nSectors: "..self.DiskSectors.."\nStacks: "..self.DiskStacks)
end
