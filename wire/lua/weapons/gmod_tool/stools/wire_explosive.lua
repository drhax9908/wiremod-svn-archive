
TOOL.Category		= "Wire - Destruction"
TOOL.Name			= "Explosives"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "model" ] = "models/dav0r/tnt/tnt.mdl"
TOOL.ClientConVar[ "effect" ] = "Explosion"
TOOL.ClientConVar[ "tirgger" ] = 1		// Current tirgger
TOOL.ClientConVar[ "damage" ] = 200		// Damage to inflict
TOOL.ClientConVar[ "doblastdamage" ] = 1
TOOL.ClientConVar[ "radius" ] = 300
TOOL.ClientConVar[ "removeafter" ] = 0
TOOL.ClientConVar[ "affectother" ] = 0
TOOL.ClientConVar[ "notaffected" ] = 0
TOOL.ClientConVar[ "delaytime" ] = 0
TOOL.ClientConVar[ "delayreloadtime" ] = 0
TOOL.ClientConVar[ "freeze" ] = 0
TOOL.ClientConVar[ "weld" ] = 1
TOOL.ClientConVar[ "maxhealth" ] = 100
TOOL.ClientConVar[ "bulletproof" ] = 0
TOOL.ClientConVar[ "explosionproof" ] = 0
TOOL.ClientConVar[ "fallproof" ] = 0
TOOL.ClientConVar[ "explodeatzero" ] = 1
TOOL.ClientConVar[ "resetatexplode" ] = 1
TOOL.ClientConVar[ "fireeffect" ] = 1
TOOL.ClientConVar[ "coloreffect" ] = 1
TOOL.ClientConVar[ "nocollide" ] = 0
TOOL.ClientConVar[ "noparentremove" ] = 0

cleanup.Register( "wire_explosive" )


if ( CLIENT ) then
	
    language.Add( "Tool_wire_explosive_name", "Wired Explosives Tool" )
    language.Add( "Tool_wire_explosive_desc", "Creates a variety of different explosives for wire system." )
    language.Add( "Tool_wire_explosive_0", "Left click to place the bomb. Right click update." )
	language.Add( "WireExplosiveTool_Model", "Model:" )
	language.Add( "WireExplosiveTool_Effects", "Effect:" )
	language.Add( "WireExplosiveTool_tirgger", "Trigger value:" )
	language.Add( "WireExplosiveTool_damage", "Dammage:" )
	language.Add( "WireExplosiveTool_delay", "On fire time (delay after triggered before explosion):" )
	language.Add( "WireExplosiveTool_delayreload", "Delay after explosion before it can be triggered again:" )
	language.Add( "WireExplosiveTool_remove", "Remove on explosion:" )
	language.Add( "WireExplosiveTool_doblastdamage", "Do blast damage:" )
	language.Add( "WireExplosiveTool_affectother", "Dammaged/moved by other wired explosives:" )
	language.Add( "WireExplosiveTool_notaffected", "Not moved by any phyiscal damage:" )
	language.Add( "WireExplosiveTool_radius", "Blast radius:" )
	language.Add( "WireExplosiveTool_freeze", "Freeze:" )
	language.Add( "WireExplosiveTool_weld", "Weld:" )
	language.Add( "WireExplosiveTool_noparentremove", "Don't remove on parent remove:" )
	language.Add( "WireExplosiveTool_nocollide", "No collide all but world:" )
	language.Add( "WireExplosiveTool_maxhealth", "Max health:" )
	language.Add( "WireExplosiveTool_weight", "Weight:" )
	language.Add( "WireExplosiveTool_bulletproof", "Bullet proof:" )
	language.Add( "WireExplosiveTool_explosionproof", "Explosion proof:" )
	language.Add( "WireExplosiveTool_fallproof", "Fall proof:" )
	language.Add( "WireExplosiveTool_explodeatzero", "Explode when health = zero:" )
	language.Add( "WireExplosiveTool_resetatexplode", "Rest health then:" )
	language.Add( "WireExplosiveTool_fireeffect", "Enable fire effect on triggered:" )
	language.Add( "WireExplosiveTool_coloreffect", "Enable color change effect on damage:" )
	language.Add( "Undone_WireExplosive", "Wired Explosive undone" )
	language.Add( "sbox_maxwire_explosive", "You've hit wired explosives limit!" )
end

if (SERVER) then
    CreateConVar('sbox_maxwire_explosive', 30)
end 


