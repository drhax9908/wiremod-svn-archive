
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
	self.Inputs = Wire_CreateInputs(self.Entity, { "Grab","Strength" })
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Holding"})
	self.WeldStrength = 0
	self.Weld = nil
	self.WeldEntity = nil
	self.Entity:GetPhysicsObject():SetMass(200)
	
	self:SetBeamRange(100)
	
	if(GetConVarNumber('sbox_wire_grabbers_onlyOwnersProps') > 0)then
		self.OnlyGrabOwners = true
	else
		self.OnlyGrabOwners = false
	end
	
	self:ShowOutput()
end

function ENT:OnRemove()
    if(self.Weld != nil)then
		self:ResetGrab()
	end
	Wire_Remove(self.Entity)
end

function ENT:Setup(Range)
    self:SetBeamRange(Range)
    Msg("Setup:/n/tRange:"..tostring(Range).."/n")
end

function ENT:ResetGrab()
    if(self.Weld && self.Weld:IsValid())then
        self.Weld:Remove()
        if(self.WeldEntity)then
            if(self.WeldEntity:IsValid())then
                self.WeldEntity:GetPhysicsObject():EnableGravity(true)
            end
        end
    end                
                
    self.Weld = nil
    self.WeldEntity = nil
                
    self.Entity:SetColor(255,255,255,255)
    Wire_TriggerOutput(self.Entity,"Holding",0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Grab") then
		if (value ~= 0 && self.Weld == nil) then
			 local vStart = self.Entity:GetPos()
			 local vForward = self.Entity:GetUp()
			 
			 local trace = {}
				 trace.start = vStart
				 trace.endpos = vStart + (vForward * self:GetBeamRange())
				 trace.filter = { self.Entity }
			 local trace = util.TraceLine( trace ) 
			
			// Bail if we hit world or a player
			if (  !trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return end
			// If there's no physics object then we can't constraint it!
			if ( !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return end
			
			if( self.OnlyGrabOwners)then
			     if(trace.Entity.Owner != self.Owner)then return false end
			end
			// Weld them!
			local const = constraint.Weld(self.Entity, trace.Entity, 0, 0, self.WeldStrength)
			trace.Entity:GetPhysicsObject():EnableGravity(false)
			
			self.WeldEntity = trace.Entity
			self.Weld = const
			
			self.Entity:SetColor(255, 0, 0, 255)
			Wire_TriggerOutput(self.Entity, "Holding", 1)
		else
			if(self.Weld != nil)then
				self:ResetGrab()
	        end
		end
    elseif(iname == "Strength")then
        self.WeldStrength = math.max(value,0)
    end
end

function ENT:ShowOutput()
	self:SetOverlayText( "Grabber" )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

