AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "Advanced Pod Controller"
local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.lockvar = 0
	self.disablevar = 0
	self.crossvar = 0
	-- Output keys. Format: self.keys["name"] = IN_*
	self.keys = { }
	self.keys["Mouse1"] = IN_ATTACK
	self.keys["Mouse2"] = IN_ATTACK2
	self.keys["W"] = IN_FORWARD
	self.keys["A"] = IN_MOVELEFT
	self.keys["S"] = IN_BACK
	self.keys["D"] = IN_MOVERIGHT
	self.keys["R"] = IN_RELOAD
	self.keys["Space"] = IN_JUMP
	self.keys["Ctrl"] = IN_DUCK
	self.keys["Shift"] = IN_SPEED
	self.keys["Zoom"] = IN_ZOOM
	-- Invert the table to use it with Wire_CreateOutputs
	local outputs = { }
	local n = 1
	for k, v in pairs( self.keys ) do
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
	n = n + 1
	outputs[n] = "Active"
	
	n = n + 1
	outputs[n] = "Team"
	
	n = n + 1
	outputs[n] = "Health"
	
	n = n + 1
	outputs[n] = "Armor"
	
	n = n + 1
	outputs[n] = "Bearing"
	
	n = n + 1
	outputs[n] = "Elevation"
	
	self.VPos = Vector(0, 0, 0)
	
	self.Outputs = Wire_CreateOutputs( self.Entity, outputs )
	self.Inputs = Wire_CreateInputs( self.Entity, { "Lock", "Terminate", "Strip weapons", "Eject", "Disable", "Crosshairs", "Brake"} )
	self:SetOverlayText( "Adv. Pod Controller" )
end

function ENT:Setup(pod)
	self.Pod = pod
end

function ENT:TriggerInput(iname, value)
		if (iname == "Lock") then
			if !(self.Pod && self.Pod:IsValid()) then return end
			if (value >= 1) then
				if (self.lockvar == 0) then
					self.Pod:Fire("Lock", "1", 0)
					self.lockvar = 1
				else
					self.Pod:Fire("Unlock", "1", 0)
					self.lockvar = 0
				end
			end
		elseif (iname == "Terminate") then
			if self.Ply and self.Ply:IsValid() then
				if (value > 0) then
					self.Ply:Kill()
				end
			end
		elseif (iname == "Strip weapons") then
			if self.Ply and self.Ply:IsValid() then
				if (value > 0) then
					self.Ply:StripWeapons( )
					self.Ply:PrintMessage(HUD_PRINTTALK,"Your weapons have been stripped!\n")
				end
			end
		elseif (iname == "Eject") then
			if self.Ply and self.Ply:IsValid() then
				if (value > 0) then
					self.Ply:ExitVehicle( )
				end
			end
		elseif (iname == "Disable") then
			if (value >= 1) then
				if (self.disablevar == 0) then
					self.disablevar = 1
				else
					self.disablevar = 0
				end
			end
		elseif (iname == "Crosshairs") then
			if (value >= 1) then
				if self.Ply and self.Ply:IsValid() then
					if (self.crossvar == 0) then
						self.Ply:CrosshairEnable()
						self.crossvar = 1
					else
						self.Ply:CrosshairDisable()
						self.crossvar = 0
					end
				end
			end
		elseif (iname == "Brake") then
			if value >= 1 then
				self.Pod:Fire("TurnOff", "1", 0)
				self.Pod:Fire("HandBrakeOn", "1", 0)
			else
				self.Pod:Fire("TurnOn", "1", 0)
				self.Pod:Fire("HandBrakeOff", "1", 0)
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
	self.keys = { }
	self.keys["Mouse1"] = IN_ATTACK
	self.keys["Mouse2"] = IN_ATTACK2
	self.keys["W"] = IN_FORWARD
	self.keys["A"] = IN_MOVELEFT
	self.keys["S"] = IN_BACK
	self.keys["D"] = IN_MOVERIGHT
	self.keys["R"] = IN_RELOAD
	self.keys["Space"] = IN_JUMP
	self.keys["Ctrl"] = IN_DUCK
	self.keys["Shift"] = IN_SPEED
	self.keys["Zoom"] = IN_ZOOM
    self.BaseClass.OnRestore(self)
end

function ENT:Think()
	if self.Pod then
		self.Ply = self.Pod:GetPassenger()
		if self.Ply and self.Ply:IsValid() then
			Wire_TriggerOutput( self.Entity, "Active", 1)
			for k, v in pairs( self.keys )  do
				if self.Ply:KeyDownLast( v ) then Wire_TriggerOutput( self.Entity, k, 1 )
				else Wire_TriggerOutput( self.Entity, k, 0 ) end
			end
			local MyPos = self.Ply:GetShootPos()
			local viewangle = self.Ply:GetAimVector():Angle()
			local tmp2 = self.Ply:GetEyeTrace()
			tmp2.Filter = self.Pod
			local tmp = tmp2.HitPos
			Wire_TriggerOutput( self.Entity, "X", tmp.x )
			Wire_TriggerOutput( self.Entity, "Y", tmp.y )
			Wire_TriggerOutput( self.Entity, "Z", tmp.z )
			local dist = (tmp-MyPos):Length()
			Wire_TriggerOutput( self.Entity, "Distance", dist)
			local plyteam = self.Ply:Team( )
			Wire_TriggerOutput( self.Entity, "Team", plyteam)
			local plyheal = self.Ply:Health( )
			Wire_TriggerOutput( self.Entity, "Health", plyheal)
			local plyarm = self.Ply:Armor( )
			Wire_TriggerOutput( self.Entity, "Armor", plyarm)
			self.VPos = tmp
			local pitch = -viewangle.p
			if pitch > 180 then pitch = pitch - 360 end
			if pitch < -180 then pitch = pitch + 360 end
			local yaw = viewangle.y
			if yaw > 180 then yaw = yaw - 360 end
			if yaw < -180 then yaw = yaw + 360 end
			Wire_TriggerOutput(self.Entity, "Bearing", -(yaw + 90))
			Wire_TriggerOutput(self.Entity, "Elevation", pitch)
		else
			Wire_TriggerOutput( self.Entity, "Active", 0) 
		end
		if (self.disablevar == 1) then
			for k, v in pairs( self.keys )  do
				Wire_TriggerOutput( self.Entity, k, 0 )
			end
			Wire_TriggerOutput( self.Entity, "Disabled", 1)
		else
			Wire_TriggerOutput( self.Entity, "Disabled", 0)
		end
	end
	self.Entity:NextThink(CurTime() + 0.01)
	return true
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end

--Duplicator support to save pod link (TAD2020)
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