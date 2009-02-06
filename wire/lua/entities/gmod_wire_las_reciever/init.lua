
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Laser Receiver"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity,{"X","Y","Z","Active","Pos"},{"NORMAL","NORMAL","NORMAL","NORMAL","VECTOR"})
	self.VPos = Vector(0,0,0)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup()
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Laser Receiver" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

