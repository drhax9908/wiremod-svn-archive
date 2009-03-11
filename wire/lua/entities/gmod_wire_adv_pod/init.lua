AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.WireDebugName = "Advanced Pod Controller"
local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	--self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.lockvar = 0
	self.disablevar = false
	self.crossvar = 0
	self.Entity:SetColor( 255, 0, 0, 255 )
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
	self.keys["Shift"] = IN_SPEED
	self.keys["Zoom"] = IN_ZOOM
	self.keys["Alt"] = IN_WALK
	self.keys["TurnLeftKey"] = IN_LEFT
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
	outputs[9] = "Shift"
	outputs[10] = "Zoom"
	outputs[11] = "Alt"
	outputs[12] = "TurnLeftKey"
	outputs[13] = "TurnRightKey"
	
	local n = 14
	
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
	
	// Create "Entity" output - must be at the end!
	local outputtypes = { }
	for i = 1, n do
		outputtypes[i] = "NORMAL"
	end
	
	n = n + 1
	outputs[n] = "Entity"
	outputtypes[n] = "ENTITY"
	
	//self.Outputs = Wire_CreateOutputs( self.Entity, outputs )
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, outputs, outputtypes)
	self.Inputs = Wire_CreateInputs( self.Entity, { "Lock", "Terminate", "Strip weapons", "Eject", "Disable", "Crosshairs", "Brake", "Allow Buttons", "Relative", "Damage Health", "Damage Armor"} )
	self:SetOverlayText( "Adv. Pod Controller" )
	
	self.pushbuttons = false
	self.LastPressed = 0
	self.BE_rel = false
end

function ENT:Link(pod,RC)
	if !pod then return false end
	self.Pod = pod
	self.RC = RC
	return true
end

local function RCEject(Ply)
	Ply.Active = false
	Ply:SetMoveType(2)
	Ply:DrawViewModel(true)
end

function ENT:TriggerInput(iname, value)
		if (iname == "Lock") then
			if self.RC then return end
			if !(self.Pod && self.Pod:IsValid()) then return end
			if (value > 0) then
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
					if self.RC then
						RCEject(self.Ply)
						self.Ply.Linked = false
					end
					self.Ply:Kill()
				end
			end
		elseif (iname == "Strip weapons") then
			if self.Ply and self.Ply:IsValid() then
				if (value > 0) then
					if self.RC then
						RCEject(self.Ply)
						self.Ply.Linked = false
						self.Ply:PrintMessage(HUD_PRINTTALK,"Your control has been terminated, and your weapons stripped!\n")
					end
					self.Ply:StripWeapons( )
					self.Ply:PrintMessage(HUD_PRINTTALK,"Your weapons have been stripped!\n")
				end
			end
		elseif (iname == "Eject") then
			if self.Ply and self.Ply:IsValid() then
				if (value > 0) then
					if self.RC then
						RCEject(self.Ply)
					else
						self.Ply:ExitVehicle( )
					end
				end
			end
		elseif (iname == "Disable") then
			self.disablevar = (value >= 1)
		elseif (iname == "Crosshairs") then
			if (value > 0) then
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
			if self.RC then return end
			if value > 0 then
				self.Pod:Fire("TurnOff", "1", 0)
				self.Pod:Fire("HandBrakeOn", "1", 0)
			else
				self.Pod:Fire("TurnOn", "1", 0)
				self.Pod:Fire("HandBrakeOff", "1", 0)
			end
		elseif (iname == "Damage Health") then
			if self.Ply and self.Ply:IsValid() then
				if value > 0 then
					if value > 100 then value = 100 end
					self.Ply:TakeDamage(value)
				end
			end
		elseif (iname == "Damage Armor") then
			if self.Ply and self.Ply:IsValid() then
				if value > 0 then
					if value > 100 then value = 100 end
					local armordam = self.Ply:Armor() - value
					if armordam < 0 then armordam = 0 end
					self.Ply:SetArmor(armordam)
				end
			end
		elseif (iname == "Allow Buttons") then
			if value > 0 then
				self.pushbuttons = true
			else
				self.pushbuttons = false
			end
		elseif (iname == "Relative") then
			if value > 0 then
				self.BE_rel = true
			else
				self.BE_rel = false
			end
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
	self.keys["Shift"] = IN_SPEED
	self.keys["Zoom"] = IN_ZOOM
	self.keys["Alt"] = IN_WALK
	self.keys["TurnLeftKey"] = IN_LEFT
	self.keys["TurnRightKey"] = IN_RIGHT
    self.BaseClass.OnRestore(self)
