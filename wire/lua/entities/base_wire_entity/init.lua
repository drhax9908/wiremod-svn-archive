
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "No Name"

function ENT:Think()
	if (!Wire_DisableOverlayTextUpdate) and (self.NextOverlayTextTime) and (CurTime() >= self.NextOverlayTextTime) then
		if (self.NextOverlayText) then
			//self.BaseClass.BaseClass.SetOverlayText(self, self.NextOverlayText)
			self.Entity:SetNetworkedBeamString( "GModOverlayText", self.NextOverlayText )
			self.NextOverlayText = nil
			self.NextOverlayTextTime = CurTime() + (self.OverlayDelay or 0.4) + math.random()*(self.OverlayRandom or 0.2)
			if (Wire_SlowerOverlayTextUpdate) then
				self.NextOverlayTextTime = self.NextOverlayTextTime + 1 //add a sec between updates
			end
		else
			self.NextOverlayText = nil
			self.NextOverlayTextTime = nil
		end
	end
end

function ENT:SetOverlayText(txt)
	if (Wire_DisableOverlayTextUpdate) then return end
	
	if (Wire_FastOverlayTextUpdate) then
		
		self.Entity:SetNetworkedBeamString( "GModOverlayText", txt, true ) //send it now, damn it!
		
	else
		
		if (self.NextOverlayTextTime) then
			self.NextOverlayText = txt
		else
		    //self.BaseClass.BaseClass.SetOverlayText(self, txt)
			self.Entity:SetNetworkedBeamString( "GModOverlayText", txt )
			
			self.NextOverlayText = nil
			
			if (not self.OverlayDelay) or (self.OverlayDelay > 0) or (Wire_SlowerOverlayTextUpdate) or (!SinglePlayer()) or (Wire_ForceDelayOverlayTextUpdate) then
				self.NextOverlayTextTime = CurTime() + (self.OverlayDelay or 0.6) + math.random()*(self.OverlayRandom or 0.2)
			end
		end
		
	end
	
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

function ENT:BuildDupeInfo()
	return WireLib.BuildDupeInfo( self.Entity )
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
end

//
//new duplicator stuff
//
function ENT:PreEntityCopy()
	//build the DupeInfo table and save it as an entity mod
	local DupeInfo = self:BuildDupeInfo()
	if DupeInfo then
		duplicator.StoreEntityModifier( self.Entity, "WireDupeInfo", DupeInfo )
	end
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	//apply the DupeInfo
	if (Ent.EntityMods) and (Ent.EntityMods.WireDupeInfo) then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end
