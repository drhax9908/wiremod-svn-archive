
function WireToolMakeAdvInput( self, trace, ply )
	
	local _keymore			= self:GetClientNumber( "keymore" )
	local _keyless			= self:GetClientNumber( "keyless" )
	local _toggle			= self:GetClientNumber( "toggle" )
	local _value_min		= self:GetClientNumber( "value_min" )
	local _value_max		= self:GetClientNumber( "value_max" )
	local _value_start		= self:GetClientNumber( "value_start" )
	local _speed			= self:GetClientNumber( "speed" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_adv_input" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( _keymore, _keyless, _toggle, _value_min, _value_max, _value_start, _speed )
		trace.Entity.keymore		= _keymore
		trace.Entity.keyless		= _keyless
		trace.Entity.toggle			= _toggle
		trace.Entity.value_min		= _value_min
		trace.Entity.value_max		= _value_max
		trace.Entity.value_start	= _value_start
		trace.Entity.speed			= _speed
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_adv_inputs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_adv_input = MakeWireAdvInput( ply, trace.HitPos, Ang, _keymore, _keyless, _toggle, _value_min, _value_max, _value_start, _speed )

	local min = wire_adv_input:OBBMins()
	wire_adv_input:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_adv_input
end


function WireToolMakeAdvPod( self, trace, ply )
	
	if not self:GetSWEP():CheckLimit("wire_pods") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_pod = MakeWireAdvPod(ply, trace.HitPos, Ang)

	wire_pod:SetPos(trace.HitPos - trace.HitNormal * wire_pod:OBBMins().z)
	
	return wire_pod
end


function WireToolMakeButton( self, trace, ply )
	
	local _model			= self:GetClientInfo( "model" )
	local _toggle			= (self:GetClientNumber( "toggle" ) ~= 0)
	local _value_off		= self:GetClientNumber( "value_off" )
	local _value_on			= self:GetClientNumber( "value_on" )
	local _description		= self:GetClientInfo( "description" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_button" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(_toggle, _value_off, _value_on)
		trace.Entity.toggle = _toggle
		trace.Entity.value_off = _value_off
		trace.Entity.value_on = _value_on
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_buttons" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_button = MakeWireButton( ply, _model, trace.HitPos, Ang, _toggle, _value_off, _value_on, _description )

	local min = wire_button:OBBMins()
	wire_button:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_button
end


