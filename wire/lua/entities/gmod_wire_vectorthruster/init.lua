
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Thruster"

local Thruster_Sound 	= Sound( "PhysicsCannister.ThrusterLoop" )
local MODEL = Model("models/jaanus/wiretool/wiretool_speed.mdl")

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetModel( MODEL )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	local max = self.Entity:OBBMaxs()
	local min = self.Entity:OBBMins()
	
	self.X = 0
	self.Y = 0
	self.Z = 0
	self.ToWorld = false
	
	self.ThrustOffset 	= Vector( 0, 0, 0 )
	--self.ThrustOffset 	= Vector( 0, 0, max.z )
	--self.ThrustOffsetR 	= Vector( 0, 0, min.z )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1
	
	self:SetForce( 2000 )
	
	self.OWEffect = "fire"
	self.UWEffect = "same"
	
	self:SetOffset( self.ThrustOffset )
	self.Entity:StartMotionController()
	
	self:Switch( false )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "Mul", "X", "Y", "Z", "ToWorld" }) //, "Pitch", "Yaw", "Roll"
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( "gmod_wire_vectorthruster" )
	ent:SetPos( SpawnPos )
	ent:SetPlayer( ply )
	ent:Spawn()
	ent:Activate()
	
	ent:Setup(5000, 0, 10000, "fire", "same", true, true, true, true)
	
	local ttable = {
		force		= 5000,
		force_min	= 0,
		force_max	= 10000,
		bidir       = true,
		sound       = true,
		pl			= ply,
		oweffect	= "fire",
		uweffect	= "same",
		owater		= true,
		uwater		= true,
		nocollide	= true
		}
	table.Merge(ent:GetTable(), ttable )
	
	return ent
end

function MakeWireVectorThruster( pl, Model, Ang, Pos, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_thrusters" ) ) then return false end
		
		local wire_thruster = ents.Create( "gmod_wire_vectorthruster" )
		if (!wire_thruster:IsValid()) then return false end
		wire_thruster:SetModel( Model )
		
		wire_thruster:SetAngles( Ang )
		wire_thruster:SetPos( Pos )
		wire_thruster:Spawn()
		
		wire_thruster:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound)
		wire_thruster:SetPlayer( pl )
		
		local ttable = {
			force		= force,
			force_min	= force_min,
			force_max	= force_max,
			bidir       = bidir,
			sound       = sound,
			pl			= pl,
			oweffect	= oweffect,
			uweffect	= uweffect,
			owater		= owater,
			uwater		= uwater,
			nocollide	= nocollide
			}
		
		table.Merge(wire_thruster:GetTable(), ttable )
		
		pl:AddCount( "wire_thrusters", wire_thruster )
		
		DoPropSpawnedEffect( wire_thruster )
		
		return wire_thruster
	end
duplicator.RegisterEntityClass("gmod_wire_vectorthruster", MakeWireVectorThruster, "Model", "Ang", "Pos", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "sound", "nocollide", "Vel", "aVel", "frozen")


function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
	
    if (self.EnableSound) then
		self.Entity:StopSound(Thruster_Sound)
	end
end

function ENT:SetForce( force, mul )
	if (force) then self.force = force end
	mul = mul or 1
	self.mul = mul
	
	local phys = self.Entity:GetPhysicsObject()
	if (!phys:IsValid()) then
		Msg("Warning: [gmod_thruster] Physics object isn't valid!\n")
		return
	end
	
	local ThrusterWorldPos
	local ThrusterWorldForce
	if (self.ToWorld) then
		ThrusterWorldPos = self.Entity:GetPos() + self.ThrustOffset
		ThrusterWorldForce = self.ThrustOffset * -1
	else
		// Get the data in worldspace
		ThrusterWorldPos = phys:LocalToWorld( self.ThrustOffset )
		ThrusterWorldForce = phys:LocalToWorldVector( self.ThrustOffset * -1 )
	end
	/*Msg("======\nself.Entity:GetPos() = "..tostring(self.Entity:GetPos()).."\n")
	Msg("ThrusterWorldPos = "..tostring(ThrusterWorldPos).."\n")
	Msg("ThrusterWorldForce = "..tostring(ThrusterWorldForce).."\n")*/
	
	
	--Msg("===============\nThrusterWorldPos = "..tostring(ThrusterWorldPos).."\n")
	--Msg("ThrusterWorldForce = "..tostring(ThrusterWorldForce).."\n")
	
	// Calculate the velocity
	ThrusterWorldForce = ThrusterWorldForce * self.force * mul * 10
	
	--Msg("ThrusterWorldPos = "..tostring(ThrusterWorldPos).."\n")
	--Msg(":GetNormalized() = "..tostring(ThrusterWorldPos:GetNormalized()).."\n")
	
	self.ForceLinear, self.ForceAngle = phys:CalculateVelocityOffset( ThrusterWorldForce, ThrusterWorldPos );
	
	--Msg("ForceLinear = "..tostring(self.ForceLinear).."\n")
	--Msg("ForceAngle = "..tostring(self.ForceAngle).."\n")
	
	self.ForceLinear = phys:WorldToLocalVector( self.ForceLinear )
	
	--Msg("ForceLinearL = "..tostring(self.ForceLinear).."\n")
	
	--self:SetOffset( self.ThrustOffset )
	
--	self.Entity:SetNetworkedVector( 1, self.ForceAngle )
--	self.Entity:SetNetworkedVector( 2, self.ForceLinear )
end

