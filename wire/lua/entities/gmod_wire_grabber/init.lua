
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Grabber"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "Grab" })
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Holding"})
	self.Weld = nil
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Grab") then
		if (value ~= 0 && self.Weld == nil) then
			 local vStart = self.Entity:GetPos()
			 local vForward = self.Entity:GetUp()
			 
			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * 100)
				 trace.filter = { self.Entity }
			 local trace = util.TraceLine( trace ) 
			
			// Bail if we hit world or a player
			if (  !trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return end
			// If there's no physics object then we can't constraint it!
			if ( !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return end
			// Weld them!
			local const = constraint.Weld(self.Entity, trace.Entity, 0, 0, 0)
			
			self.Weld = const
			
			self.Entity:SetColor(255, 0, 0, 255)
			Wire_TriggerOutput(self.Entity, "Holding", 1)
		else
			if(self.Weld != nil)then
				if(self.Weld && self.Weld:IsValid())then
                    self.Weld:Remove()
                end
                self.Weld = nil
                self.Entity:SetColor(255,255,255,255)
                Wire_TriggerOutput(self.Entity,"Holding",0)
	        end
		end
    end
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "Grabber" )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

