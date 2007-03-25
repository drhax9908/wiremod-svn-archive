//Advanced Duplicator Paster by TAD2020
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Paster"
ENT.OverlayDelay = 0

local MODEL = Model( "models/props_lab/powerbox02d.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	/*self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )*/
	//self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Entity:SetMoveType( MOVETYPE_NONE )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self.Entity:DrawShadow( false )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then phys:Wake() end
	
	self.UndoListEnts	= {}
	self.UndoListConsts	= {}
	self.PropCount	= 0

	// Spawner is "edge-triggered"
	self.SpawnLastValue	= 0
	self.UndoLastValue	= 0

	// Add inputs/outputs (TheApathetic)
	self.Inputs = Wire_CreateInputs(self.Entity, {"Spawn", "Undo", "X", "Y", "Z" })
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Out"})
	
	self.stage = 0
	self.thinkdelay = 0.05
	
	self.Ents,self.Constraints,self.DupeInfo,self.offset = nil,nil,nil,nil
	self.constIDtable, self.entIDtable, self.CreatedConstraints, self.CreatedEnts, self.TempMoveTypes = {}, {}, {}, {}, {}
	
end

function ENT:Setup(ents, const, holdangle, delay, undo_delay, max_range, show_beam)
	
	self.MyEnts 			= ents
	self.MyConstraints 		= const
	self.MyHoldAngle		= holdangle
	//self.MyDupeInfo 		= dupeinfo
	//self.MyDORInfo 			= dorinfo
	//self.HeadEntID			= headentid
	self.delay				= delay
	self.undo_delay			= undo_delay
	self.MaxRange			= max_range
	self.ShowBeam			= show_beam
	
	self:ShowOutput()
	
	if (show_beam) then
		self:SetBeamLength(math.min(self.MaxRange, 2000))
	else
		self:SetBeamLength(0)
	end
	
	//self:Paste()
end

function ENT:OnTakeDamage( dmginfo )	self.Entity:TakePhysicsDamage( dmginfo ) end

/*function ENT:Use( activator, caller, type, value )
	
	local Owner = self:GetPlayer()
	
	if ((Owner == nil or Owner == activator) and self.stage == 0) then
		self:Paste()
		return true
	else
		return false
	end
end*/

function ENT:Paste()
	//if (self.stage != 0) then return end
	--Msg("====start====\n")
	//self:HideGhost(true)
	//self.Ents 			= table.Copy(self.MyEnts)
	//self.Constraints 	= table.Copy(self.MyConstraints)
	//self.DupeInfo 		= table.Copy(self.MyDupeInfo)
	//self.DORInfo 		= table.Copy(self.MyDORInfo)
	
	if (self.MaxRange > 0) then
		local skew		= Vector(self:GetSkewX(), self:GetSkewY(), 1)
		skew			= skew*((self.MaxRange + self:GetSkewZ())/skew:Length())
		local beam_x	= self.Entity:GetRight()*skew.x
		local beam_y	= self.Entity:GetForward()*skew.y
		local beam_z	= self.Entity:GetUp()*skew.z
		local trace		= {}
		trace.start		= self.Entity:GetPos() + self.Entity:GetUp()*self.Entity:OBBMaxs().z
		trace.endpos	= trace.start + beam_x + beam_y + beam_z
		local trace		= util.TraceLine(trace)
		self.offset		= trace.HitPos
	else
		self.offset = self.Entity:GetPos() + self.Entity:GetUp() * self.Entity:OBBMaxs().z
	end
	
	local angle  = self.Entity:GetAngles()
	angle.pitch = 0
	angle.roll = 0
	
	AdvDupe.ConvertEntityPositionsToWorld( self.MyEnts, self.offset, angle - self.MyHoldAngle )
	AdvDupe.ConvertConstraintPositionsToWorld( self.MyConstraints, self.offset, angle - self.MyHoldAngle )
	
	Msg("===doing paster paste===\n")
	local Ents, Constraints = duplicator.Paste( self:GetPlayer(), self.MyEnts, self.MyConstraints )
	
	AdvDupe.ResetPositions( self.MyEnts, self.MyConstraints )
	
	// Add all of the created entities
	//  to the undo system under one undo.
	undo.Create( "Duplicator" )
		
		self.UndoListEnts[self.PropCount] = {}
		for k, ent in pairs( Ents ) do
			undo.AddEntity( ent )
			self:GetPlayer():AddCleanup( "duplicates", ent )
			table.insert(self.UndoListEnts[self.PropCount], ent:EntIndex())
		end
		
		undo.SetPlayer( self:GetPlayer() )
		
	undo.Finish()
	
	self.PropCount = self.PropCount + 1
	
	self:ShowOutput()
	
	--Msg("going to stage 1\n")
	//self.stage = 1
end



function ENT:TriggerInput(iname, value)
	local pl = self:GetPlayer()
	
	if (iname == "Spawn") then
		// Spawner is "edge-triggered" (TheApathetic)
		if ((value > 0) == self.SpawnLastValue) then return end
		self.SpawnLastValue = (value > 0)
		
		if (self.SpawnLastValue) then
			// Simple copy/paste of old numpad Spawn with a few modifications
			if (self.delay == 0) then self:Paste() return end
			
			local TimedSpawn = 	function ( ent, pl )
				if (!ent) then return end
				if (!ent == NULL) then return end
				ent:GetTable():Paste()
			end
			
			timer.Simple( self.delay, TimedSpawn, self.Entity, pl )
		end
	elseif (iname == "Undo") then
		// Same here
		if ((value > 0) == self.UndoLastValue) then return end
		self.UndoLastValue = (value > 0)

		if (self.UndoLastValue) then self:DoUndo(pl) end
	elseif (iname == "X") then
		self:SetSkewX(self.Inputs.X.Value or 0)
	elseif (iname == "Y") then
		self:SetSkewY(self.Inputs.Y.Value or 0)
	elseif (iname == "Z") then
		if (self.ShowBeam) then
			self:SetBeamLength(math.min((self.MaxRange + value), 2000))
		end
		self.SkewZ = math.min(value, -self.MaxRange)
	end
end


function ENT:ShowOutput()
	self:SetOverlayText("Spawn Delay: "..self.delay.."\nUndo Delay: "..self.undo_delay.."\nCurrent Props: "..self.PropCount)
	Wire_TriggerOutput(self.Entity, "Out", self.PropCount)
end

function ENT:HideGhost(hide)
	local tool = self:GetPlayer():GetActiveWeapon()
	if ( tool:GetClass() == "gmod_tool" )
	and (tool:GetTable():GetToolObject().Name == "Advanced Duplicator") then
		tool:GetTable():GetToolObject():HideGhost(hide)
	end
end




function ENT:DoUndo( pl )

	if (!self.UndoListEnts || #self.UndoListEnts == 0) then return end

	local Ents = table.remove(self.UndoListEnts, 1)
	
	for _, entindex in pairs( Ents ) do
		local ent = ents.GetByIndex( entindex )
		if (ent && ent:IsValid()) then
			ent:Remove()
		end
	end
	
	umsg.Start( "UndoWirePasterProp", pl ) umsg.End()
	self.PropCount = self.PropCount - 1
	Wire_TriggerOutput(self.Entity, "Out", self.PropCount)
	self:ShowOutput()
end


function ENT:UndoPaste(pastenum)
	
	//todo: for delay undo
	//need a way to index a pasted ent and remove it's table from the undolist table and be able to add to the undo list.
	
end



/*function ENT:Think()
	
	if (self.stage == 1) then
	
		//Msg("starting ent\n")
		for entID, EntTable in pairs(self.Ents) do
			//Msg("doing ent   "..entID.."\n")
			local EntClass = EntTable.Class
			
			// Check the antities class is registered with the duplicator
			if EntClass and duplicator.GetEntType(EntClass) then
				
				local Args = duplicator.PasteGetEntArgs( self:GetPlayer(), EntTable, self.offset )
				
				// make the Entity
				Ent = duplicator.GetEntType(EntClass).Func(self:GetPlayer(), unpack(Args))
				
				if (Ent && Ent:IsValid()) then
					if (Ent:GetPhysicsObject():IsValid()) then
						Ent:GetPhysicsObject():EnableMotion(false)
					end
					//self.TempMoveTypes[Ent:EntIndex()] = Ent:GetMoveType()
					//Ent:SetMoveType( MOVETYPE_NONE )
					Ent:SetNotSolid(true)
					Ent:SetParent(self.Entity)
					self.entIDtable[entID] = Ent
					table.insert(self.CreatedEnts,Ent)
					
					duplicator.PasteApplyEntMods( self:GetPlayer(), Ent, EntTable )
				end
				
			elseif (EntClass) then
				Msg("Duplicator Paste: Unknown class " .. EntClass .. "\n")
			end
			
			if ( entID == self.HeadEntID ) then
				self.HeadEntity = Ent
			end
			
			
			if (table.Count(self.Ents) >= 1) then 
				self.Ents[entID] = nil
				self.Entity:NextThink(CurTime() + self.thinkdelay)
				return true
			end
		end
		
		--Msg("going to stage 2\n")
		self.stage = 2
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
		
	elseif (self.stage == 2) then
		
		for k=1,4 do //make 4 each time
			local Constraint = table.remove(self.Constraints)
			
			if (Constraint) then
				
				// Check If the constraint type has been registered with the duplicator
				if Constraint.Type and duplicator.KnownConstraintType(Constraint.Type) then
					
					local Args, DoConstraint = duplicator.PasteGetConstraintArgs( self:GetPlayer(), Constraint, self.entIDtable, self.offset )
					
					// make the constraint
					if DoConstraint then
						
						local const = duplicator.ConstraintTypeFunc( Constraint.Type, Args )
						table.insert(self.CreatedConstraints,const)
						
						if (Constraint.ConstID) then
							self.constIDtable[Constraint.ConstID] = const
						end
					end
				end
				
				if (k ==3) then
					self.Entity:NextThink(CurTime() + self.thinkdelay)
					return true
				end
			else
				--Msg("going to stage 3\n")
				self.stage = 4
				self.Entity:NextThink(CurTime() + self.thinkdelay)
				return true
			end
		end
		
	elseif (self.stage == 3) then
		
		/*for id, infoTable in pairs(self.DupeInfo) do
			local ent = self.entIDtable[id]
			local isdupeinfo = false
			if (ent) and (ent:IsValid()) and (infoTable) and (ent.ApplyDupeInfo) then
				ent:ApplyDupeInfo(
					self:GetPlayer(), ent, infoTable,
					function(id) return self.entIDtable[id] end,
					function(id) return self.constIDtable[id] end
					)
				isdupeinfo = true
			end
			
			if (table.Count(self.DupeInfo) >= 1) then 
				self.DupeInfo[id] = nil
				if (isdupeinfo) then
					self.Entity:NextThink(CurTime() + self.thinkdelay)
					return true
				end
			end
		end*
		
		for id, infoTable in pairs(self.DupeInfo) do
			local ent = self.entIDtable[id]
			if (ent) and (ent:IsValid()) and (infoTable) and (ent.ApplyDupeInfo) then
			    ent:ApplyDupeInfo(
					self:GetPlayer(), ent, infoTable,
					function(id) return self.entIDtable[id] end,
					function(id) return self.constIDtable[id] end
					)
			end
		end
		
		--Msg("going to stage 4\n")
		self.stage = 4
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
		
	elseif (self.stage == 4) then
		//this just looks wrong, so no
		--Msg("starting rotate\n")
		duplicator.PasteRotate( self:GetPlayer(), self.HeadEntity, self.CreatedEnts )
		
		duplicator.PasteApplyDORInfo( self.DORInfo, function(id) return self.entIDtable[id] end )
		
		--Msg("going to stage 5\n")
		self.stage = 5
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
		
	elseif (self.stage == 5) then
		
		//Msg("starting cleanup\n")
		self.PropCount = self.PropCount + 1
		
		undo.Create("Duplicator")
		
		self.UndoListEnts[self.PropCount] = {}
		for _, ent in pairs( self.CreatedEnts ) do
			self:GetPlayer():AddCleanup( "duplicates", ent )
			//ent:SetMoveType(self.TempMoveTypes[ent:EntIndex()])
			if (ent:GetPhysicsObject():IsValid()) then
				ent:GetPhysicsObject():EnableMotion(true)
			end
			ent:SetNotSolid(false)
			ent:SetParent()
			undo.AddEntity( ent )
			table.insert(self.UndoListEnts[self.PropCount], ent:EntIndex())
		end
		
		for _, ent in pairs( self.CreatedConstraints ) do
			self:GetPlayer():AddCleanup( "duplicates", ent )
			undo.AddEntity( ent )
		end
		
		undo.SetPlayer( self:GetPlayer() )
		undo.Finish()
		
		self.constIDtable, self.entIDtable, self.CreatedConstraints, self.CreatedEnts = {}, {}, {}, {}
		self.stage = 0
		
		
		//todo
		/*if (self.undo_delay > 0) then
			
			timer.Simple( delay, updopaste )
			// Update prop count output when prop is deleted (TheApathetic)
			timer.Simple(delay + 0.25, self:ShowOutput)
			
		end*
		
		
		
		
		--Msg("====done====\n")
		
		//self:HideGhost(false)
		
		self:ShowOutput()
		
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
	end
	
end*/