function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	

	// Get client's CVars
	local _tirgger		= self:GetClientNumber( "tirgger" ) 
	local _damage 		= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
	local _model		= self:GetClientInfo( "model" )
	local _removeafter	= self:GetClientNumber( "removeafter" ) == 1
	local _delaytime	= self:GetClientNumber( "delaytime" )
	local _delayreloadtime	= self:GetClientNumber( "delayreloadtime" )
	local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
	local _radius		= self:GetClientNumber( "radius" )
	local _affectother	= self:GetClientNumber( "affectother" ) == 1
	local _notaffected	= self:GetClientNumber( "notaffected" ) == 1
	local _freeze		= self:GetClientNumber( "freeze" ) == 1
	local _weld		= self:GetClientNumber( "weld" ) == 1
	local _maxhealth		= self:GetClientNumber( "maxhealth" )
	local _bulletproof		= self:GetClientNumber( "bulletproof" ) == 1
	local _explosionproof		= self:GetClientNumber( "explosionproof" ) == 1
	local _fallproof		= self:GetClientNumber( "fallproof" ) == 1
	local _explodeatzero		= self:GetClientNumber( "explodeatzero" ) == 1
	local _resetatexplode		= self:GetClientNumber( "resetatexplode" ) == 1
	local _fireeffect		= self:GetClientNumber( "fireeffect" ) == 1
	local _coloreffect		= self:GetClientNumber( "coloreffect" ) == 1
	local _noparentremove		= self:GetClientNumber( "noparentremove" ) == 1
	local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
	local _weight		= self:GetClientNumber( "weight" )
	
	if (not util.IsValidModel(_model)) then return false end
	if (not util.IsValidProp(_model)) then return false end
	
	if ( !self:GetSWEP():CheckLimit( "wire_explosive" ) ) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local explosive = MakeWireExplosive( ply, trace.HitPos, Ang, _tirgger, _damage, _model, _removeafter, _delaytime, _doblastdamage, _radius, _affectother, _notaffected, _delayreloadtime, _maxhealth, _bulletproof, _explosionproof, _fallproof, _explodeatzero, _resetatexplode, _fireeffect, _coloreffect )
	
	local min = explosive:OBBMins()
	explosive:SetPos( trace.HitPos - trace.HitNormal * min.z )
		
	if ( _freeze ) then
		explosive:GetPhysicsObject():Sleep()
	end
	
	// Don't weld to world
	if ( trace.Entity:IsValid() && _weld ) then
		const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0 )
		if (!_noparentremove) then trace.Entity:DeleteOnRemove( explosive ) end
	end
	
	if (_weight <= 0) then _weight = 1 end
	explosive.Entity:GetPhysicsObject():SetMass(_weight)
	
	if (_nocollide) then explosive.Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER) end
	
	undo.Create("WireExplosive")
		undo.AddEntity( explosive )
		undo.SetPlayer( ply )
	undo.Finish()
	
	
	ply:AddCleanup( "wire_explosive", explosive )
	
	return true
	
end

function TOOL:RightClick( trace )
	
	local ply = self:GetOwner()
	//shot an explosive, update it instead
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_explosive" && trace.Entity:GetTable().pl == ply ) then
		//double you code double your fun (copy from above)
		// Get client's CVars
		local _tirgger		= self:GetClientNumber( "tirgger" ) 
		local _damage 		= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
		local _model		= self:GetClientInfo( "model" )
		local _removeafter	= self:GetClientNumber( "removeafter" ) == 1
		local _delaytime	= self:GetClientNumber( "delaytime" )
		local _delayreloadtime	= self:GetClientNumber( "delayreloadtime" )
		local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
		local _radius		= self:GetClientNumber( "radius" )
		local _affectother	= self:GetClientNumber( "affectother" ) == 1
		local _notaffected	= self:GetClientNumber( "notaffected" ) == 1
		local _freeze		= self:GetClientNumber( "freeze" ) == 1
		local _weld		= self:GetClientNumber( "weld" ) == 1
		local _maxhealth		= self:GetClientNumber( "maxhealth" )
		local _bulletproof		= self:GetClientNumber( "bulletproof" ) == 1
		local _explosionproof		= self:GetClientNumber( "explosionproof" ) == 1
		local _fallproof		= self:GetClientNumber( "fallproof" ) == 1
		local _explodeatzero		= self:GetClientNumber( "explodeatzero" ) == 1
		local _resetatexplode		= self:GetClientNumber( "resetatexplode" ) == 1
		local _fireeffect		= self:GetClientNumber( "fireeffect" ) == 1
		local _coloreffect		= self:GetClientNumber( "coloreffect" ) == 1
		local _noparentremove		= self:GetClientNumber( "noparentremove" ) == 1
		local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
		local _weight		= self:GetClientNumber( "weight" )
		
		trace.Entity:GetTable():Setup( _damage, _delaytime, _removeafter, _doblastdamage, _radius, _affectother, _notaffected, _delayreloadtime, _maxhealth, _bulletproof, _explosionproof, _fallproof, _explodeatzero, _resetatexplode, _fireeffect, _coloreffect )

		local ttable =
		{
			key				= key,
			damage			= damage,
			model			= model,
			removeafter		= removeafter,
			delaytime		= delaytime,
			doblastdamage	= doblastdamage,
			radius			= radius,
			affectother		= affectother,
			notaffected		= notaffected,
			delayreloadtime	= delayreloadtime,
			maxhealth		= maxhealth,
			bulletproof		= bulletproof,
			explosionproof	= explosionproof,
			fallproof		= fallproof,
			explodeatzero	= explodeatzero,
			resetatexplode	= resetatexplode,
			fireeffect		= fireeffect,
			coloreffect		= coloreffect,
		}

		table.Merge( trace.Entity:GetTable(), ttable )

		if (_weight <= 0) then _weight = 1 end
		trace.Entity:GetPhysicsObject():SetMass(_weight)
		
		if (_nocollide) then trace.Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER) end
		
		return true
	end
	