function ENT:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound)
	self:SetForce(force)
	
	self.OWEffect = oweffect
	self.UWEffect = uweffect
	self.ForceMin = force_min
	self.ForceMax = force_max
	self.BiDir = bidir
	self.EnableSound = sound
	self.OWater = owater
	self.UWater = uwater
	
	if (not sound) then
		self.Entity:StopSound(Thruster_Sound)
	end
	
	self:SetOverlayText( "Thrust = " .. 0 .. "\nMul: " .. math.Round(force*1000)/1000 )
end

function ENT:TriggerInput(iname, value)
	
	if (iname == "Mul") then
		if (value == 0) then
			self:Switch(false, 0)
		elseif ( (self.BiDir) and (math.abs(value) > 0.01) and (math.abs(value) > self.ForceMin) ) or ( (value > 0.01) and (value > self.ForceMin) ) then
			self:Switch(true, math.min(value, self.ForceMax))
		else
			self:Switch(false, 0)
		end
		return
	end
	
	if (iname == "ToWorld") then
		if (value > 0) then
			self.ToWorld = true
		else
			self.ToWorld = false
		end
		self:SetToWorld( self.ToWorld )
		--Msg("self.ToWorld= "..tostring(self.ToWorld).."\n")
		self:Switch( self:IsOn(), self.mul )
		return
	end
	
	if (iname == "X") then
		self.X = value
	end
	if (iname == "Y") then
		self.Y = value
	end
	if (iname == "Z") then
		self.Z = value
	end
	if (iname == "X") or (iname == "Y") or (iname == "Z") then
		self.ThrustOffset = Vector( self.X, self.Y, self.Z ):GetNormalized()
	end
	
	/*if (iname == "Offset_Pitch") then
		self.ThrustOffset = math.RotationMatrix( Vector(1,0,0), value, self.ThrustOffset )
	end
	if (iname == "Offset_Yaw") then
		self.ThrustOffset = math.RotationMatrix( Vector(0,0,1), value, self.ThrustOffset )
	end
	if (iname == "Offset_Roll") then
		self.ThrustOffset = math.RotationMatrix( Vector(0,1,0), value, self.ThrustOffset )
	end*/
	
	if (self.ThrustOffset == Vector(0,0,0)) then
		self:SetOn( false )
	end
	
	self:SetOffset( self.ThrustOffset )
	//self.ForceAngle = self.ThrustOffset * -1
	--self:SetForce( self.force, self.mul )
	self:Switch( self:IsOn(), self.mul )
	
end

function ENT:PhysicsSimulate( phys, deltatime )
	if (!self:IsOn()) then return SIM_NOTHING end
	if (self.Entity:IsPlayerHolding()) then return SIM_NOTHING end
	
	if (self.Entity:WaterLevel() > 0) then
	    if (not self.UWater) then
	    	self:SetEffect("none")
			return SIM_NOTHING
		end
		
		if (self.UWEffect == "same") then
	    	self:SetEffect(self.OWEffect)
		else
	    	self:SetEffect(self.UWEffect)
		end
	else
	    if (not self.OWater) then
	    	self:SetEffect("none")
			return SIM_NOTHING
		end
		
	    self:SetEffect(self.OWEffect)
	end
	
	local ForceAngle, ForceLinear = self.ForceAngle, self.ForceLinear
	
	return ForceAngle, ForceLinear, SIM_LOCAL_ACCELERATION
end

function ENT:Switch( on, mul )
	if (!self.Entity:IsValid()) then return false end
	
	local changed = (self:IsOn() ~= on)
	self:SetOn( on )
	
	if (on) then 
	    if (changed) and (self.EnableSound) then
			self.Entity:StopSound( Thruster_Sound )
			self.Entity:EmitSound( Thruster_Sound )
		end
		
		if (mul ~= self.PrevOutput) then
			self:SetOverlayText( "Thrust = " .. math.Round(self.force*mul*1000)/1000 .. "\nMul: " .. math.Round(self.force*1000)/1000 )
			self.PrevOutput = mul
		end
		
		self:SetForce( nil, mul )
	else
	    if (self.EnableSound) then
			self.Entity:StopSound( Thruster_Sound )
		end
		
		if (self.PrevOutput) then
			self:SetOverlayText( "Thrust = Off".."\nMul: "..math.Round(self.force*1000)/1000 )
			self.PrevOutput = nil
		end
	end
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	return true
end

function ENT:OnRestore()
	local phys = self.Entity:GetPhysicsObject()
	
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	local max = self.Entity:OBBMaxs()
	local min = self.Entity:OBBMins()
	
	self.ThrustOffset 	= Vector( 0, 0, 1)
	--self.ThrustOffset 	= Vector( 0, 0, max.z )
	--self.ThrustOffsetR 	= Vector( 0, 0, min.z )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1
	
	self:SetOffset( self.ThrustOffset )
	self.Entity:StartMotionController()
	
	if (self.PrevOutput) then
		self:Switch(true, self.PrevOutput)
	else
		self:Switch(false)
	end
	
    self.BaseClass.OnRestore(self)
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	
	if (self.PrevOutput) and (self:IsOn()) then
		info.PrevOutput = self.PrevOutput
	end
	
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	
	if (info.PrevOutput) then
		self:Switch(true, info.PrevOutput)
	end
	
end