end

local function fixupangle(angle)
	if angle > 180 then angle = angle - 360 end
	if angle < -180 then angle = angle + 360 end
	return angle
end

function ENT:Think()
	local _,_,_,coloralpha = self.Entity:GetColor()
	if self.Pod and self.Pod:IsValid() then
		Wire_TriggerOutput( self.Entity, "Entity", self.Pod )
		local Ply = nil
		if self.RC then
			if !self.Pod:Alive() then self.Pod.Active = false end
			if self.Pod.Active then
				Ply = self.Pod
			end
		else
			Ply = self.Pod:GetPassenger()
		end
		if Ply and Ply:IsValid() then
			local temp = false
			if self.Ply == nil then
				if !self.RC then
					self.junkBE = CurTime() + 2
				else
					self.junkBE = nil
					temp = true
				end
			end
			self.Ply = Ply
			if temp then self.Ply.Initial = self.Ply:GetAimVector():Angle() end
			self.Entity:SetColor( 0, 255, 0, coloralpha )
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
				
				if self.BE_rel then
					local PodAngle
					if !self.RC then
						PodAngle = self.Pod:GetAngles()
						if self.Pod:GetClass() != "prop_vehicle_prisoner_pod" then
							PodAngle.y = PodAngle.y + 90
						end
					else
						PodAngle = self.Ply.Initial
					end
					Wire_TriggerOutput(self.Entity, "Bearing", fixupangle((AimVectorAngle.y - PodAngle.y)))
					Wire_TriggerOutput(self.Entity, "Elevation", fixupangle(-(AimVectorAngle.p - PodAngle.p)))
				else
					Wire_TriggerOutput(self.Entity, "Bearing", fixupangle((AimVectorAngle.y)))
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
				self.Entity:SetColor( 255, 0, 0, coloralpha )
				for k, _ in pairs( self.keys )  do
					Wire_TriggerOutput( self.Entity, k, 0 )
				end
				self.Pod.Initial = nil
				Wire_TriggerOutput( self.Entity, "Team", 0)
				Wire_TriggerOutput( self.Entity, "Health", 0)
				Wire_TriggerOutput( self.Entity, "Armor", 0)
				Wire_TriggerOutput( self.Entity, "Distance", 0)
				Wire_TriggerOutput( self.Entity, "X", 0)
				Wire_TriggerOutput( self.Entity, "Y", 0)
				Wire_TriggerOutput( self.Entity, "Z", 0)
				Wire_TriggerOutput(self.Entity, "Bearing", 0)
				Wire_TriggerOutput(self.Entity, "Elevation", 0)
				-- How the HECK shall this work? You are checking for "if Ply and Ply:IsValid() then" and now we are in the "else". So the player is invalid.
				--self.Ply.Initial = nil
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
	if (self.Pod) and (self.Pod:IsValid()) and (!self.RC) then
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


function MakeWireAdvPod(pl, Pos, Ang, Model, frozen)
	if not pl:CheckLimit("wire_pods") then return false end
	
	local wire_pod = ents.Create("gmod_wire_adv_pod")
	if not wire_pod:IsValid() then return false end
	wire_pod:SetModel( Model or MODEL )
	wire_pod:SetAngles(Ang)
	wire_pod:SetPos(Pos)
	wire_pod:Spawn()

	if wire_pod:GetPhysicsObject():IsValid() then
		wire_pod:GetPhysicsObject():EnableMotion(!frozen)
	end

	wire_pod:SetPlayer(pl)
	wire_pod.pl = pl
	
	pl:AddCount("wire_pods", wire_pod)
	pl:AddCleanup( "gmod_wire_adv_pod", wire_pod )
	
	return wire_pod
end
duplicator.RegisterEntityClass("gmod_wire_adv_pod", MakeWireAdvPod, "Pos", "Ang", "Model", "frozen")
