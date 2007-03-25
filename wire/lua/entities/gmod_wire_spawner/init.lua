
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()

	self.Entity:SetMoveType( MOVETYPE_NONE )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self.Entity:DrawShadow( false )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then phys:Wake() end
	
	self.UndoList = {}

	// Spawner is "edge-triggered"
	self.SpawnLastValue = 0
	self.UndoLastValue = 0

	// Made more efficient by updating the overlay text and
	// Wire output only when number of active props changes (TheApathetic)
	self.CurrentPropCount = 0

	// Add inputs/outputs (TheApathetic)
	self.Inputs = Wire_CreateInputs(self.Entity, {"Spawn", "Undo"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Out"})
end

function ENT:SetDelays( delay, undo_delay )
	self.delay = delay
	self.undo_delay = undo_delay
	self:ShowOutput()
end

function ENT:GetCreationDelay()	return self.delay	end
function ENT:GetDeletionDelay()	return self.undo_delay	end

function ENT:OnTakeDamage( dmginfo )	self.Entity:TakePhysicsDamage( dmginfo ) end


function ENT:DoSpawn( pl, down )

	local ent	= self.Entity
	if (!ent:IsValid()) then return end

	local phys	= ent:GetPhysicsObject()
	if (!phys:IsValid()) then return end

	local Pos	= ent:GetPos()
	local Ang	= ent:GetAngles()
	local Model	= ent:GetModel()
	local Vel	= phys:GetVelocity()
	local aVel	= phys:GetAngleVelocity()
	local delay	= self:GetDeletionDelay()

	local prop = MakeProp( pl, Pos, Ang, Model, {}, {} )
	if (!prop || !prop:IsValid()) then return end

	local nocollide = constraint.NoCollide( prop, ent, 0, 0 )
	if (nocollide:IsValid()) then prop:DeleteOnRemove( nocollide ) end

	undo.Create("Prop")
		undo.AddEntity( prop )
		undo.AddEntity( nocollide )
		undo.SetPlayer( pl )
	undo.Finish()
	
	pl:AddCleanup( "props", prop )
	pl:AddCleanup( "props", nocollide )

	table.insert( self.UndoList, 1, prop )

	if (delay == 0) then return end

	timer.Simple( delay, function( ent ) if ent:IsValid() then ent:Remove() end end, prop )
	// Update prop count output when prop is deleted (TheApathetic)
	// No longer needed because Think() now updates more often (TheApathetic)
	//timer.Simple(delay + 0.25, function (spawner) Wire_TriggerOutput(spawner, "Out", spawner:GetPropCount()) end, self.Entity)

	// Handled by Think() now
	//Wire_TriggerOutput(self.Entity, "Out", self:GetPropCount())
	//self:ShowOutput()
end

function ENT:DoUndo( pl )

	if (!self.UndoList || #self.UndoList == 0) then return end

	local ent = self.UndoList[	#self.UndoList ]
	self.UndoList[	#self.UndoList ] = nil

	if (!ent || !ent:IsValid()) then
		return self:DoUndo(pl)
	end
	
	ent:Remove()
	umsg.Start( "UndoWireSpawnerProp", pl ) umsg.End()
	
	// Handled by Think() now (TheApathetic)
	//Wire_TriggerOutput(self.Entity, "Out", self:GetPropCount())
	//self:ShowOutput()
end

function ENT:Think()
	self.BaseClass.Think(self)

	// Purge list of no longer existing props
	for i = #self.UndoList,1,-1 do
		local ent = self.UndoList[i]
		if (!ent || !ent:IsValid() || ent:EntIndex() == 0) then
			table.remove(self.UndoList, i)
		end
	end

	// Check to see if active prop count has changed
	if (#self.UndoList != self.CurrentPropCount) then
		self.CurrentPropCount = #self.UndoList
		Wire_TriggerOutput(self.Entity, "Out", self.CurrentPropCount)		
		self:ShowOutput()
	end

	self.Entity:NextThink(CurTime() + 0.1)
	return true
end

/* No longer needed
function ENT:GetPropCount()
	local count = 0
	for _,ent in pairs(self.UndoList) do
		if (ent && ent:IsValid()) then count = count + 1 end
	end

	return count
end
*/

function ENT:TriggerInput(iname, value)
	local pl = self:GetPlayer()

	if (iname == "Spawn") then
		// Spawner is "edge-triggered" (TheApathetic)
		if ((value > 0) == self.SpawnLastValue) then return end
		self.SpawnLastValue = (value > 0)

		if (self.SpawnLastValue) then
			// Simple copy/paste of old numpad Spawn with a few modifications
			local delay = self:GetCreationDelay()
			if (delay == 0) then self:DoSpawn( pl ) return end

			local TimedSpawn = 	function ( ent, pl )
				if (!ent) then return end
				if (!ent == NULL) then return end
				ent:GetTable():DoSpawn( pl )
			end

			timer.Simple( delay, TimedSpawn, self.Entity, pl )
		end
	elseif (iname == "Undo") then
		// Same here
		if ((value > 0) == self.UndoLastValue) then return end
		self.UndoLastValue = (value > 0)

		if (self.UndoLastValue) then self:DoUndo(pl) end
	end
end

function ENT:ShowOutput()
	self:SetOverlayText("Spawn Delay: "..self:GetCreationDelay().."\nUndo Delay: "..self:GetDeletionDelay().."\nActive Props: "..self.CurrentPropCount)
end