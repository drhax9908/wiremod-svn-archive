
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
	self.Outputs = WireLib.CreateSpecialOutputs( self.Entity, { "Out" }, { "ENTITY" } )
end

function ENT:Setup(maxrange, players, npcs, npcname, beacons, hoverballs, thrusters, props, propmodel, vehicles, playername, casesen, rpgs, painttarget, minrange, maxtargets, maxbogeys, notargetowner, entity, notownersstuff, steamname, colorcheck, colortarget, pcolR, pcolG, pcolB, pcolA, checkbuddylist, onbuddylist )
 	self.MaxRange			= maxrange
	self.MinRange			= minrange or 1
	self.TargetPlayer		= players
	self.NoTargetOwner		= notargetowner
	self.NoTargetOwnersStuff = notownersstuff
	self.TargetNPC			= npcs
	self.NPCName			= npcname
	self.TargetBeacon		= beacons
	self.TargetHoverballs	= hoverballs
	self.TargetThrusters	= thrusters
	self.TargetProps		= props
	self.PropModel			= propmodel
	self.TargetVehicles		= vehicles
	self.PlayerName			= playername
	self.SteamName			= steamname
	self.ColorCheck			= colorcheck
	self.ColorTarget		= colortarget
	self.PcolR				= pcolR
	self.PcolG				= pcolG
	self.PcolB				= pcolB
	self.PcolA				= pcolA
	self.CaseSen			= casesen
	self.TargetRPGs			= rpgs
	self.EntFil				= entity
	self.CheckBuddyList		= checkbuddylist
	self.OnBuddyList		= onbuddylist
	self.PaintTarget		= painttarget
	self.MaxTargets			= math.floor(math.Clamp((maxtargets or 1), 1, server_settings.Int("wire_target_finders_maxtargets", 10)))
	self.MaxBogeys			= math.floor(math.Clamp((maxbogeys or 1), self.MaxTargets , server_settings.Int("wire_target_finders_maxbogeys", 30)))
	
	if (self.SelectedTargets) then --unpaint before clearing
		for _,ent in pairs(self.SelectedTargets) do
			self:TargetPainter(ent, false)
		end
	end
	self.SelectedTargets = {}
	self.SelectedTargetsSel = {}
	
	local AdjOutputs = {}
	local AdjOutputsT = {}
	for i = 1, self.MaxTargets do
		table.insert(AdjOutputs, tostring(i))
		table.insert(AdjOutputsT, "NORMAL")
		table.insert(AdjOutputs, tostring(i).."_Ent")
		table.insert(AdjOutputsT, "ENTITY")
	end
	WireLib.AdjustSpecialOutputs(self.Entity, AdjOutputs, AdjOutputsT)
	
	
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
	local ch = 1
	if (sensor.Inputs) and (sensor.Inputs.Target.SrcId) then
		ch = tonumber(sensor.Inputs.Target.SrcId)
	end
	if self.SelectedTargets[ch] then
		if (not self.SelectedTargets[ch]:IsValid()) then
	        self.SelectedTargets[ch] = nil
			Wire_TriggerOutput(self.Entity, tostring(ch), 0)
	        return sensor:GetPos()
	    end
	
		return self.SelectedTargets[ch]:GetPos()
	end

	return sensor:GetPos()
end

function ENT:GetBeaconVelocity(sensor)
	local ch = 1
	if (sensor.Inputs) and (sensor.Inputs.Target.SrcId) then
		ch = tonumber(sensor.Inputs.Target.SrcId)
	end
	if self.SelectedTargets[ch] then
		if (not self.SelectedTargets[ch]:IsValid()) then
	        self.SelectedTargets[ch] = nil
			Wire_TriggerOutput(self.Entity, tostring(ch), 0)
	        return sensor:GetVelocity()
	    end
		return self.SelectedTargets[ch]:GetVelocity()
	end
	return sensor:GetVelocity()
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
		Wire_TriggerOutput(self.Entity, tostring(ch), 1)
	end
end

//function ENT:SelectorPrev(ch) end --TODO if needed

function ENT:FindName(name)
	local found = false
	if string.len(self.PlayerName) > 0 then 
		if self.CaseSen then
			if string.find(name, self.PlayerName) then 
				found = true
			end
		else
			if string.find(string.lower(name), string.lower(self.PlayerName)) then 
				found = true
			end
		end
	else
		found = true
	end
	return found
end

function ENT:FindSteam(steamid)
	local found = false
	if string.len(self.SteamName) > 0 then 
		if string.find(steamid, self.SteamName) then 
			found = true
		end
	else
		found = true
	end
	return found
end

function ENT:FindColor(contact)
	if (!self.ColorCheck) then return true end
	
	local col = Color(contact:GetColor())
	if (col.r == self.PcolR) and (col.g == self.PcolG) and (col.b == self.PcolB) and (col.a == self.PcolA) then
		return self.ColorTarget
	else
		return !self.ColorTarget	
	end
end

function ENT:FindModel(name)
	local found = false
	if string.len(self.PropModel) > 0 then 
		if string.find(string.lower(name), string.lower(self.PropModel)) then 
			found = true
		end
	else
		found = true
	end
	return found
end

function ENT:FindNPCName(name)
	local found = false
	if string.len(self.NPCName) > 0 then 
		if string.find(string.lower(name), string.lower(self.NPCName)) then 
			found = true
		end
	else
		found = true
	end
	return found
end

function ENT:FindEntity(name)
	local found = false
	if string.len(self.EntFil) > 0 then
		if string.find(string.lower(name), string.lower(self.EntFil)) then 
			found = true
		end
	end
	return found
