
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Turret"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "trigger" ] 		= "1"
TOOL.ClientConVar[ "delay" ] 		= "0.05"
TOOL.ClientConVar[ "toggle" ] 		= "0"
TOOL.ClientConVar[ "force" ] 		= "1"
TOOL.ClientConVar[ "sound" ] 		= "0"
TOOL.ClientConVar[ "damage" ] 		= "10"
TOOL.ClientConVar[ "spread" ] 		= "0"
TOOL.ClientConVar[ "numbullets" ]	= "1"
TOOL.ClientConVar[ "automatic" ]	= "1"
TOOL.ClientConVar[ "tracer" ] 		= "Tracer"

cleanup.Register( "wire_turrets" )

// Precache these sounds..
Sound( "ambient.electrical_zap_3" )
Sound( "NPC_FloorTurret.Shoot" )

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then

	language.Add( "Tool_wire_turret_name", "Turret" )
	language.Add( "Tool_wire_turret_desc", "Throws bullets at things" )
	language.Add( "Tool_wire_turret_0", "Click somewhere to spawn an turret. Click on an existing turret to change it." )
	
	language.Add( "Tool_wire_turret_spread", "Bullet Spread" )
	language.Add( "Tool_wire_turret_numbullets", "Bullets per Shot" )
	language.Add( "Tool_wire_turret_force", "Bullet Force" )
	language.Add( "Tool_wire_turret_sound", "Shoot Sound" )
	language.Add( "Tool_wire_turret_trigger", "Trigger Value" )
	
	language.Add( "Undone_wire_turret", "Undone Turret" )
	
	language.Add( "Cleanup_wire_turrets", "Turret" )
	language.Add( "Cleaned_wire_turrets", "Cleaned up all Turrets" )
	language.Add( "SBoxLimit_wire_turrets", "You've reached the Turret limit!" )

end

if (SERVER) then
    CreateConVar('sbox_maxwire_turrets', 30)
end 

function TOOL:LeftClick( trace, worldweld )

	worldweld = worldweld or false

	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local trigger 		= self:GetClientNumber( "trigger" ) 
	local delay 		= self:GetClientNumber( "delay" ) 
	local toggle 		= self:GetClientNumber( "toggle" ) == 1
	local force 		= self:GetClientNumber( "force" )
	local sound 		= self:GetClientInfo( "sound" )
	local tracer 		= self:GetClientInfo( "tracer" )
	local damage	 	= self:GetClientNumber( "damage" )
	local spread	 	= self:GetClientNumber( "spread" )
	local numbullets 	= self:GetClientNumber( "numbullets" )
	
	
	// We shot an existing turret - just change its values
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_turret" && trace.Entity:GetTable().pl == ply ) then

		trace.Entity:GetTable():SetDamage( damage )
		trace.Entity:GetTable():SetDelay( delay )
		trace.Entity:GetTable():SetToggle( toggle )
		trace.Entity:GetTable():SetNumBullets( numbullets )
		trace.Entity:GetTable():SetSpread( spread )
		trace.Entity:GetTable():SetForce( force )
		trace.Entity:GetTable():SetSound( sound )
		trace.Entity:GetTable():SetTracer( tracer )
		trace.Entity:GetTable():SetTrigger( trigger )
		return true
		
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_turrets" ) ) then return false end

	if ( trace.Entity != NULL && (!trace.Entity:IsWorld() || worldweld) ) then
	
		trace.HitPos = trace.HitPos + trace.HitNormal * 2
	
	else
	
		trace.HitPos = trace.HitPos + trace.HitNormal * 2
	
	end


	local turret = MakeWireTurret( ply, trace.HitPos, nil, trigger, delay, toggle, damage, force, sound, numbullets, spread, tracer )
	/*
	local Angle = trace.HitNormal:Angle()
		Angle:RotateAroundAxis( Angle:Forward(), 90 )
		Angle:RotateAroundAxis( Angle:Forward(), 90 )
	*/
	turret:SetAngles( trace.HitNormal:Angle() )
	
	local weld = WireLib.Weld(turret, trace.Entity, trace.PhysicsBone, true, false, worldweld)
	
	undo.Create("WireTurret")
		undo.AddEntity( turret )
		undo.AddEntity( weld )
		undo.SetPlayer( ply )
	undo.Finish()
	
	return true

end

function TOOL:RightClick( trace )
	return self:LeftClick( trace, true )
end

if (SERVER) then

	function MakeWireTurret( ply, Pos, Ang, trigger, delay, toggle, damage, force, sound, numbullets, spread, tracer, Vel, aVel, frozen, nocollide )
	
		if ( !ply:CheckLimit( "wire_turrets" ) ) then return nil end
		
		local turret = ents.Create( "gmod_wire_turret" )
		if (!turret:IsValid()) then return false end
		
		turret:SetPos( Pos )
		if ( Ang ) then turret:SetAngles( Ang ) end
		turret:Spawn()
		
		
		if ( !SinglePlayer() ) then
			
			// Clamp stuff in multiplayer.. because people are idiots
			
			delay		= math.Clamp( delay, 0.05, 3600 )
			numbullets	= 1
			force		= math.Clamp( force, 0.01, 100 )
			spread		= math.Clamp( spread, 0, 1 )
			damage		= math.Clamp( damage, 0, 500 )
			
		end
		
		turret:GetTable():SetDamage( damage )
		turret:GetTable():SetPlayer( ply )
		
		turret:GetTable():SetSpread( spread )
		turret:GetTable():SetForce( force )
		turret:GetTable():SetSound( sound )
		turret:GetTable():SetTracer( tracer )
		
		turret:GetTable():SetNumBullets( numbullets )
		
		turret:GetTable():SetDelay( delay )
		turret:GetTable():SetToggle( toggle )
		
		turret:GetTable():SetTrigger( trigger )
		
		if ( nocollide == true ) then turret:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = 
		{
			trigger		= trigger,
			delay 		= delay,
			toggle 		= toggle,
			damage 		= damage,
			pl			= ply,
			nocollide 	= nocollide,
			force		= force,
			sound		= sound,
			spread		= spread,
			numbullets	= numbullets,
			tracer		= tracer
		}

		table.Merge( turret:GetTable(), ttable )
		
		ply:AddCount( "wire_turrets", turret )
		ply:AddCleanup( "wire_turrets", turret )

		return turret
		
	end
	
	duplicator.RegisterEntityClass( "gmod_wire_turret", MakeWireTurret, "Pos", "Ang", "trigger", "delay", "toggle", "damage", "force", "sound", "numbullets", "spread", "tracer", "Vel", "aVel", "frozen", "nocollide" )

