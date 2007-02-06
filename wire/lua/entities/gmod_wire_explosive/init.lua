
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Explosive"
ENT.OverlayDelay = 0

/*---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------*/
function ENT:Initialize()

	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	self.exploding = false
	self.reloading = false
	self.NormInfo = ""
	self.count = 0
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "Detonate", "ResetHealth" })
	
	self.Entity:SetMaxHealth(100)
	self.Entity:SetHealth(100)
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Health" })
end

/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if (iname == "Detonate") then
		if ( !self.exploding && !self.reloading ) then
			if ( math.abs(value) == self.key ) then
				self:Trigger()
			end
		end
	elseif (iname == "ResetHealth") then
		self:ResetHealth()
	end
end

/*---------------------------------------------------------
   Name: Setup
   Desc: does a whole lot of setting up
---------------------------------------------------------*/
function ENT:Setup( damage, delaytime, removeafter, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, invisibleatzero, nocollide )

	self.Damage = damage 
	self.Delayetime = delaytime
	self.Removeafter = removeafter
	self.DoBlastDamage = doblastdamage
	self.Radius = radius
	self.Affectother = affectother
	self.Notaffected = notaffected
	self.Delayreloadtime = delayreloadtime
	
	self.BulletProof = bulletproof
	self.ExplosionProof = explosionproof
	self.FallProof = fallproof
	
	self.ExplodeAtZero = explodeatzero
	self.ResetAtExplode = resetatexplode
	
	self.FireEffect = fireeffect
	self.ColorEffect = coloreffect
	self.NoCollide = nocollide
	self.InvisibleAtZero = invisibleatzero
	
	self.Entity:SetMaxHealth(maxhealth)
	self:ResetHealth()


	//self.Entity:SetHealth(maxhealth)
	//Wire_TriggerOutput(self.Entity, "Health", maxhealth)
	
	//reset everthing back and try to stop exploding
	//self.exploding = false
	//self.reloading = false
	//self.count = 0
	//self.Entity:Extinguish()
	//if (self.ColorEffect) then self.Entity:SetColor(255, 255, 255, 255) end
	
	self.NormInfo = "Explosive"
	if (self.DoBlastDamage) then self.NormInfo = self.NormInfo.." (Damage: "..self.Damage..")" end
	if (self.Radius > 0 || self.Delayetime > 0) then self.NormInfo = self.NormInfo.."\n" end
	if (self.Radius > 0 ) then self.NormInfo = self.NormInfo.." Rad: "..self.Radius end
	if (self.Delayetime > 0) then self.NormInfo = self.NormInfo.." Delay: "..self.Delayetime end
	
	self:ShowOutput()
	
end

function ENT:ResetHealth( )
	self.Entity:SetHealth( self.Entity:GetMaxHealth() )
	Wire_TriggerOutput(self.Entity, "Health", self.Entity:GetMaxHealth())
	
	//put the fires out and try to stop exploding
	self.exploding = false
	self.reloading = false
	self.count = 0
	self.Entity:Extinguish()
	
	if (self.ColorEffect) then self.Entity:SetColor(255, 255, 255, 255) end
	
	self.Entity:SetNoDraw( false )
	
	if (self.NoCollide) then
		self.Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	else
		self.Entity:SetCollisionGroup(COLLISION_GROUP_NONE)
	end
	
	self:ShowOutput()
end


