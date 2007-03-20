
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Targetter"
ENT.OverlayDelay = 0

local MODEL = Model( "models/props_lab/powerbox02d.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs(self.Entity, { "Hold" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup(maxrange, players, npcs, beacons, hoverballs, thrusters, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner)
 	self.MaxRange			= maxrange
	self.MinRange			= minrange or 1
	self.TargetPlayer		= players
	self.NoTargetOwner		= notargetowner
	self.TargetNPC			= npcs
	self.TargetBeacon		= beacons
	self.TargetHoverballs	= hoverballs
	self.TargetThrusters	= thrusters
	self.TargetRPGs			= rpgs
	self.PaintTarget		= painttarget
	self.MaxTargets			= math.floor(math.Clamp((maxtargets or 1), 1, server_settings.Int("wire_target_finders_maxtargets", 10)))
	self.MaxBogeys			= math.floor(math.Clamp((maxbogeys or 1), self.MaxTargets , server_settings.Int("wire_target_finders_maxbogeys", 30)))
	
	self.SelectedTargets = {}
	self.SelectedTargetsSel = {}
	
	local AdjOutputs = {}
	for i = 1, self.MaxTargets do table.insert(AdjOutputs, tostring(i)) end
	Wire_AdjustOutputs(self.Entity, AdjOutputs)
	
	
	self.Selector = {}
	self.Selector.Next = {}
	self.Selector.Prev = {}
	self.Selector.Hold = {}
	local AdjInputs = {}
	for i = 1, self.MaxTargets do
		local inputnext = tostring(i).."-NextTarget"
		//local inputprev = tostring(i).."-PrevTarget"
		local inputhold = tostring(i).."-HoldTarget"
		self.Selector.Next[inputnext] = i
		//self.Selector.Prev[inputprev] = i
		//self.Selector.Hold[inputhold] = i
		table.insert(AdjInputs, inputnext)
		//table.insert(AdjInputs, inputprev)
		table.insert(AdjInputs, inputhold)
	end
	table.insert(AdjInputs, "Hold")
	Wire_AdjustInputs(self.Entity, AdjInputs)
	
	
	self:ShowOutput(false)
	//Wire_TriggerOutput(self.Entity, "Out", 0)
end

function ENT:TriggerInput(iname, value)
	if (value > 0) then
		if self.Selector.Next[iname] then
			self:SelectorNext(self.Selector.Next[iname])
		/*elseif self.Selector.Prev[iname] then
			self:SelectorPrev(self.Selector.Prev[iname])*/
		/*elseif self.Selector.Hold[iname] then
			self:SelectorHold(self.Selector.Hold[iname])*/
		end
	end
end


function ENT:GetBeaconPos(sensor)
	local ch = tonumber(sensor.Inputs.Target.SrcId)
	if self.SelectedTargets[ch] then
		if (not self.SelectedTargets[ch]:IsValid()) then
	        self.SelectedTargets[ch] = nil
	        return sensor:GetPos()
	    end
	
		return self.SelectedTargets[ch]:GetPos()
	end

	return sensor:GetPos()
end


function ENT:SelectorNext(ch)
	if (self.Bogeys) and (#self.Bogeys > 0) then
		if (!self.SelectedTargetsSel[ch]) then self.SelectedTargetsSel[ch] = 1 end
		
		local sel = self.SelectedTargetsSel[ch]
		if (sel > #self.Bogeys) then sel = 1 end
		
		if (self.SelectedTargets[ch]) and (self.SelectedTargets[ch]:IsValid()) then
			
			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], false) end
			table.insert(self.Bogeys, self.SelectedTargets[ch]) //put old target back
			self.SelectedTargets[ch] = table.remove(self.Bogeys, sel) //pull next target
			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], true) end
			
		else
			
			self.SelectedTargets[ch] = table.remove(self.Bogeys, sel) //pull next target
			if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[ch], true) end
			
		end
		
		self.SelectedTargetsSel[ch] = sel + 1
		self.Inputs[ch.."-HoldTarget"].Value = 1 //put the channel on hold so it wont change in the next scan
	end
end

//function ENT:SelectorPrev(ch) end
//function ENT:SelectorHold(ch) end


