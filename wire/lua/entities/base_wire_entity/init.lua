
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "No Name"

function ENT:Think()
	if (self.NextOverlayTextTime) and (CurTime() >= self.NextOverlayTextTime) then
		if (self.NextOverlayText) then
			//self.BaseClass.BaseClass.SetOverlayText(self, self.NextOverlayText)
			self.Entity:SetNetworkedBeamString( "GModOverlayText", self.NextOverlayText )
			self.NextOverlayText = nil
			self.NextOverlayTextTime = CurTime() + (self.OverlayDelay or 0.4) + math.random()*(self.OverlayRandom or 0.2)
		else
			self.NextOverlayText = nil
			self.NextOverlayTextTime = nil
		end
	end
end

function ENT:SetOverlayText(txt)
	
	if (Wire_FastOverlayTextUpdate) then
		
		self.Entity:SetNetworkedBeamString( "GModOverlayText", txt )
		
	else
		
		if (self.NextOverlayTextTime) then
			self.NextOverlayText = txt
		else
		    //self.BaseClass.BaseClass.SetOverlayText(self, txt)
			self.Entity:SetNetworkedBeamString( "GModOverlayText", txt )
			
			self.NextOverlayText = nil
			
			if (not self.OverlayDelay) or (self.OverlayDelay > 0) then
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
	//return WireLib.BuildDupeInfo( self.Entity )
	if (not self.Inputs) then return end
	
	local info = { Wires = {} }
	for k,input in pairs(self.Inputs) do
		if (input.Src) and (input.Src:IsValid()) then
		    info.Wires[k] = {
				StartPos = input.StartPos,
				Material = input.Material,
				Color = input.Color,
				Width = input.Width,
				Src = input.Src:EntIndex(),
				SrcId = input.SrcId,
				SrcPos = Vector(0, 0, 0),
			}
			
			if (input.Path) then
				info.Wires[k].Path = {}
				
			    for _,v in ipairs(input.Path) do
			        if (v.Entity) and (v.Entity:IsValid()) then
			        	table.insert(info.Wires[k].Path, { Entity = v.Entity:EntIndex(), Pos = v.Pos })
					end
			    end
			    
			    local n = table.getn(info.Wires[k].Path)
			    if (n > 0) and (info.Wires[k].Path[n].Entity == info.Wires[k].Src) then
			        info.Wires[k].SrcPos = info.Wires[k].Path[n].Pos
			        table.remove(info.Wires[k].Path, n)
			    end
			end
		end
	end
	
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	//WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
	if (info.Wires) then
		for k,input in pairs(info.Wires) do
		    
			Wire_Link_Start(ply:UniqueID(), ent, input.StartPos, k, input.Material, input.Color, input.Width)
		    
			if (input.Path) then
		        for _,v in ipairs(input.Path) do
					
					local ent2 = GetEntByID(v.Entity)
					if (!ent2) or (!ent2:IsValid()) then ent2 = ents.GetByIndex(v.Entity) end
					if (ent2) or (ent2:IsValid()) then
						Wire_Link_Node(ply:UniqueID(), ent2, v.Pos)
					else
						Msg("ApplyDupeInfo: Error, Could not find the entity for wire path\n")
					end
				end
		    end
			
			local ent2 = GetEntByID(input.Src)
		    if (!ent2) or (!ent2:IsValid()) then ent2 = ents.GetByIndex(input.Src) end
			if (ent2) or (ent2:IsValid()) then
				Wire_Link_End(ply:UniqueID(), ent2, input.SrcPos, input.SrcId)
			else
				Msg("ApplyDupeInfo: Error, Could not find the output entity\n")
			end
		end
	end
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
