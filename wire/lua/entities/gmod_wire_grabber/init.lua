
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
	self.ExtraProp = nil
	self.ExtraPropWeld = nil
	self.Gravity = true
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

function ENT:Setup(Range,Gravity)
    self:SetBeamRange(Range)
    self.Gravity = Gravity
    Msg("Setup:\n\tRange:"..tostring(Range).."\n\tGravity:"..tostring(Gravity).."\n")
end

function ENT:ResetGrab()
    if(self.Weld && self.Weld:IsValid())then
        self.Weld:Remove()
        Msg("-Weld1\n")
        if(self.WeldEntity)then
            if(self.WeldEntity:IsValid())then
                self.WeldEntity:GetPhysicsObject():EnableGravity(true)
            end
        end
    end
    if(self.ExtraPropWeld && self.ExtraPropWeld:IsValid())then
        self.ExtraPropWeld:Remove()
        Msg("-Weld2\n")
    end                
                
    self.Weld = nil
    self.WeldEntity = nil
    self.ExtraPropWeld = nil
                
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
			if (  (!trace.Entity:IsValid() && trace.Entity != GetWorldEntity())  || trace.Entity:IsPlayer() ) then return end
			// If there's no physics object then we can't constraint it!
			if ( !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return end
			
			if( self.OnlyGrabOwners)then
			     if(trace.Entity.Owner != self.Owner)then return false end
			end
			// Weld them!
			local const = constraint.Weld(self.Entity, trace.Entity, 0, 0, self.WeldStrength)
			local const2
			Msg("+Weld1\n")
			if(self.ExtraProp)then
			     if(self.ExtraProp:IsValid())then
			         const2 = constraint.Weld(self.ExtraProp, trace.Entity, 0, 0, self.WeldStrength)
			         Msg("+Weld2\n")
			     end
			end
			if(self.Gravity)then
			     trace.Entity:GetPhysicsObject():EnableGravity(false)
			end
			
			self.WeldEntity = trace.Entity
			self.Weld = const
			self.ExtraPropWeld = const2
			
			self.Entity:SetColor(255, 0, 0, 255)
			Wire_TriggerOutput(self.Entity, "Holding", 1)
		else
			if(self.Weld != nil || self.ExtraPropWeld != nil)then
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

