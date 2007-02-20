
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
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end

function ENT:Setup(force, length, showbeam)
	self.Force = force
	self.Tlength = length
	self.value = 0
	if (showbeam) then
		self:SetBeamLength(length)	
	else
		self:SetBeamLength(0)
	end
	self:TriggerInput("A", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		self.value = value
		self:ShowOutput(value)
		if (value != 0) then
			self:Think()
		end
	/*elseif (iname == "B") then
		multiplier = value*/
	end
end

function ENT:Think()
	
	local vForward = self.Entity:GetUp()
	local vStart = self.Entity:GetPos() + vForward*self.Entity:OBBMaxs().z

	local trace = {}
	trace.start = vStart
	trace.endpos = vStart + (vForward * self.Tlength)
	trace.filter = { self.Entity }
	--print("Trace")
	local trace = util.TraceLine( trace ) 

	// Bail if we hit world or a player
	if (  !trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return end
	--print("Ent is valid and not player")
	if ( trace.Entity:GetClass() != "prop_physics" ) then return end
	
	local phys = trace.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		--print("Applying force: "..tostring(vForward * self.Force * self.value))
		phys:ApplyForceCenter( vForward * self.Force * self.value )
	end
	
	//self.Entity:NextThink(CurTime() + 0.05)
	//return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText("Forcer\n"..tostring(math.Round(value * self.Force)))
end
