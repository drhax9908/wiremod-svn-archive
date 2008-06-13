TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Wheel"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "torque" ] 		= "3000"
TOOL.ClientConVar[ "friction" ] 	= "1"
TOOL.ClientConVar[ "nocollide" ] 	= "1"
TOOL.ClientConVar[ "forcelimit" ] 	= "0"
TOOL.ClientConVar[ "fwd" ] 			= "1"	// Forward
TOOL.ClientConVar[ "bck" ] 			= "-1"	// Back
TOOL.ClientConVar[ "stop" ] 		= "0"	// Stop

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
	language.Add( "Cleanup_wire_wheels", "Wire Wheels" )
	language.Add( "Cleaned_wire_wheels", "Cleaned up all Wire Wheels" )
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
	local model			= ply:GetInfo( "wheel_model" )
	
	local fwd			= self:GetClientNumber( "fwd" )
	local bck			= self:GetClientNumber( "bck" )
	local stop			= self:GetClientNumber( "stop" )
	
	if ( !util.IsValidModel( model ) ) then return false end
	if ( !util.IsValidProp( model ) ) then return false end
	
	if ( fwd == stop || bck == stop || fwd == bck ) then return false end
	
	// Create the wheel
	local wheelEnt = MakeWireWheel( ply, trace.HitPos, Angle(0,0,0), model, nil, nil, nil, fwd, bck, stop, torque )
	
	// Make sure we have our wheel angle
	self.wheelAngle = Angle( tonumber(ply:GetInfo( "wheel_rx" )), tonumber(ply:GetInfo( "wheel_ry" )), tonumber(ply:GetInfo( "wheel_rz" )) )
	
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
	
	wheelEnt:SetMotor( constraint )
	wheelEnt:SetDirection( constraint.direction )
	wheelEnt:SetAxis( trace.HitNormal )
	wheelEnt:SetToggle( toggle )
	wheelEnt:DoDirectionEffect()
	wheelEnt:SetBaseTorque( torque )

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
		
	wheelEnt:SetTorque( torque )
	wheelEnt:SetFwd( fwd )
	wheelEnt:SetBck( bck )
	wheelEnt:SetStop( stop )

	return true

end

if ( SERVER ) then

	/*---------------------------------------------------------
	   For duplicator, creates the wheel.
	---------------------------------------------------------*/
	function MakeWireWheel( pl, Pos, Ang, Model, Vel, aVel, frozen, fwd, bck, stop, BaseTorque, direction, axis, Data )
		
		if ( !pl:CheckLimit( "wire_wheels" ) ) then return false end
		
		local wheel = ents.Create( "gmod_wire_wheel" )
		if ( !wheel:IsValid() ) then return end
		
		wheel:SetModel( Model )
		wheel:SetPos( Pos )
		wheel:SetAngles( Ang )
		wheel:Spawn()
		
		wheel:SetPlayer( pl )
		
		duplicator.DoGenericPhysics( wheel, pl, Data )
		
		wheel.fwd = fwd
		wheel.bck = bck
		wheel.stop = stop
		
		wheel:SetFwd( fwd )
		wheel:SetBck( bck )
		wheel:SetStop( stop )

		if ( axis ) then
			wheel.Axis = axis
		end
		
		if ( direction ) then
			wheel:SetDirection( direction )
		end
		
		wheel:SetBaseTorque( BaseTorque )
		wheel:UpdateOverlayText()
		
		pl:AddCount( "wire_wheels", wheel )
		
		return wheel
		
	end

	duplicator.RegisterEntityClass( "gmod_wire_wheel", MakeWireWheel, "Pos", "Ang", "model", "Vel", "aVel", "frozen", "fwd", "bck", "stop", "BaseTorque", "direction", "Axis", "Data" )
	
	
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

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetOwner():GetInfo( "wheel_model" )) then
		self.wheelAngle = Angle( tonumber(self:GetOwner():GetInfo( "wheel_rx" )), tonumber(self:GetOwner():GetInfo( "wheel_ry" )), tonumber(self:GetOwner():GetInfo( "wheel_rz" )) )
		self:MakeGhostEntity( self:GetOwner():GetInfo( "wheel_model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireWheel( self.GhostEntity, self:GetOwner() )
	
end


function TOOL.BuildCPanel( CPanel )

	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool_wire_wheel_name", Description	= "#Tool_wire_wheel_desc" }  )
	
	local Options = { Default = {	wire_wheel_torque		= "3000",
									wire_wheel_friction		= "0",
									wire_wheel_nocollide	= "1",
									wire_wheel_forcelimit	= "0",
									wire_wheel_fwd			= "1",
									wire_wheel_bck			= "-1",
									wire_wheel_stop			= "0", } }
									
	local CVars = { "wire_wheel_torque", "wire_wheel_friction", "wire_wheel_nocollide", "wire_wheel_forcelimit", "wire_wheel_fwd", "wire_wheel_bck", "wire_wheel_stop" }
	
	CPanel:AddControl( "ComboBox", { Label = "#Presets",
									 MenuButton = 1,
									 Folder = "wire_wheel",
									 Options = Options,
									 CVars = CVars } )
									 
	CPanel:AddControl( "Slider", { Label = "#WireWheelTool_group",
									 Description = "#WireWheelTool_group_desc",
									 Type = "Float",
									 Min = -10,
									 Max = 10,
									 Command = "wire_wheel_fwd" } )
									 
	CPanel:AddControl( "Slider", { Label = "#WireWheelTool_group_stop",
									 Description = "#WireWheelTool_group_desc",
									 Type = "Float",
									 Min = -10,
									 Max = 10,
									 Command = "wire_wheel_stop" } )
									 
	CPanel:AddControl( "Slider", { Label = "#WireWheelTool_group_reverse",
									 Description = "#WireWheelTool_group_desc",
									 Type = "Float",
									 Min = -10,
									 Max = 10,
									 Command = "wire_wheel_bck" } )
									 
	CPanel:AddControl( "PropSelect", { Label = "#WheelTool_model",
									 ConVar = "wheel_model",
									 Category = "Wheels",
									 Models = list.Get( "WheelModels" ) } )
									 
	CPanel:AddControl( "Slider", { Label = "#WheelTool_torque",
									 Description = "#WheelTool_torque_desc",
									 Type = "Float",
									 Min = 10,
									 Max = 10000,
									 Command = "wire_wheel_torque" } )
									 
									 
	CPanel:AddControl( "Slider", { Label = "#WheelTool_forcelimit",
									 Description = "#WheelTool_forcelimit_desc",
									 Type = "Float",
									 Min = 0,
									 Max = 50000,
									 Command = "wire_wheel_forcelimit" } )
									 
	CPanel:AddControl( "Slider", { Label = "#WheelTool_friction",
									 Description = "#WheelTool_friction_desc",
									 Type = "Float",
									 Min = 0,
									 Max = 100,
									 Command = "wire_wheel_friction" } )
									 
	CPanel:AddControl( "CheckBox", { Label = "#WheelTool_nocollide",
									 Description = "#WheelTool_nocollide_desc",
									 Command = "wire_wheel_nocollide" } )
									 
end
