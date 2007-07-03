AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

local material 	= "cable/rope"

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create( "sent_deployableballoons" )
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self.Entity:SetModel("models/props_junk/PropaneCanister001a.mdl")
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid(SOLID_VPHYSICS)
	local phys = self.Entity:GetPhysicsObject()
	if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "Deploy", "Force", "Lenght", "Weld?"}) end
	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "Deployed"}) end
	self.Deployed 			= 0
	self.Balloon			= 0
	self.Constrants			= {}
	self.force				= 500
	self.weld				= 0
	self.rl 				= 64
	self.amount			= 1 --should not change
	Wire_TriggerOutput(self.Entity, "Deployed", self.Deployed)
	Wire_TriggerOutput(self.Entity, "Force", self.force)
	if (phys:IsValid()) then
		phys:SetMass(250)
		phys:Wake()
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "Deploy") then
		if value > 0 then
			if self.Deployed == 0 then
				self:DeployBalloons()
				self.Deployed = 1
			end
			Wire_TriggerOutput(self.Entity, "Deployed", self.Deployed)
		else
			if self.Deployed == 1 then
				self:RetractBalloons()
				self.Deployed = 0
			end
			Wire_TriggerOutput(self.Entity, "Deployed", self.Deployed)
		end
	elseif (iname == "Force") then
		self.force = value
		if self.Deployed == 1 then
			self.Balloon:SetForce(value)
		end
	elseif (iname == "Lenght") then
		self.rl = value
	elseif (iname == "Weld?") then
		if value > 0 then
			self.weld = 1
		else
			self.weld = 0
		end
	end
end

function ENT:DeployBalloons()
	self.BalloonsAndStuff = {} --reset array
	for i=1,self.amount do
		local balloon = ents.Create( "gmod_iballoon" ) --invincible balloon
		duplicator.DoGeneric(balloon, {Pos = self.Entity:GetPos() + (self.Entity:GetUp()*25)})
		balloon:Spawn()
		duplicator.DoGenericPhysics( balloon, pl, {Pos = Pos})
		balloon:SetRenderMode( RENDERMODE_TRANSALPHA )
		balloon:SetColor(math.random(0,255), math.random(0,255), math.random(0,255), 255 )
		balloon:SetForce(self.force)
		balloon:SetMaterial("models/balloon/balloon")
		local spawnervec = (self.Entity:GetPos()-balloon:GetPos()):Normalize()*250 --just to be sure
		local trace = util.QuickTrace(balloon:GetPos(), spawnervec, balloon)
		local Pos = self.Entity:GetPos() + (self.Entity:GetUp()*25)
		local attachpoint = Pos + Vector( 0, 0, -10 )	
		local LPos1 = balloon:WorldToLocal( attachpoint )
		local LPos2 = trace.Entity:WorldToLocal( trace.HitPos )
		local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		if (phys:IsValid()) then
			LPos2 = phys:WorldToLocal( trace.HitPos )
		end
		if self.weld == 1 then
			local constraint = constraint.Weld( balloon, trace.Entity, 0, trace.PhysicsBone, 0)
			table.insert(self.Constrants, constraint)
		else
			local constraint, rope = constraint.Rope( balloon, trace.Entity, 0, trace.PhysicsBone, LPos1, LPos2, 0,self.rl,0, 1.5, material, nil )
			table.insert(self.Constrants, constraint)
			table.insert(self.Constrants, rope)
		end
		self.Balloon = balloon
	end
end

function ENT:RetractBalloons()
	for k,v in pairs(self.Constrants) do
		table.remove(self.Constrants, k)
		v:Remove()
	end
	self.Balloon:Remove()
end
