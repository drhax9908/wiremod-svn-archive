
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


function WireToolMakeLamp( self, trace, ply )
	
	local pos, ang = trace.HitPos + trace.HitNormal * 10, trace.HitNormal:Angle() - Angle( 90, 0, 0 )

	local r 	= math.Clamp( self:GetClientNumber( "r" ), 0, 255 )
	local g 	= math.Clamp( self:GetClientNumber( "g" ), 0, 255 )
	local b 	= math.Clamp( self:GetClientNumber( "b" ), 0, 255 )
	local const = self:GetClientInfo( "const" )
	local texture 	= self:GetClientInfo( "texture" )
	
	if	trace.Entity:IsValid() and 
		trace.Entity:GetClass() == "gmod_wire_lamp" and
		trace.Entity:GetPlayer() == ply
	then
		trace.Entity:SetLightColor( r, g, b )
		trace.Entity.lightr = r
		trace.Entity.lightg = g
		trace.Entity.lightb = b
		trace.Entity:SetFlashlightTexture( texture )
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_lamps" ) ) then return false end
	
	local wire_lamp = MakeWireLamp( ply, r, g, b, texture, { Pos = pos, Angle = ang } )
	
	ply:AddCleanup( "gmod_wire_lamp", wire_lamp )
	
	if (const == "weld") then

		return wire_lamp --helper left click will do weld

	elseif (const == "rope") then

		local length 	= self:GetClientNumber( "ropelength" )
		local material 	= self:GetClientInfo( "ropematerial" )

		local LPos1 = Vector( 0, 0, 5 )
		local LPos2 = trace.Entity:WorldToLocal( trace.HitPos )

		if (trace.Entity:IsValid()) then     
			local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
			if (phys:IsValid()) then
				LPos2 = phys:WorldToLocal( trace.HitPos )
			end
		end
		
		local constraint, rope = constraint.Rope( wire_lamp, trace.Entity, 
												  0, trace.PhysicsBone, 
												  LPos1, LPos2, 
												  0, length,
												  0, 
												  1.5, 
												  material, 
												  nil )
		
		undo.Create("gmod_wire_lamp")
			undo.AddEntity( wire_lamp )
			undo.AddEntity( rope )
			undo.AddEntity( constraint )
			undo.SetPlayer( ply )
		undo.Finish()

		return true

	else --none
	
		undo.Create("gmod_wire_lamp")
			undo.AddEntity( wire_lamp )
			undo.SetPlayer( ply )
		undo.Finish()

		return true
	end
end


function WireToolMakeLight( self, trace, ply )
	
	local directional	= (self:GetClientNumber("directional") ~= 0)
	local radiant	= (self:GetClientNumber("radiant") ~= 0)

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_light" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(directional, radiant)
		trace.Entity.directional = directional
		trace.Entity.radiant = radiant
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_lights" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_light = MakeWireLight( ply, Ang, trace.HitPos, directional, radiant )
	
	local min = wire_light:OBBMins()
	wire_light:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_light
end


function WireToolMakeOscilloscope( self, trace, ply )
	
	local model = self:GetClientInfo( "model" )
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_oscilloscope = MakeWireOscilloscope( ply, Ang, trace.HitPos, model )
	
	local min = wire_oscilloscope:OBBMins()
	wire_oscilloscope:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_oscilloscope
end


function WireToolMakePanel( self, trace, ply )
	
	local model		= self:GetClientInfo( "model" )
	local CreateFlat	= self:GetClientNumber( "createflat" )
	local weld			= self:GetClientNumber( "createflat" ) == 1
	
	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end
	
	local Ang			= trace.HitNormal:Angle()
	if (CreateFlat == 0) then --Weld panel flat to surface shot instead of perpendicular to it? (TheApathetic)
		Ang.pitch = Ang.pitch + 90
	end
	
	local wire_panel = MakeWirePanel( ply, Ang, trace.HitPos, model )
	
	local min = wire_panel:OBBMins()
	wire_panel:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_panel
end


function WireToolMakePixel( self, trace, ply )
	
	local nocollide			= self:GetClientNumber( "noclip" ) == 1
	local model             = self:GetClientInfo( "model" )
	
	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_pixel" && trace.Entity:GetTable().pl == ply ) then
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_pixels" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_pixel = MakeWirePixel( ply, Ang, trace.HitPos, model, nocollide )
	
	local min = wire_pixel:OBBMins()
	wire_pixel:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_pixel 