/*---------------------------------------------------------
   Name: OnTakeDamage
   Desc: Entity takes damage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )

	if ( dmginfo:GetInflictor():GetClass() == "gmod_wire_explosive"  && !self.Affectother ) then return end
	
	if ( !self.Notaffected ) then self.Entity:TakePhysicsDamage( dmginfo ) end
	
	if (dmginfo:IsBulletDamage() && self.BulletProof) || 
		(dmginfo:IsExplosionDamage() && self.ExplosionProof) || 
		(dmginfo:IsFallDamage() && self.FallProof) then return end //fix fall damage, it doesn't happen
	
	if (self.Entity:Health() > 0) then //don't need to beat a dead horse
		dammage = dmginfo:GetDamage()
		h = self.Entity:Health() - dammage
		if (h < 0) then h = 0 end
		self.Entity:SetHealth(h)
		Wire_TriggerOutput(self.Entity, "Health", h)
		self:ShowOutput()
		if (self.ColorEffect) then 
			if (h == 0) then c = 0 else c = 255 * (h / self.Entity:GetMaxHealth()) end
			self.Entity:SetColor(255, c, c, 255)
		end
		if (h == 0) then
			if (self.ExplodeAtZero) then self:Trigger() end //oh shi--
		end
	end

end

/*---------------------------------------------------------
   Name: Trigger
   Desc: Start exploding
---------------------------------------------------------*/
function ENT:Trigger()
	if ( self.Delayetime > 0 ) then
		self.exploding = true
		if (self.FireEffect) then self.Entity:Ignite((self.Delayetime + 3),0) end
		timer.Simple( self.Delayetime, self.Explode, self )
		self.count = self.Delayetime
		self:Countdown()
	else
		self.exploding = true
		self:Explode()
	end
end

/*---------------------------------------------------------
   Name: Explode
   Desc: is one needed?
---------------------------------------------------------*/
function ENT:Explode( )
	
	if ( !self.Entity:IsValid() ) then return end
	
	self.Entity:Extinguish()
	
	if (!self.exploding) then return end //why are we exploding if we shouldn't be
	
	ply = self.Entity
	
	if (self.InvisibleAtZero) then
		ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ply:SetNoDraw( true )
		ply:SetColor(255, 255, 255, 0)
	end
	
	if ( self.DoBlastDamage ) then
		util.BlastDamage( self.Entity, ply, self.Entity:GetPos(), self.Radius, self.Damage )
	end

	local effectdata = EffectData()
	 effectdata:SetOrigin( self.Entity:GetPos() )
	util.Effect( "Explosion", effectdata, true, true )
	
	if ( self.Removeafter ) then
		self.Entity:Remove()
		return
	end
	
	self.exploding = false
	
	
	
	if ( self.Delayreloadtime > 0 ) then
		//t = self.Delayreloadtime + 1
		self.reloading = true
		timer.Simple( self.Delayreloadtime, self.Reloaded, self )
		self.count = self.Delayreloadtime
		self:Countdown()
	else //keep it from going off again for at least another second
		self.reloading = true
		timer.Simple( 1, self.Reloaded, self )
		self:ShowOutput(0)
	end
	
end

function ENT:Reloaded( )
	self.reloading = false
	if (self.ResetAtExplode) then self:ResetHealth() end
end

function ENT:Countdown( )
	self:ShowOutput()
	self.count = self.count - 1
	if ( self.count > 0 ) then //theres still time left
		timer.Simple( 1, self.Countdown, self )
	else //will be done after this second
		timer.Simple( 1, self.ShowOutput, self )
	end
end

/*---------------------------------------------------------
   Name: ShowOutput
   Desc: don't foreget to call this when changes happen
---------------------------------------------------------*/
function ENT:ShowOutput( )
	local txt = ""
	if (self.reloading && self.Delayreloadtime > 0) then
		txt = "Rearming... "..self.count
		if (self.ColorEffect && !self.InvisibleAtZero) then 
			if (self.count == 0) then c = 255 else c = 255 * ((self.Delayreloadtime - self.count) / self.Delayreloadtime) end
			self.Entity:SetColor(255, c, c, 255)
		end
		if (self.InvisibleAtZero) then
			ply:SetNoDraw( false )
			if (self.count == 0) then c = 255 else c = 255 * ((self.Delayreloadtime - self.count) / self.Delayreloadtime) end
			self.Entity:SetColor(255, 255, 255, c)
		end
	elseif (self.exploding) then
		txt = "Triggered... "..self.count
	else
		txt = self.NormInfo.."\nHealth: "..self.Entity:Health().."/"..self.Entity:GetMaxHealth()
	end
	self:SetOverlayText(txt)
end
