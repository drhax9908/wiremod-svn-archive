TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Turret"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "delay" ] 		= "0.05"
TOOL.ClientConVar[ "force" ] 		= "1"
TOOL.ClientConVar[ "sound" ] 		= "0"
TOOL.ClientConVar[ "damage" ] 		= "10"
TOOL.ClientConVar[ "spread" ] 		= "0"
TOOL.ClientConVar[ "numbullets" ]	= "1"
TOOL.ClientConVar[ "automatic" ]	= "1"
TOOL.ClientConVar[ "tracer" ] 		= "Tracer"
TOOL.ClientConVar[ "tracernum" ] 	= "1"

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
	language.Add( "Tool_wire_turret_tracernum", "Tracer Every x Bullets:" )
	
	language.Add( "Undone_wire_turret", "Undone Turret" )
	
	language.Add( "Cleanup_wire_turrets", "Turret" )
	language.Add( "Cleaned_wire_turrets", "Cleaned up all Turrets" )
	language.Add( "SBoxLimit_wire_turrets", "You've reached the Turret limit!" )
end

if (SERVER) then
    CreateConVar('sbox_maxwire_turrets', 30)
end 

function TOOL:LeftClick( trace, worldweld )
	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	if (CLIENT) then return true end
	
	worldweld = worldweld or false
	
	local ply = self:GetOwner()
	
	local delay 		= self:GetClientNumber( "delay" ) 
	local force 		= self:GetClientNumber( "force" )
	local sound 		= self:GetClientInfo( "sound" )
	local tracer 		= self:GetClientInfo( "tracer" )
	local damage	 	= self:GetClientNumber( "damage" )
	local spread	 	= self:GetClientNumber( "spread" )
	local numbullets 	= self:GetClientNumber( "numbullets" )
	local tracernum 	= self:GetClientNumber( "tracernum" )
	
	// We shot an existing turret - just change its values
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_turret" && trace.Entity.pl == ply ) then

		trace.Entity:SetDamage( damage )
		trace.Entity:SetDelay( delay )
		trace.Entity:SetNumBullets( numbullets )
		trace.Entity:SetSpread( spread )
		trace.Entity:SetForce( force )
		trace.Entity:SetSound( sound )
		trace.Entity:SetTracer( tracer )
		trace.Entity:SetTracerNum( tracernum )
		return true
		
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_turrets" ) ) then return false end

	if ( trace.Entity != NULL && (!trace.Entity:IsWorld() || worldweld) ) then
		trace.HitPos = trace.HitPos + trace.HitNormal * 2
	else
		trace.HitPos = trace.HitPos + trace.HitNormal * 2
	end
	
	local turret = MakeWireTurret( ply, trace.HitPos, nil, delay, damage, force, sound, numbullets, spread, tracer, tracernum )
	
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

	function MakeWireTurret( ply, Pos, Ang, delay, damage, force, sound, numbullets, spread, tracer, tracernum, Vel, aVel, frozen, nocollide )
		
		if ( !ply:CheckLimit( "wire_turrets" ) ) then return nil end
		
		local turret = ents.Create( "gmod_wire_turret" )
		if (!turret:IsValid()) then return false end
		
		turret:SetPos( Pos )
		if ( Ang ) then turret:SetAngles( Ang ) end
		turret:Spawn()
		
		// Clamp stuff in multiplayer.. because people are idiots
		if ( !SinglePlayer() ) then
			delay		= math.Clamp( delay, 0.05, 3600 )
			numbullets	= 1
			force		= math.Clamp( force, 0.01, 100 )
			spread		= math.Clamp( spread, 0, 1 )
			damage		= math.Clamp( damage, 0, 500 )
			tracernum	= 1
		end
		
		turret:SetDamage( damage )
		turret:SetPlayer( ply )
		
		turret:SetSpread( spread )
		turret:SetForce( force )
		turret:SetSound( sound )
		turret:SetTracer( tracer )
		turret:SetTracerNum( tracernum or 1 )
		
		turret:SetNumBullets( numbullets )
		
		turret:SetDelay( delay )
		
		if ( nocollide == true ) then turret:GetPhysicsObject():EnableCollisions( false ) end

		local ttable = {
			delay 		= delay,
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
	
	duplicator.RegisterEntityClass( "gmod_wire_turret", MakeWireTurret, "Pos", "Ang", "delay", "damage", "force", "sound", "numbullets", "spread", "tracer", "Vel", "aVel", "frozen", "nocollide" )

end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", { Text = "#Tool_wire_turret_name", Description	= "#Tool_wire_turret_desc" }  )
	
	local params = { Label = "#Presets", MenuButton = 1, Folder = "wire_turret", Options = {}, CVars = {} }
		
		params.Options.default = {
			wire_turret_delay		=		0.2,
			wire_turret_force		=		1,
			wire_turret_sound		=		"pistol",
			wire_turret_damage		=		10,
			wire_turret_spread		=		0,
			wire_turret_numbullets	=		1,
		}
		
		table.insert( params.CVars, "wire_turret_delay" )
		table.insert( params.CVars, "wire_turret_force" )
		table.insert( params.CVars, "wire_turret_sound" )
		table.insert( params.CVars, "wire_turret_damage" )
		table.insert( params.CVars, "wire_turret_spread" )
		table.insert( params.CVars, "wire_turret_numbullets" )
		
	CPanel:AddControl( "ComboBox", params )
	
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
	
		CPanel:AddControl( "Slider",  { Label	= "#Tool_wire_turret_tracernum",
									Type	= "Integer",
									Min		= 0,
									Max		= 15,
									Command = "wire_turret_tracernum" }	 )
	
	else
	
		CPanel:AddControl( "Slider",  { Label	= "#Delay",
									Type	= "Float",
									Min		= 0.05,
									Max		= 1.0,
									Command = "wire_turret_delay" }	 )
	
	end
	
end
