AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Pod Controller"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	-- Output self.Keys. Format: self.Keys["name"] = IN_*
	self.Keys = { }
	self.Keys["W"] = IN_FORWARD
	self.Keys["A"] = IN_MOVELEFT
	self.Keys["S"] = IN_BACK
	self.Keys["D"] = IN_MOVERIGHT
	self.Keys["Mouse1"] = IN_ATTACK
	self.Keys["R"] = IN_RELOAD
	
	-- Invert the table to use it with Wire_CreateOutputs
	local outputs = { }
	local n = 1
	
	for k, v in pairs( self.Keys ) do
		outputs[n] = k
		n = n + 1
	end
	
	outputs[n] = "Active"
	
	self.VPos = Vector(0, 0, 0)

	-- Create outputs
	self.Outputs = Wire_CreateOutputs( self.Entity, outputs )
	self.Inputs = Wire_CreateInputs( self.Entity, { "Lock" } )
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
	self.Keys = { }
	self.Keys["W"] = IN_FORWARD
	self.Keys["A"] = IN_MOVELEFT
	self.Keys["S"] = IN_BACK
	self.Keys["D"] = IN_MOVERIGHT
	self.Keys["Mouse1"] = IN_ATTACK
	self.Keys["R"] = IN_RELOAD
	
    self.BaseClass.OnRestore(self)
end

-- Called every 0.01 seconds, check for key down
function ENT:Think()
	-- Check that we have a pod
	if self.Pod then
		-- Check if we should look for player entering/exiting the vehicle TTLFP = TimeToLookForPod
		if self.TTLFP < CurTime() then
			-- Check if the old player still is in our vehicle
			if !(self.Ply and self.Ply:GetVehicle() == self.Pod) then
				-- Get all players
				local plys = player.GetAll()
				self.Ply = nil
				-- Loop through all players and check if their vehicle is our vehicle
				for k,v in pairs(plys) do
					if v:GetVehicle() == self.Pod then self.Ply = v; break end
				end
				
				if self.Ply then Wire_TriggerOutput( self.Entity, "Active", 1)
				else Wire_TriggerOutput( self.Entity, "Active", 0) end
			end
			-- Look for players again in 1/10 second
			self.TTLFP = CurTime() + 0.1
		end
		
		if self.Ply then
			-- Loop through all the self.Keys, and check if they was pressed last frame
			for k, v in pairs( self.Keys )  do
				if self.Ply:KeyDownLast( v ) then Wire_TriggerOutput( self.Entity, k, 1 )
				else Wire_TriggerOutput( self.Entity, k, 0 ) end
			end
			local trace = util.GetPlayerTrace(self.Ply)
			trace.filter = self.Pod
			self.VPos = util.TraceLine(trace).HitPos
		end
	end
	self.Entity:NextThink(CurTime() + 0.01)
	return true
end

function ENT:TriggerInput(iname, value)
	if !(self.Pod && self.Pod:IsValid()) then return end
	if value > 0 then
		self.Pod:Fire("Lock", "1", 0)
	else
		self.Pod:Fire("Unlock", "1", 0)
	end
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
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