end

function TOOL.BuildCPanel( CPanel )

	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool_wire_turret_name", Description	= "#Tool_wire_turret_desc" }  )
	
	// Presets
	local params = { Label = "#Presets", MenuButton = 1, Folder = "wire_turret", Options = {}, CVars = {} }
		
		params.Options.default = {
			wire_turret_trigger		= 		1,
			wire_turret_delay		=		0.2,
			wire_turret_toggle		=		1,
			wire_turret_force		=		1,
			wire_turret_sound		=		"pistol",
			wire_turret_damage		=		10,
			wire_turret_spread		=		0,
			wire_turret_numbullets	=		1,
		}
			
		table.insert( params.CVars, "wire_turret_trigger" )
		table.insert( params.CVars, "wire_turret_delay" )
		table.insert( params.CVars, "wire_turret_toggle" )
		table.insert( params.CVars, "wire_turret_force" )
		table.insert( params.CVars, "wire_turret_sound" )
		table.insert( params.CVars, "wire_turret_damage" )
		table.insert( params.CVars, "wire_turret_spread" )
		table.insert( params.CVars, "wire_turret_numbullets" )
		
	CPanel:AddControl( "ComboBox", params )
	
	//trigger value
	CPanel:AddControl( "Slider",  { Label	= "#Tool_wire_turret_trigger",
									Type	= "Integer",
									Min		= 0,
									Max		= 10,
									Command = "wire_turret_trigger" }	 )
	
	// Shot sounds
	local weaponSounds = {Label = "#Tool_wire_turret_sound", MenuButton = 0, Options={}, CVars = {}}
		weaponSounds["Options"]["#No Weapon"]	= { wire_turret_sound = "" }
		weaponSounds["Options"]["#Pistol"]		= { wire_turret_sound = "Weapon_Pistol.Single" }
		weaponSounds["Options"]["#SMG"]			= { wire_turret_sound = "Weapon_SMG1.Single" }
		weaponSounds["Options"]["#AR2"]			= { wire_turret_sound = "Weapon_AR2.Single" }
		weaponSounds["Options"]["#Shotgun"]		= { wire_turret_sound = "Weapon_Shotgun.Single" }
		weaponSounds["Options"]["#Floor Turret"]	= { wire_turret_sound = "NPC_FloorTurret.Shoot" }
		weaponSounds["Options"]["#Airboat Heavy"]	= { wire_turret_sound = "Airboat.FireGunHeavy" }
		weaponSounds["Options"]["#Zap"]	= { wire_turret_sound = "ambient.electrical_zap_3" }
		
		
	CPanel:AddControl("ComboBox", weaponSounds )
	
	// Tracer
	local TracerType = {Label = "#Tracer", MenuButton = 0, Options={}, CVars = {}}
		TracerType["Options"]["#Default"]			= { wire_turret_tracer = "Tracer" }
		TracerType["Options"]["#AR2 Tracer"]		= { wire_turret_tracer = "AR2Tracer" }
		TracerType["Options"]["#Airboat Tracer"]	= { wire_turret_tracer = "AirboatGunHeavyTracer" }
		TracerType["Options"]["#Laser"]				= { wire_turret_tracer = "LaserTracer" }
		
		
	CPanel:AddControl("ComboBox", TracerType )
	
	// Various controls that you should play with!
	
	if ( SinglePlayer() ) then
	
		CPanel:AddControl( "Slider",  { Label	= "#Tool_wire_turret_numbullets",
									Type	= "Integer",
									Min		= 1,
									Max		= 10,
									Command = "wire_turret_numbullets" }	 )
	end

	CPanel:AddControl( "Slider",  { Label	= "#Damage",
									Type	= "Float",
									Min		= 0,
									Max		= 100,
									Command = "wire_turret_damage" }	 )

	CPanel:AddControl( "Slider",  { Label	= "#Tool_wire_turret_spread",
									Type	= "Float",
									Min		= 0,
									Max		= 1.0,
									Command = "wire_turret_spread" }	 )

	CPanel:AddControl( "Slider",  { Label	= "#Tool_wire_turret_force",
									Type	= "Float",
									Min		= 0,
									Max		= 500,
									Command = "wire_turret_force" }	 )
									
	// The delay between shots.
	if ( SinglePlayer() ) then
	
		CPanel:AddControl( "Slider",  { Label	= "#Delay",
									Type	= "Float",
									Min		= 0.01,
									Max		= 1.0,
									Command = "wire_turret_delay" }	 )
									
	else
	
		CPanel:AddControl( "Slider",  { Label	= "#Delay",
									Type	= "Float",
									Min		= 0.05,
									Max		= 1.0,
									Command = "wire_turret_delay" }	 )
	
	end
	
	// The toggle switch.
	CPanel:AddControl( "Checkbox", { Label = "#Toggle", Command = "wire_turret_toggle" } )


end
