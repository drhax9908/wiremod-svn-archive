
TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Explosives (Simple)"
TOOL.Command		= nil
TOOL.ConfigName		= nil

TOOL.ClientConVar[ "model" ] = "models/props_c17/oildrum001_explosive.mdl"
TOOL.ClientConVar[ "modelman" ] = ""
TOOL.ClientConVar[ "tirgger" ] = 1		// Current tirgger
TOOL.ClientConVar[ "damage" ] = 200		// Damage to inflict
TOOL.ClientConVar[ "doblastdamage" ] = 1
TOOL.ClientConVar[ "radius" ] = 300
TOOL.ClientConVar[ "removeafter" ] = 0
--TOOL.ClientConVar[ "affectother" ] = 0
--TOOL.ClientConVar[ "notaffected" ] = 0
--TOOL.ClientConVar[ "delaytime" ] = 0
--TOOL.ClientConVar[ "delayreloadtime" ] = 0
TOOL.ClientConVar[ "freeze" ] = 0
TOOL.ClientConVar[ "weld" ] = 1
--TOOL.ClientConVar[ "maxhealth" ] = 100
--TOOL.ClientConVar[ "bulletproof" ] = 0
--TOOL.ClientConVar[ "explosionproof" ] = 0
TOOL.ClientConVar[ "weight" ] = 400
--TOOL.ClientConVar[ "explodeatzero" ] = 1
--TOOL.ClientConVar[ "resetatexplode" ] = 1
--TOOL.ClientConVar[ "fireeffect" ] = 1
--TOOL.ClientConVar[ "coloreffect" ] = 1
TOOL.ClientConVar[ "nocollide" ] = 0
TOOL.ClientConVar[ "noparentremove" ] = 0
--TOOL.ClientConVar[ "invisibleatzero" ] = 0

cleanup.Register( "wire_simple_explosive" )


if ( CLIENT ) then
	
    language.Add( "Tool_wire_simple_explosive_name", "Simple Wired Explosives Tool" )
    language.Add( "Tool_wire_simple_explosive_desc", "Creates a simple explosives for wire system." )
    language.Add( "Tool_wire_simple_explosive_0", "Left click to place the bomb. Right click update." )
	language.Add( "WireSimpleExplosiveTool_Model", "Model:" )
	language.Add( "WireSimpleExplosiveTool_modelman", "Manual model selection:" )
	language.Add( "WireSimpleExplosiveTool_usemodelman", "Use manual model selection:" )
	--language.Add( "WireSimpleExplosiveTool_Effects", "Effect:" )
	language.Add( "WireSimpleExplosiveTool_tirgger", "Trigger value:" )
	language.Add( "WireSimpleExplosiveTool_damage", "Dammage:" )
	--language.Add( "WireSimpleExplosiveTool_delay", "On fire time (delay after triggered before explosion):" )
	--language.Add( "WireSimpleExplosiveTool_delayreload", "Delay after explosion before it can be triggered again:" 
	language.Add( "WireSimpleExplosiveTool_remove", "Remove on explosion:" )
	language.Add( "WireSimpleExplosiveTool_doblastdamage", "Do blast damage:" )
	--language.Add( "WireSimpleExplosiveTool_affectother", "Dammaged/moved by other wired Explosives:" )
	--language.Add( "WireSimpleExplosiveTool_notaffected", "Not moved by any phyiscal damage:" )
	language.Add( "WireSimpleExplosiveTool_radius", "Blast radius:" )
	language.Add( "WireSimpleExplosiveTool_freeze", "Freeze:" )
	language.Add( "WireSimpleExplosiveTool_weld", "Weld:" )
	language.Add( "WireSimpleExplosiveTool_noparentremove", "Don't remove on parent remove:" )
	language.Add( "WireSimpleExplosiveTool_nocollide", "No collide all but world:" )
	--language.Add( "WireSimpleExplosiveTool_maxhealth", "Max health:" )
	language.Add( "WireSimpleExplosiveTool_weight", "Weight:" )
	--language.Add( "WireSimpleExplosiveTool_bulletproof", "Bullet proof:" )
	--language.Add( "WireSimpleExplosiveTool_explosionproof", "Explosion proof:" )
	--language.Add( "WireSimpleExplosiveTool_fallproof", "Fall proof:" )
	--language.Add( "WireSimpleExplosiveTool_explodeatzero", "Explode when health = zero:" )
	--language.Add( "WireSimpleExplosiveTool_resetatexplode", "Rest health then:" )
	--language.Add( "WireSimpleExplosiveTool_fireeffect", "Enable fire effect on triggered:" )
	--language.Add( "WireSimpleExplosiveTool_coloreffect", "Enable color change effect on damage:" )
	--language.Add( "WireSimpleExplosiveTool_invisibleatzero", "Become invisible when health reaches 0:" )
	language.Add( "Undone_WireSimpleExplosive", "Wired SimpleExplosive undone" )
	language.Add( "sbox_maxwire_simple_explosive", "You've hit wired explosives limit!" )
end

if (SERVER) then
    CreateConVar('sbox_maxwire_simple_explosive', 30)
end 


function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	
	if ( !self:GetSWEP():CheckLimit( "wire_simple_explosive" ) ) then return false end
	
	// Get client's CVars
	local _tirgger			= self:GetClientNumber( "tirgger" ) 
	local _damage 			= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
	local _removeafter		= self:GetClientNumber( "removeafter" ) == 1
	local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
	local _radius			= self:GetClientNumber( "radius" )
	local _freeze			= self:GetClientNumber( "freeze" ) == 1
	local _weld				= self:GetClientNumber( "weld" ) == 1
	local _noparentremove	= self:GetClientNumber( "noparentremove" ) == 1
	local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
	local _weight		= self:GetClientNumber( "weight" )
	
	//get & check selected model
	_model = self:GetSelModel( true )
	if (!_model) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local explosive = MakeWireSimpleExplosive( ply, trace.HitPos, Ang, _tirgger, _damage, _model, _removeafter, _doblastdamage, _radius, _nocollide )
	
	local min = explosive:OBBMins()
	explosive:SetPos( trace.HitPos - trace.HitNormal * min.z )
		
	if ( _freeze ) then
		explosive:GetPhysicsObject():Sleep() //will freeze the explosive till something touches it
	end
	
	// Don't weld to world
	if ( trace.Entity:IsValid() && _weld ) then
		const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0 )
		if (!_noparentremove) then trace.Entity:DeleteOnRemove( explosive ) end
	end
	
	if (_weight <= 0) then _weight = 1 end
	explosive.Entity:GetPhysicsObject():SetMass(_weight)
	
	undo.Create("WireSimpleExplosive")
		undo.AddEntity( explosive )
		undo.SetPlayer( ply )
	undo.Finish()
	
	
	ply:AddCleanup( "wire_simple_explosive", explosive )
	
	return true
	
