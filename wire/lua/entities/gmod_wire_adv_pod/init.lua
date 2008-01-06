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
	self.disablevar = false
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
	self.keys["Alt(walk)"] = IN_WALK
	self.keys["TurnLeltKey"] = IN_LEFT
	self.keys["TurnRightKey"] = IN_RIGHT

	local outputs = { }
	outputs[1] = "W"
	outputs[2] = "A"
	outputs[3] = "S"
	outputs[4] = "D"
	outputs[5] = "Mouse1"
	outputs[6] = "Mouse2"
	outputs[7] = "R"
	outputs[8] = "Space"
	outputs[9] = "Ctrl"
	outputs[10] = "Shift"
	outputs[11] = "Zoom"
	outputs[12] = "Alt(walk)"
	outputs[13] = "TurnLeltKey"
	outputs[14] = "TurnRightKey"
	
	local n = 15
	
	--aim
	outputs[n] = "X"
	n = n + 1
	outputs[n] = "Y"
	n = n + 1
	outputs[n] = "Z"
	--n = n + 1
	--outputs[n] = "AimVector" --TODO: place holder for later
	
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
	self.Inputs = Wire_CreateInputs( self.Entity, { "Lock", "Terminate", "Strip weapons", "Eject", "Disable", "Crosshairs", "Brake", "Allow Buttons", "Relitive"} )
	self:SetOverlayText( "Adv. Pod Controller" )
	
	self.pushbuttons = false
	self.LastPressed = 0
	self.BE_rel = false
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
			self.disablevar = (value >= 1)
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
		elseif (iname == "Allow Buttons") then
			self.pushbuttons = (value >= 1)
		elseif (iname == "Relitive") then
			self.BE_rel = (value >= 1)
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

local function fixupangle(angle)
	if angle > 180 then angle = angle - 360 end
	if angle < -180 then angle = angle + 360 end
	return angle
end

function ENT:Think()
	if self.Pod then
		local Ply = self.Pod:GetPassenger()
		if Ply and Ply:IsValid() then
			if self.Ply == nil then self.junkBE = CurTime() + 2 end
			self.Ply = Ply
			
			Wire_TriggerOutput( self.Entity, "Active", 1)
			
			if not self.disablevar then
				for k, v in pairs( self.keys )  do
					if not self.disablevar and self.Ply:KeyDownLast( v ) then
						Wire_TriggerOutput( self.Entity, k, 1 )
					else
						Wire_TriggerOutput( self.Entity, k, 0 )
					end
				end
			end
			
			--player info
			Wire_TriggerOutput( self.Entity, "Team", self.Ply:Team())
			Wire_TriggerOutput( self.Entity, "Health", self.Ply:Health())
			Wire_TriggerOutput( self.Entity, "Armor", self.Ply:Armor())
			
			if self.junkBE then --all this info is garbage while the player is entering the pod, junk it for the first 2 second
				if self.junkBE < CurTime() then self.junkBE = nil end
			else
				local trace = util.GetPlayerTrace( self.Ply )
				trace.filter = {self.Ply,self.Pod}
				local EyeTrace = util.TraceLine( trace )
				self.VPos = EyeTrace.HitPos
				local dist = (EyeTrace.HitPos-self.Ply:GetShootPos()):Length()
				Wire_TriggerOutput( self.Entity, "Distance", dist)
				
				Wire_TriggerOutput( self.Entity, "X", EyeTrace.HitPos.x )
				Wire_TriggerOutput( self.Entity, "Y", EyeTrace.HitPos.y )
				Wire_TriggerOutput( self.Entity, "Z", EyeTrace.HitPos.z )
				
				local AimVectorAngle = self.Ply:GetAimVector():Angle()
				local PodAngle = self.Pod:GetAngles()
				if self.BE_rel then
					Wire_TriggerOutput(self.Entity, "Bearing", fixupangle(AimVectorAngle.y - PodAngle.y))
					Wire_TriggerOutput(self.Entity, "Elevation", fixupangle(AimVectorAngle.p - PodAngle.p))
				else
					Wire_TriggerOutput(self.Entity, "Bearing", -(fixupangle(AimVectorAngle.y) + 90))
					Wire_TriggerOutput(self.Entity, "Elevation", fixupangle(-AimVectorAngle.p))
				end
				
				if self.pushbuttons then
					if EyeTrace.Entity and EyeTrace.Entity:IsValid() and EyeTrace.Entity:GetClass() == "gmod_wire_button" and dist < 256 and self.Ply:KeyDownLast( IN_ATTACK ) then
						if EyeTrace.Entity.Toggle then
							if self.LastPressed + 0.5 < CurTime() then
								EyeTrace.Entity:Switch(not EyeTrace.Entity:IsOn())
								self.LastPressed = CurTime()
							end
						elseif not EyeTrace.Entity:IsOn() then
							EyeTrace.Entity:Switch(true)
							EyeTrace.Entity.PrevUser = self.Ply
							EyeTrace.Entity.podpress = true
						end
					end
				end
			end
		else
			if self.Ply then --clear outputs
				Wire_TriggerOutput( self.Entity, "Active", 0) 
				for k, _ in pairs( self.keys )  do
					Wire_TriggerOutput( self.Entity, k, 0 )
				end
				Wire_TriggerOutput( self.Entity, "Team", 0)
				Wire_TriggerOutput( self.Entity, "Health", 0)
				Wire_TriggerOutput( self.Entity, "Armor", 0)
				Wire_TriggerOutput( self.Entity, "Distance", 0)
				Wire_TriggerOutput( self.Entity, "X", 0)
				Wire_TriggerOutput( self.Entity, "Y", 0)
				Wire_TriggerOutput( self.Entity, "Z", 0)
				Wire_TriggerOutput(self.Entity, "Bearing", 0)
				Wire_TriggerOutput(self.Entity, "Elevation", 0)
			end
			self.Ply = nil
		end
		if self.disablevar then
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


function MakeWireAdvPod(pl, Pos, Ang)
	if not pl:CheckLimit("wire_pods") then return false end
	
	local wire_pod = ents.Create("gmod_wire_adv_pod")
	if not wire_pod:IsValid() then return false end
	
	wire_pod:SetAngles(Ang)
	wire_pod:SetPos(Pos)
	wire_pod:Spawn()
	wire_pod:SetPlayer(pl)
	wire_pod.pl = pl
	
	pl:AddCount("wire_pods", wire_pod)
	
	return wire_pod
end
duplicator.RegisterEntityClass("gmod_wire_adv_pod", MakeWireAdvPod, "Pos", "Ang", "Vel", "aVel", "frozen")
