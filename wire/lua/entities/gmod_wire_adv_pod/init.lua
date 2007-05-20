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
	outputs[n] = "Active"
	
	-- Create outputs
	self.Outputs = Wire_CreateOutputs( self.Entity, outputs )
	self:SetOverlayText( "Pod Controller" )
end

-- Link to pod
function ENT:Setup( pod )
	self.Pod = pod
	self.TTLFP = CurTime()
end

-- No inputs
function ENT:TriggerInput(iname, value)

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
				
				if self.Ply then Wire_TriggerOutput( self.Entity, "Active", 1)
				else Wire_TriggerOutput( self.Entity, "Active", 0) end
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