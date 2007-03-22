
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Thruster"
TOOL.Command		= nil

if (not file.Exists("../addons/wire/settings/controls/wire_thruster.txt")) then
	TOOL.ConfigName		= ""
end

if ( CLIENT ) then
    language.Add( "Tool_wire_thruster_name", "Thruster Tool (Wire)" )
    language.Add( "Tool_wire_thruster_desc", "Spawns a thruster for use with the wire system." )
    language.Add( "Tool_wire_thruster_0", "Primary: Create/Update Thruster" )
    language.Add( "WireThrusterTool_Model", "Model:" )
    language.Add( "WireThrusterTool_OWEffects", "Over water effects:" )
    language.Add( "WireThrusterTool_UWEffects", "Under water effects:" )
    language.Add( "WireThrusterTool_force", "Force multiplier:" )
    language.Add( "WireThrusterTool_force_min", "Force minimum:" )
    language.Add( "WireThrusterTool_force_max", "Force maximum:" )
    language.Add( "WireThrusterTool_bidir", "Bi-directional:" )
    language.Add( "WireThrusterTool_collision", "Collision:" )
    language.Add( "WireThrusterTool_sound", "Enable sound:" )
    language.Add( "WireThrusterTool_owater", "Works out of water:" )
    language.Add( "WireThrusterTool_uwater", "Works under water:" )
	language.Add( "sboxlimit_wire_thrusters", "You've hit thrusters limit!" )
	language.Add( "undone_wirethruster", "Undone Wire Thruster" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_thrusters', 10)
end

TOOL.ClientConVar[ "force" ] = "1500"
TOOL.ClientConVar[ "force_min" ] = "0"
TOOL.ClientConVar[ "force_max" ] = "10000"
TOOL.ClientConVar[ "model" ] = "models/props_c17/lampShade001a.mdl"
TOOL.ClientConVar[ "bidir" ] = "1"
TOOL.ClientConVar[ "collision" ] = "0"
TOOL.ClientConVar[ "sound" ] = "0"
TOOL.ClientConVar[ "oweffect" ] = "fire"
TOOL.ClientConVar[ "uweffect" ] = "same"
TOOL.ClientConVar[ "owater" ] = "1"
TOOL.ClientConVar[ "uwater" ] = "1"

cleanup.Register( "wire_thrusters" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local force			= self:GetClientNumber( "force" )
	local force_min		= self:GetClientNumber( "force_min" )
	local force_max		= self:GetClientNumber( "force_max" )
	local model			= self:GetClientInfo( "model" )
	local bidir			= (self:GetClientNumber( "bidir" ) ~= 0)
	local collision		= (self:GetClientNumber( "collision" ) == 0)
	local sound			= (self:GetClientNumber( "sound" ) ~= 0)
	local oweffect		= self:GetClientInfo( "oweffect" )
	local uweffect		= self:GetClientInfo( "uweffect" )
	local owater			= (self:GetClientNumber( "owater" ) ~= 0)
	local uwater			= (self:GetClientNumber( "uwater" ) ~= 0)

	// If we shot a wire_thruster change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_thruster" && trace.Entity.pl == ply ) then

		trace.Entity:SetForce( force )
		trace.Entity:SetEffect( effect )
		trace.Entity:Setup(force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound)

		trace.Entity.force		= force
		trace.Entity.force_min	= force_min
		trace.Entity.force_max	= force_max
		trace.Entity.bidir		= bidir
		trace.Entity.sound		= sound
		trace.Entity.oweffect	= oweffect
		trace.Entity.uweffect	= uweffect
		trace.Entity.owater		= owater
		trace.Entity.uwater		= uwater

		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_thrusters" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_thruster = MakeWireThruster( ply, model, Ang, trace.HitPos, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nil, collision )
	
	local min = wire_thruster:OBBMins()
	wire_thruster:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const, nocollide
	
	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const, nocollide = constraint.Weld( wire_thruster, trace.Entity, 0, trace.PhysicsBone, 0, collision, true )
		// Don't disable collision if it's not attached to anything
		if ( collision ) then
			wire_thruster:GetPhysicsObject():EnableCollisions( false )
			wire_thruster.nocollide = true
		end
	end

	undo.Create("WireThruster")
		undo.AddEntity( wire_thruster )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
		
	ply:AddCleanup( "wire_thrusters", wire_thruster )
	ply:AddCleanup( "wire_thrusters", const )
	ply:AddCleanup( "wire_thrusters", nocollide )
	
	return true
end

if (SERVER) then

	function MakeWireThruster( pl, Model, Ang, Pos, force, force_min, force_max, oweffect, uweffect, owater, uwater, bidir, sound, nocollide, Vel, aVel, frozen )
		if ( !pl:CheckLimit( "wire_thrusters" ) ) then return false end
	
		local wire_thruster = ents.Create( "gmod_wire_thruster" )
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
			effect		= effect,
			nocollide	= nocollide
			}

		table.Merge(wire_thruster:GetTable(), ttable )

		pl:AddCount( "wire_thrusters", wire_thruster )

		return wire_thruster
	end

	duplicator.RegisterEntityClass("gmod_wire_thruster", MakeWireThruster, "Model", "Ang", "Pos", "force", "force_min", "force_max", "oweffect", "uweffect", "owater", "uwater", "bidir", "sound", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireThruster( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end
	
	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_thruster" || trace.Entity:IsPlayer()) then
	
		ent:SetNoDraw( true )
		return
		
	end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local min = ent:OBBMins()
	 ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )
	
	ent:SetNoDraw( false )
end


function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireThruster( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_thruster_name", Description = "#Tool_wire_thruster_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_thruster",

		Options = {
			Default = {
				wire_thruster_force = "20",
				wire_thruster_model = "models/props_junk/plasticbucket001a.mdl",
				wire_thruster_effect = "fire",
			}
		},

		CVars = {
			[0] = "wire_thruster_model",
			[1] = "wire_thruster_force",
			[2] = "wire_thruster_effect"
		}
	})

	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_Model",
		MenuButton = "0",

		Options = {
			["#Thruster"]				= { wire_thruster_model = "models/dav0r/thruster.mdl" },
			["#Paint_Bucket"]			= { wire_thruster_model = "models/props_junk/plasticbucket001a.mdl" },
			["#Small_Propane_Canister"]	= { wire_thruster_model = "models/props_junk/PropaneCanister001a.mdl" },
			["#Medium_Propane_Tank"]	= { wire_thruster_model = "models/props_junk/propane_tank001a.mdl" },
			["#Cola_Can"]				= { wire_thruster_model = "models/props_junk/PopCan01a.mdl" },
			["#Bucket"]					= { wire_thruster_model = "models/props_junk/MetalBucket01a.mdl" },
			["#Vitamin_Jar"]			= { wire_thruster_model = "models/props_lab/jar01a.mdl" },
			["#Lamp_Shade"]				= { wire_thruster_model = "models/props_c17/lampShade001a.mdl" },
			["#Fat_Can"]				= { wire_thruster_model = "models/props_c17/canister_propane01a.mdl" },
			["#Black_Canister"]			= { wire_thruster_model = "models/props_c17/canister01a.mdl" },
			["#Red_Canister"]			= { wire_thruster_model = "models/props_c17/canister02a.mdl" }
		}
	})

	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_OWEffects",
		MenuButton = "0",

		Options = {
			["#No_Effects"] = { wire_thruster_oweffect = "none" },
			["#Flames"] = { wire_thruster_oweffect = "fire" },
			["#Plasma"] = { wire_thruster_oweffect = "plasma" },
			["#Smoke"] = { wire_thruster_oweffect = "smoke" },
			["#Smoke Random"] = { wire_thruster_oweffect = "smoke_random" },
			["#Smoke Do it Youself"] = { wire_thruster_oweffect = "smoke_diy" },
			["#Rings"] = { wire_thruster_oweffect = "rings" },
			["#Rings Growing"] = { wire_thruster_oweffect = "rings_grow" },
			["#Rings Shrinking"] = { wire_thruster_oweffect = "rings_shrink" },
			["#Bubbles"] = { wire_thruster_oweffect = "bubble" },
			["#Magic"] = { wire_thruster_oweffect = "magic" },
			["#Magic Random"] = { wire_thruster_oweffect = "magic_color" },
			["#Magic Do It Yourself"] = { wire_thruster_oweffect = "magic_diy" },
			["#Colors"] = { wire_thruster_oweffect = "color" },
			["#Colors Random"] = { wire_thruster_oweffect = "color_random" },
			["#Colors Do It Yourself"] = { wire_thruster_oweffect = "color_diy" },
			["#Blood"] = { wire_thruster_oweffect = "blood" },
			["#Money"] = { wire_thruster_oweffect = "money" },
			["#Sperms"] = { wire_thruster_oweffect = "sperm" },
			["#Feathers"] = { wire_thruster_oweffect = "feather" },
			["#Candy Cane"] = { wire_thruster_oweffect = "candy_cane" },
			["#Goldstar"] = { wire_thruster_oweffect = "goldstar" },
			["#Water Small"] = { wire_thruster_oweffect = "water_small" },
			["#Water Medium"] = { wire_thruster_oweffect = "water_medium" },
			["#Water Big"] = { wire_thruster_oweffect = "water_big" },
			["#Water Huge"] = { wire_thruster_oweffect = "water_huge" },
			["#Striderblood Small"] = { wire_thruster_oweffect = "striderblood_small" },
			["#Striderblood Medium"] = { wire_thruster_oweffect = "striderblood_medium" },
			["#Striderblood Big"] = { wire_thruster_oweffect = "striderblood_big" },
			["#Striderblood Huge"] = { wire_thruster_oweffect = "striderblood_huge" },
			["#More Sparks"] = { wire_thruster_oweffect = "more_sparks" },
			["#Spark Fountain"] = { wire_thruster_oweffect = "spark_fountain" },
			["#Jetflame"] = { wire_thruster_oweffect = "jetflame" },
			["#Jetflame Advanced"] = { wire_thruster_oweffect = "jetflame_advanced" },
			["#Jetflame Blue"] = { wire_thruster_oweffect = "jetflame_blue" },
			["#Jetflame Red"] = { wire_thruster_oweffect = "jetflame_red" },
			["#Jetflame Purple"] = { wire_thruster_oweffect = "jetflame_purple" },
			["#Comic Balls"] = { wire_thruster_oweffect = "balls" },
			["#Comic Balls Random"] = { wire_thruster_oweffect = "balls_random" },
			["#Comic Balls Fire Colors"] = { wire_thruster_oweffect = "balls_firecolors" },
			["#Souls"] = { wire_thruster_oweffect = "souls" },
			["#Debugger 10 Seconds"] = { wire_thruster_oweffect = "debug_10" },
			["#Debugger 30 Seconds"] = { wire_thruster_oweffect = "debug_30" },
			["#Debugger 60 Seconds"] = { wire_thruster_oweffect = "debug_60" },
			["#Fire and Smoke"] = { wire_thruster_oweffect = "fire_smoke" },
			["#Fire and Smoke Huge"] = { wire_thruster_oweffect = "fire_smoke_big" },
			["#5 Growing Rings"] = { wire_thruster_oweffect = "rings_grow_rings" },
			["#Color and Magic"] = { wire_thruster_oweffect = "color_magic" },
		}
	})

	panel:AddControl("ComboBox", {
		Label = "#WireThrusterTool_UWEffects",
		MenuButton = "0",

		Options = {
			["#No_Effects"] = { wire_thruster_uweffect = "none" },
			["#Same as over water"] = { wire_thruster_uweffect = "same" },
			["#Flames"] = { wire_thruster_uweffect = "fire" },
			["#Plasma"] = { wire_thruster_uweffect = "plasma" },
			["#Smoke"] = { wire_thruster_uweffect = "smoke" },
			["#Smoke Random"] = { wire_thruster_uweffect = "smoke_random" },
			["#Smoke Do it Youself"] = { wire_thruster_uweffect = "smoke_diy" },
			["#Rings"] = { wire_thruster_uweffect = "rings" },
			["#Rings Growing"] = { wire_thruster_uweffect = "rings_grow" },
			["#Rings Shrinking"] = { wire_thruster_uweffect = "rings_shrink" },
			["#Bubbles"] = { wire_thruster_uweffect = "bubble" },
			["#Magic"] = { wire_thruster_uweffect = "magic" },
			["#Magic Random"] = { wire_thruster_uweffect = "magic_color" },
			["#Magic Do It Yourself"] = { wire_thruster_uweffect = "magic_diy" },
			["#Colors"] = { wire_thruster_uweffect = "color" },
			["#Colors Random"] = { wire_thruster_uweffect = "color_random" },
			["#Colors Do It Yourself"] = { wire_thruster_uweffect = "color_diy" },
			["#Blood"] = { wire_thruster_uweffect = "blood" },
			["#Money"] = { wire_thruster_uweffect = "money" },
			["#Sperms"] = { wire_thruster_uweffect = "sperm" },
			["#Feathers"] = { wire_thruster_uweffect = "feather" },
			["#Candy Cane"] = { wire_thruster_uweffect = "candy_cane" },
			["#Goldstar"] = { wire_thruster_uweffect = "goldstar" },
			["#Water Small"] = { wire_thruster_uweffect = "water_small" },
			["#Water Medium"] = { wire_thruster_uweffect = "water_medium" },
			["#Water Big"] = { wire_thruster_uweffect = "water_big" },
			["#Water Huge"] = { wire_thruster_uweffect = "water_huge" },
			["#Striderblood Small"] = { wire_thruster_uweffect = "striderblood_small" },
			["#Striderblood Medium"] = { wire_thruster_uweffect = "striderblood_medium" },
			["#Striderblood Big"] = { wire_thruster_uweffect = "striderblood_big" },
			["#Striderblood Huge"] = { wire_thruster_uweffect = "striderblood_huge" },
			["#More Sparks"] = { wire_thruster_uweffect = "more_sparks" },
			["#Spark Fountain"] = { wire_thruster_uweffect = "spark_fountain" },
			["#Jetflame"] = { wire_thruster_uweffect = "jetflame" },
			["#Jetflame Advanced"] = { wire_thruster_uweffect = "jetflame_advanced" },
			["#Jetflame Blue"] = { wire_thruster_uweffect = "jetflame_blue" },
			["#Jetflame Red"] = { wire_thruster_uweffect = "jetflame_red" },
			["#Jetflame Purple"] = { wire_thruster_uweffect = "jetflame_purple" },
			["#Comic Balls"] = { wire_thruster_uweffect = "balls" },
			["#Comic Balls Random"] = { wire_thruster_uweffect = "balls_random" },
			["#Comic Balls Fire Colors"] = { wire_thruster_uweffect = "balls_firecolors" },
			["#Souls"] = { wire_thruster_uweffect = "souls" },
			["#Debugger 10 Seconds"] = { wire_thruster_uweffect = "debug_10" },
			["#Debugger 30 Seconds"] = { wire_thruster_uweffect = "debug_30" },
			["#Debugger 60 Seconds"] = { wire_thruster_uweffect = "debug_60" },
			["#Fire and Smoke"] = { wire_thruster_uweffect = "fire_smoke" },
			["#Fire and Smoke Huge"] = { wire_thruster_uweffect = "fire_smoke_big" },
			["#5 Growing Rings"] = { wire_thruster_uweffect = "rings_grow_rings" },
			["#Color and Magic"] = { wire_thruster_uweffect = "color_magic" },
		}
	})

	panel:AddControl("Slider", {
		Label = "#WireThrusterTool_force",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_thruster_force"
	})

	panel:AddControl("Slider", {
		Label = "#WireThrusterTool_force_min",
		Type = "Float",
		Min = "0",
		Max = "10000",
		Command = "wire_thruster_force_min"
	})

	panel:AddControl("Slider", {
		Label = "#WireThrusterTool_force_max",
		Type = "Float",
		Min = "0",
		Max = "10000",
		Command = "wire_thruster_force_max"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_bidir",
		Command = "wire_thruster_bidir"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_collision",
		Command = "wire_thruster_collision"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_sound",
		Command = "wire_thruster_sound"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_owater",
		Command = "wire_thruster_owater"
	})

	panel:AddControl("CheckBox", {
		Label = "#WireThrusterTool_uwater",
		Command = "wire_thruster_uwater"
	})
end