end


function WireToolMakeScreen( self, trace, ply )
	
	local Smodel	= self:GetClientInfo( "model" )
	
	if (not util.IsValidModel(Smodel)) then return false end
	if (not util.IsValidProp(Smodel)) then return false end
	
	// Extra stuff for Wire Screen (TheApathetic)
	local SingleValue	= self:GetClientNumber("singlevalue") == 1
	local SingleBigFont	= self:GetClientNumber("singlebigfont") == 1
	local TextA			= self:GetClientInfo("texta")
	local TextB			= self:GetClientInfo("textb")
	local LeftAlign		= self:GetClientNumber("leftalign") == 1
	local Floor			= self:GetClientNumber("floor") == 1
	local CreateFlat		= self:GetClientNumber("createflat")

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_screen" && trace.Entity.pl == ply) then
		trace.Entity:Setup(SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor)
		
		trace.Entity.SingleValue	= SingleValue
		trace.Entity.SingleBigFont	= SingleBigFont
		trace.Entity.TextA			= TextA
		trace.Entity.TextB 			= TextB
		trace.Entity.LeftAlign 		= LeftAlign
		trace.Entity.Floor	 		= Floor
		return true
	end

	local Ang		= trace.HitNormal:Angle()
	if (CreateFlat == 0) then --Make screens spawn flat on props instead of perpendicular to them (TheApathetic)
		Ang.pitch = Ang.pitch + 90
	end
	
	local wire_screen = MakeWireScreen( ply, Ang, trace.HitPos, Smodel, SingleValue, SingleBigFont, TextA, TextB, LeftAlign, Floor )
	
	local min = wire_screen:OBBMins()
	wire_screen:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_screen
end


function WireToolMakeSoundEmitter( self, trace, ply )
	
	local sound			= Sound( self:GetClientInfo( "sound" ) )
	local collision		= (self:GetClientInfo( "collision" ) ~= 0)
	local model			= self:GetClientInfo( "model" )

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_soundemitter" && trace.Entity.pl == ply ) then
		trace.Entity:SetSound( Sound(sound) )
		trace.Entity.sound	= sound
		return true
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_emitters" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_emitter = MakeWireEmitter( ply, model, Ang, trace.HitPos, sound )
	
	local min = wire_emitter:OBBMins()
	wire_emitter:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_emitter
end


function WireToolMakeTextScreen( self, trace, ply )
	
	if ( !self:GetSWEP():CheckLimit( "wire_textscreens" ) ) then return false end
	
	local Smodel = self.Model
	if (not util.IsValidModel(Smodel)) then return false end
	if (not util.IsValidProp(Smodel)) then return false end

	local TextList = {}
	for i = 1, 12 do
		TextList[i] = self:GetClientInfo("text"..i)
	end
	local chrPerLine = 16 - tonumber(self:GetClientInfo("tsize"))
	local textJust = self:GetClientInfo("tjust")
	local tRed		= math.min(self:GetClientNumber("tred"), 255)
	local tGreen	= math.min(self:GetClientNumber("tgreen"), 255)
	local tBlue		= math.min(self:GetClientNumber("tblue"), 255)

	local numInputs	= self:GetClientNumber("ninputs")
	local CreateFlat = self:GetClientNumber("createflat")
	local defaultOn = self:GetClientNumber("defaulton")

	if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_textscreen" && trace.Entity.pl == ply) then
		trace.Entity:Setup(TextList, chrPerLine, textJust, tRed, tGreen, tBlue, numInputs, defaultOn)
		trace.Entity.TextList	= TextList
		trace.Entity.chrPerLine	= chrPerLine
		trace.Entity.textJust	= textJust
		trace.Entity.tRed		= tRed
		trace.Entity.tGreen		= tGreen
		trace.Entity.tBlue		= tBlue
		trace.Entity.numInputs	= numInputs
		trace.Entity.defaultOn	= defaultOn
		return true
	end

	local Ang = trace.HitNormal:Angle()
	if (CreateFlat == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	local wire_textscreen = MakeWireTextScreen( ply, Ang, trace.HitPos, Model(self.Model), TextList, chrPerLine, textJust, tRed, tGreen, tBlue, numInputs, defaultOn)
	
	local min = wire_textscreen:OBBMins()
	wire_textscreen:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_textscreen
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
