--[[
	This is stool code, 
		These are used by the Wired tools' LeftClick to make/update an ent,
		the part after trace check and before welding/undo/cleanup creation.
]]--


function WireToolMakeGate( self, trace, ply )
	local action	= self:GetClientInfo( "action" )
	local noclip	= self:GetClientNumber( "noclip" ) == 1
	local model		= self:GetClientInfo( "model" )

	if ( GateActions[action] == nil ) then return false end

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_gate" && trace.Entity.pl == ply ) then
		trace.Entity:Setup( GateActions[action], noclip )
		trace.Entity:GetTable().action = action
		return true
	end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	if ( GateActions[action].group == "Arithmetic" and !self:GetSWEP():CheckLimit( "wire_gates" ) ) then return false end
	if ( GateActions[action].group == "Comparison" and !self:GetSWEP():CheckLimit( "wire_gate_comparisons" ) ) then return false end
	if ( GateActions[action].group == "Logic" and !self:GetSWEP():CheckLimit( "wire_gate_logics" ) ) then return false end
	if ( GateActions[action].group == "Memory" and !self:GetSWEP():CheckLimit( "wire_gate_memorys" ) ) then return false end
	if ( GateActions[action].group == "Selection" and !self:GetSWEP():CheckLimit( "wire_gate_selections" ) ) then return false end
	if ( GateActions[action].group == "Time" and !self:GetSWEP():CheckLimit( "wire_gate_times" ) ) then return false end
	if ( GateActions[action].group == "Trig" and !self:GetSWEP():CheckLimit( "wire_gate_trigs" ) ) then return false end
	if ( GateActions[action].group == "Table" and !self:GetSWEP():CheckLimit( "wire_gate_duplexer" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_gate = MakeWireGate( ply, trace.HitPos, Ang, model, action, noclip )

	local min = wire_gate:OBBMins()
	wire_gate:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_gate
end


function WireToolMake7Seg( self, trace, ply )
	
	local model			= self:GetClientInfo( "model" )
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)
	local br			= math.min(self:GetClientNumber("br"), 255)
	local bg			= math.min(self:GetClientNumber("bg"), 255)
	local bb			= math.min(self:GetClientNumber("bb"), 255)
	local ba			= math.min(self:GetClientNumber("ba"), 255)
	local worldweld		= self:GetClientNumber("worldweld") == 1

	-- If we shot a wire_indicator change its force
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_indicator" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(0, ar, ag, ab, aa, 1, br, bg, bb, ba)
		trace.Entity.a	= 0
		trace.Entity.ar	= ar
		trace.Entity.ag	= ag
		trace.Entity.ab	= ab
		trace.Entity.aa	= aa
		trace.Entity.b	= 1
		trace.Entity.br	= br
		trace.Entity.bg	= bg
		trace.Entity.bb	= bb
		trace.Entity.ba	= ba
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_indicators" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		-- Allow ragdolls to be used?
	
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_indicators = MakeWire7Seg( ply, model, Ang, trace.HitPos, trace.HitNormal, 0, ar, ag, ab, aa, 1, br, bg, bb, ba )	
	
	undo.Create("Wire7Seg")
		for x=1, 7 do
			--make welds
			local const = WireLib.Weld(wire_indicators[x], trace.Entity, trace.PhysicsBone, true, false, worldweld)
			undo.AddEntity( wire_indicators[x] )
			undo.AddEntity( const )
			ply:AddCleanup( "wire_indicators", wire_indicators[x] )
			ply:AddCleanup( "wire_indicators", const)
		end
		undo.SetPlayer( ply )
	undo.Finish()
	
	return true --return true so leftclick helper skips making undo/cleanup/weld
	
end


function WireToolMakeIndicator( self, trace, ply )
	
	local noclip		= self:GetClientNumber( "noclip" ) == 1
	local model			= self:GetClientInfo( "model" )
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)
	local b				= self:GetClientNumber("b")
	local br			= math.min(self:GetClientNumber("br"), 255)
	local bg			= math.min(self:GetClientNumber("bg"), 255)
	local bb			= math.min(self:GetClientNumber("bb"), 255)
	local ba			= math.min(self:GetClientNumber("ba"), 255)
	local material		= self:GetClientInfo( "material" )
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_indicator" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
		trace.Entity:SetMaterial( material )
		trace.Entity.a	= a
		trace.Entity.ar	= ar
		trace.Entity.ag	= ag
		trace.Entity.ab	= ab
		trace.Entity.aa	= aa
		trace.Entity.b	= b
		trace.Entity.br	= br
		trace.Entity.bg	= bg
		trace.Entity.bb	= bb
		trace.Entity.ba	= ba
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_indicators" ) ) then return false end
	
	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		-- Allow ragdolls to be used?
	
	local Ang = self:GetGhostAngle(trace.HitNormal:Angle())
	Ang.pitch = Ang.pitch + 90
	
	local wire_indicator = MakeWireIndicator( ply, model, Ang, trace.HitPos, a, ar, ag, ab, aa, b, br, bg, bb, ba, material, noclip )
	
	local min = wire_indicator:OBBMins()
	wire_indicator:SetPos( trace.HitPos - trace.HitNormal * self:GetGhostMin(min) )
	
	return wire_indicator