end


function TOOL:GetSelModel( showerr )

	local model		= self:GetClientInfo( "model" )
	
	if (model == "usemanmodel") then
		local _modelman = self:GetClientInfo( "modelman" )
		if (_modelman && string.len(_modelman) > 0) then
			model = _modelman
		else
			local message = "You need to define a model."
			if (showerr) then
				self:GetOwner():PrintMessage(3, message)
				self:GetOwner():PrintMessage(2, message)
			end
			return false
		end
	elseif (model == "usereloadmodel") then
		if (self.reloadmodel && string.len(self.reloadmodel) > 0) then
			model = self.reloadmodel
		else
			local message = "You need to select a model model."
			if (showerr) then
				self:GetOwner():PrintMessage(3, message)
				self:GetOwner():PrintMessage(2, message)
			end
			return false
		end
	end
	
	if (not util.IsValidModel(model)) then
		//something fucked up, notify user of that
		local message = "This is not a valid model."..model
		if (showerr) then
			self:GetOwner():PrintMessage(3, message)
			self:GetOwner():PrintMessage(2, message)
		end
		return false
	end
	if (not util.IsValidProp(model)) then return false end
	
	return model
end


function TOOL:RightClick( trace )
	
	local ply = self:GetOwner()
	//shot an explosive, update it instead
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_simple_explosive" && trace.Entity:GetTable().pl == ply ) then
		//double you code double your fun (copy from above)
		// Get client's CVars
		local _tirgger		= self:GetClientNumber( "tirgger" ) 
		local _damage 		= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
		local _removeafter	= self:GetClientNumber( "removeafter" ) == 1
		local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
		local _radius		= self:GetClientNumber( "radius" )
		local _freeze		= self:GetClientNumber( "freeze" ) == 1
		local _weld		= self:GetClientNumber( "weld" ) == 1
		local _noparentremove		= self:GetClientNumber( "noparentremove" ) == 1
		local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
		local _weight		= self:GetClientNumber( "weight" )
		
		trace.Entity:GetTable():Setup( _damage, _delaytime, _removeafter, _doblastdamage, _radius, _nocollide )
		
		if (_weight <= 0) then _weight = 1 end
		trace.Entity:GetPhysicsObject():SetMass(_weight)
		
		return true
	end
	
end

function TOOL:Reload( trace )
	//get the model of what was shot and set our reloadmodel to that
	//model info getting code mostly copied from OverloadUT's What Is That? STool
	if !trace.Entity then return false end
	local ent = trace.Entity
	local ply = self:GetOwner()
	local class = ent:GetClass()
	if class == "worldspawn" then
		return false
	else
		local model = ent:GetModel()
		local message = "Model selected: "..model
		self.reloadmodel = model
		ply:PrintMessage(3, message)
		ply:PrintMessage(2, message)
	end
	return true
end

if SERVER then 
	
	function MakeWireSimpleExplosive(pl, Pos, Ang, key, damage, model, removeafter, doblastdamage, radius, nocollide, Vel, aVel, frozen )
	
		if ( !pl:CheckLimit( "wire_simple_explosive" ) ) then return nil end

		local explosive = ents.Create( "gmod_wire_simple_explosive" )
		
		explosive:SetModel( model )
		explosive:SetPos( Pos )	
		explosive:SetAngles( Ang )
		explosive:Spawn()
		explosive:Activate()
		
		explosive:GetTable():Setup( damage, delaytime, removeafter, doblastdamage, radius, nocollide )
		explosive:GetTable():SetPlayer( pl )
		
		local ttable = 
		{
			key = key,
			pl	= pl,
			nocollide = nocollide,
			description = description,
			key = key, 
			damage = damage, 
			model = model, 
			removeafter = removeafter, 
			doblastdamage = doblastdamage, 
			radius = radius
		}
		
		table.Merge( explosive:GetTable(), ttable )
				
		pl:AddCount( "wire_simple_explosive", explosive )
		
		return explosive
		
	end
	
	duplicator.RegisterEntityClass( "gmod_wire_simple_explosive", MakeWireSimpleExplosive, "Pos", "Ang", "key", "damage", "model", "removeafter", "delaytime", "doblastdamage", "radius", "nocollide", "Vel", "aVel", "frozen" )
		
end

function TOOL:UpdateGhostWireSimpleExplosive( ent, player )

	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() ) then -- || trace.Entity:GetClass() == "gmod_wire_simple_explosive"
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

	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetSelModel()) then
		
		local _model = self:GetSelModel()
		if (!_model) then return end
		
		self:MakeGhostEntity( _model, Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireSimpleExplosive( self.GhostEntity, self:GetOwner() )
	
end