end

if SERVER then

	function MakeWireExplosive(pl, Pos, Ang, key, damage, model, removeafter, delaytime, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect, Vel, aVel, frozen, nocollide )
		if ( !pl:CheckLimit( "wire_explosive" ) ) then return nil end

		local explosive = ents.Create( "gmod_wire_explosive" )
		
		explosive:SetModel( model or "" )
		explosive:SetPos( Pos )	
		explosive:SetAngles( Ang )
		explosive:Spawn()
		explosive:Activate()
		
		explosive:GetTable():Setup( damage, delaytime, removeafter, doblastdamage, radius, affectother, notaffected, delayreloadtime, maxhealth, bulletproof, explosionproof, fallproof, explodeatzero, resetatexplode, fireeffect, coloreffect )
		explosive:GetTable():SetPlayer( pl )
		
		if (nocollide) then explosive:GetPhysicsObject():EnableCollision(false) end
		
		local ttable = 
		{
			key				= key,
			damage			= damage,
			model			= model,
			removeafter		= removeafter,
			delaytime		= delaytime,
			doblastdamage	= doblastdamage,
			radius			= radius,
			affectother		= affectother,
			notaffected		= notaffected,
			delayreloadtime	= delayreloadtime,
			maxhealth		= maxhealth,
			bulletproof		= bulletproof,
			explosionproof	= explosionproof,
			fallproof		= fallproof,
			explodeatzero	= explodeatzero,
			resetatexplode	= resetatexplode,
			fireeffect		= fireeffect,
			coloreffect		= coloreffect,
			pl				= pl,
			nocollide		= nocollide,
			description		= description
		}
		
		table.Merge( explosive:GetTable(), ttable )
				
		pl:AddCount( "wire_explosive", explosive )
		
		return explosive
	end
		
	duplicator.RegisterEntityClass("gmod_wire_explosive", MakeWireExplosive, "Pos", "Ang", "key", "damage", "model", "removeafter", "delaytime", "doblastdamage", "radius", "affectother", "notaffected", "delayreloadtime", "maxhealth", "bulletproof", "explosionproof", "fallproof", "explodeatzero", "resetatexplode", "fireeffect", "coloreffect", "Vel", "aVel", "frozen" )

end

function TOOL:UpdateGhostWireExplosive( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() ) then -- || trace.Entity:GetClass() == "gmod_wire_explosive"
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
	
	self:UpdateGhostWireExplosive( self.GhostEntity, self:GetOwner() )
	
end