end


//Prop Protection Buddy List Support (EXPERIMENTAL!!!)
function ENT:CheckTheBuddyList(Ami)
	if (!self.CheckBuddyList) then return true end
	
	local info = Ami:GetInfo( "propprotection_ami"..self:GetPlayer():EntIndex() ) --am I on their list
	if ( info == "0" ) then
		return !self.OnBuddyList
	end
	return self.OnBuddyList
end

/*function ENT:BelongsToBuddy(contact)
	if (!self.CheckBuddyList) then return true end
	
	local info = self:GetOwner():GetInfo( "propprotection_ami"..contact:GetPlayer():EntIndex() )
	if ( info == "0" ) then
		return false
	else
		return true
	end
end*/


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
			local contactClass = contact:GetClass()
			if 	( !self.NoTargetOwnersStuff or (contactClass == "player") or ( contact:GetOwner() != self:GetPlayer() and !self:checkOwnership( contact ) ) ) and (
				((self.TargetNPC)			and (string.find(contactClass, "^npc_.*")) and (contactClass ~= "npc_heli_avoidsphere") and (self:FindNPCName(contactClass))) or
				((self.TargetPlayer)		and (contactClass == "player") and (!self.NoTargetOwner or self:GetPlayer() != contact) and self:FindName(contact:GetName()) and self:FindSteam(contact:SteamID()) and self:FindColor(contact) and self:CheckTheBuddyList(contact) ) or
				((self.TargetBeacon)		and (contactClass == "gmod_wire_locator")) or
				((self.TargetRPGs)			and (contactClass == "rpg_missile")) or
				((self.TargetHoverballs)	and (contactClass == "gmod_hoverball" or contactClass == "gmod_wire_hoverball")) or
				((self.TargetThrusters)		and (contactClass == "gmod_thruster" or contactClass == "gmod_wire_thruster" or contactClass == "gmod_wire_vectorthruster")) or
				((self.TargetProps)			and (contactClass == "prop_physics") and (self:FindModel(contact:GetModel()))) or
				((self.TargetVehicles)		and (string.find(contactClass, "prop_vehicle"))) or
				(self:FindEntity(contactClass)) )
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
					Wire_TriggerOutput(self.Entity, tostring(i), 1)
					Wire_TriggerOutput(self.Entity, tostring(i).."_Ent", self.SelectedTargets[i])
				else
					self.SelectedTargets[i] = nil
					Wire_TriggerOutput(self.Entity, tostring(i), 0)
					Wire_TriggerOutput(self.Entity, tostring(i).."_Ent", NULL)
				end
			end
		end
		
	end
	
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

function ENT:OnRestore()
	self.BaseClass.OnRestore(self)
	
	self.MaxTargets = self.MaxTargets or 1
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



//
//	PropProtection support 
//
//	Uses code from uclip for checking ownership	
//
-- Written by Team Ulysses, http://ulyssesmod.net/
local hasPropProtection = false -- Chaussette's Prop Protection (preferred over PropSecure)
local propProtectionFn -- Function to call to see if a prop belongs to a player. We have to fetch it from a local so we'll store it here.

local hasPropSecure = false -- Prop Secure by Conna
local hasProtector = false -- Protector by Conna

local noProtection = false -- If there's no protection whatsoever, this is flagged. 
-- We need this flag because with a protector, we default to _not_ being able to go through things.
-- This flag saves us major memory/bandwidth when there's no protection

-- We'll check status of protectors in this init
local function init()
	local t = hook.GetTable()
	local fn
	if t.CanTool[ 0 ] then -- ULib
		fn = t.CanTool[ 0 ].PropProtection
	else
		fn = t.CanTool.PropProtection
	end
	
	hasPropProtection = type( fn ) == "function"
	
	if hasPropProtection then
		-- We're going to get the function we need now. It's local so this is a bit dirty			
		local gi = debug.getinfo( fn )		
		for i=1,gi.nups do
			if debug.getupvalue( fn, i ) == "Appartient" then
				local junk
				junk, propProtectionFn = debug.getupvalue( fn, i )
				break
			end
		end
	end
	
	hasPropSecure = type( PropSecure ) == "table"
	hasProtector = type( Protector ) == "table"
	
	if not hasPropProtection and not hasPropSecure and not hasProtector then
		noProtection = true
	end
end
hook.Add( "Initialize", "WireTargetFinderInitialize", init )

-- This function checks the protector to see if ownership has changed from what we think it is. Notifies player too.	
local function updateOwnership( ply, ent )
	if noProtection then return end -- No point on going on	
	if not ent.WireTargetFinder then ent.WireTargetFinder = {} end -- Initialize table
	
	local owns
	if hasPropProtection then -- Chaussette's Prop Protection (preferred over PropSecure)
		owns = propProtectionFn( ply, ent )
	elseif hasPropSecure then -- PropSecure
		owns = PropSecure.IsPlayers( ply, ent )
	elseif hasProtector then -- Protector
		owns = Protector.Owner( ent ) == ply:UniqueID()
	end
	
	if owns == false then -- More convienent to store as nil, takes less memory!
		owns = nil
	end
	
	if ent.WireTargetFinder[ ply ] ~= owns then
		ent.WireTargetFinder[ ply ] = owns
	end
end

function ENT:checkOwnership( ent )
	if noProtection then return true end -- No protection, they own everything.
	if (!self.CheckBuddyList) then return true end
	
	updateOwnership( self:GetPlayer(), ent )	-- Make sure server and the client are current
	return ent.WireTargetFinder[ self:GetPlayer() ]
end
