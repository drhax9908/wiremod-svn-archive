
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Forcer"
ENT.OverlayDelay = 0

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.F = 0
	self.FoO = 0
	self.V = 0
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "Force", "OffsetForce", "Velocity" })
end

function ENT:Setup(force, length, showbeam)
	self.Force = math.max(force, 1)
	self.Tlength = math.max(length, 1)
	self.F = 0
	self.FoO = 0
	self.V = 0
	if (showbeam) then
		self:SetBeamLength(length)	
	else
		self:SetBeamLength(0)
	end
	self:TriggerInput("Force", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Force") then
		self.F = value
		self:ShowOutput()
		if (value > 0) then self:Think() end
	elseif (iname == "OffsetForce") then
		self.FoO = value
		self:ShowOutput()
		if (value > 0) then self:Think() end
	elseif (iname == "Velocity") then
		self.V = value
		self:ShowOutput()
		if (value > 0) then self:Think() end
	end
end

function ENT:Think()
	local vForward = self.Entity:GetUp()
	local vStart = self.Entity:GetPos() + vForward*self.Entity:OBBMaxs().z

	local trace = {}
	trace.start = vStart
	trace.endpos = vStart + (vForward * self.Tlength)
	trace.filter = { self.Entity }
	
	local trace = util.TraceLine( trace )
	
	if (trace.Entity) and (trace.Entity:IsValid()) then // and (!trace.Entity:IsPlayer()) then
		
		if (trace.Entity:GetMoveType() == MOVETYPE_VPHYSICS) then
			local phys = trace.Entity:GetPhysicsObject()
			if (phys:IsValid()) then
				if (self.F > 0) then phys:ApplyForceCenter( vForward * self.Force * self.F ) end
				if (self.FoO > 0) then phys:ApplyForceOffset( vForward * self.FoO, trace.HitPos ) end
				if (self.V > 0) then phys:SetVelocity( vForward * self.V ) end
			end
		else
			if (self.V > 0) then trace.Entity:SetVelocity( vForward * self.V ) end
		end
		
	end
	
	self.Entity:NextThink(CurTime() + 0.05)
	return true
end

function ENT:ShowOutput()
	self:SetOverlayText(
		"Forcer\nCenter Force= "..tostring(math.Round(self.F * self.Force))..
		"\nOffset Force= "..tostring(math.Round(self.FoO))..
		"\nVelocity= "..tostring(math.Round(self.V))
	)
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	//Moves old "A" input to new "Force" input for older saves
	if (info.Wires) and (info.Wires.A) then
		info.Wires.Force = info.Wires.A
		info.Wires.A = nil
	end
	
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end