function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_explosive_name", Description = "#Tool_wire_explosive_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_explosive",

		Options = {
			Default = {
				wire_explosive_model = "models/props_c17/oildrum001_explosive.mdl",
				wire_explosive_tirgger = "1",
				wire_explosive_damage = "200",
				wire_explosive_delaytime = "0",
				wire_explosive_removeafter = "0",
				wire_explosive_doblastdamage = "1",
				wire_explosive_affectother = "0",
				wire_explosive_notaffected = "0",
				wire_explosive_freeze = "0",
				wire_explosive_weld = "1",
				wire_explosive_maxhealth = "100",
				wire_explosive_bulletproof = "0",
				wire_explosive_explosionproof = "0",
				wire_explosive_fallproof = "0",
				wire_explosive_explodeatzero = "1",
				wire_explosive_resetatexplode = "1",
				wire_explosive_fireeffect = "1",
				wire_explosive_nocollide = "0",
				wire_explosive_weight = "100",
				wire_explosive_noparentremove = "0"
			}
		},
		
		CVars = {
			[0] = "wire_explosive_model",
			[1] = "wire_explosive_tirgger",
			[2] = "wire_explosive_damage",
			[3] = "wire_explosive_delaytime",
			[4] = "wire_explosive_removeafter",
			[5] = "wire_explosive_doblastdamage",
			[6] = "wire_explosive_affectother",
			[7] = "wire_explosive_notaffected",
			[8] = "wire_explosive_freeze",
			[9] = "wire_explosive_weld",
			[10] = "wire_explosive_maxhealth",
			[11] = "wire_explosive_bulletproof",
			[12] = "wire_explosive_explosionproof",
			[13] = "wire_explosive_fallproof",
			[14] = "wire_explosive_explodeatzero",
			[15] = "wire_explosive_resetatexplode",
			[16] = "wire_explosive_fireeffect",
			[17] = "wire_explosive_nocollide",
			[17] = "wire_explosive_weight",
			[18] = "wire_explosive_noparentremove"
		}
	})
	
	panel:AddControl("ComboBox", {
		Label = "#WireExplosiveTool_Model",
		MenuButton = "0",

		Options = {
			["Dynamite"]				= { wire_explosive_model = "models/dav0r/tnt/tnt.mdl" },
			["Heli Bomb"]				= { wire_explosive_model = "models/Combine_Helicopter/helicopter_bomb01.mdl" },
			["Flat Bomb"]				= { wire_explosive_model = "models/jaanus/thruster_flat.mdl"	},
			["Oil Drum"]				= { wire_explosive_model = "models/props_c17/oildrum001.mdl" },
			["Explosive Oil Drum"]		= { wire_explosive_model = "models/props_c17/oildrum001_explosive.mdl" },
			["PHX Cannon Ball"]			= { wire_explosive_model = "models/\props_phx/cannonball.mdl" },
			["PHX Facepunch Barrel"]	= { wire_explosive_model = "models/\props_phx/facepunch_barrel.mdl" },
			["PHX Oil Drum"]			= { wire_explosive_model = "models/\props_phx/oildrum001.mdl" },
			["PHX Explosive Oil Drum"]	= { wire_explosive_model = "models/\props_phx/oildrum001_explosive.mdl" },
			["PHX Rocket"]				= { wire_explosive_model = "models/\props_phx/rocket1.mdl" },
			["PHX Torpedo"]				= { wire_explosive_model = "models/\props_phx/torpedo.mdl" },
			["PHX WW2 Bomb"]			= { wire_explosive_model = "models/\props_phx/ww2bomb.mdl" },
			["Paint Bucket"]			= { wire_explosive_model = "models/props_junk/plasticbucket001a.mdl" },
			["Small Propane Canister"]	= { wire_explosive_model = "models/props_junk/PropaneCanister001a.mdl" },
			["Medium Propane Tank"]		= { wire_explosive_model = "models/props_junk/propane_tank001a.mdl" },
			["Cola Can"]				= { wire_explosive_model = "models/props_junk/PopCan01a.mdl" },
			["Vitamin Jar"]				= { wire_explosive_model = "models/props_lab/jar01a.mdl" },
			["Fat Can"]					= { wire_explosive_model = "models/props_c17/canister_propane01a.mdl" },
			["Black Canister"]			= { wire_explosive_model = "models/props_c17/canister01a.mdl" },
			["Red Canister"]			= { wire_explosive_model = "models/props_c17/canister02a.mdl" },
			["Gas Pump"]				= { wire_explosive_model = "models/props_wasteland/gaspump001a.mdl" },
			["cardboard_box001a"]		= { wire_explosive_model = "models/props_junk/cardboard_box001a.mdl" },
			["cardboard_box001b"]		= { wire_explosive_model = "models/props_junk/cardboard_box001b.mdl" },
			["cardboard_box002a"]		= { wire_explosive_model = "models/props_junk/cardboard_box002a.mdl" },
			["cardboard_box002b"]		= { wire_explosive_model = "models/props_junk/cardboard_box002b.mdl" },
			["cardboard_box003a"]		= { wire_explosive_model = "models/props_junk/cardboard_box003a.mdl" },
			["cardboard_box003b"]		= { wire_explosive_model = "models/props_junk/cardboard_box003b.mdl" },
			["cardboard_box004a"]		= { wire_explosive_model = "models/props_junk/cardboard_box004a.mdl" },	
			["Cinder Block"]			= { wire_explosive_model = "models/props_junk/CinderBlock01a.mdl" },
			["Gas can"]					= { wire_explosive_model = "models/props_junk/gascan001a.mdl" },
			["Traffic Cone"]			= { wire_explosive_model = "models/props_junk/TrafficCone001a.mdl" },
			["Metal gas can"]			= { wire_explosive_model = "models/props_junk/metalgascan.mdl" },
			["Metal paint can"]			= { wire_explosive_model = "models/props_junk/metal_paintcan001a.mdl" },
			["Wood crate 1"]			= { wire_explosive_model = "models/props_junk/wood_crate001a.mdl" },
			["Wood crate 2"]			= { wire_explosive_model = "models/props_junk/wood_crate002a.mdl" },
			["Wood Pallet 1"]			= { wire_explosive_model = "models/props_junk/wood_pallet001a.mdl" }
		}
	})
	
	/*panel:AddControl("ComboBox", {
		Label = "#WireExplosiveTool_Effects",
		MenuButton = "0",

		Options = {
			["#Explosion"]				= { wire_explosive_effect = "Explosion" },
			["#HelicopterMegaBomb"]	= { wire_explosive_effect = "HelicopterMegaBomb" },
			["#TeslaZap"]				= { wire_explosive_effect = "TeslaZap" },
			["#StunstickImpact"]		= { wire_explosive_effect = "StunstickImpact" },
			["#TeslaHitBoxes"]			= { wire_explosive_effect = "TeslaHitBoxes" },
			["#WaterSurfaceExplosion"]	= { wire_explosive_effect = "WaterSurfaceExplosion" }
		}
	})*/
	
	panel:AddControl("Slider", {
		Label = "#WireExplosiveTool_tirgger",
		Type = "Integer",
		Min = "1",
		Max = "10",
		Command = "wire_explosive_tirgger"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireExplosiveTool_damage",
		Description = "#ExplosiveTool_damage_desc",
		Type = "Integer",
		Min = "1",
		Max = "500",
		Command = "wire_explosive_damage"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireExplosiveTool_radius",
		Description = "#ExplosiveTool_delay",
		Type = "Integer",
		Min = "1",
		Max = "400",
		Command = "wire_explosive_radius"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireExplosiveTool_delay",
		Description = "#ExplosiveTool_delay",
		Type = "Integer",
		Min = "0",
		Max = "30",
		Command = "wire_explosive_delaytime"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireExplosiveTool_delayreload",
		Description = "#ExplosiveTool_delayreload",
		Type = "Integer",
		Min = "0",
		Max = "30",
		Command = "wire_explosive_delayreloadtime"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_remove",
		Command = "wire_explosive_removeafter"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_doblastdamage",
		Command = "wire_explosive_doblastdamage"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_affectother",
		Command = "wire_explosive_affectother"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_notaffected",
		Command = "wire_explosive_notaffected"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_freeze",
		Command = "wire_explosive_freeze"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_weld",
		Command = "wire_explosive_weld"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_noparentremove",
		Command = "wire_explosive_noparentremove"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_nocollide",
		Command = "wire_explosive_nocollide"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireExplosiveTool_maxhealth",
		Description = "#ExplosiveTool_maxhealth",
		Type = "Integer",
		Min = "0",
		Max = "300",
		Command = "wire_explosive_maxhealth"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireExplosiveTool_weight",
		Description = "#ExplosiveTool_weight",
		Type = "Integer",
		Min = "1",
		Max = "1000",
		Command = "wire_explosive_weight"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_bulletproof",
		Command = "wire_explosive_bulletproof"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_explosionproof",
		Command = "wire_explosive_explosionproof"
	})
	
	/*panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_fallproof",
		Command = "wire_explosive_fallproof"
	})*/
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_explodeatzero",
		Command = "wire_explosive_explodeatzero"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_resetatexplode",
		Command = "wire_explosive_resetatexplode"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_fireeffect",
		Command = "wire_explosive_fireeffect"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireExplosiveTool_coloreffect",
		Command = "wire_explosive_coloreffect"
	})
	
end
