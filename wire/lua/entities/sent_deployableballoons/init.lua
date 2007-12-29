AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local material 	= "cable/rope"

function ENT:SpawnFunction( ply, tr )
	if (not tr.Hit) then return end
	local SpawnPos = tr.HitPos+tr.HitNormal*16
	local ent = ents.Create("sent_deployableballoons")
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
	self.Deployed = 0
	self.Balloon = 0
	self.Constraints = {}
	self.force = 500
	self.weld = false
	self.popable = false
	self.rl = 64
	if WireAddon then
		self.Inputs = Wire_CreateInputs(self.Entity,{ "Deploy", "Force", "Lenght", "Weld?", "Popable?"})
		self.Outputs = Wire_CreateOutputs(self.Entity,{ "Deployed"})
		Wire_TriggerOutput(self.Entity,"Deployed", self.Deployed)
		Wire_TriggerOutput(self.Entity,"Force", self.force)
	end
	local phys = self.Entity:GetPhysicsObject()
	if(phys:IsValid()) then
		phys:SetMass(250)
		phys:Wake()
	end
end

function ENT:TriggerInput(key,value)
	if (key == "Deploy") then
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
	elseif (key == "Force") then
		self.force = value
		if self.Deployed == 1 then
			self.Balloon:SetForce(value)
		end
	elseif (key == "Lenght") then
		self.rl = value
	elseif (key == "Weld?") then
		self.weld = value > 0
	elseif (key == "Popable?") then
		self.popable = value > 0
	end
end

function ENT:DeployBalloons()
	local balloon
	if self.popable then
		balloon = ents.Create("gmod_balloon") --normal balloon
	else
		balloon = ents.Create("gmod_iballoon") --invincible balloon
	end
	balloon:Spawn()
	balloon:SetRenderMode( RENDERMODE_TRANSALPHA )
	balloon:SetColor(math.random(0,255), math.random(0,255), math.random(0,255), 255 )
	balloon:SetForce(self.force)
	balloon:SetMaterial("models/balloon/balloon")
	duplicator.DoGeneric(balloon,{Pos = self.Entity:GetPos() + (self.Entity:GetUp()*25)})
	duplicator.DoGenericPhysics(balloon,pl,{Pos = Pos})
	local spawnervec = (self.Entity:GetPos()-balloon:GetPos()):Normalize()*250 --just to be sure
	local trace = util.QuickTrace(balloon:GetPos(),spawnervec,balloon)
	local Pos = self.Entity:GetPos()+(self.Entity:GetUp()*25)
	local attachpoint = Pos + Vector(0,0,-10)	
	local LPos1 = balloon:WorldToLocal(attachpoint)
	local LPos2 = trace.Entity:WorldToLocal(trace.HitPos)
	local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone)
	if(phys:IsValid()) then
		LPos2 = phys:WorldToLocal(trace.HitPos)
	end
	if self.weld then
		local constraint = constraint.Weld( balloon, trace.Entity, 0, trace.PhysicsBone, 0)
		balloon:DeleteOnRemove(constraint)
	else
		local constraint, rope = constraint.Rope(balloon,trace.Entity,0,trace.PhysicsBone,LPos1,LPos2,0,self.rl,0,1.5,material,nil)
		balloon:DeleteOnRemove(constraint)
		balloon:DeleteOnRemove(rope)
	end
	self.Entity:DeleteOnRemove(balloon)
	self.Balloon = balloon
end

function ENT:RetractBalloons()
	if self.Balloon:IsValid() then
		local r, g, b = self.Balloon:GetColor()
		local effectdata = EffectData()
			effectdata:SetOrigin( self.Balloon:GetPos() )
			effectdata:SetStart( Vector( r, g, b ) )
		util.Effect( "balloon_pop", effectdata )
		self.Balloon:Remove()
	else
		self.Balloon = nil
	end
end
