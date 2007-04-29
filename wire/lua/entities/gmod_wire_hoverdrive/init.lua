
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "HoverDrive"

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	
	self.Entity:SetModel( "models//props_c17/utilityconducter001.mdl" )
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	//self.Entity:SetModel( "models/dav0r/hoverball.mdl" )
	//self.Entity:PhysicsInitSphere( 8, "metal_bouncy" )
	
	local phys = self.Entity:GetPhysicsObject()
	
	if ( phys:IsValid() ) then 
		phys:SetMass( 100 )
		phys:EnableGravity( false )
		phys:Wake() 
	end
	
	self.Entity:StartMotionController()
	
	self.Fraction = 0
	
	self.ZVelocity = 0
	self.XVelocity = 0
	self.YVelocity = 0
	self:SetTargetZ( self.Entity:GetPos().z )
	//self:SetTargetX( self.Entity:GetPos().x )
	//self:SetTargetY( self.Entity:GetPos().y )
	self.Target = self.Entity:GetPos()
	self:SetSpeed( 1 )
	self:SetStrength( 10 )
	self:EnableHover()

	//self.Inputs = Wire_CreateInputs(self.Entity, { "X_Velocity", "Y_Velocity", "Z_Velocity", "HoverMode" })
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity, {"Data"}, {"HOVERDATAPORT"})
	self.Outputs = Wire_CreateOutputs(self.Entity, { "A: Zpos", "B: Xpos", "C: Ypos" })
	
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16

	local ent = ents.Create( "gmod_wire_hoverdrive" )
	ent:SetPos( SpawnPos )
	ent:SetPlayer( ply )
	ent:Spawn()
	ent:Activate()
	
	ent:SetSpeed( 1 )
	ent:SetAirResistance( 0 )
	ent:SetStrength( 10 )
	
	return ent
end

function ENT:OnInputWireLink(iname, iType, src, oname, oType)
	self.Offset = self.Entity:GetPos() - src.Entity:GetPos()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Data") then
		self.Target = value.Target + self.Offset
		if (value.Hover >= 1) and (!self:GetHoverMode()) then
			self:EnableHover()
		elseif (value.Hover == 0) and (self:GetHoverMode()) then
			self:DisableHover()
		end
	end
end


function ENT:EnableHover()
	self:SetHoverMode( 1 )
	self:SetStrength( self.strength or 1 ) //reset weight so it will work
	self:SetTargetZ( self.Entity:GetPos().z ) //set height to current
	self.Target = self.Entity:GetPos()
	local phys = self.Entity:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:EnableGravity( false )
		phys:Wake()
	end
end

function ENT:DisableHover()
	self:SetHoverMode( 0 )
	self:SetStrength(0.1) //for less dead weight while off
	local phys = self.Entity:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:EnableGravity( true ) //falls slowly otherwise
	end
end


function ENT:OnRestore()
	self.ZVelocity = 0
	self.XVelocity = 0
	self.YVelocity = 0
	
	self.BaseClass.OnRestore(self)
end

/*---------------------------------------------------------
   Name: OnTakeDamage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )
	//self.Entity:TakePhysicsDamage( dmginfo )
end

/*---------------------------------------------------------
   Name: Think
---------------------------------------------------------*/
function ENT:Think()

	self.Entity:NextThink( CurTime() + 0.25 )

	self.Entity:SetNetworkedInt( "TargetZ", self:GetTargetZ() )
	
	return true
	
end


local function GetTargetAndExponent(deltatime, Target, Velocity, AxisPos, AxisVel, AirResistance, Speed)
	if ( Velocity != 0 ) then
		Target = Target + ( Velocity * deltatime * Speed )
	end
	
	local Diff = Target - AxisPos
	Diff = math.Clamp( Diff, -600, 600 )
	
	if ( Diff == 0 ) then
		return Target, 0
	end
	
	local Exponent = Diff^2
	if ( Diff < 0 ) then
		Exponent = Exponent * -1
	end
	Exponent = ( Exponent * deltatime * 300 ) - ( AxisVel * deltatime * 600 * ( AirResistance + 1 ) )
	
	//Exponent = Exponent//Exponent = math.Clamp( Exponent, -5000, 5000 )
	
	return Target, math.Clamp( Exponent, -5000, 5000 ) //Exponent
end

