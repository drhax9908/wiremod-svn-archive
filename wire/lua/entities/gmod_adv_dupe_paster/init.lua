
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Paster"
ENT.OverlayDelay = 0

local MODEL = Model( "models/props_lab/powerbox02d.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	//self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.stage = 0
	self.thinkdelay = 0.05
	
	self.Ents,self.Constraints,self.DupeInfo,self.offset = nil,nil,nil,nil
	self.constIDtable, self.entIDtable, self.CreatedConstraints, self.CreatedEnts, self.TempMoveTypes = {}, {}, {}, {}, {}
	
end

function ENT:Setup(ents, const, dupeinfo, offset, headentid)
	
	self.MyEnts 			= 	ents
	self.MyConstraints 		=	const
	self.MyDupeInfo 		= 	dupeinfo
	self.Myoffset			=	offset
	self.HeadEntID			= 	headentid
	
	self:Paste()
end

function ENT:Use( activator, caller, type, value )
	
	local Owner = self:GetPlayer()
	
	if ((Owner == nil or Owner == activator) and self.stage == 0) then
		self:Paste()
		return true
	else
		return false
	end
end

function ENT:Paste()
	if (self.stage != 0) then return end
	Msg("====start====\n")
	
	if ( self:GetPlayer():GetActiveWeapon():GetClass() == "gmod_tool" ) then
		self:GetPlayer():GetActiveWeapon():GetTable():GetToolObject():HideGhost(true)
	end
	
	self.Ents 			= 	table.Copy(self.MyEnts)
	self.Constraints 	=	table.Copy(self.MyConstraints)
	self.DupeInfo 		= 	table.Copy(self.MyDupeInfo)
	self.offset			=	self.Myoffset
	
	Msg("going to stage 1\n")
	self.stage = 1
end



function ENT:Think()
	
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
		
		Msg("going to stage 2\n")
		self.stage = 2
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
		
	elseif (self.stage == 2) then
		
		//Msg("starting const\n")
		local Constraint = table.remove(self.Constraints)
		
		if (Constraint) then
			
			//Msg("doing const\n")
			// Check If the constraint type has been registered with the duplicator
			if Constraint.Type and duplicator.KnownConstraintType(Constraint.Type) then
				
				local Args, DoConstraint = duplicator.PasteGetConstraintArgs( self:GetPlayer(), Constraint, self.entIDtable, self.offset )
				
				// make the constraint
				if DoConstraint then
					//Msg("making the const\n")
					
					local const = duplicator.ConstraintTypeFunc( Constraint.Type, Args )
					table.insert(self.CreatedConstraints,const)
					
					if (Constraint.ConstID) then
						self.constIDtable[Constraint.ConstID] = const
						//Msg("Dupe add constraint ID: " .. Constraint.ConstID .. "\n")
					end
				end
			end
			
			self.Entity:NextThink(CurTime() + self.thinkdelay)
			return true
		else
			Msg("going to stage 3\n")
			self.stage = 3
			self.Entity:NextThink(CurTime() + self.thinkdelay)
			return true
		end
		
	elseif (self.stage == 3) then
		
		
		//Msg("starting dupeinfo\n")
		
		for id, infoTable in pairs(self.DupeInfo) do
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
		end
		
		Msg("going to stage 4\n")
		self.stage = 4
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
		
	elseif (self.stage == 5) then
		//this just looks wrong, so no
		Msg("starting rotate\n")
		duplicator.PasteRotate( self:GetPlayer(), self.HeadEntity, self.CreatedEnts )
		
		Msg("going to stage 5\n")
		self.stage = 4
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
		
	elseif (self.stage == 4) then
		
		//Msg("starting cleanup\n")
		
		undo.Create("Duplicator")
		
		for _, ent in pairs( self.CreatedEnts ) do
			self:GetPlayer():AddCleanup( "duplicates", ent )
			//ent:SetMoveType(self.TempMoveTypes[ent:EntIndex()])
			if (ent:GetPhysicsObject():IsValid()) then
				ent:GetPhysicsObject():EnableMotion(true)
			end
			ent:SetNotSolid(false)
			ent:SetParent()
			undo.AddEntity( ent )
		end
		
		for _, ent in pairs( self.CreatedConstraints ) do
			self:GetPlayer():AddCleanup( "duplicates", ent )
			undo.AddEntity( ent )
		end
		
		undo.SetPlayer( self:GetPlayer() )
		undo.Finish()
		
		self.constIDtable, self.entIDtable, self.CreatedConstraints, self.CreatedEnts = {}, {}, {}, {}
		self.stage = 0
		Msg("====done====\n")
		
		if ( self:GetPlayer():GetActiveWeapon():GetClass() == "gmod_tool" ) then
			self:GetPlayer():GetActiveWeapon():GetTable():GetToolObject():HideGhost(false)
		end
		
		self.Entity:NextThink(CurTime() + self.thinkdelay)
		return true
	end
	
end