function ENT:Think()
	self.BaseClass.Think(self)

	if (self.Inputs.Hold) and (self.Inputs.Hold.Value > 0) then
		//do nothing for now
	else
		if (self.NextTargetTime) and (CurTime() < self.NextTargetTime) then return end
		self.NextTargetTime = CurTime()+1
		
		// Find targets that meet requirements
		local contacts = ents.FindInSphere(self.Entity:GetPos(), self.MaxRange or 10)
		local mypos = self.Entity:GetPos()
		local bogeys,dists = {},{}
		for _,contact in pairs(contacts) do
			// Multiple if statements replaced with one long one
			local contactClass = contact:GetClass()
			if ((self.TargetNPC)			and (string.find(contactClass, "^npc_.*")) and (contactClass ~= "npc_heli_avoidsphere")) or
				((self.TargetPlayer)		and (contactClass == "player") and ((!self.NoTargetOwner) or (self.pl != target))) or
				((self.TargetBeacon)		and (contactClass == "gmod_wire_locator")) or
				((self.TargetRPGs)			and (contactClass == "rpg_missile")) or
				((self.TargetHoverballs)	and (contactClass == "gmod_hoverball" or contactClass == "gmod_wire_hoverball")) or
				((self.TargetThrusters)		and (contactClass == "gmod_thruster" or contactClass == "gmod_wire_thruster"))
			then
				local dist = (contact:GetPos() - mypos):Length()
				if (dist >= self.MinRange) then
					//put targets in a table index by the distance from the finder
					bogeys[dist] = contact
					table.insert(dists,dist)
				end
			end
		end
		
		//sort the list of bogeys by key (distance)
		self.Bogeys = {}
		self.InRange = {}
		table.sort(dists)
		local k = 1
		for i,d in pairs(dists) do
			if !self:IsTargeted(bogeys[d], i) then
				self.Bogeys[k] = bogeys[d]
				k = k + 1
				if (k > self.MaxBogeys) then break end
			end
		end
		
		
		//check that the selected targets are valid
		for i = 1, self.MaxTargets do
			if (self:IsOnHold(i)) then
				self.InRange[i] = true
			end
			
			if (!self.InRange[i]) or (!self.SelectedTargets[i]) or (self.SelectedTargets[i] == nil) or (!self.SelectedTargets[i]:IsValid()) then
				if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], false) end
				if (#self.Bogeys > 0) then
					self.SelectedTargets[i] = table.remove(self.Bogeys, 1)
					if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], true) end
				else
					self.SelectedTargets[i] = nil
				end
			end
		end
		
	end
	
	//Wire_TriggerOutput(self.Entity, "Out", targetnum)
	
	//temp hack
	if self.SelectedTargets[1] then
		self:ShowOutput(true)
	else
		self:ShowOutput(false)
	end
end

function ENT:IsTargeted(bogey, bogeynum)
	for i = 1, self.MaxTargets do
		if (self.SelectedTargets[i]) and (self.SelectedTargets[i] == bogey) then
			//hold this target
			if (self.Inputs[i.."-HoldTarget"]) and (self.Inputs[i.."-HoldTarget"].Value > 0) then
				self.InRange[i] = true
				return true
			end
			
			//this bogey is not as close as others, untarget it and let it be add back to the list
			if (bogeynum > self.MaxTargets) then
				self.SelectedTargets[i] = nil
				if (self.PaintTarget) then self:TargetPainter(bogey, false) end
				return false
			end
			
			self.InRange[i] = true
			return true
		end
	end
	return false
end

function ENT:IsOnHold(ch)
	if (self.Inputs[ch.."-HoldTarget"]) and (self.Inputs[ch.."-HoldTarget"].Value > 0) then
		return true
	end
	return false
end


function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	
	//unpaint all our targets
	if (self.PaintTarget) then
		for _,ent in pairs(self.SelectedTargets) do
			self:TargetPainter(ent, false)
		end
	end
end


function ENT:TargetPainter( tt, targeted )
	if tt &&						// There is a target
		tt.Entity &&				// Target has is an entity
		tt.Entity:IsValid() && 		// And it's valid
		tt.Entity:EntIndex() != 0	// And isn't worldspawn
	then
		if (targeted) then
			tt.Entity:SetColor(255, 0, 0, 255)
		else
			tt.Entity:SetColor(255, 255, 255, 255)
		end
	end
end


function ENT:ShowOutput(value)
	local txt = "Target Finder - "
	if (value) then
		txt = txt .. "Target Acquired"
	else
		txt = txt .. "No Target"
	end
	
	if (self.Inputs.Hold) and (self.Inputs.Hold.Value > 0) then txt = txt .. " - Locked" end

	self:SetOverlayText(txt)
end