local function GetTargetAndExponentVector(deltatime, Target, Velocity, AxisPos, AxisVel, AirResistance, Speed)
	if ( Velocity != 0 ) then
		Target = Target + ( Velocity * deltatime * Speed )
	end
	
	local Diff = Target - AxisPos
	Diff.x = math.Clamp( Diff.x, -100, 100 )
	Diff.y = math.Clamp( Diff.y, -100, 100 )
	Diff.z = math.Clamp( Diff.z, -100, 100 )
	
	if ( Diff == Vector(0,0,0) ) then
		return Target, Vector(0,0,0)
	end
	
	local Exponent = Vector()
	Exponent.x = Diff.x^2
	Exponent.y = Diff.y^2
	Exponent.z = Diff.z^2
	
	if ( Diff.x < 0 ) then Exponent.x = Exponent.x * -1 end
	if ( Diff.y < 0 ) then Exponent.y = Exponent.y * -1 end
	if ( Diff.z < 0 ) then Exponent.z = Exponent.z * -1 end
	
	Exponent = ( Exponent * deltatime * 300 ) - ( AxisVel * deltatime * 600 * ( AirResistance + 1 ) )
	
	Exponent.x = math.Clamp( Exponent.x, -5000, 5000 )
	Exponent.y = math.Clamp( Exponent.y, -5000, 5000 )
	Exponent.z = math.Clamp( Exponent.z, -5000, 5000 )
	
	return Target, Exponent
end

/*---------------------------------------------------------
   Name: Simulate
---------------------------------------------------------*/
function ENT:PhysicsSimulate( phys, deltatime )
	
	local Pos = phys:GetPos()
	//local txt = string.format( "Speed: %i\nResistance: %.2f", self:GetSpeed(), self:GetAirResistance() )
	//txt = txt.."\nZ pos: "..math.floor(Pos.z) //.."Target: "..math.floor(self:GetTargetZ())
	
	local txt = "TargetX = "..self.Target.x.."\nTargetY = "..self.Target.y.."\nTargetZ = "..self.Target.z
	
	Wire_TriggerOutput(self.Entity, "A: Zpos", Pos.z)
	Wire_TriggerOutput(self.Entity, "B: Xpos", Pos.x)
	Wire_TriggerOutput(self.Entity, "C: Ypos", Pos.y)
	
	
	if (self:GetHoverMode() > 0) then
		
		txt = txt.."\n(on)"
		self:SetOverlayText( txt )
		
		local physVel = phys:GetVelocity()
		local physAngVel = phys:GetAngleVelocity()
		local AirResistance = self:GetAirResistance()
		local Speed = self:GetSpeed()
	
		phys:Wake()
		
		self.Velovity = Vector( self.XVelocity, self.YVelocity, self.ZVelocity )
		local Vel = phys:LocalToWorldVector( self.Velovity )
		
		/*local TargetX, ExponentX = GetTargetAndExponent(deltatime, self:GetTargetX(), Vel.x, Pos.x, physVel.x, AirResistance, Speed)
		self:SetTargetX(TargetX)
		
		local TargetY, ExponentY = GetTargetAndExponent(deltatime, self:GetTargetY(), Vel.y, Pos.y, physVel.y, AirResistance, Speed)
		self:SetTargetY(TargetY)
		
		local TargetZ, ExponentZ = GetTargetAndExponent(deltatime, self:GetTargetZ(), Vel.z, Pos.z, physVel.z, AirResistance, Speed)
		self:SetTargetZ(TargetZ)*/
		
		local Target, Exponent = GetTargetAndExponentVector(deltatime, self.Target, Vel, Pos, physVel, AirResistance, Speed)
		self.Target = Target
		self:SetTargetZ(Target.Z)
			
		local Ang = phys:GetAngles()
		
		if ( Exponent == Vector(0,0,0) ) then return end
		
		//local Linear = Vector(0,0,0)
		local Angular = Vector(0,0,0)
		
		/*Linear.z = ExponentZ
		Linear.x = ExponentX
		Linear.y = ExponentY*/
		// Linear
		return Angular, Exponent, SIM_GLOBAL_ACCELERATION //SIM_LOCAL_ACCELERATION
	else
		txt = txt.."\n(off)"
		self:SetOverlayText( txt )
		return SIM_GLOBAL_FORCE
	end

end

function ENT:SetZVelocity( z )

	if ( z != 0 ) then
		self.Entity:GetPhysicsObject():Wake()
	end

	self.ZVelocity = z * FrameTime() * 5000
end

function ENT:SetXVelocity( x )

	if ( x != 0 ) then
		self.Entity:GetPhysicsObject():Wake()
	end

	self.XVelocity = x * FrameTime() * 5000
end

function ENT:SetYVelocity( y )

	if ( y != 0 ) then
		self.Entity:GetPhysicsObject():Wake()
	end

	self.YVelocity = y * FrameTime() * 5000
end

/*---------------------------------------------------------
   GetAirFriction
---------------------------------------------------------*/
function ENT:GetAirResistance( )
	return self.Entity:GetVar( "AirResistance", 0 )
end


/*---------------------------------------------------------
   SetAirFriction
---------------------------------------------------------*/
function ENT:SetAirResistance( num )
	self.Entity:SetVar( "AirResistance", num )
end

/*---------------------------------------------------------
   SetStrength
---------------------------------------------------------*/
function ENT:SetStrength( strength )

	local phys = self.Entity:GetPhysicsObject()
	if ( phys:IsValid() ) then 
		phys:SetMass( 150 * strength )
	end
end





		



