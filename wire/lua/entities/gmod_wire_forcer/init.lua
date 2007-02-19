
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = ""

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "B" })
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(force, length)
	self:TriggerInput("A", 0)
	self.Force = force
	self.Tlength = length
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		if (value ~= 0) then
			 local vStart = self.Entity:GetPos()
			 local vForward = self.Entity:GetUp()
			 
			 local trace = {}
			 trace.start = vStart
			 trace.endpos = vStart + (vForward * self.Tlength)
			 trace.filter = { self.Entity }
			 --print("Trace")
			 local trace = util.TraceLine( trace ) 
			
			// Bail if we hit world or a player
			if (  !trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return end
			--print("Ent is valid and not player")
			if ( CLIENT && trace.Entity:GetClass() != "prop_physics" ) then return end
			--print("Applying force: "..tostring(self.Entity:GetUp() * self.Force * value))
			trace.Entity:GetPhysicsObject():ApplyForceCenter( self.Entity:GetUp() * self.Force * value )
		end
	end
	--[[
	if (iname == "B") then
		multiplier = value
	end
	]]
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Forcer" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

