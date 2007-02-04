
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "No Name"

function ENT:Think()
	if (self.NextOverlayTextTime) and (CurTime() >= self.NextOverlayTextTime) then
	    if (self.NextOverlayText) then
		    self.BaseClass.BaseClass.SetOverlayText(self, self.NextOverlayText)
			self.NextOverlayText = nil
			self.NextOverlayTextTime = CurTime() + (self.OverlayDelay or 0.4) + math.random()*(self.OverlayRandom or 0.2)
		else
			self.NextOverlayText = nil
			self.NextOverlayTextTime = nil
		end
	end
end

function ENT:SetOverlayText(txt)
	if (self.NextOverlayTextTime) then
		self.NextOverlayText = txt
	else
	    self.BaseClass.BaseClass.SetOverlayText(self, txt)
		self.NextOverlayText = nil
		
		if (not self.OverlayDelay) or (self.OverlayDelay > 0) then
			self.NextOverlayTextTime = CurTime() + (self.OverlayDelay or 0.6) + math.random()*(self.OverlayRandom or 0.2)
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

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	if (info.Wires) then
		for k,input in pairs(info.Wires) do
		    Wire_Link_Start(ply:UniqueID(), ent, input.StartPos, k, input.Material, input.Color, input.Width)
		    if (input.Path) then
		        for _,v in ipairs(input.Path) do
		        	Wire_Link_Node(ply:UniqueID(), GetEntByID(v.Entity), v.Pos)
				end
		    end
		    Wire_Link_End(ply:UniqueID(), GetEntByID(input.Src), input.SrcPos, input.SrcId)
		end
	end
end
