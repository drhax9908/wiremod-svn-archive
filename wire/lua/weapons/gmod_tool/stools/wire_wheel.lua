
TOOL.Category		= "Wire"
TOOL.Name			= "Wheel"
TOOL.Command		= nil
TOOL.ConfigName		= nil

TOOL.ClientConVar[ "torque" ] 		= "3000"
TOOL.ClientConVar[ "friction" ] 	= "1"
TOOL.ClientConVar[ "nocollide" ] 	= "1"
TOOL.ClientConVar[ "forcelimit" ] 	= "0"
TOOL.ClientConVar[ "fwd" ] 			= "1"	// Forward
TOOL.ClientConVar[ "bck" ] 			= "-1"	// Back
TOOL.ClientConVar[ "stop" ] 		= "0"	// Stop
TOOL.ClientConVar[ "model" ] 		= "models/props_vehicles/carparts_wheel01a.mdl"
TOOL.ClientConVar[ "rx" ] 			= "90"
TOOL.ClientConVar[ "ry" ] 			= "0"
TOOL.ClientConVar[ "rz" ] 			= "90"


// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then
	language.Add( "Tool_wire_wheel_name", "Wheel Tool (wire)" )
    language.Add( "Tool_wire_wheel_desc", "Attaches a wheel to something." )
    language.Add( "Tool_wire_wheel_0", "Click on a prop to attach a wheel." )
	
	language.Add( "WireWheelTool_group", "Input value to go forward:" )
	language.Add( "WireWheelTool_group_reverse", "Input value to go in reverse:" )
	language.Add( "WireWheelTool_group_stop", "Input value for no acceleration:" )
	language.Add( "WireWheelTool_group_desc", "All these values need to be different." )
	
	language.Add( "undone_WireWheel", "Undone Wire Wheel" )
	language.Add( "Cleanup_wire_wheels", "Wired Wheels" )
	language.Add( "Cleaned_wire_wheels", "Cleaned up all Wired Wheels" )
	language.Add( "SBoxLimit_wire_wheels", "You've reached the wired wheels limit!" )

end

if (SERVER) then
    CreateConVar('sbox_maxwire_wheels', 30)
end 

cleanup.Register( "wire_wheels" )

/*---------------------------------------------------------
   Places a wheel
---------------------------------------------------------*/
function TOOL:LeftClick( trace )

	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()

	if ( !self:GetSWEP():CheckLimit( "wire_wheels" ) ) then return false end

	local targetPhys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	
	// Get client's CVars
	local torque		= self:GetClientNumber( "torque" )
	local friction 		= self:GetClientNumber( "friction" )
	local nocollide		= self:GetClientNumber( "nocollide" )
	local limit			= self:GetClientNumber( "forcelimit" )
	local model			= self:GetClientInfo( "model" )
	
	local fwd			= self:GetClientNumber( "fwd" )
	local bck			= self:GetClientNumber( "bck" )
	local stop			= self:GetClientNumber( "stop" )
	
	if ( !util.IsValidModel( model ) ) then return false end
	if ( !util.IsValidProp( model ) ) then return false end
	
	if ( fwd == stop || bck == stop || fwd == bck ) then return false end
	
	
	// Create the wheel
	local wheelEnt = MakeWireWheel( ply, trace.HitPos, Angle(0,0,0), model, nil, nil, nil, fwd, bck, stop )
	
	
	// Make sure we have our wheel angle
	self.wheelAngle = Angle( tonumber(self:GetClientInfo( "rx" )), tonumber(self:GetClientInfo( "ry" )), tonumber(self:GetClientInfo( "rz" )) )
	
	local TargetAngle = trace.HitNormal:Angle() + self.wheelAngle	
	wheelEnt:SetAngles( TargetAngle )
	
	local CurPos = wheelEnt:GetPos()
	local NearestPoint = wheelEnt:NearestPoint( CurPos - (trace.HitNormal * 512) )
	local wheelOffset = CurPos - NearestPoint
		
	wheelEnt:SetPos( trace.HitPos + wheelOffset + trace.HitNormal )
	
	// Wake up the physics object so that the entity updates
	wheelEnt:GetPhysicsObject():Wake()
	
	local TargetPos = wheelEnt:GetPos()
			
	// Set the hinge Axis perpendicular to the trace hit surface
	local LPos1 = wheelEnt:GetPhysicsObject():WorldToLocal( TargetPos + trace.HitNormal )
	local LPos2 = targetPhys:WorldToLocal( trace.HitPos )
	
	local constraint, axis = constraint.Motor( wheelEnt, trace.Entity, 0, trace.PhysicsBone, LPos1,	LPos2, friction, torque, 0, nocollide, false, ply, limit )
	
	undo.Create("WireWheel")
	undo.AddEntity( axis )
	undo.AddEntity( constraint )
	undo.AddEntity( wheelEnt )
	undo.SetPlayer( ply )
	undo.Finish()

	
	ply:AddCleanup( "wire_wheels", axis )
	ply:AddCleanup( "wire_wheels", constraint )
	ply:AddCleanup( "wire_wheels", wheelEnt )
	
	wheelEnt:GetTable():SetMotor( constraint )
	wheelEnt:GetTable():SetDirection( constraint:GetTable().direction )
	wheelEnt:GetTable():SetAxis( trace.HitNormal )
	wheelEnt:GetTable():SetToggle( toggle )
	wheelEnt:GetTable():DoDirectionEffect()
	wheelEnt:GetTable():SetBaseTorque( torque )

	return true

