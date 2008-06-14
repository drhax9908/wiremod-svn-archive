
function WireToolMakeWeight( self, trace, ply )
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_weight" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	local model = self:GetClientInfo( "model" )

	if !self:GetSWEP():CheckLimit( "wire_weights" ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_weight = MakeWireWeight( ply, trace.HitPos, Ang, model )

	local min = wire_weight:OBBMins()
	wire_weight:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_weight
end


function WireToolMakeExplosivesSimple( self, trace, ply )
	if ( !self:GetSWEP():CheckLimit( "wire_simple_explosive" ) ) then return false end
	
	local _tirgger			= self:GetClientNumber( "tirgger" ) 
	local _damage 			= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
	local _removeafter		= self:GetClientNumber( "removeafter" ) == 1
	local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
	local _radius			= math.Clamp( self:GetClientNumber( "radius" ), 0, 10000 )
	local _freeze			= self:GetClientNumber( "freeze" ) == 1
	local _weld				= self:GetClientNumber( "weld" ) == 1
	local _noparentremove	= self:GetClientNumber( "noparentremove" ) == 1
	local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
	local _weight			= math.Max(self:GetClientNumber( "weight" ), 1)
	
	//get & check selected model
	_model = self:GetSelModel( true )
	if (!_model) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local explosive = MakeWireSimpleExplosive( ply, trace.HitPos, Ang, _tirgger, _damage, _model, _removeafter, _doblastdamage, _radius, _nocollide )
	
	local min = explosive:OBBMins()
	explosive:SetPos( trace.HitPos - trace.HitNormal * min.z )
		
	if _freeze then
		explosive:GetPhysicsObject():Sleep() //will freeze the explosive till something touches it
	end
	
	explosive.Entity:GetPhysicsObject():SetMass(_weight)
	// Make sure the weight is duplicated as well (TheApathetic)
	duplicator.StoreEntityModifier( explosive, "MassMod", {Mass = _weight} )
	
	undo.Create("WireSimpleExplosive")
		undo.AddEntity( explosive )
		
	// Don't weld to world
	if ( trace.Entity:IsValid() && _weld ) then
		if (_noparentremove) then 
			local const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0, false )
			undo.AddEntity( const )
		else
			local const, nocollide = constraint.Weld( explosive, trace.Entity, 0, trace.PhysicsBone, 0, collision == 0, true )
			undo.AddEntity( const )
		end
	end
	
		undo.SetPlayer( ply )
	undo.Finish()
	
	return true
end