end


function WireToolMakeConsoleScreen( self, trace, ply )
	
	if ( !self:GetSWEP():CheckLimit( "wire_consolescreens" ) ) then return false end
	
	local model = self:GetClientInfo( "model" )
	
	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_consolescreen = MakeWireconsoleScreen( ply, Ang, trace.HitPos, model )
	local min = wire_consolescreen:OBBMins()
	wire_consolescreen:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_consolescreen
end


function WireToolMakeDigitalScreen( self, trace, ply )
	
	if ( !self:GetSWEP():CheckLimit( "wire_digitalscreens" ) ) then return false end
	
	local model = self:GetClientInfo( "model" )
	
	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_digitalscreen = MakeWireDigitalScreen( ply, Ang, trace.HitPos, model )
	local min = wire_digitalscreen:OBBMins()
	wire_digitalscreen:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_digitalscreen
end


function WireToolMakeEmitter( self, tr, pl )
	
	local r = self:GetClientNumber( "r" );
	local g = self:GetClientNumber( "g" );
	local b = self:GetClientNumber( "b" );
	local a = self:GetClientNumber( "a" );
	local size = self:GetClientNumber( "size" );
	local showbeams = util.tobool( self:GetClientNumber( "showbeams" ) );
	
	// did we hit another holoemitter?
	if( tr.HitNonWorld && tr.Entity:GetClass() == "gmod_wire_holoemitter" ) then
		// update it.
		tr.Entity:SetColor( r, g, b, a );
		
		// update size and show states
		tr.Entity:SetNetworkedBool( "ShowBeam", showbeams );
		tr.Entity:SetNetworkedFloat( "PointSize", size );
		
		tr.Entity.r = r
		tr.Entity.g = g
		tr.Entity.b = b
		tr.Entity.a = a
		tr.Entity.showbeams = showbeams
		tr.Entity.size = size
		
		return true;
	end

	// we linking?
	if( tr.HitNonWorld && tr.Entity:IsValid() && tr.Entity:GetClass() == "gmod_wire_hologrid" ) then
		// link to this point.
		if( self.Emitter && self.Emitter:IsValid() ) then
			// link.
			self.Emitter:LinkToGrid( tr.Entity );
			
			// reset selected emitter
			self.Emitter = nil;
			
			//
			return true;
		else
			// prevent effects
			return false;
		end
	end
	
	// create a holo emitter.
	if( !self:GetSWEP():CheckLimit( "wire_holoemitters" ) ) then return false; end
	
	// fix angle
	local ang = tr.HitNormal:Angle();
	ang.pitch = ang.pitch + 90;
	
	// create emitter
	local emitter = MakeWireHoloemitter( pl, tr.HitPos, ang, r, g, b, a, showbeams, size );
	
	// pull it out of the spawn point
	local mins = emitter:OBBMins();
	emitter:SetPos( tr.HitPos - tr.HitNormal * mins.z );
	
	return emitter
end


function WireToolMakeHoloGrid( self, tr, pl )
	
	if( !self:GetSWEP():CheckLimit( "wire_hologrids" ) ) then return false end
	
	local pl = self:GetOwner()
	
	local ang = tr.HitNormal:Angle()
	ang.p = ang.p + 90
	
	local grid = MakeWireHologrid( pl, tr.HitPos, ang )
	
	local mins = grid:OBBMins()
	grid:SetPos( tr.HitPos - tr.HitNormal * mins.z )
	
	return grid
end


