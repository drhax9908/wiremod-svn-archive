AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Advanced Pod Controller"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	--[[
	-- Set the name of self (To let us have several controllers)
	-- Note: Player:GetVehicle does actually work on pods. (&/(%&/(/&%)(/( wiki)
	self.Tname = "wpod"..wire_pod_count
	wire_pod_count = wire_pod_count + 1
	self.Entity:SetName(self.Tname)
	
	]]
	
	-- Output keys. Format: keys["name"] = IN_*
	keys = { }
	keys["Mouse1"] = IN_ATTACK
	keys["Mouse2"] = IN_ATTACK2
	keys["MWHEELUP"] = IN_INVPREV
	keys["MWHEELDOWN"] = IN_INVNEXT
	keys["W"] = IN_FORWARD
	keys["A"] = IN_MOVELEFT
	keys["S"] = IN_BACK
	keys["D"] = IN_MOVERIGHT
	keys["R"] = IN_RELOAD
	keys["Space"] = IN_JUMP
	keys["Ctrl"] = IN_DUCK
	keys["Shift"] = IN_SPEED
	keys["Zoom"] = IN_ZOOM

	
	-- Invert the table to use it with Wire_CreateOutputs
	local outputs = { }
	local n = 1
	
	for k, v in pairs( keys ) do
		outputs[n] = k
		n = n + 1
	end
	
	-- <angle>
	outputs[n] = "X"
	n = n + 1
	outputs[n] = "Y"
	n = n + 1
	outputs[n] = "Z"
	-- </angle>
	
	n = n + 1
	outputs[n] = "Distance"
	--[[ elevation / bearing outputs
	n = n + 1
	outputs[n] = "Bearing"
	
	n = n + 1
	outputs[n] = "Elevation"
	--]]
	n = n + 1
	outputs[n] = "Active"
	
	n = n + 1
	outputs[n] = "team"
	
	-- Create outputs
	self.Outputs = Wire_CreateOutputs( self.Entity, outputs )
	self.Inputs = Wire_CreateInputs( self.Entity, { "Lock", "Terminate", "Strip weapons", "Eject" } )
	self:SetOverlayText( "Adv. Pod Controller" )
end

-- Link to pod
function ENT:Setup( pod )
	self.Pod = pod
	self.TTLFP = CurTime()
end

function ENT:TriggerInput(iname, value)
		if (iname == "Lock") then
			if !(self.Pod && self.Pod:IsValid()) then return end
				if value > 0 then
					self.Pod:Fire("Lock", "1", 0)
				else
					self.Pod:Fire("Unlock", "1", 0)
				end
	elseif (iname == "Terminate") then
		if self.Ply then
			if (value >= 1) then
				self.Ply:Kill()
			end
		end
	elseif (iname == "Strip weapons") then
		if self.Ply then
			if (value >= 1) then
				self.Ply:StripWeapons( )
				self.Ply:PrintMessage(HUD_PRINTTALK,"Your weapons have been stripped!\n")
			end
		end
	elseif (iname == "Eject") then
		if self.Ply then
			if (value >= 1) then
				self.Ply:ExitVehicle( )
			end
		end
	end
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Pod Controller" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
	keys = { }
	keys["Mouse1"] = IN_ATTACK
	keys["Mouse2"] = IN_ATTACK2
	keys["MWHEELUP"] = IN_INVPREV
	keys["MWHEELDOWN"] = IN_INVNEXT
	keys["W"] = IN_FORWARD
	keys["A"] = IN_MOVELEFT
	keys["S"] = IN_BACK
	keys["D"] = IN_MOVERIGHT
	keys["R"] = IN_RELOAD
	keys["Space"] = IN_JUMP
	keys["Ctrl"] = IN_DUCK
	keys["Shift"] = IN_SPEED
	keys["Zoom"] = IN_ZOOM

	
    self.BaseClass.OnRestore(self)
end

-- Called every 0.01 seconds, check for key down
function ENT:Think()
local brng = Angle(0, 0, 0)
	-- Check that we have a pod
	if self.Pod then
		-- Check if we should look for player entering/exiting the vehicle TTLFP = TimeToLookForPod
		if ( !self.TTLFP ) then return end
		if self.TTLFP < CurTime() then
			-- Check if the old player is still in our vehicle
			if !(self.Ply and self.Ply:GetVehicle() == self.Pod) then
				-- Get all players
				local plys = player.GetAll()
				self.Ply = nil
				-- Loop through all players and check if their vehicle is our vehicle
				for k,v in pairs(plys) do
					if v:GetVehicle() == self.Pod then self.Ply = v end
				end
				
				if self.Ply then
				Wire_TriggerOutput( self.Entity, "Active", 1)
				else
				Wire_TriggerOutput( self.Entity, "Active", 0) 
				end
			end
			-- Look for players again in 1/10 second
			self.TTLFP = CurTime() + 0.1
		end
		
		if self.Ply then
			-- Loop through all the keys, and check if they was pressed last frame
			for k, v in pairs( keys )  do
				--[[
				if self.Ply:KeyDownLast( v ) then Wire_TriggerOutput( self.Entity, k, 1 )-- ; print( "Pressed: "..k..":"..v )
				else Wire_TriggerOutput( self.Entity, k, 0 ) end
				]]
				if self.Ply:KeyDownLast( v ) then Wire_TriggerOutput( self.Entity, k, 1 )
				else Wire_TriggerOutput( self.Entity, k, 0 ) end
				
				local tmp = self.Ply:GetEyeTrace().HitPos
				Wire_TriggerOutput( self.Entity, "X", tmp.x )
				Wire_TriggerOutput( self.Entity, "Y", tmp.y )
				Wire_TriggerOutput( self.Entity, "Z", tmp.z )
				local MyPos = self.Entity:GetPos()
				dist = (tmp-MyPos):Length()
				Wire_TriggerOutput( self.Entity, "Distance", dist)
				--[[ Non-working elevation / bearing code
				local DeltaPos = self.Entity:WorldToLocal(tmp)
				brng = DeltaPos:Angle( )
				local pitch = brng.p
				local yaw = brng.y
				if (yaw > 180) then yaw = yaw - 360 end
				if (yaw < -180) then yaw = yaw + 360 end
				if (yaw > 180) then yaw = yaw - 360 end
				if (yaw < -180) then yaw = yaw + 360 end
				if (pitch > 180) then pitch = ypitch - 360 end
				if (pitch < -180) then pitch = pitch + 360 end
				if (pitch > 180) then pitch = pitch - 360 end
				if (pitch < -180) then pitch = pitch + 360 end
				Wire_TriggerOutput(self.Entity, "Bearing", -yaw - 90)
				Wire_TriggerOutput(self.Entity, "Elevation", -pitch)
				--]]
				local plyteam = self.Ply:Team( )
				Wire_TriggerOutput( self.Entity, "Team", plyteam)
				
				
			end
		end
	end
	self.Entity:NextThink(CurTime() + 0.01)
	return true
end


//Duplicator support to save pod link (TAD2020)
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.Pod) and (self.Pod:IsValid()) then
	    info.pod = self.Pod:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.pod) then
		self.Pod = GetEntByID(info.pod)
		if (!self.Pod) then
			self.Pod = ents.GetByIndex(info.pod)
		end
	end
end