end


/*---------------------------------------------------------
   Apply new values to the wheel
---------------------------------------------------------*/
function TOOL:RightClick( trace )

	if ( trace.Entity && trace.Entity:GetClass() != "gmod_wire_wheel" ) then return false end
	if (CLIENT) then return true end
	
	local wheelEnt = trace.Entity
	
	// Only change your own wheels..
	if ( wheelEnt:GetTable():GetPlayer():IsValid() && 
	     wheelEnt:GetTable():GetPlayer() != self:GetOwner() ) then 
		 
		 return false 
		 
	end

	// Get client's CVars
	local torque		= self:GetClientNumber( "torque" )
	local toggle		= self:GetClientNumber( "toggle" ) != 0
	local fwd			= self:GetClientNumber( "fwd" )
	local bck			= self:GetClientNumber( "bck" )
	local stop			= self:GetClientNumber( "stop" )
		
	wheelEnt:GetTable():SetTorque( torque )
	wheelEnt:GetTable():SetFwd( fwd )
	wheelEnt:GetTable():SetBck( bck )
	wheelEnt:GetTable():SetStop( stop )

	return true

end

if ( SERVER ) then

	/*---------------------------------------------------------
	   For duplicator, creates the wheel.
	---------------------------------------------------------*/
	function MakeWireWheel( pl, Pos, Ang, Model, Vel, aVel, frozen, fwd, bck, stop )

		if ( !pl:CheckLimit( "wire_wheels" ) ) then return false end
	
		local wheel = ents.Create( "gmod_wire_wheel" )
		if ( !wheel:IsValid() ) then return end
		
		wheel:SetModel( Model )
		wheel:SetPos( Pos )
		wheel:SetAngles( Ang )
		wheel:Spawn()
		
		wheel:GetTable():SetPlayer( pl )

		if ( wheel:GetPhysicsObject():IsValid() ) then
		
			Phys = wheel:GetPhysicsObject()
			if Vel then Phys:SetVelocity(Vel) end
			if aVel then Phys:AddAngleVelocity(aVel) end
			Phys:EnableMotion(frozen != true)
			
		end
	
		wheel:GetTable().model = model
		wheel:GetTable().fwd = fwd
		wheel:GetTable().bck = bck
		wheel:GetTable().stop = stop
		
		wheel:GetTable():SetFwd( fwd )
		wheel:GetTable():SetBck( bck )
		wheel:GetTable():SetStop( stop )
		
		/*local ttable = {
			pl			= pl,
			nocollide	= nocollide,
			description = description,
			Pos			= Pos,
			Ang			= Ang,
			Model		= Model,
			fwd			= fwd,
			bck			= bck,
			stop		= stop
		}
		
		table.Merge( wheel:GetTable(), ttable )*/
		
		
		pl:AddCount( "wire_wheels", wheel )
		
		return wheel
		
	end

	duplicator.RegisterEntityClass( "gmod_wire_wheel", MakeWireWheel, "Pos", "Ang", "model", "Vel", "aVel", "frozen", "fwd", "bck", "stop" )
	

end

function TOOL:UpdateGhostWireWheel( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end
	
	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if ( trace.Entity:IsPlayer() ) then
	
		ent:SetNoDraw( true )
		return
		
	end
	
	local Ang = trace.HitNormal:Angle() + self.wheelAngle
	local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint( CurPos - (trace.HitNormal * 512) )
	local WheelOffset = CurPos - NearestPoint
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos + trace.HitNormal + WheelOffset )
	ent:SetAngles( Ang )
	
	ent:SetNoDraw( false )
	
end

/*---------------------------------------------------------
   Maintains the ghost wheel
---------------------------------------------------------*/
function TOOL:Think()

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self.wheelAngle = Angle( tonumber(self:GetClientInfo( "rx" )), tonumber(self:GetClientInfo( "ry" )), tonumber(self:GetClientInfo( "rz" )) )
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireWheel( self.GhostEntity, self:GetOwner() )
	
end
